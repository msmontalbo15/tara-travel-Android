import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Semantic Version representation and comparator (Major.Minor.Patch+Build).
class SemanticVersion implements Comparable<SemanticVersion> {
  final int major;
  final int minor;
  final int patch;
  final int build;
  final String raw;

  const SemanticVersion({
    required this.major,
    required this.minor,
    required this.patch,
    this.build = 0,
    required this.raw,
  });

  /// Parses version strings such as `1.0.0`, `1.2.3+4`, `v2.0.1+10`.
  factory SemanticVersion.parse(String input) {
    final sanitized = input.trim().replaceFirst(RegExp(r'^[vV]'), '');
    final parts = sanitized.split('+');
    final versionPart = parts[0];
    final buildPart = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    final numbers = versionPart.split('.');
    final major = numbers.isNotEmpty ? int.tryParse(numbers[0]) ?? 0 : 0;
    final minor = numbers.length > 1 ? int.tryParse(numbers[1]) ?? 0 : 0;
    final patch = numbers.length > 2 ? int.tryParse(numbers[2]) ?? 0 : 0;

    return SemanticVersion(
      major: major,
      minor: minor,
      patch: patch,
      build: buildPart,
      raw: input,
    );
  }

  @override
  int compareTo(SemanticVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);
    return build.compareTo(other.build);
  }

  bool operator <(SemanticVersion other) => compareTo(other) < 0;
  bool operator <=(SemanticVersion other) => compareTo(other) <= 0;
  bool operator >(SemanticVersion other) => compareTo(other) > 0;
  bool operator >=(SemanticVersion other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemanticVersion &&
          major == other.major &&
          minor == other.minor &&
          patch == other.patch &&
          build == other.build;

  @override
  int get hashCode => Object.hash(major, minor, patch, build);

  @override
  String toString() => build > 0 ? '$major.$minor.$patch+$build' : '$major.$minor.$patch';
}

/// Remote configuration model fetched from Supabase `public.app_versions`.
class AppVersionInfo {
  final String id;
  final String platform;
  final SemanticVersion minSupportedVersion;
  final SemanticVersion latestVersion;
  final String? forceUpdateUrl;
  final bool maintenanceMode;
  final String maintenanceTitle;
  final String maintenanceMessage;
  final DateTime? estimatedBackOnline;
  final String releaseNotes;
  final DateTime createdAt;

  const AppVersionInfo({
    required this.id,
    required this.platform,
    required this.minSupportedVersion,
    required this.latestVersion,
    this.forceUpdateUrl,
    required this.maintenanceMode,
    required this.maintenanceTitle,
    required this.maintenanceMessage,
    this.estimatedBackOnline,
    required this.releaseNotes,
    required this.createdAt,
  });

  factory AppVersionInfo.fromMap(Map<String, dynamic> map) {
    final minVerStr = map['min_supported_version'] as String? ?? '1.0.0';
    final latestVerStr = map['latest_version'] as String? ?? '1.0.0';
    final estimatedStr = map['estimated_back_online'] as String?;
    final createdStr = map['created_at'] as String?;

    return AppVersionInfo(
      id: map['id'] as String? ?? '',
      platform: map['platform'] as String? ?? 'android',
      minSupportedVersion: SemanticVersion.parse(minVerStr),
      latestVersion: SemanticVersion.parse(latestVerStr),
      forceUpdateUrl: map['force_update_url'] as String?,
      maintenanceMode: map['maintenance_mode'] as bool? ?? false,
      maintenanceTitle: map['maintenance_title'] as String? ?? 'Under Scheduled Maintenance',
      maintenanceMessage: map['maintenance_message'] as String? ??
          'We are currently performing routine system upgrades. Please check back shortly.',
      estimatedBackOnline: estimatedStr != null ? DateTime.tryParse(estimatedStr) : null,
      releaseNotes: map['release_notes'] as String? ?? 'General improvements and bug fixes.',
      createdAt: createdStr != null ? (DateTime.tryParse(createdStr) ?? DateTime.now()) : DateTime.now(),
    );
  }
}

