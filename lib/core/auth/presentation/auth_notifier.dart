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
/// • All tokens persisted via [SecureSessionRepository] (Keystore / Keychain).
/// • Session restore runs at app startup in main() before runApp().
/// • Biometric login supports offline sessions — no network round-trip needed
///   when a valid user ID is already stored locally.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../repositories/auth_repository.dart';
import '../data/secure_session_repository.dart';
import '../domain/auth_state.dart';
import '../services/biometric_service.dart';
import '../../providers/repository_providers.dart';
import '../../services/connectivity_service.dart';

export '../domain/auth_state.dart';

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
  /// If the account is new and [onConfirmNewAccount] is provided, it prompts
  /// the user before creating the account in Supabase.
  Future<void> signInWithGoogle({
    Future<bool> Function({
      required String email,
      required String? displayName,
      required String? photoUrl,
    })? onConfirmNewAccount,
  }) async {
    if (_throttled()) return;
    _recordAttempt();

    state = const AsyncData(AuthLoading());
    try {
      final user = await _authRepo.signInWithGoogle(
        onConfirmNewAccount: onConfirmNewAccount,
      );
      if (user == null) {
        // User dismissed the picker or cancelled creation — not an error.
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

  // ── Biometric Sign-In ─────────────────────────────────────────────────────

  /// Authenticates using device biometrics (Face ID / Fingerprint).
  ///
  /// Online path: restores the full Supabase session via [SecureSessionRepository].
  /// Offline path: hydrates the user identity from the stored user ID without
  ///   a network call, so the user can access their locally-cached trip data.
  Future<void> signInWithBiometric() async {
    if (_throttled()) return;
    _recordAttempt();
    state = const AsyncData(AuthLoading());

    final bio = BiometricAuthService.instance;

    final isEnabled = await bio.isBiometricsEnabled();
    if (!isEnabled) {
      state = const AsyncData(AuthError(
          message:
              'Biometric login is not set up. Sign in with Google first, then enable it in Profile Settings.'));
      return;
    }

    final authenticated = await bio.authenticate();
    if (!authenticated) {
      state = const AsyncData(AuthError(
          message: 'Biometric authentication failed. Please try again.'));
      return;
    }

    // ── Offline-aware session restore ──────────────────────────────────────
    final isOnline = await ConnectivityService.instance.isOnline;

    if (!isOnline) {
      // Offline path: skip Supabase network call.
      // Use the in-memory user if Supabase already hydrated it, otherwise
      // fall back to the stored user ID to reconstruct a minimal identity.
      final inMemoryUser = Supabase.instance.client.auth.currentUser;
      if (inMemoryUser != null) {
        state = AsyncData(AuthAuthenticated(inMemoryUser));
        return;
      }

      final storedUserId = await _sessionRepo.getStoredUserId();
      if (storedUserId != null) {
        // No valid User object available offline — signal as offline session.
        state = const AsyncData(AuthError(
            message:
                'You\'re offline. Re-open the app with internet to fully restore your session.'));
        return;
      }

      state = const AsyncData(AuthError(
          message:
              'No saved session found. Please connect to the internet and sign in with Google.'));
      return;
    }

    // ── Online path ────────────────────────────────────────────────────────
    try {
      final user = await _sessionRepo.restoreSession();
      if (user != null) {
        state = AsyncData(AuthAuthenticated(user));
      } else {
        state = const AsyncData(AuthError(
            message:
                'Session expired. Please sign in with Google to continue.'));
      }
    } catch (e) {
      debugPrint('[AuthNotifier] signInWithBiometric restoreSession error: $e');
      state = const AsyncData(
          AuthError(message: 'Authentication failed. Please try again.'));
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
