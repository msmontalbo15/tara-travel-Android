import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/whats_new_model.dart';
import 'app_version_service.dart';

/// Service managing 'What's New' first-run detection, release notes caching,
/// and update snooze policies.
class WhatsNewService {
  static const String _kLastSeenAppVersion = 'tara_last_seen_app_version';
  static const String _kLastSnoozeTimestamp = 'tara_last_snooze_update_timestamp';
  static const String _kLastSnoozeVersion = 'tara_last_snooze_version';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  String? _cachedLastSeenVersion;
  bool _isInitialized = false;

  WhatsNewService();

  /// Pre-initializes in-memory cache from secure storage.
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _cachedLastSeenVersion = await _storage.read(key: _kLastSeenAppVersion);
      _isInitialized = true;
    } catch (e) {
      debugPrint('[WhatsNewService] Initialize warning: $e');
    }
  }

  /// Returns the semantic version string the user previously acknowledged.
  Future<String?> getLastSeenVersion() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _cachedLastSeenVersion;
  }

  /// Determines whether the post-update "What's New" modal should be presented.
  ///
  /// Evaluates true when the current runtime binary version is strictly higher
  /// than the last acknowledged version recorded in secure local storage.
  Future<bool> shouldShowWhatsNewOnLaunch({
    SemanticVersion? currentVersionOverride,
  }) async {
    try {
      final lastSeenRaw = await getLastSeenVersion();
      final current = currentVersionOverride ??
          SemanticVersion.parse(AppVersionService.currentAppVersionString);

      // Fresh install: baseline current version so users aren't interrupted
      // before completing onboarding/first trip setup.
      if (lastSeenRaw == null) {
        await markCurrentVersionSeen(version: current);
        return false;
      }

      final lastSeen = SemanticVersion.parse(lastSeenRaw);
      return current > lastSeen;
    } catch (e) {
      debugPrint('[WhatsNewService] shouldShowWhatsNew check error: $e');
      return false;
    }
  }

  /// Acknowledges the current version so the popup is never shown again for this release.
  Future<void> markCurrentVersionSeen({SemanticVersion? version}) async {
    final v = version ?? SemanticVersion.parse(AppVersionService.currentAppVersionString);
    _cachedLastSeenVersion = v.toString();
    try {
      await _storage.write(key: _kLastSeenAppVersion, value: v.toString());
    } catch (e) {
      debugPrint('[WhatsNewService] markCurrentVersionSeen error: $e');
    }
  }

  /// Snoozes non-mandatory update prompts for the specified duration (default 24h).
  Future<void> snoozeUpdatePrompt({
    required String targetVersion,
    Duration duration = const Duration(hours: 24),
  }) async {
    final expiry = DateTime.now().toUtc().add(duration).toIso8601String();
    try {
      await Future.wait([
        _storage.write(key: _kLastSnoozeTimestamp, value: expiry),
        _storage.write(key: _kLastSnoozeVersion, value: targetVersion),
      ]);
    } catch (e) {
      debugPrint('[WhatsNewService] snoozeUpdatePrompt error: $e');
    }
  }

  /// Returns true if a soft update prompt for [targetVersion] was snoozed and has not yet expired.
  Future<bool> isUpdatePromptSnoozed({required String targetVersion}) async {
    try {
      final results = await Future.wait([
        _storage.read(key: _kLastSnoozeTimestamp),
        _storage.read(key: _kLastSnoozeVersion),
      ]);
      final expiryStr = results[0];
      final snoozedVer = results[1];

      if (expiryStr == null || snoozedVer != targetVersion) {
        return false;
      }

      final expiry = DateTime.tryParse(expiryStr);
      if (expiry == null) return false;

      return DateTime.now().toUtc().isBefore(expiry);
    } catch (e) {
      debugPrint('[WhatsNewService] isUpdatePromptSnoozed error: $e');
      return false;
    }
  }

  /// Retrieves structured release notes for the target version, with fallback.
  ReleaseNotesData getReleaseNotes({
    required SemanticVersion version,
    String? rawNotes,
    DateTime? releaseDate,
  }) {
    return ReleaseNotesData.parse(
      version: version,
      rawNotes: rawNotes,
      releaseDate: releaseDate,
    );
  }
}

/// Riverpod provider for WhatsNewService.
final whatsNewServiceProvider = Provider<WhatsNewService>((ref) {
  return WhatsNewService();
});

/// FutureProvider that detects whether What's New should pop up on app start.
final shouldShowWhatsNewProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(whatsNewServiceProvider);
  return service.shouldShowWhatsNewOnLaunch();
});
