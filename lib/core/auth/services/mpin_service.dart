import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages 4-Digit MPIN security, hashing, and 30-day persistent session validation.
class MpinSecurityService {
  MpinSecurityService._();
  static final MpinSecurityService instance = MpinSecurityService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _kMpinHashKey = 'mpin_hash_key';
  static const String _kMpinSaltKey = 'mpin_salt_key';
  static const String _kMpinExpiryKey = 'mpin_session_expiry_key';
  static const String _kFaceVerificationEnabledKey = 'face_verification_enabled_key';

  // ── MPIN Registration & Hashing ──────────────────────────────────────────

  /// Hashes and securely stores a 4-digit MPIN.
  /// Automatically initializes or extends the 30-day session window.
  Future<bool> setMpin(String pin) async {
    if (pin.length != 4 || int.tryParse(pin) == null) {
      debugPrint('[MpinSecurityService] Invalid MPIN format. Must be 4 digits.');
      return false;
    }

    try {
      final salt = DateTime.now().microsecondsSinceEpoch.toString();
      final hashedPin = _hashPin(pin, salt);

      // Set session expiry to 30 days from now
      final expiryTime = DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch;

      await Future.wait([
        _storage.write(key: _kMpinHashKey, value: hashedPin),
        _storage.write(key: _kMpinSaltKey, value: salt),
        _storage.write(key: _kMpinExpiryKey, value: expiryTime.toString()),
      ]);

      // Persist active session tokens to secure storage
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await _storage.write(
          key: 'supabase_session_token',
          value: session.refreshToken ?? '',
        );
      }

      debugPrint('[MpinSecurityService] 4-Digit MPIN set successfully (30 days session active).');
      return true;
    } catch (e) {
      debugPrint('[MpinSecurityService] setMpin error: $e');
      return false;
    }
  }

  /// Verifies entered MPIN against the stored hash.
  Future<bool> verifyMpin(String pin) async {
    try {
      final storedHash = await _storage.read(key: _kMpinHashKey);
      final storedSalt = await _storage.read(key: _kMpinSaltKey);

      if (storedHash == null || storedSalt == null) return false;

      final inputHash = _hashPin(pin, storedSalt);
      final isValid = inputHash == storedHash;

      if (isValid) {
        // Refresh session expiry on correct PIN login
        await extendSessionWindow();
      }
      return isValid;
    } catch (e) {
      debugPrint('[MpinSecurityService] verifyMpin error: $e');
      return false;
    }
  }

  /// Returns `true` if an MPIN has been registered on this device.
  Future<bool> hasMpin() async {
    try {
      final hash = await _storage.read(key: _kMpinHashKey);
      return hash != null && hash.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Clears MPIN registration.
  Future<void> clearMpin() async {
    try {
      await Future.wait([
        _storage.delete(key: _kMpinHashKey),
        _storage.delete(key: _kMpinSaltKey),
        _storage.delete(key: _kMpinExpiryKey),
      ]);
      debugPrint('[MpinSecurityService] MPIN cleared.');
    } catch (e) {
      debugPrint('[MpinSecurityService] clearMpin error: $e');
    }
  }

  // ── 30-Day Session Management ─────────────────────────────────────────────

  /// Checks if the current MPIN/Biometric session is within the 30-day window.
  Future<bool> isSessionValid() async {
    try {
      final expiryStr = await _storage.read(key: _kMpinExpiryKey);
      if (expiryStr == null) return false;

      final expiryEpoch = int.tryParse(expiryStr) ?? 0;
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryEpoch);

      return DateTime.now().isBefore(expiryDate);
    } catch (e) {
      return false;
    }
  }

  /// Extends the 30-day session window by another 30 days.
  Future<void> extendSessionWindow() async {
    try {
      final expiryTime = DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch;
      await _storage.write(key: _kMpinExpiryKey, value: expiryTime.toString());
    } catch (e) {
      debugPrint('[MpinSecurityService] extendSessionWindow error: $e');
    }
  }

  /// Returns remaining days in the 30-day session window (0 if expired).
  Future<int> getDaysRemaining() async {
    try {
      final expiryStr = await _storage.read(key: _kMpinExpiryKey);
      if (expiryStr == null) return 0;

      final expiryEpoch = int.tryParse(expiryStr) ?? 0;
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryEpoch);
      final diff = expiryDate.difference(DateTime.now()).inDays;

      return diff > 0 ? diff : 0;
    } catch (e) {
      return 0;
    }
  }

  // ── Face Verification Preference ──────────────────────────────────────────

  /// Sets whether Face Verification (Face ID) is enabled.
  Future<void> setFaceVerificationEnabled(bool enabled) async {
    await _storage.write(
      key: _kFaceVerificationEnabledKey,
      value: enabled ? 'true' : 'false',
    );
  }

  /// Returns whether Face Verification (Face ID) is enabled.
  Future<bool> isFaceVerificationEnabled() async {
    final val = await _storage.read(key: _kFaceVerificationEnabledKey);
    return val == 'true';
  }

  // ── Helper ───────────────────────────────────────────────────────────────

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$pin:$salt:tara_travel_secure_mpin_v1');
    return sha256.convert(bytes).toString();
  }
}
