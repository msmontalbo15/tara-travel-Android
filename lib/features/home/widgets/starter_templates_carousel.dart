import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/jit_guard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../create_trip/models/new_trip_model.dart';

/// A curated set of Philippine getaway starter templates surfaced on the home
/// screen when the user has no active trips. Tapping a card opens the
/// create-trip flow with the destination and trip type pre-filled.
class StarterTemplatesCarousel extends ConsumerWidget {
  const StarterTemplatesCarousel({super.key});

  static const List<_TemplateData> _templates = [
    _TemplateData(
      emoji: '🏖️',
      destination: 'Boracay, Philippines',
      tagline: 'Beach & Sunset',
      durationDays: 3,
      tripType: 'Beach',
      accentColor: Color(0xFF00B4DB),
    ),
    _TemplateData(
      emoji: '🌲',
      destination: 'Baguio City, Philippines',
      tagline: 'Cool Breeze & Cafes',
      durationDays: 2,
      tripType: 'Nature',
      accentColor: Color(0xFF43A047),
    ),
    _TemplateData(
      emoji: '🏄',
      destination: 'Siargao, Philippines',
      tagline: 'Surf & Island Hop',
      durationDays: 4,
      tripType: 'Adventure',
      accentColor: Color(0xFF2E7D32),
    ),
    _TemplateData(
      emoji: '⛰️',
      destination: 'Cebu, Philippines',
      tagline: 'Canyoneering & Falls',
      durationDays: 3,
      tripType: 'Adventure',
      accentColor: Color(0xFFFF8C42),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Text(
                '✨',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 6),
              const Text(
                'Need inspiration?',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'Tap to use',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),

        // ── Horizontal card carousel ─────────────────────────────────
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: _templates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final t = _templates[index];
              return _TemplateCard(
                data: t,
                onTap: () async {
                  final canProceed =
                      await JitGuard.checkCreateTripGuard(context, ref);
                  if (!canProceed || !context.mounted) return;

                  // Pre-fill a NewTripModel draft with template defaults
                  final now = DateTime.now();
                  final draft = NewTripModel(
                    destination: t.destination,
                    tripType: t.tripType,
                    fromDate: now.add(const Duration(days: 7)),
                    toDate: now.add(Duration(days: 7 + t.durationDays - 1)),
                  );

                  if (context.mounted) {
                    Navigator.pushNamed(
                      context,
                      '/create-trip',
                      arguments: draft,
                    );
                  }
                },
              );
            },
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}

// ── Template data model ──────────────────────────────────────────────────────

class _TemplateData {
  final String emoji;
  final String destination;
  final String tagline;
  final int durationDays;
  final String tripType;
  final Color accentColor;

  const _TemplateData({
    required this.emoji,
    required this.destination,
    required this.tagline,
    required this.durationDays,
    required this.tripType,
    required this.accentColor,
  });

  /// Short readable destination label (city name before first comma)
  String get shortName => destination.split(',').first;
}

// ── Individual template card ─────────────────────────────────────────────────

class _TemplateCard extends StatefulWidget {
  final _TemplateData data;
  final VoidCallback onTap;

  const _TemplateCard({required this.data, required this.onTap});

  @override
  State<_TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<_TemplateCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) async {
        await _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: 138,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                d.accentColor.withValues(alpha: 0.15),
                d.accentColor.withValues(alpha: 0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: d.accentColor.withValues(alpha: 0.30),
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ── Emoji + duration pill row ──────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    d.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: d.accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${d.durationDays}D',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: d.accentColor,
                      ),
                    ),
                  ),
                ],
              ),

              // ── Labels ────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.shortName,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    d.tagline,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
