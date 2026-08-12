/// auth_repository.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// Data-layer auth contract backed by Supabase and native Google Sign-In.
///
/// Security posture:
/// • Zero hardcoded secrets — GOOGLE_WEB_CLIENT_ID loaded from .env at runtime.
/// • All network calls isolated to async methods — never blocks the main thread.
/// • Typed [AuthFailure] propagated upward; raw exceptions never cross the
///   repository boundary into the presentation layer.
/// • Network-related failures explicitly typed as [NetworkFailure] for upstream
///   circuit-breaker / retry logic.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase show AuthState;

import '../auth/domain/auth_state.dart';

// ── Repository ────────────────────────────────────────────────────────────────

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ── Google Sign-In ─────────────────────────────────────────────────────────
  GoogleSignIn? _googleSignInInstance;

  GoogleSignIn get _googleSignIn {
    _googleSignInInstance ??= GoogleSignIn(
      serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
      scopes: const ['email', 'profile', 'openid'],
    );
    return _googleSignInInstance!;
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  /// Performs fast native Google Sign-In and exchanges the ID token with Supabase.
  /// Automatically falls back to OAuth browser flow if native SDK is unconfigured.
  Future<User?> signInWithGoogle() async {
    try {
      GoogleSignInAccount? googleUser;
      try {
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.signOut();
        }
        googleUser = await _googleSignIn.signIn();
      } catch (e) {
        debugPrint('[AuthRepository] Native Google sign-in note: $e');
      }

      if (googleUser != null) {
        final googleAuth = await googleUser.authentication;
        final idToken = googleAuth.idToken;
        final accessToken = googleAuth.accessToken;

        if (idToken != null) {
          final response = await _supabase.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: accessToken,
          );
          return response.user;
        }
      }

      // If user deliberately cancelled native account picker, return null
      if (googleUser == null && await _googleSignIn.isSignedIn() == false) {
        return null;
      }

      // Fallback: Trigger browser OAuth flow if native token wasn't issued
      final launched = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'taratravel://callback',
      );
      if (launched) {
        return await waitForSession(timeout: const Duration(seconds: 15));
      }
      return null;
    } on AuthException catch (e) {
      throw AuthFailureMapper.fromAuthException(e);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      debugPrint('[AuthRepository] signInWithGoogle error: $e');
      final msg = e.toString().toLowerCase();
      if (msg.contains('network') || msg.contains('socket')) {
        throw const NetworkFailure();
      }
      throw UnknownAuthFailure('Google sign-in failed: ${e.toString()}');
    }
  }

  // ── Session ────────────────────────────────────────────────────────────────

  /// Blocks until a Supabase session materialises after an async auth event
  /// (e.g., deep-link OTP callback). Times out after [timeout].
  Future<User?> waitForSession({
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final current = _supabase.auth.currentUser;
    if (current != null) return current;
    try {
      final event = await _supabase.auth.onAuthStateChange
          .firstWhere(
            (s) =>
                s.event == AuthChangeEvent.signedIn ||
                s.event == AuthChangeEvent.tokenRefreshed,
          )
          .timeout(timeout);
      return event.session?.user ?? _supabase.auth.currentUser;
    } catch (_) {
      return _supabase.auth.currentUser;
    }
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────

  /// Signs out from Supabase. Google sign-out is best-effort.
  ///
  /// Callers must also invoke [SecureSessionRepository.clearSession()] to
  /// wipe the encrypted token store — this is handled by [AuthNotifier].
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _supabase.auth.signOut();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// The current authenticated Supabase user (sync — no network call).
  User? get currentUser => _supabase.auth.currentUser;

  /// Whether a valid local session exists.
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  /// Live stream of Supabase auth state changes.
  Stream<supabase.AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
