import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/secure_session_repository.dart';

/// Manages device Biometric Authentication (Face ID, Face Unlock, Fingerprint/Touch ID).
///
/// Key fixes vs. previous version:
/// • `biometricOnly: false` — allows device credential fallback (PIN/pattern)
///   if the biometric scan fails. Setting it to `true` caused a silent no-op
///   on many Android devices running API 30+ when the user had a fallback PIN.
/// • Detects all enrolled types: face, fingerprint, strong, weak.
/// • `getStrongestAvailableType()` returns the best type for UI labelling.
class BiometricAuthService {
  BiometricAuthService._();
  static final BiometricAuthService instance = BiometricAuthService._();

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _kBiometricEnabledKey = 'biometric_enabled_flag';

  // ── Availability ────────────────────────────────────────────────────────────

  /// Returns `true` if the device hardware supports biometrics AND at least
  /// one biometric credential is enrolled.
  Future<bool> isBiometricsAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      if (!canCheck || !isSupported) return false;

      // Also verify at least one credential is actually enrolled.
      final types = await _auth.getAvailableBiometrics();
      return types.isNotEmpty;
    } on PlatformException catch (e) {
      debugPrint('[BiometricAuthService] isBiometricsAvailable error: $e');
      return false;
    } catch (e) {
      debugPrint('[BiometricAuthService] isBiometricsAvailable unexpected: $e');
      return false;
    }
  }

  /// Returns all enrolled biometric types on this device.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('[BiometricAuthService] getAvailableBiometrics error: $e');
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Returns the strongest available biometric type, prioritising:
  ///   1. face  (Face ID / Face Unlock)
  ///   2. fingerprint (Touch ID / classic fingerprint)
  ///   3. strong (Android class-3 biometric, e.g. under-display fingerprint)
  ///   4. weak   (Android class-2 biometric)
  ///   5. null   (nothing enrolled)
  Future<BiometricType?> getStrongestAvailableType() async {
    final types = await getAvailableBiometrics();
    if (types.contains(BiometricType.face))        return BiometricType.face;
    if (types.contains(BiometricType.fingerprint)) return BiometricType.fingerprint;
    if (types.contains(BiometricType.strong))      return BiometricType.strong;
    if (types.contains(BiometricType.weak))        return BiometricType.weak;
    return null;
  }

  /// `true` if Face ID / Face Unlock is the strongest enrolled credential.
  Future<bool> hasFaceIdSupport() async {
    final best = await getStrongestAvailableType();
    return best == BiometricType.face;
  }

  /// `true` if any fingerprint sensor is enrolled (fingerprint OR strong type).
  Future<bool> hasFingerprintSupport() async {
    final types = await getAvailableBiometrics();
    return types.contains(BiometricType.fingerprint) ||
        types.contains(BiometricType.strong) ||
        types.contains(BiometricType.weak);
  }

  // ── Authentication ──────────────────────────────────────────────────────────

  /// Triggers the system biometric prompt.
  ///
  /// IMPORTANT: `biometricOnly: false` is intentional — it allows the user
  /// to fall back to their PIN/pattern/password if the biometric scan fails
  /// repeatedly. On Android 10+ with `biometricOnly: true`, some OEM
  /// implementations silently drop the request without showing any UI.
  Future<bool> authenticate({
    String reason = 'Scan your face or fingerprint to log in to Tara Travel',
  }) async {
    try {
      final available = await isBiometricsAvailable();
      if (!available) {
        debugPrint('[BiometricAuthService] No enrolled biometrics — skipping prompt.');
        return false;
      }

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          // biometricOnly: false → allows PIN fallback; prevents silent drop on Android.
          biometricOnly: false,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
    } on PlatformException catch (e) {
      // NotAvailable / PasscodeNotSet / LockedOut — surface cleanly.
      debugPrint('[BiometricAuthService] PlatformException: ${e.code} — ${e.message}');
      switch (e.code) {
        case auth_error.notAvailable:
        case auth_error.notEnrolled:
        case auth_error.passcodeNotSet:
          return false;
        case auth_error.lockedOut:
        case auth_error.permanentlyLockedOut:
          debugPrint('[BiometricAuthService] Biometric locked out.');
          return false;
        default:
          return false;
      }
    } catch (e) {
      debugPrint('[BiometricAuthService] authenticate unexpected: $e');
      return false;
    }
  }

  // ── Registration & Status Management ────────────────────────────────────────

  /// Whether biometrics is registered and enabled on this device.
  Future<bool> isBiometricsRegistered() async {
    return await isBiometricsEnabled();
  }

  /// Registers biometric authentication by prompting the user for Face ID / Fingerprint
  /// scan. If authenticated successfully, persists enabled status.
  Future<bool> registerBiometrics({String? customReason}) async {
    final type = await getStrongestAvailableType();
    final typeName = type == BiometricType.face ? 'Face ID' : 'Biometrics';
    final reason = customReason ?? 'Scan your $typeName to register biometric login for Tara Travel';

    final success = await authenticate(reason: reason);
    if (success) {
      await setBiometricsEnabled(true);
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await SecureSessionRepository.instance.persistSession(session);
      }
      debugPrint('[BiometricAuthService] Biometrics registered successfully.');
    } else {
      debugPrint('[BiometricAuthService] Biometric registration failed or cancelled.');
    }
    return success;
  }

  /// Unregisters/disables biometric authentication for this device.
  Future<void> unregisterBiometrics() async {
    await setBiometricsEnabled(false);
    debugPrint('[BiometricAuthService] Biometrics unregistered.');
  }

  /// Returns a human-readable status string for UI display.
  Future<String> getBiometricStatusLabel() async {
    final available = await isBiometricsAvailable();
    if (!available) return 'Hardware Unavailable / Not Enrolled';

    final registered = await isBiometricsRegistered();
    final type = await getStrongestAvailableType();
    final name = type == BiometricType.face ? 'Face ID' : 'Fingerprint';

    if (registered) {
      return '$name Registered & Active';
    } else {
      return '$name Available (Not Registered)';
    }
  }

  // ── Face Verification Management ──────────────────────────────────────────

  /// Registers Face Verification (Face ID) by prompting for a face scan.
  Future<bool> registerFaceVerification() async {
    final hasFace = await hasFaceIdSupport();
    final reason = hasFace
        ? 'Scan your face to enable Face Verification for Tara Travel'
        : 'Scan your biometric credential to enable Face Verification';

    final success = await authenticate(reason: reason);
    if (success) {
      await setBiometricsEnabled(true);
      await _storage.write(key: 'face_verification_enabled_flag', value: 'true');
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await SecureSessionRepository.instance.persistSession(session);
      }
      debugPrint('[BiometricAuthService] Face Verification registered successfully.');
    }
    return success;
  }

  /// Whether Face Verification is registered and enabled on this device.
  Future<bool> isFaceVerificationRegistered() async {
    final flag = await _storage.read(key: 'face_verification_enabled_flag');
    final enabled = await isBiometricsEnabled();
    return flag == 'true' || enabled;
  }

  /// Disables Face Verification.
  Future<void> unregisterFaceVerification() async {
    await _storage.write(key: 'face_verification_enabled_flag', value: 'false');
    debugPrint('[BiometricAuthService] Face Verification disabled.');
  }

  // ── User Preference ─────────────────────────────────────────────────────────

  /// Persists whether the user has opted into biometric login.
  Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(
      key: _kBiometricEnabledKey,
      value: enabled ? 'true' : 'false',
    );
  }

  /// Whether the user has opted into biometric login (default: false).
  Future<bool> isBiometricsEnabled() async {
    final val = await _storage.read(key: _kBiometricEnabledKey);
    return val == 'true';
  }
}
