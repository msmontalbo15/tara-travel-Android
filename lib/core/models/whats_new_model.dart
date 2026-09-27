import 'package:flutter/material.dart';
import '../services/app_version_service.dart';
import '../theme/app_colors.dart';

/// Categories for release notes highlights and changes.
enum WhatsNewCategory {
  feature(
    label: 'NEW',
    icon: Icons.stars_rounded,
    color: AppColors.primary,
    bgColor: AppColors.sand,
    textColor: AppColors.primary,
  ),
  improvement(
    label: 'IMPROVED',
    icon: Icons.bolt_rounded,
    color: AppColors.amber,
    bgColor: AppColors.amberLight,
    textColor: AppColors.amberText,
  ),
  security(
    label: 'PRIVACY & SECURITY',
    icon: Icons.shield_rounded,
    color: AppColors.green,
    bgColor: AppColors.greenBg,
    textColor: AppColors.green,
  ),
  fix(
    label: 'REFINED',
    icon: Icons.handyman_rounded,
    color: AppColors.blue,
    bgColor: AppColors.blueLight,
    textColor: AppColors.blue,
  );

  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color textColor;

  const WhatsNewCategory({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.textColor,
  });
}

/// A distinct highlight item within a release update.
class WhatsNewItem {
  final String title;
  final String description;
  final WhatsNewCategory category;
  final String? highlightTag;
  final IconData? iconOverride;

  const WhatsNewItem({
    required this.title,
    required this.description,
    this.category = WhatsNewCategory.feature,
    this.highlightTag,
    this.iconOverride,
  });

  IconData get effectiveIcon => iconOverride ?? category.icon;
}

/// Curated release manifest containing authoritative update notes per version.
class TaraReleaseManifest {
  TaraReleaseManifest._();

  /// Curated changelog items for known Tara Travel app versions.
  static final Map<String, ReleaseNotesData> _manifest = {
    '1.0.1': ReleaseNotesData(
      version: SemanticVersion.parse('1.0.1+1'),
      tagline: 'Meet-up arrival countdowns, Philippine geocoding & enhanced travel pacing.',
      items: const [
        WhatsNewItem(
          title: 'Smart Meet-up & Departure Advisory',
          description:
              'Automatic Day 1 Stop 0 assembly countdown with customizable grace periods, companion check-ins, and GPS departure detection.',
          category: WhatsNewCategory.feature,
          highlightTag: 'PLAN 11',
          iconOverride: Icons.place_rounded,
        ),
        WhatsNewItem(
          title: 'Philippine Offline Geocoding',
          description:
              'Instant high-speed offline search and coordinates across all 17 regions, 82 provinces, and 1,600+ municipalities.',
          category: WhatsNewCategory.feature,
          highlightTag: 'LOCAL-FIRST',
          iconOverride: Icons.map_rounded,
        ),
        WhatsNewItem(
          title: 'Tara AI Travel Copilot',
          description:
              'Context-aware travel assistant providing day-by-day itinerary suggestions, pacing recommendations, and packing lists.',
          category: WhatsNewCategory.feature,
          highlightTag: 'AI COPILOT',
          iconOverride: Icons.auto_awesome_rounded,
        ),
        WhatsNewItem(
          title: 'Vehicle Garage & Fuel Pacing',
          description:
              'Track personal vehicles, real-time DOE fuel averages, and exact per-kilometer road trip fuel budgets.',
          category: WhatsNewCategory.improvement,
          highlightTag: 'GARAGE',
          iconOverride: Icons.directions_car_filled_rounded,
        ),
        WhatsNewItem(
          title: 'MPIN Local Vault & Privacy Lock',
          description:
              '3-layer cryptographic encryption with biometric Face ID / Fingerprint verification and strict NPC RA 10173 data isolation.',
          category: WhatsNewCategory.security,
          highlightTag: 'SECURITY',
          iconOverride: Icons.lock_outline_rounded,
        ),
        WhatsNewItem(
          title: 'Battery & GPS Navigation Refinements',
          description:
              'Optimized geofence polling and background presence updates for extended battery life on cross-island road trips.',
          category: WhatsNewCategory.fix,
          highlightTag: 'OPTIMIZATION',
          iconOverride: Icons.battery_charging_full_rounded,
        ),
      ],
    ),
    '1.0.0': ReleaseNotesData(
      version: SemanticVersion.parse('1.0.0+1'),
      tagline: 'Welcome to Tara Travel — Local-first group travel planning for the Philippines.',
      items: const [
        WhatsNewItem(
          title: 'Collaborative Group Itineraries',
          description:
              'Build multi-day travel schedules together with real-time sync, companion check-ins, and live itinerary docks.',
          category: WhatsNewCategory.feature,
          iconOverride: Icons.calendar_today_rounded,
        ),
        WhatsNewItem(
          title: 'Split Expenses & GCash / Maya Receipts',
          description:
              'Effortlessly divide travel bills, track who paid what, and settle debts with local payment links.',
          category: WhatsNewCategory.feature,
          iconOverride: Icons.account_balance_wallet_rounded,
        ),
        WhatsNewItem(
          title: 'Offline-First Synchronization',
          description:
              'Your trips, packing lists, and notes stay available even when traveling through low-reception islands and mountain passes.',
          category: WhatsNewCategory.improvement,
          iconOverride: Icons.cloud_off_rounded,
        ),
      ],
    ),
  };

