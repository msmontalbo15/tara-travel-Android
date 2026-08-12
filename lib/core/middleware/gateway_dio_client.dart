/// gateway_dio_client.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// Factory that builds a pre-configured [Dio] instance with the
/// [GatewayInterceptor] chain mounted.
///
/// All HTTP calls outside of the Supabase SDK (e.g. direct REST calls,
/// third-party APIs) should use the [Dio] instance from [gatewayDioProvider]
/// so they benefit from rate limiting, token injection, refresh, and auditing.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'gateway_interceptor.dart';

class GatewayDioClient {
  GatewayDioClient._();

  /// Builds a [Dio] instance with the full gateway interceptor chain.
  static Dio build() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Mount the gateway interceptor — order matters:
    // QueuedInterceptorsWrapper serialises concurrent requests through the
    // same interceptor, preventing race conditions in the rate limiter and
    // the 401 refresh circuit breaker.
    dio.interceptors.add(GatewayInterceptor());

    return dio;
  }
}

// ── Riverpod Provider ──────────────────────────────────────────────────────────

/// Provides a shared [Dio] instance with the gateway interceptor chain mounted.
/// Use this for all HTTP calls that are NOT routed through the Supabase SDK.
final gatewayDioProvider = Provider<Dio>((ref) {
  return GatewayDioClient.build();
});
