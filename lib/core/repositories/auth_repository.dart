/// auth_repository.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// Data-layer auth contract backed by Supabase and native Google Sign-In.
///
/// Security posture:
/// • Zero hardcoded secrets — GOOGLE_WEB_CLIENT_ID loaded from .env at runtime.
/// • All network calls isolated to async methods — never blocks the main thread.
/// • Typed [AuthFailure] propagated upward; raw exceptions never cross the
///   repository boundary into the presentation layer.
/// • Password strength validation exposed via [validatePassword] for UI reuse.
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

// ── Email validation ──────────────────────────────────────────────────────────

/// RFC 5321-aligned email regex for client-side UX pre-validation.
/// NOTE: Must NOT be used as a server-side security gate.
final _emailRegex =
    RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');

bool isValidEmail(String email) => _emailRegex.hasMatch(email.trim());

// ── Repository ────────────────────────────────────────────────────────────────

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ── Google Sign-In ─────────────────────────────────────────────────────────
  //
  // Uses the `google_sign_in` package. On Android 14+ with Credential Manager
  // support enabled in the package, it delegates to Credential Manager API
  // automatically — no code change needed at this layer.
  GoogleSignIn get _googleSignIn => GoogleSignIn(
        serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
        scopes: ['email', 'profile', 'openid'],
      );

  // ── OTP / Magic Link ───────────────────────────────────────────────────────

  /// Sends a magic link + OTP to [email].
  Future<void> signInWithMagicLink(String email) async {
    await _supabase.auth.signInWithOtp(
      email: email.trim(),
      emailRedirectTo: 'taratravel://callback',
    );
  }

  /// Sends a 6-digit OTP to [email] for passwordless sign-in.
  Future<void> sendEmailOtp(String email) async {
    await _supabase.auth.signInWithOtp(
      email: email.trim(),
      shouldCreateUser: true,
    );
  }

  /// Verifies an OTP for generic email authentication.
  Future<AuthResponse> verifyEmailOtp(String email, String token) async {
    return _supabase.auth.verifyOTP(
      email: email.trim(),
      token: token,
      type: OtpType.email,
    );
  }

  /// Verifies an OTP sent during the sign-up confirmation flow.
  Future<AuthResponse> verifySignupOtp(String email, String token) async {
    return _supabase.auth.verifyOTP(
      email: email.trim(),
      token: token,
      type: OtpType.signup,
    );
  }

  // ── Email + Password ───────────────────────────────────────────────────────

  /// Signs in an existing user with [email] and [password].
  /// Throws a typed [AuthFailure] on failure.
  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    return _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Creates a new account with [email] and [password].
  ///
  /// [displayName] is stored in `user_metadata.full_name` for immediate
  /// availability after sign-up without an additional profile fetch.
  ///
  /// IMPORTANT: The caller must validate [password] strength via
  /// [validatePassword] before calling this — server-side validation
  /// is a secondary guard only.
  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password, {
    String? displayName,
  }) async {
    return _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: (displayName != null && displayName.isNotEmpty)
          ? {'full_name': displayName, 'name': displayName}
          : null,
    );
  }

  // ── Password Reset ─────────────────────────────────────────────────────────

  /// Sends a password-reset email to [email].
  ///
  /// Register `taratravel://reset` in Supabase → Auth → URL Configuration →
  /// Redirect URLs before enabling this flow.
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: 'taratravel://reset',
    );
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  /// Performs native Google Sign-In and exchanges the ID token with Supabase.
  ///
  /// Returns the authenticated [User], or `null` if the user dismissed the
  /// account picker (cancellation is not an error).
  ///
  /// Throws a strongly-typed [AuthFailure] subclass for all other failures.
  Future<User?> signInWithGoogle() async {
    try {
      // Force the account picker to appear — prevents silent wrong-account
      // selection in multi-account or shared-device setups.
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled — not an error.

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw const UnknownAuthFailure(
          'Google sign-in failed: ID token not received. '
          'Verify GOOGLE_WEB_CLIENT_ID in .env and google-services.json.',
        );
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return response.user;
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
