import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Crashlytics Telemetry & Error Forensics Service.
///
/// Captures uncaught Flutter framework errors, platform zone exceptions,
/// and edge-case forensic logs (e.g. offline navigation, map rendering,
/// and camera QR scanning failures).
class CrashlyticsService {
  CrashlyticsService._();
  static final CrashlyticsService instance = CrashlyticsService._();

  bool _isInitialized = false;

  /// Whether Crashlytics telemetry has been initialized.
  bool get isInitialized => _isInitialized;

  /// Initializes Crashlytics hooks into the Flutter error pipeline.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Guard for platforms where Firebase is not initialized or supported
      if (Firebase.apps.isEmpty) {
        debugPrint('[Crashlytics] Firebase not initialized; skipping Crashlytics setup.');
        return;
      }

      // Automatically enable crash collection in release mode
      if (!kIsWeb) {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(kReleaseMode);

        // Pass all uncaught "fatal" errors from the framework to Crashlytics
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

        // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }

      _isInitialized = true;
      debugPrint('[Crashlytics] Initialized successfully (collection enabled: $kReleaseMode).');
    } catch (e, stack) {
      debugPrint('[Crashlytics] Initialization error (non-fatal): $e\n$stack');
    }
  }

  /// Sets the active user identifier for crash attribution.
  Future<void> setUserIdentifier(String userId) async {
    if (!_isInitialized || kIsWeb) return;
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
    } catch (e) {
      debugPrint('[Crashlytics] setUserIdentifier error: $e');
    }
  }

  /// Clears the user identifier on sign out.
  Future<void> clearUserIdentifier() async {
    if (!_isInitialized || kIsWeb) return;
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier('');
    } catch (e) {
      debugPrint('[Crashlytics] clearUserIdentifier error: $e');
    }
  }

  /// Sets custom diagnostic key-value pairs (e.g. active trip, connectivity status).
  Future<void> setCustomKey(String key, Object value) async {
    if (!_isInitialized || kIsWeb) return;
    try {
      await FirebaseCrashlytics.instance.setCustomKey(key, value);
    } catch (e) {
      debugPrint('[Crashlytics] setCustomKey error: $e');
    }
  }

  /// Appends a breadcrumb message to the Crashlytics session log.
  Future<void> log(String message) async {
    debugPrint('[Crashlytics Log] $message');
    if (!_isInitialized || kIsWeb) return;
    try {
      await FirebaseCrashlytics.instance.log(message);
    } catch (e) {
      debugPrint('[Crashlytics] log error: $e');
    }
  }

  /// Records a non-fatal or fatal error with full stack trace.
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async {
    debugPrint('[Crashlytics Error] $exception (fatal: $fatal, reason: $reason)');
    if (!_isInitialized || kIsWeb) return;
    try {
      await FirebaseCrashlytics.instance.recordError(
        exception,
        stack,
        reason: reason,
        information: information,
        fatal: fatal,
      );
    } catch (e) {
      debugPrint('[Crashlytics] recordError failure: $e');
    }
  }
}
