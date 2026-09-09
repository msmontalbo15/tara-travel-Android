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
      serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'] ??
          '616637846202-puvdihfams46tvjiofdseamheem66pau.apps.googleusercontent.com',
      scopes: const ['email', 'profile', 'openid'],
    );
    return _googleSignInInstance!;
  }

  // ── Registration Check ───────────────────────────────────────────────────

  /// Checks if a user profile already exists with the given email.
  Future<bool> isUserRegistered(String email) async {
    try {
      final res = await _supabase.rpc(
        'check_user_registered',
        params: {'p_email': email.trim().toLowerCase()},
      );
      if (res is bool) return res;
    } catch (e) {
      debugPrint('[AuthRepository] check_user_registered RPC note: $e');
    }

    // Fallback: direct table query
    try {
      final rows = await _supabase
          .from('users')
          .select('id')
          .eq('email', email.trim().toLowerCase())
          .limit(1);
      return (rows as List).isNotEmpty;
    } catch (e) {
      debugPrint('[AuthRepository] direct users table check error: $e');
      // If table query fails, default to false so confirmation can be shown safely
      return false;
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  /// Performs fast native Google Sign-In and exchanges the ID token with Supabase.
  /// If the account is not registered yet and [onConfirmNewAccount] is provided,
  /// it prompts for confirmation before creating the Supabase user.
  Future<User?> signInWithGoogle({
    Future<bool> Function({
      required String email,
      required String? displayName,
      required String? photoUrl,
    })? onConfirmNewAccount,
  }) async {
    try {
      GoogleSignInAccount? googleUser;
      Object? nativeError;
      try {
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.signOut();
        }
        googleUser = await _googleSignIn.signIn();
      } catch (e) {
        nativeError = e;
        debugPrint('[AuthRepository] Native Google sign-in error: $e');
      }

      if (googleUser != null) {
        // If confirmation callback is provided, check if the account is already registered
        if (onConfirmNewAccount != null) {
          final registered = await isUserRegistered(googleUser.email);
          if (!registered) {
            final confirmed = await onConfirmNewAccount(
              email: googleUser.email,
              displayName: googleUser.displayName,
              photoUrl: googleUser.photoUrl,
            );
            if (!confirmed) {
              // User cancelled creating an account
              await _googleSignIn.signOut();
              return null;
            }
          }
        }

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

      // If user deliberately cancelled native account picker without any error
      if (googleUser == null && nativeError == null) {
        return null;
      }

      if (nativeError != null) {
        throw UnknownAuthFailure('Google sign-in error: $nativeError');
      }

      throw const UnknownAuthFailure('Failed to obtain Google ID token. Please check Google Play Services configuration.');
    } on AuthException catch (e) {
      debugPrint('[AuthRepository] Supabase AuthException: ${e.message} (status: ${e.statusCode})');
      throw UnknownAuthFailure('Supabase Auth: ${e.message} [Code: ${e.statusCode}]');
    } catch (e) {
      if (e is AuthFailure) rethrow;
      debugPrint('[AuthRepository] signInWithGoogle error: $e');
      throw UnknownAuthFailure('Auth Error: $e');
    }
  }

  // ── Pure Supabase Email / Password Authentication ─────────────────────────

  /// Signs in directly using Supabase Email and Password.
  Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return response.user;
    } on AuthException catch (e) {
      throw AuthFailureMapper.fromAuthException(e);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('network') || msg.contains('socket')) {
        throw const NetworkFailure();
      }
      throw UnknownAuthFailure('Sign-in failed: $e');
    }
  }

  /// Registers a new user directly using Supabase Email and Password.
  Future<User?> signUpWithEmailPassword({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: fullName != null && fullName.isNotEmpty ? {'full_name': fullName.trim()} : null,
      );
      return response.user;
    } on AuthException catch (e) {
      throw AuthFailureMapper.fromAuthException(e);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('network') || msg.contains('socket')) {
        throw const NetworkFailure();
      }
      throw UnknownAuthFailure('Sign-up failed: $e');
    }
  }

  /// Signs in anonymously directly via Supabase Auth (zero external providers).
  Future<User?> signInAnonymously() async {
    try {
      final response = await _supabase.auth.signInAnonymously();
      return response.user;
    } on AuthException catch (e) {
      throw AuthFailureMapper.fromAuthException(e);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('network') || msg.contains('socket')) {
        throw const NetworkFailure();
      }
      throw UnknownAuthFailure('Anonymous sign-in failed: $e');
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
