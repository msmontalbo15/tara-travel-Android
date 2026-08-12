/// auth_notifier_test.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// Unit tests for the MVI [AuthState] sealed hierarchy and
/// [AuthFailureMapper] — updated to reflect the Google + Biometric-only
/// authentication system (email/password auth has been removed).
///
/// Tests cover:
/// • [AuthState] sealed class construction and invariants
/// • [AuthFailureMapper] mapping from raw exceptions to typed failures
/// • [AuthFailure] user-facing message contracts
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:tara_travel/core/auth/domain/auth_state.dart';

void main() {
  // ── AuthState sealed hierarchy ─────────────────────────────────────────────

  group('AuthState sealed hierarchy', () {
    test('AuthUnauthenticated is an AuthState', () {
      const state = AuthUnauthenticated();
      expect(state, isA<AuthState>());
    });

    test('AuthLoading is an AuthState', () {
      const state = AuthLoading();
      expect(state, isA<AuthState>());
    });

    test('AuthError carries message and isRetryable defaults to true', () {
      const state = AuthError(message: 'test error');
      expect(state.message, 'test error');
      expect(state.isRetryable, isTrue);
    });

    test('AuthError can be non-retryable', () {
      const state = AuthError(message: 'fatal error', isRetryable: false);
      expect(state.isRetryable, isFalse);
    });
  });

  // ── AuthFailureMapper ──────────────────────────────────────────────────────

  group('AuthFailureMapper.fromAuthException', () {
    AuthException make(String msg) => AuthException(msg);

    test('maps network error to NetworkFailure', () {
      final failure =
          AuthFailureMapper.fromAuthException(make('network error occurred'));
      expect(failure, isA<NetworkFailure>());
    });

    test('maps socket error to NetworkFailure', () {
      final failure =
          AuthFailureMapper.fromAuthException(make('socket connection failed'));
      expect(failure, isA<NetworkFailure>());
    });

    test('maps unknown errors to UnknownAuthFailure', () {
      final failure =
          AuthFailureMapper.fromAuthException(make('something unexpected'));
      expect(failure, isA<UnknownAuthFailure>());
    });

    test('unknown long messages are truncated in userMessage', () {
      final longMsg = 'x' * 100;
      final failure = AuthFailureMapper.fromAuthException(make(longMsg));
      expect(failure, isA<UnknownAuthFailure>());
      expect(failure.userMessage, isNot(contains(longMsg)));
      expect(failure.userMessage, contains('try again'));
    });
  });

  group('AuthFailureMapper.fromException', () {
    test('wraps non-AuthException network errors as NetworkFailure', () {
      // ignore: prefer_const_constructors
      final failure = AuthFailureMapper.fromException(
          Exception('network error in socket layer'));
      expect(failure, isA<NetworkFailure>());
    });

    test('wraps unknown exceptions as UnknownAuthFailure', () {
      // ignore: prefer_const_constructors
      final failure =
          AuthFailureMapper.fromException(Exception('totally unknown'));
      expect(failure, isA<UnknownAuthFailure>());
    });

    test('re-wraps AuthException via fromAuthException', () {
      final failure =
          AuthFailureMapper.fromException(const AuthException('network timeout'));
      expect(failure, isA<NetworkFailure>());
    });
  });

  // ── AuthFailure userMessages ───────────────────────────────────────────────

  group('AuthFailure userMessages', () {
    test('NetworkFailure has user-friendly message', () {
      expect(const NetworkFailure().userMessage, contains('internet connection'));
    });

    test('GoogleSignInCancelled has user-friendly message', () {
      expect(const GoogleSignInCancelled().userMessage, contains('cancelled'));
    });

    test('SessionExpired has user-friendly message', () {
      expect(const SessionExpired().userMessage, contains('expired'));
    });

    test('BiometricFailed has user-friendly message', () {
      expect(const BiometricFailed().userMessage, contains('Biometric'));
    });

    test('OfflineSessionExpired has user-friendly message', () {
      expect(
          const OfflineSessionExpired().userMessage, contains('offline'));
    });

    test('UnknownAuthFailure short message is returned as-is', () {
      const failure = UnknownAuthFailure('Short error.');
      expect(failure.userMessage, 'Short error.');
    });

    test('UnknownAuthFailure long message (>80 chars) is replaced with generic text', () {
      final longMsg = 'A very detailed internal error message ' * 5;
      final failure = UnknownAuthFailure(longMsg);
      expect(failure.userMessage, contains('try again'));
      expect(failure.userMessage, isNot(contains(longMsg)));
    });
  });
}
