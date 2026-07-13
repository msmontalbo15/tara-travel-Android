/// auth_notifier.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// MVI-style [AsyncNotifier] that owns all authentication business logic.
///
/// The UI layer dispatches *intents* (method calls) and observes [AuthState]
/// transitions — no raw `bool isLoading` or `String? error` state anywhere
/// in the presentation layer.
///
/// Security guarantees:
/// • Client-side rate-limit guard: rejects rapid retries < 2 s apart.
/// • Password strength enforced before any network call.
/// • All tokens persisted via [SecureSessionRepository] (Keystore / Keychain).
/// • Session restore runs at app startup in main() before runApp().
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../repositories/auth_repository.dart';
import '../data/secure_session_repository.dart';
import '../domain/auth_state.dart';
import '../../providers/repository_providers.dart';

export '../domain/auth_state.dart';

// ── Password Validation ───────────────────────────────────────────────────────

/// Production password rules (client-side pre-flight):
/// • Minimum 8 characters
/// • At least one uppercase letter
/// • At least one digit
/// • At least one special character (!@#$%^&*-_=+?)
final _passwordRegex =
    RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*\-_=+?]).{8,}$');

/// Validates [password] and returns a [WeakPassword] failure if invalid,
/// or `null` if the password is strong enough.
AuthFailure? validatePassword(String password) {
  if (password.length < 8) {
    return const WeakPassword('Password must be at least 8 characters.');
  }
  if (!RegExp(r'[A-Z]').hasMatch(password)) {
    return const WeakPassword('Add at least one uppercase letter.');
  }
  if (!RegExp(r'\d').hasMatch(password)) {
    return const WeakPassword('Add at least one number.');
  }
  if (!RegExp(r'[!@#$%^&*\-_=+?]').hasMatch(password)) {
    return const WeakPassword('Add at least one special character (!@#\$%^&*).');
  }
  return null; // Strong ✓
}

