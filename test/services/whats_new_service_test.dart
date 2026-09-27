import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tara_travel/core/models/whats_new_model.dart';
import 'package:tara_travel/core/services/app_version_service.dart';

void main() {
  group('WhatsNewModel & ReleaseNotesData Unit Tests', () {
    test('TaraReleaseManifest contains curated release notes for v1.0.1', () {
      final v101 = SemanticVersion.parse('1.0.1+1');
      final notes = TaraReleaseManifest.getForVersion(v101);

      expect(notes.version.displayVersion, '1.0.1');
      expect(notes.items.isNotEmpty, true);
      expect(notes.items.any((item) => item.title.contains('Meet-up')), true);
      expect(notes.items.any((item) => item.highlightTag == 'PLAN 11'), true);
      expect(notes.items.any((item) => item.category == WhatsNewCategory.security), true);
    });

    test('ReleaseNotesData.parse parses structured tags [NEW], [PERF], [SEC], [FIX]', () {
      const rawNotes = '''
[NEW] Smart Assembly: Day 1 Stop 0 countdown and arrival sync.
[PERF] Lightning Geocoding: Offline region lookup in sub-millisecond time.
[SECURITY] MPIN Lock: 3-layer AES-256 vault and biometric auth.
[FIX] Battery Drain: Reduced background telemetry polling.
''';
      final version = SemanticVersion.parse('1.2.0');
      final parsed = ReleaseNotesData.parse(version: version, rawNotes: rawNotes);

      expect(parsed.items.length, 4);

      expect(parsed.items[0].category, WhatsNewCategory.feature);
      expect(parsed.items[0].title, 'Smart Assembly');
      expect(parsed.items[0].description, 'Day 1 Stop 0 countdown and arrival sync.');

      expect(parsed.items[1].category, WhatsNewCategory.improvement);
      expect(parsed.items[1].title, 'Lightning Geocoding');

      expect(parsed.items[2].category, WhatsNewCategory.security);
      expect(parsed.items[2].title, 'MPIN Lock');

      expect(parsed.items[3].category, WhatsNewCategory.fix);
      expect(parsed.items[3].title, 'Battery Drain');
    });

    test('ReleaseNotesData.parse falls back to TaraReleaseManifest when raw notes are empty or default', () {
      final version = SemanticVersion.parse('1.0.1');
      final parsedDefault = ReleaseNotesData.parse(
        version: version,
        rawNotes: 'General improvements and bug fixes.',
      );

      expect(parsedDefault.items.isNotEmpty, true);
      expect(parsedDefault.items.any((i) => i.highlightTag == 'PLAN 11'), true);
    });

    test('SemanticVersion correctly distinguishes version upgrade delta', () {
      final vOld = SemanticVersion.parse('1.0.0+1');
      final vCurrent = SemanticVersion.parse('1.0.1+1');
      final vNewer = SemanticVersion.parse('1.1.0+5');

      expect(vCurrent > vOld, true);
      expect(vOld < vCurrent, true);
      expect(vCurrent == SemanticVersion.parse('1.0.1+1'), true);
      expect(vCurrent < vNewer, true);
    });

    test('WhatsNewItem effectiveIcon falls back to category icon when iconOverride is null', () {
      const itemWithCustomIcon = WhatsNewItem(
        title: 'Custom',
        description: 'Custom icon test',
        category: WhatsNewCategory.feature,
        iconOverride: Icons.rocket_launch,
      );
      expect(itemWithCustomIcon.effectiveIcon, Icons.rocket_launch);

      const itemWithDefaultIcon = WhatsNewItem(
        title: 'Default',
        description: 'Default category icon test',
        category: WhatsNewCategory.security,
      );
      expect(itemWithDefaultIcon.effectiveIcon, WhatsNewCategory.security.icon);
    });
  });
}
