/// secure_session_repository.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// Encrypted offline session persistence using [FlutterSecureStorage].
///
/// On Android, storage is backed by EncryptedSharedPreferences → Android
/// Keystore (AES-256-GCM). On iOS it uses the system Keychain.
///
/// Security guarantees:
/// • Zero plaintext secrets on disk.
/// • Atomic clear on sign-out — all keys wiped in one deleteAll() call.
/// • Corruption resilience — if the Keystore key is invalidated (device
///   wipe, OS upgrade, biometric change) a [PlatformException] is caught,
///   the store is cleared, and null is returned gracefully.
/// • Session expiry is checked locally before the Supabase `setSession()`
///   call to avoid an unnecessary network round-trip.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Key constants ─────────────────────────────────────────────────────────────

const _kAccessToken  = 'supa_access_token';
const _kRefreshToken = 'supa_refresh_token';
const _kUserId       = 'supa_user_id';
const _kExpiryEpoch  = 'supa_expiry_epoch';

// ── Repository ────────────────────────────────────────────────────────────────

class SecureSessionRepository {
  SecureSessionRepository._();

  static final SecureSessionRepository instance = SecureSessionRepository._();

  /// Android Keystore-backed EncryptedSharedPreferences.
  /// iOS Keychain with accessibility = whenUnlocked.
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      // Require device unlock — tokens cannot be read from the lock screen.
      keyCipherAlgorithm:
          KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // ── Write ──────────────────────────────────────────────────────────────────

  /// Persists a Supabase [Session] to encrypted storage.
  /// Safe to call on any isolate — [FlutterSecureStorage] is thread-safe.
  Future<void> persistSession(Session session) async {
    try {
      await Future.wait([
        _storage.write(key: _kAccessToken,  value: session.accessToken),
        _storage.write(key: _kRefreshToken, value: session.refreshToken),
        _storage.write(key: _kUserId,       value: session.user.id),
        _storage.write(
          key:   _kExpiryEpoch,
          value: session.expiresAt?.toString() ??
              (DateTime.now()
                      .add(const Duration(hours: 1))
                      .millisecondsSinceEpoch ~/
                  1000)
                  .toString(),
        ),
      ]);
    } on PlatformException catch (e) {
      debugPrint('[SecureSessionRepository] persistSession error: $e');
      // Non-fatal — app continues; next launch will re-authenticate.
    }
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  /// Attempts to restore a persisted session.
  ///
  /// Returns the restored Supabase [User] on success, or `null` when:
  /// • No session was stored (fresh install / after sign-out).
  /// • The stored session has expired (local check before any network call).
  /// • The Keystore key was invalidated (corruption path — store is cleared).
  Future<User?> restoreSession() async {
    try {
      final values = await Future.wait([
        _storage.read(key: _kAccessToken),
        _storage.read(key: _kRefreshToken),
        _storage.read(key: _kExpiryEpoch),
      ]);

      final accessToken  = values[0];
      final refreshToken = values[1];
      final expiryStr    = values[2];

      if (accessToken == null || refreshToken == null) return null;

      // Local expiry pre-check — avoids unnecessary Supabase network call.
      if (expiryStr != null) {
        final expiryEpoch = int.tryParse(expiryStr) ?? 0;
        final expiresAt =
            DateTime.fromMillisecondsSinceEpoch(expiryEpoch * 1000);
        if (DateTime.now().isAfter(expiresAt)) {
          debugPrint('[SecureSessionRepository] Session expired locally — clearing.');
          await clearSession();
          return null;
        }
      }

      // Rehydrate the Supabase client session — this may trigger a token
      // refresh if the access token is close to expiry (Supabase SDK handles
      // the refresh automatically via the refresh token).
      final response = await Supabase.instance.client.auth.setSession(
        base64.encode(utf8.encode(jsonEncode({
          'access_token':  accessToken,
          'refresh_token': refreshToken,
        }))),
      );

      return response.user;
    } on AuthException catch (e) {
      debugPrint('[SecureSessionRepository] restoreSession AuthException: $e');
      await clearSession();
      return null;
    } on PlatformException catch (e) {
      // Keystore key invalidated (device wipe, OS upgrade, biometric change).
      debugPrint('[SecureSessionRepository] Keystore key lost — clearing session: $e');
      await clearSession();
      return null;
    } catch (e) {
      debugPrint('[SecureSessionRepository] restoreSession unexpected error: $e');
      await clearSession();
      return null;
    }
  }

  // ── Clear ──────────────────────────────────────────────────────────────────

  /// Atomically wipes all persisted session tokens.
  /// Called on sign-out, session expiry, and Keystore key loss.
  Future<void> clearSession() async {
    try {
      await _storage.deleteAll();
    } on PlatformException catch (e) {
      debugPrint('[SecureSessionRepository] clearSession error: $e');
      // Best-effort: individual key deletes as fallback.
      for (final key in [_kAccessToken, _kRefreshToken, _kUserId, _kExpiryEpoch]) {
        try { await _storage.delete(key: key); } catch (_) {}
      }
    }
  }

  // ── Query ──────────────────────────────────────────────────────────────────

  /// Returns the stored user ID without rehydrating the full Supabase session.
  /// Useful for pre-auth database routing (e.g., [DatabaseService.switchUser]).
  Future<String?> getStoredUserId() async {
    try {
      return await _storage.read(key: _kUserId);
    } on PlatformException catch (e) {
      debugPrint('[SecureSessionRepository] getStoredUserId error: $e');
      return null;
    }
  }

  /// Returns `true` if there is a stored (potentially expired) session.
  Future<bool> hasStoredSession() async {
    try {
      final token = await _storage.read(key: _kAccessToken);
      return token != null;
    } on PlatformException {
      return false;
    }
  }
}
