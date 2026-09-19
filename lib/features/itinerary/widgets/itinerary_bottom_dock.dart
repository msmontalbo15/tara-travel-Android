import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/models/trip_model.dart';
import '../../../core/theme/app_colors.dart';
import 'adventure_compass_sheet.dart';
import 'itinerary_map_sheet.dart';

/// Floating bottom action dock providing travelers with 1-tap route navigation / map overview
/// and primary "Add Stop" button.
/// Adapts gracefully when map tracking is disabled or in adventure mode (Plan 10).
class ItineraryBottomDock extends StatelessWidget {
  final ItineraryDay? currentDay;
  final String tripId;
  final bool canManage;
  final bool isMapEnabled;
  final JourneyMode journeyMode;
  final VoidCallback onAddStop;
  final VoidCallback? onTimelineTap;

  const ItineraryBottomDock({
    super.key,
    required this.currentDay,
    required this.tripId,
    required this.canManage,
    required this.onAddStop,
    this.isMapEnabled = true,
    this.journeyMode = JourneyMode.standard,
    this.onTimelineTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final hasStops = currentDay != null && currentDay!.stops.isNotEmpty;
    final isAdventure = journeyMode == JourneyMode.adventure;

    return Positioned(
      left: 12,
      right: 12,
      bottom: bottomInset > 0 ? bottomInset + 8 : 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.deepEarth.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // ── 1. Hero Action: Live Nav vs Compass vs Timeline ───────
                Expanded(
                  flex: 5,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        if (!isMapEnabled) {
                          // Map disabled: switch to / scroll timeline
                          onTimelineTap?.call();
                        } else if (isAdventure) {
                          // Adventure mode: open off-grid compass
                          if (currentDay != null) {
                            AdventureCompassSheet.show(
                              context,
                              day: currentDay!,
                              tripId: tripId,
                            );
                          }
                        } else {
                          // Standard map: launch live navigation
                          Navigator.pushNamed(context, '/navigation');
                        }
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: !isMapEnabled
                                ? [const Color(0xFF2E7D32), const Color(0xFF388E3C)]
                                : isAdventure
                                    ? [const Color(0xFFEF6C00), const Color(0xFFF57C00)]
                                    : [AppColors.primary, const Color(0xFFE86A3E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: (!isMapEnabled
                                      ? const Color(0xFF2E7D32)
                                      : isAdventure
                                          ? const Color(0xFFEF6C00)
                                          : AppColors.primary)
                                  .withValues(alpha: 0.45),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              !isMapEnabled
                                  ? Icons.view_timeline_rounded
                                  : isAdventure
                                      ? Icons.explore_rounded
                                      : Icons.navigation_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              !isMapEnabled
                                  ? 'Timeline'
                                  : isAdventure
                                      ? 'Compass'
                                      : 'Live Nav',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // ── 2. Secondary Action: Day Map vs Stops Roster ───────────
                Expanded(
                  flex: 4,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (currentDay != null) {
                          ItineraryMapSheet.show(
                            context,
                            day: currentDay!,
                            tripId: tripId,
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              !isMapEnabled ? Icons.format_list_bulleted_rounded : Icons.map_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              !isMapEnabled
                                  ? 'Stops'
                                  : (hasStops ? 'Day Map' : 'Map'),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── 3. Add Stop Action (for managers) ──────────────────────
                if (canManage) ...[
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        onAddStop();
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.24),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Stop',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
