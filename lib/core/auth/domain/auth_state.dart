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

/// An async operation is in-flight (sign-in, sign-up, OTP send, etc.).
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// The user is fully authenticated and a valid Supabase session exists.
final class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);
}

/// Sign-up succeeded but email OTP confirmation is pending.
final class AuthOtpPending extends AuthState {
  /// The email address that the OTP was sent to.
  final String email;

  /// The display name entered during registration (preserved across the
  /// OTP screen so it can be forwarded to the profile after verification).
  final String? pendingName;

  const AuthOtpPending({required this.email, this.pendingName});
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

final class InvalidCredentials extends AuthFailure {
  const InvalidCredentials();

  @override
  String get userMessage => 'Incorrect email or password.';
}

final class EmailAlreadyTaken extends AuthFailure {
  const EmailAlreadyTaken();

  @override
  String get userMessage =>
      'This email is already registered. Try signing in instead.';
}

final class InvalidOrExpiredOtp extends AuthFailure {
  const InvalidOrExpiredOtp();

  @override
  String get userMessage => 'Invalid or expired verification code. Request a new one.';
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

final class WeakPassword extends AuthFailure {
  final String detail;

  const WeakPassword(this.detail);

  @override
  String get userMessage => detail;
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
/// Call site: `AuthFailure.fromAuthException(e)`
extension AuthFailureMapper on AuthFailure {
  static AuthFailure fromAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid') && msg.contains('credential')) {
      return const InvalidCredentials();
    }
    if (msg.contains('already registered') || msg.contains('already exists')) {
      return const EmailAlreadyTaken();
    }
    if (msg.contains('invalid otp') ||
        msg.contains('otp expired') ||
        msg.contains('token') ||
        msg.contains('expired')) {
      return const InvalidOrExpiredOtp();
    }
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
