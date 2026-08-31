import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/theme/app_colors.dart';
import 'itinerary_map_sheet.dart';

/// Floating bottom action dock providing travelers with 1-tap route navigation / map overview
/// and primary "Add Stop" button.
class ItineraryBottomDock extends StatelessWidget {
  final ItineraryDay? currentDay;
  final String tripId;
  final bool canManage;
  final VoidCallback onAddStop;

  const ItineraryBottomDock({
    super.key,
    required this.currentDay,
    required this.tripId,
    required this.canManage,
    required this.onAddStop,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final hasStops = currentDay != null && currentDay!.stops.isNotEmpty;

    return Positioned(
      left: 14,
      right: 14,
      bottom: bottomInset > 0 ? bottomInset + 8 : 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.deepEarth.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.40),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // ── 1. Live Navigation & Driving Mode (Hero Action) ───────
                Expanded(
                  flex: 5,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pushNamed(context, '/navigation');
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primary,
                            Color(0xFFE86A3E),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.navigation_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Live Nav',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // ── 2. Day Map & Route Overview ────────────────────────────
                Expanded(
                  flex: 4,
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
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.map_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            hasStops ? 'Day Map' : 'Map',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── 3. Add Stop Action (for managers) ──────────────────────
                if (canManage) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onAddStop();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.20),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Stop',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
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
