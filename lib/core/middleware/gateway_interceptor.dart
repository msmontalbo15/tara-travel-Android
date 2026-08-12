/// gateway_interceptor.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// Dio [QueuedInterceptorsWrapper] that acts as the Middleware/Gateway layer
/// between the Flutter app and all external API calls.
///
/// REQUEST pipeline (executed for every outbound call):
///   1. Connectivity Check  — throws [OfflineException] if no internet
///   2. Rate Limiter        — sliding window: 30 requests / 60 s per endpoint
///   3. TLS Enforcer        — rejects plain HTTP URLs
///   4. Token Injector      — attaches Bearer token from SecureSessionRepository
///
/// RESPONSE pipeline:
///   5. Token Refresher     — on HTTP 401: calls recoverSession() once, retries
///                            2nd consecutive 401 → forces sign-out
///   6. Audit Logger        — records method, path, status, latency
///   7. Error Normaliser    — maps 4xx/5xx to descriptive [DioException]
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../auth/data/secure_session_repository.dart';
import '../services/connectivity_service.dart';
import 'audit_logger.dart';
import 'token_service.dart';

// ── Custom Exception ──────────────────────────────────────────────────────────

class OfflineException implements Exception {
  const OfflineException();
  @override
  String toString() => 'OfflineException: No internet connection.';
}

// ── Gateway Interceptor ───────────────────────────────────────────────────────

class GatewayInterceptor extends QueuedInterceptorsWrapper {
  // ── Rate Limiter state ─────────────────────────────────────────────────────
  // Map<endpointPath, Queue<requestTimestamp>>
  final Map<String, Queue<DateTime>> _rateLimitWindows = {};
  static const int _maxRequests = 30;
  static const Duration _windowDuration = Duration(seconds: 60);

  // ── 401 circuit-breaker ────────────────────────────────────────────────────
  bool _isRefreshing = false;
  int _consecutiveUnauthorized = 0;
  static const int _maxUnauthorized = 2;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final stopwatch = Stopwatch()..start();
    options.extra['_stopwatch'] = stopwatch;

    try {
      // 1. Connectivity Check ─────────────────────────────────────────────────
      final isOnline = await ConnectivityService.instance.isOnline;
      if (!isOnline) {
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            error: const OfflineException(),
            message: 'No internet connection.',
          ),
        );
      }

      // 2. Rate Limiter ────────────────────────────────────────────────────────
      final path = options.path;
      final now = DateTime.now();
      final window = _rateLimitWindows.putIfAbsent(path, () => Queue<DateTime>());

      // Purge timestamps outside the sliding window
      while (window.isNotEmpty &&
          now.difference(window.first) > _windowDuration) {
        window.removeFirst();
      }

      if (window.length >= _maxRequests) {
        debugPrint('[GatewayInterceptor] Rate limit reached for: $path');
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            message: 'Rate limit exceeded. Please wait before trying again.',
          ),
        );
      }
      window.addLast(now);

      // 3. TLS Enforcer ────────────────────────────────────────────────────────
      if (options.uri.scheme == 'http') {
        debugPrint('[GatewayInterceptor] Blocked insecure HTTP request: ${options.uri}');
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badCertificate,
            message: 'Insecure HTTP requests are not permitted.',
          ),
        );
      }

      // 4. Token Injector ──────────────────────────────────────────────────────
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null && !TokenService.isTokenExpired(session.accessToken)) {
        options.headers.addAll(
            TokenService.buildAuthHeader(session.accessToken));
      }

      handler.next(options);
    } catch (e) {
      debugPrint('[GatewayInterceptor] onRequest error: $e');
      handler.next(options); // Fail open — let the request proceed
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _consecutiveUnauthorized = 0; // Reset on success

    // 6. Audit Logger ──────────────────────────────────────────────────────────
    final sw = response.requestOptions.extra['_stopwatch'] as Stopwatch?;
    AuditLogger.instance.logRequest(
      method: response.requestOptions.method,
      path: response.requestOptions.path,
      statusCode: response.statusCode ?? 0,
      latencyMs: sw?.elapsedMilliseconds ?? 0,
      userId: Supabase.instance.client.auth.currentUser?.id,
    );

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final sw = err.requestOptions.extra['_stopwatch'] as Stopwatch?;

    // 5. Token Refresher ───────────────────────────────────────────────────────
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _consecutiveUnauthorized++;

      if (_consecutiveUnauthorized >= _maxUnauthorized) {
        // Circuit breaker: too many 401s → force sign-out
        debugPrint(
            '[GatewayInterceptor] Circuit breaker: $_consecutiveUnauthorized consecutive 401s. Signing out.');
        _consecutiveUnauthorized = 0;
        // Wipe the stored session so the user sees the login screen
        await SecureSessionRepository.instance.clearSession();
        return handler.next(err);
      }

      _isRefreshing = true;
      try {
        final refreshed = await Supabase.instance.client.auth.refreshSession();
        _isRefreshing = false;

        if (refreshed.session != null) {
          await SecureSessionRepository.instance
              .persistSession(refreshed.session!);
          debugPrint('[GatewayInterceptor] Token refreshed successfully.');

          // Retry the original request with the new token
          final opts = err.requestOptions;
          opts.headers.addAll(
              TokenService.buildAuthHeader(refreshed.session!.accessToken));

          try {
            final dio = Dio();
            final retryResponse = await dio.fetch(opts);
            return handler.resolve(retryResponse);
          } catch (retryErr) {
            debugPrint('[GatewayInterceptor] Retry after refresh failed: $retryErr');
          }
        }
      } catch (refreshErr) {
        _isRefreshing = false;
        debugPrint('[GatewayInterceptor] Token refresh failed: $refreshErr');
      }
    }

    // 6. Audit Logger (error path) ─────────────────────────────────────────────
    AuditLogger.instance.logRequest(
      method: err.requestOptions.method,
      path: err.requestOptions.path,
      statusCode: err.response?.statusCode ?? 0,
      latencyMs: sw?.elapsedMilliseconds ?? 0,
      userId: Supabase.instance.client.auth.currentUser?.id,
      offline: err.error is OfflineException,
    );

    // 7. Error Normaliser ──────────────────────────────────────────────────────
    final status = err.response?.statusCode;
    String? message;
    if (status == 403) message = 'You don\'t have permission to perform this action.';
    if (status == 404) message = 'The requested resource was not found.';
    if (status == 429) message = 'Too many requests. Please wait and try again.';
    if (status != null && status >= 500) {
      message = 'Server error. Please try again later.';
    }

    if (message != null) {
      return handler.next(DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: err.error,
        message: message,
      ));
    }

    handler.next(err);
  }
}
