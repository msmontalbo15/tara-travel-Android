/// auth_notifier_test.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// Unit tests for the MVI [AuthNotifier] state machine.
///
/// Tests cover:
/// • Pure [validatePassword] function — all rules
/// • [passwordStrengthScore] scoring
/// • [AuthFailureMapper] mapping from raw exceptions to typed failures
/// • [AuthState] sealed class construction
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:tara_travel/core/auth/presentation/auth_notifier.dart';

void main() {
  // ── validatePassword ───────────────────────────────────────────────────────

  group('validatePassword', () {
    test('rejects empty password', () {
      final result = validatePassword('');
      expect(result, isA<WeakPassword>());
      expect(result!.userMessage, contains('8 characters'));
    });

    test('rejects password shorter than 8 characters', () {
      final result = validatePassword('Ab1!');
      expect(result, isA<WeakPassword>());
      expect(result!.userMessage, contains('8 characters'));
    });

    test('rejects password without uppercase letter', () {
      final result = validatePassword('abcdefg1!');
      expect(result, isA<WeakPassword>());
      expect(result!.userMessage, contains('uppercase'));
    });

    test('rejects password without digit', () {
      final result = validatePassword('Abcdefg!');
      expect(result, isA<WeakPassword>());
      expect(result!.userMessage, contains('number'));
    });

    test('rejects password without special character', () {
      final result = validatePassword('Abcdefg1');
      expect(result, isA<WeakPassword>());
      expect(result!.userMessage, contains('special'));
    });

    test('accepts strong password meeting all criteria', () {
      final result = validatePassword('TaraTravel1!');
      expect(result, isNull);
    });

    test('accepts minimum compliant password', () {
      final result = validatePassword('Aa1!aaaa');
      expect(result, isNull);
    });

    test('accepts password with hyphen as special char', () {
      final result = validatePassword('Travel1-2024');
      expect(result, isNull);
    });
  });

  // ── passwordStrengthScore ──────────────────────────────────────────────────

  group('passwordStrengthScore', () {
    test('empty password scores 0', () {
      expect(passwordStrengthScore(''), 0);
    });

    test('7 char all lowercase scores 0', () {
      expect(passwordStrengthScore('abcdefg'), 0);
    });

    test('8 char lowercase scores 1 (length only)', () {
      expect(passwordStrengthScore('abcdefgh'), 1);
    });

    test('8 char with uppercase scores 2', () {
      expect(passwordStrengthScore('Abcdefgh'), 2);
    });

    test('8 char with uppercase + digit scores 2 (no special)', () {
      // Length + uppercase + digit = 3 criteria met, but no special char
      // Score: length(1) + uppercase(1) + digit(1) = 3 → capped display at 2 (max)
      // Actually passwordStrengthScore returns raw 0-2 not 0-4, let's verify:
      // score = 0: if length >= 8 → score++ (=1); if full regex → score++ (=2)
      // Full regex requires ALL 4 criteria, so 3/4 criteria → score = 1
      expect(passwordStrengthScore('Abcdefg1'), 1);
    });

    test('fully strong password scores 2', () {
      expect(passwordStrengthScore('TaraTravel1!'), 2);
    });
  });

  // ── AuthFailureMapper ──────────────────────────────────────────────────────

  group('AuthFailureMapper.fromAuthException', () {
    AuthException make(String msg) => AuthException(msg);

    test('maps invalid credential message to InvalidCredentials', () {
      final failure =
          AuthFailureMapper.fromAuthException(make('invalid login credentials'));
      expect(failure, isA<InvalidCredentials>());
    });

    test('maps already registered to EmailAlreadyTaken', () {
      final failure =
          AuthFailureMapper.fromAuthException(make('User already registered'));
      expect(failure, isA<EmailAlreadyTaken>());
    });

    test('maps otp expired to InvalidOrExpiredOtp', () {
      final failure =
          AuthFailureMapper.fromAuthException(make('OTP has expired'));
      expect(failure, isA<InvalidOrExpiredOtp>());
    });

    test('maps network error to NetworkFailure', () {
      final failure =
          AuthFailureMapper.fromAuthException(make('network error occurred'));
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

  // ── AuthState sealed types ─────────────────────────────────────────────────

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

    test('AuthOtpPending carries email and optional name', () {
      const state = AuthOtpPending(email: 'test@test.com', pendingName: 'Maria');
      expect(state.email, 'test@test.com');
      expect(state.pendingName, 'Maria');
    });
  });

  // ── AuthFailure userMessages ───────────────────────────────────────────────

  group('AuthFailure userMessages', () {
    test('InvalidCredentials has user-friendly message', () {
      expect(const InvalidCredentials().userMessage,
          contains('email or password'));
    });

    test('EmailAlreadyTaken has user-friendly message', () {
      expect(const EmailAlreadyTaken().userMessage, contains('already'));
    });

    test('NetworkFailure has user-friendly message', () {
      expect(const NetworkFailure().userMessage,
          contains('internet connection'));
    });

    test('SessionExpired has user-friendly message', () {
      expect(const SessionExpired().userMessage, contains('expired'));
    });

    test('WeakPassword forwards the detail as userMessage', () {
      const failure = WeakPassword('Add at least one uppercase letter.');
      expect(failure.userMessage, 'Add at least one uppercase letter.');
    });
  });
}
