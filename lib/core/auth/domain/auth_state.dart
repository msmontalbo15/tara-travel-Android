/// auth_state.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// MVI-style sealed state hierarchy for the authentication flow.
///
/// All UI widgets observe [AuthState] from [authNotifierProvider] and react
/// deterministically. No raw `bool isLoading` or `String? error` fields are
/// needed in the presentation layer.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'package:supabase_flutter/supabase_flutter.dart';

// ── AuthState ─────────────────────────────────────────────────────────────────

/// Sealed hierarchy representing every possible authentication lifecycle state.
sealed class AuthState {
  const AuthState();
}

/// Initial / signed-out state.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// An async operation is in-flight (sign-in, session restore, etc.).
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// The user is fully authenticated and a valid Supabase session exists.
final class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);
}

/// A non-fatal error occurred. The user may retry if [isRetryable] is true.
final class AuthError extends AuthState {
  final String message;
  final bool isRetryable;

  const AuthError({required this.message, this.isRetryable = true});
}

// ── AuthFailure ───────────────────────────────────────────────────────────────

/// Typed failure sealed class. Converts raw Supabase / platform exceptions
/// into user-facing messages without leaking internal stack traces.
sealed class AuthFailure implements Exception {
  const AuthFailure();

  /// Returns a localised, user-friendly message safe for display in the UI.
  String get userMessage;
}

final class NetworkFailure extends AuthFailure {
  const NetworkFailure();

  @override
  String get userMessage => 'No internet connection. Please check your network.';
}

final class GoogleSignInCancelled extends AuthFailure {
  const GoogleSignInCancelled();

  @override
  String get userMessage => 'Google sign-in was cancelled.';
}

final class SessionExpired extends AuthFailure {
  const SessionExpired();

  @override
  String get userMessage =>
      'Your session has expired. Please sign in again.';
}

final class BiometricFailed extends AuthFailure {
  const BiometricFailed();

  @override
  String get userMessage =>
      'Biometric authentication failed. Please try again or sign in with Google.';
}

final class OfflineSessionExpired extends AuthFailure {
  const OfflineSessionExpired();

  @override
  String get userMessage =>
      'Your offline session has expired. Please connect to the internet and sign in with Google.';
}

final class UnknownAuthFailure extends AuthFailure {
  final String raw;

  const UnknownAuthFailure(this.raw);

  @override
  String get userMessage =>
      raw.length > 80 ? 'Authentication failed. Please try again.' : raw;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Maps a raw [AuthException] message to a strongly-typed [AuthFailure].
extension AuthFailureMapper on AuthFailure {
  static AuthFailure fromAuthException(AuthException e) {
    final msg = e.message.toLowerCase();

    if (msg.contains('network') || msg.contains('socket')) {
      return const NetworkFailure();
    }
    return UnknownAuthFailure(e.message);
  }

  static AuthFailure fromException(Object e) {
    if (e is AuthException) return fromAuthException(e);
    final msg = e.toString().toLowerCase();
    if (msg.contains('network') || msg.contains('socket')) {
      return const NetworkFailure();
    }
    return UnknownAuthFailure(e.toString());
  }
}