/// Status tiers for version evaluation.
enum VersionStatus {
  /// App is on the latest version.
  upToDate,

  /// A newer version is available, but current version is still supported.
  softUpdate,

  /// Current version is strictly below minimum supported; hard gate required.
  forceUpdate,

  /// System is in global maintenance mode.
  maintenance,
}

/// Evaluation result detailing actionable version state.
class VersionCheckResult {
  final VersionStatus status;
  final SemanticVersion currentVersion;
  final AppVersionInfo? remoteConfig;
  final String message;

  const VersionCheckResult({
    required this.status,
    required this.currentVersion,
    this.remoteConfig,
    required this.message,
  });

  bool get isUpToDate => status == VersionStatus.upToDate;
  bool get isSoftUpdate => status == VersionStatus.softUpdate;
  bool get isForceUpdate => status == VersionStatus.forceUpdate;
  bool get isMaintenance => status == VersionStatus.maintenance;
  bool get hasUpdate => isSoftUpdate || isForceUpdate;
}

/// Gateway service for app version compatibility, remote maintenance mode,
/// and direct cloud OTA channels.
class AppVersionService {
  final SupabaseClient _supabase;

  /// Default baseline version corresponding to `pubspec.yaml`.
  static const String currentAppVersionString = '1.0.0+1';

  AppVersionService({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  /// Returns the current runtime SemanticVersion of the mobile app.
  SemanticVersion getCurrentVersion() {
    return SemanticVersion.parse(currentAppVersionString);
  }

  /// Queries Supabase `public.app_versions` and evaluates version gate.
  Future<VersionCheckResult> checkVersionStatus({
    String platform = 'android',
    SemanticVersion? currentVersionOverride,
  }) async {
    final current = currentVersionOverride ?? getCurrentVersion();

    try {
      final response = await _supabase
          .from('app_versions')
          .select()
          .eq('platform', platform)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return VersionCheckResult(
          status: VersionStatus.upToDate,
          currentVersion: current,
          message: 'No remote version constraints configured.',
        );
      }

      final remote = AppVersionInfo.fromMap(response);

      // 1. Maintenance Mode Gate (Tier 3)
      if (remote.maintenanceMode) {
        return VersionCheckResult(
          status: VersionStatus.maintenance,
          currentVersion: current,
          remoteConfig: remote,
          message: remote.maintenanceMessage,
        );
      }

      // 2. Mandatory Force-Update Gate (Tier 1)
      if (current < remote.minSupportedVersion) {
        return VersionCheckResult(
          status: VersionStatus.forceUpdate,
          currentVersion: current,
          remoteConfig: remote,
          message: 'Update required to continue using Tara Travel.',
        );
      }

      // 3. Recommended Soft Update (Tier 2)
      if (current < remote.latestVersion) {
        return VersionCheckResult(
          status: VersionStatus.softUpdate,
          currentVersion: current,
          remoteConfig: remote,
          message: 'A new version of Tara Travel is available.',
        );
      }

      // 4. Up-to-date
      return VersionCheckResult(
        status: VersionStatus.upToDate,
        currentVersion: current,
        remoteConfig: remote,
        message: 'Tara Travel is up to date.',
      );
    } catch (e) {
      debugPrint('[AppVersionService] Version check failed gracefully: $e');
      // Graceful offline fallback: do not lock out user if network/DB check errors
      return VersionCheckResult(
        status: VersionStatus.upToDate,
        currentVersion: current,
        message: 'Unable to check version remotely: $e',
      );
    }
  }
}

/// Provider for AppVersionService singleton.
final appVersionServiceProvider = Provider<AppVersionService>((ref) {
  return AppVersionService();
});

/// FutureProvider that fetches the authoritative version status on demand.
final appVersionCheckProvider = FutureProvider<VersionCheckResult>((ref) async {
  final service = ref.watch(appVersionServiceProvider);
  return service.checkVersionStatus();
});
