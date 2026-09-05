import 'package:flutter_test/flutter_test.dart';
import 'package:tara_travel/core/services/app_version_service.dart';

void main() {
  group('SemanticVersion Parser & Comparator Tests', () {
    test('Correctly parses standard semantic version strings', () {
      final v = SemanticVersion.parse('1.2.3');
      expect(v.major, equals(1));
      expect(v.minor, equals(2));
      expect(v.patch, equals(3));
      expect(v.build, equals(0));
    });

    test('Correctly parses version strings with build number and v-prefix', () {
      final v = SemanticVersion.parse('v2.4.1+15');
      expect(v.major, equals(2));
      expect(v.minor, equals(4));
      expect(v.patch, equals(1));
      expect(v.build, equals(15));
    });

    test('Compares major, minor, patch, and build numbers hierarchically', () {
      final v1 = SemanticVersion.parse('1.0.0');
      final v2 = SemanticVersion.parse('1.0.1');
      final v3 = SemanticVersion.parse('1.1.0');
      final v4 = SemanticVersion.parse('2.0.0');

      expect(v1 < v2, isTrue);
      expect(v2 < v3, isTrue);
      expect(v3 < v4, isTrue);
      expect(v4 > v1, isTrue);
    });

    test('Compares build numbers when semantic version is identical', () {
      final b1 = SemanticVersion.parse('1.0.0+1');
      final b2 = SemanticVersion.parse('1.0.0+2');

      expect(b1 < b2, isTrue);
      expect(b2 > b1, isTrue);
      expect(b1 <= b2, isTrue);
      expect(b2 >= b1, isTrue);
    });

    test('Identical versions evaluate to equality', () {
      final vA = SemanticVersion.parse('1.4.2+8');
      final vB = SemanticVersion.parse('1.4.2+8');

      expect(vA == vB, isTrue);
      expect(vA.compareTo(vB), equals(0));
    });
  });

  group('VersionStatus Invariant Evaluation Tests', () {
    final now = DateTime.now();

    test('Detects maintenance mode as highest priority gate', () {
      final config = AppVersionInfo(
        id: 'cfg-1',
        platform: 'android',
        minSupportedVersion: SemanticVersion.parse('1.0.0'),
        latestVersion: SemanticVersion.parse('1.1.0'),
        maintenanceMode: true,
        maintenanceTitle: 'Routine Server Upgrades',
        maintenanceMessage: 'Temporarily down for database index optimization.',
        releaseNotes: 'None',
        createdAt: now,
      );

      final current = SemanticVersion.parse('1.0.5');
      final status = config.maintenanceMode
          ? VersionStatus.maintenance
          : (current < config.minSupportedVersion
              ? VersionStatus.forceUpdate
              : (current < config.latestVersion
                  ? VersionStatus.softUpdate
                  : VersionStatus.upToDate));

      expect(status, equals(VersionStatus.maintenance));
    });

    test('Detects mandatory force-update when current is strictly below min_supported', () {
      final config = AppVersionInfo(
        id: 'cfg-2',
        platform: 'android',
        minSupportedVersion: SemanticVersion.parse('1.1.0'),
        latestVersion: SemanticVersion.parse('1.2.0'),
        maintenanceMode: false,
        maintenanceTitle: '',
        maintenanceMessage: '',
        releaseNotes: 'Critical database migration fix',
        createdAt: now,
      );

      final current = SemanticVersion.parse('1.0.9+5');
      expect(current < config.minSupportedVersion, isTrue);
      final status = current < config.minSupportedVersion
          ? VersionStatus.forceUpdate
          : VersionStatus.upToDate;

      expect(status, equals(VersionStatus.forceUpdate));
    });

    test('Detects recommended soft-update when current is within supported range but below latest', () {
      final config = AppVersionInfo(
        id: 'cfg-3',
        platform: 'android',
        minSupportedVersion: SemanticVersion.parse('1.0.0'),
        latestVersion: SemanticVersion.parse('1.2.0'),
        maintenanceMode: false,
        maintenanceTitle: '',
        maintenanceMessage: '',
        releaseNotes: 'Exciting new land transit routes added',
        createdAt: now,
      );

      final current = SemanticVersion.parse('1.1.0');
      expect(current >= config.minSupportedVersion, isTrue);
      expect(current < config.latestVersion, isTrue);
      final status = current < config.latestVersion
          ? VersionStatus.softUpdate
          : VersionStatus.upToDate;

      expect(status, equals(VersionStatus.softUpdate));
    });

    test('Evaluates to upToDate when current equals or exceeds latest version', () {
      final config = AppVersionInfo(
        id: 'cfg-4',
        platform: 'android',
        minSupportedVersion: SemanticVersion.parse('1.0.0'),
        latestVersion: SemanticVersion.parse('1.2.0+3'),
        maintenanceMode: false,
        maintenanceTitle: '',
        maintenanceMessage: '',
        releaseNotes: '',
        createdAt: now,
      );

      final current = SemanticVersion.parse('1.2.0+3');
      expect(current >= config.latestVersion, isTrue);
    });
  });
}