  /// Returns curated release notes for a version, or default fallback.
  static ReleaseNotesData getForVersion(SemanticVersion version) {
    final key = version.displayVersion;
    if (_manifest.containsKey(key)) {
      return _manifest[key]!;
    }
    // Return latest available or baseline
    return _manifest['1.0.1'] ??
        ReleaseNotesData(
          version: version,
          tagline: 'Latest performance updates and feature improvements.',
          items: const [
            WhatsNewItem(
              title: 'General Improvements',
              description: 'Stability enhancements, improved offline caching, and bug fixes.',
              category: WhatsNewCategory.improvement,
            ),
          ],
        );
  }
}

/// Fully parsed release notes representation for presentation in UI.
class ReleaseNotesData {
  final SemanticVersion version;
  final DateTime? releaseDate;
  final String tagline;
  final List<WhatsNewItem> items;

  const ReleaseNotesData({
    required this.version,
    this.releaseDate,
    required this.tagline,
    required this.items,
  });

  /// Dynamically parses raw release notes text (e.g. from Supabase remote config)
  /// into structured [WhatsNewItem] entries with fallback to [TaraReleaseManifest].
  factory ReleaseNotesData.parse({
    required SemanticVersion version,
    String? rawNotes,
    DateTime? releaseDate,
  }) {
    if (rawNotes == null || rawNotes.trim().isEmpty || rawNotes == 'General improvements and bug fixes.') {
      final manifestData = TaraReleaseManifest.getForVersion(version);
      return ReleaseNotesData(
        version: version,
        releaseDate: releaseDate ?? manifestData.releaseDate,
        tagline: manifestData.tagline,
        items: manifestData.items,
      );
    }

    final lines = rawNotes
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final parsedItems = <WhatsNewItem>[];

    for (final line in lines) {
      // Remove leading bullet characters
      final cleanLine = line.replaceFirst(RegExp(r'^[-*•]\s*'), '').trim();
      if (cleanLine.isEmpty) continue;

      WhatsNewCategory cat = WhatsNewCategory.feature;
      String? tag;
      String content = cleanLine;

      // Check category tags like [NEW], [FEAT], [IMPROVE], [PERF], [SEC], [FIX]
      final tagMatch = RegExp(r'^\[([A-Za-z0-9_-]+)\]\s*(.*)$').firstMatch(cleanLine);
      if (tagMatch != null) {
        final rawTag = tagMatch.group(1)!.toUpperCase();
        content = tagMatch.group(2)!.trim();
        tag = rawTag;

        if (rawTag.contains('NEW') || rawTag.contains('FEAT')) {
          cat = WhatsNewCategory.feature;
        } else if (rawTag.contains('IMP') || rawTag.contains('PERF')) {
          cat = WhatsNewCategory.improvement;
        } else if (rawTag.contains('SEC') || rawTag.contains('PRIV')) {
          cat = WhatsNewCategory.security;
        } else if (rawTag.contains('FIX') || rawTag.contains('BUG')) {
          cat = WhatsNewCategory.fix;
        }
      } else {
        // Keyword heuristics if no bracket tag is present
        final lower = cleanLine.toLowerCase();
        if (lower.contains('fix') || lower.contains('resolved') || lower.contains('crash')) {
          cat = WhatsNewCategory.fix;
          tag = 'FIX';
        } else if (lower.contains('optim') || lower.contains('faster') || lower.contains('improve')) {
          cat = WhatsNewCategory.improvement;
          tag = 'PERFORMANCE';
        } else if (lower.contains('security') || lower.contains('privacy') || lower.contains('encrypt')) {
          cat = WhatsNewCategory.security;
          tag = 'SECURITY';
        } else {
          cat = WhatsNewCategory.feature;
        }
      }

      // Split title and description if contains ':'
      String title = content;
      String description = '';

      if (content.contains(':')) {
        final parts = content.split(':');
        title = parts[0].trim();
        description = parts.sublist(1).join(':').trim();
      } else if (content.contains(' - ')) {
        final parts = content.split(' - ');
        title = parts[0].trim();
        description = parts.sublist(1).join(' - ').trim();
      }

      parsedItems.add(WhatsNewItem(
        title: title,
        description: description,
        category: cat,
        highlightTag: tag,
      ));
    }

    if (parsedItems.isEmpty) {
      return TaraReleaseManifest.getForVersion(version);
    }

    return ReleaseNotesData(
      version: version,
      releaseDate: releaseDate,
      tagline: 'Discover what is new in version ${version.displayVersion}',
      items: parsedItems,
    );
  }
}