/// Scores password strength: 0 = weak, 1 = fair, 2 = strong.
int passwordStrengthScore(String password) {
  int score = 0;
  if (password.length >= 8) score++;
  if (_passwordRegex.hasMatch(password)) score++;
  return score;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<AuthState> {
  // Rate-limit: minimum milliseconds between auth attempts.
  static const _kMinRetryMs = 2000;
  DateTime? _lastAttempt;

  AuthRepository get _authRepo => ref.read(authRepositoryProvider);
  SecureSessionRepository get _sessionRepo => SecureSessionRepository.instance;

  @override
  Future<AuthState> build() async {
    // On first build, determine the initial auth state from the Supabase
    // client (which may have been hydrated from SecureSessionRepository
    // in main() before runApp).
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      return AuthAuthenticated(currentUser);
    }
    return const AuthUnauthenticated();
  }

  // ── Rate Limiting ─────────────────────────────────────────────────────────

  bool _throttled() {
    if (_lastAttempt == null) return false;
    return DateTime.now().difference(_lastAttempt!) <
        const Duration(milliseconds: _kMinRetryMs);
  }

  void _recordAttempt() => _lastAttempt = DateTime.now();

  // ── Google Sign-In ────────────────────────────────────────────────────────

  /// Initiates native Google Sign-In via the google_sign_in package.
  /// The underlying Credential Manager API is used automatically on
  /// Android 14+ when the package version supports it.
  Future<void> signInWithGoogle() async {
    if (_throttled()) return;
    _recordAttempt();

    state = const AsyncData(AuthLoading());
    try {
      final user = await _authRepo.signInWithGoogle();
      if (user == null) {
        // User dismissed the picker — not an error.
        state = const AsyncData(AuthUnauthenticated());
        return;
      }

      // Persist session tokens to Keystore-backed encrypted storage.
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await _sessionRepo.persistSession(session);
      }

      state = AsyncData(AuthAuthenticated(user));
    } on AuthFailure catch (f) {
      state = AsyncData(AuthError(message: f.userMessage));
    } on AuthException catch (e) {
      final failure = AuthFailureMapper.fromAuthException(e);
      state = AsyncData(AuthError(message: failure.userMessage));
    } catch (e) {
      debugPrint('[AuthNotifier] signInWithGoogle unexpected: $e');
      state = const AsyncData(
          AuthError(message: 'Google sign-in failed. Please try again.'));
    }
  }

  // ── Email Sign-In ─────────────────────────────────────────────────────────

  /// Signs in an existing user with [email] and [password].
  Future<void> signInWithEmail(String email, String password) async {
    if (_throttled()) return;
    _recordAttempt();

    state = const AsyncData(AuthLoading());
    try {
      final response =
          await _authRepo.signInWithEmailPassword(email, password);
      final user = response.user;
      if (user == null) {
        state = const AsyncData(
            AuthError(message: 'Sign-in failed. Please try again.'));
        return;
      }

      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await _sessionRepo.persistSession(session);
      }

      state = AsyncData(AuthAuthenticated(user));
    } on AuthException catch (e) {
      final failure = AuthFailureMapper.fromAuthException(e);
      state = AsyncData(AuthError(message: failure.userMessage));
    } catch (e) {
      final failure = AuthFailureMapper.fromException(e);
      state = AsyncData(AuthError(message: failure.userMessage));
    }
  }

  // ── Email Sign-Up ─────────────────────────────────────────────────────────

  /// Registers a new user. Returns [AuthOtpPending] if email confirmation
  /// is required, or [AuthAuthenticated] if confirmation is disabled in
  /// the Supabase project.
  Future<void> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    if (_throttled()) return;
    _recordAttempt();

    // Client-side password strength gate — runs before any network call.
    final pwFailure = validatePassword(password);
    if (pwFailure != null) {
      state = AsyncData(AuthError(message: pwFailure.userMessage));
      return;
    }

    state = const AsyncData(AuthLoading());
    try {
      final response = await _authRepo.signUpWithEmailPassword(
        email,
        password,
        displayName: displayName,
      );

      if (response.user != null && response.session == null) {
        // Email confirmation required → OTP screen.
        state = AsyncData(
            AuthOtpPending(email: email, pendingName: displayName));
      } else if (response.user != null && response.session != null) {
        // Confirmation disabled → immediately authenticated.
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) await _sessionRepo.persistSession(session);
        state = AsyncData(AuthAuthenticated(response.user!));
      } else {
        state = const AsyncData(
            AuthError(message: 'Registration failed. Please try again.'));
      }
    } on AuthException catch (e) {
      final failure = AuthFailureMapper.fromAuthException(e);
      state = AsyncData(AuthError(message: failure.userMessage));
    } catch (e) {
      final failure = AuthFailureMapper.fromException(e);
      state = AsyncData(AuthError(message: failure.userMessage));
    }
  }

  // ── OTP Verification ──────────────────────────────────────────────────────

  /// Verifies a 6-digit [code] sent to [email]. Tries `signup` OTP type
  /// first, then falls back to `email` type (for magic-link resend paths).
  Future<void> verifyOtp(String email, String code, {String? pendingName}) async {
    if (code.length < 6) {
      state = const AsyncData(
          AuthError(message: 'Enter the full 6-digit verification code.'));
      return;
    }

    state = const AsyncData(AuthLoading());
    try {
      AuthResponse response;
      try {
        response = await _authRepo.verifySignupOtp(email, code);
      } on AuthException {
        response = await _authRepo.verifyEmailOtp(email, code);
      }

      final user = response.user;
      if (user == null) {
        state = const AsyncData(
            AuthError(message: 'Verification failed. Please try again.'));
        return;
      }

      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) await _sessionRepo.persistSession(session);

      state = AsyncData(AuthAuthenticated(user));
    } on AuthException catch (e) {
      final failure = AuthFailureMapper.fromAuthException(e);
      state = AsyncData(AuthError(message: failure.userMessage));
    } catch (e) {
      state = const AsyncData(
          AuthError(message: 'Invalid code. Please try again.'));
    }
  }

  // ── OTP Resend ────────────────────────────────────────────────────────────

  /// Resends the OTP to [email] without changing the overall state
  /// (the OTP screen remains visible).
  Future<void> resendOtp(String email) async {
    try {
      await _authRepo.signInWithMagicLink(email);
    } catch (e) {
      debugPrint('[AuthNotifier] resendOtp error: $e');
    }
  }

  // ── Password Reset ────────────────────────────────────────────────────────

  /// Sends a password reset email. State briefly enters [AuthLoading],
  /// then returns to [AuthUnauthenticated] (success/failure both shown
  /// as snackbar by the UI, not as a state transition).
  Future<void> sendPasswordReset(String email) async {
    state = const AsyncData(AuthLoading());
    try {
      await _authRepo.sendPasswordResetEmail(email);
    } catch (e) {
      debugPrint('[AuthNotifier] sendPasswordReset error: $e');
    } finally {
      state = const AsyncData(AuthUnauthenticated());
    }
  }

  // ── Session Restore ───────────────────────────────────────────────────────

  /// Called once from [main()] before [runApp] to rehydrate a persisted
  /// session. Silently redirects to [AuthUnauthenticated] on any failure.
  Future<void> restoreSession() async {
    try {
      final user = await _sessionRepo.restoreSession();
      if (user != null) {
        state = AsyncData(AuthAuthenticated(user));
      } else {
        state = const AsyncData(AuthUnauthenticated());
      }
    } catch (e) {
      debugPrint('[AuthNotifier] restoreSession error: $e');
      state = const AsyncData(AuthUnauthenticated());
    }
  }

  // ── Token Refresh ─────────────────────────────────────────────────────────

  /// Called by [AuthGate] whenever Supabase fires a [tokenRefreshed] event.
  /// Persists the new tokens to encrypted storage so the offline session
  /// stays valid after the refresh.
  Future<void> onTokenRefreshed(Session session) async {
    await _sessionRepo.persistSession(session);
    debugPrint('[AuthNotifier] Refreshed session persisted.');
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────

  /// Signs out from Supabase + Google, and wipes all encrypted session data.
  Future<void> signOut() async {
    try {
      await _authRepo.signOut();
    } catch (e) {
      debugPrint('[AuthNotifier] signOut error: $e');
    }
    await _sessionRepo.clearSession();
    state = const AsyncData(AuthUnauthenticated());
  }

  // ── State Helpers ─────────────────────────────────────────────────────────

  /// Clears a transient error state back to [AuthUnauthenticated].
  void clearError() {
    if (state.value is AuthError) {
      state = const AsyncData(AuthUnauthenticated());
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
