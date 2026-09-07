import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/models/member_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../itinerary/widgets/navigate_route_button.dart';
import '../../itinerary/widgets/stop_detail_sheet.dart';
import '../../../core/providers/itinerary_provider.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/providers/auth_provider.dart';

/// OngoingTripHud
/// ─────────────────────────────────────────────────────────────────────────────
/// Travel Cockpit Hero for Ongoing Trips (Plan 13):
/// • Displays Current Active / Next Upcoming Stop prominently.
/// • Shows stop type, start/end time, and location summary.
/// • 1-tap "Navigate" trigger via Google Maps / Waze.
/// • 1-tap "Mark Arrived" / "Slide to Arrive" action that updates Supabase.
/// • Tapping the HUD card opens the full [StopDetailSheet].
/// ─────────────────────────────────────────────────────────────────────────────
class OngoingTripHud extends ConsumerWidget {
  final String tripId;
  final ItineraryStop? activeStop;
  final ItineraryStop? nextStop;
  final int totalStops;
  final int visitedStops;
  final VoidCallback onOpenItinerary;

  const OngoingTripHud({
    super.key,
    required this.tripId,
    required this.activeStop,
    required this.nextStop,
    required this.totalStops,
    required this.visitedStops,
    required this.onOpenItinerary,
  });

  void _openStopDetail(BuildContext context, WidgetRef ref, ItineraryStop targetStop) {
    final trip = ref.read(activeTripProvider).asData?.value;
    final members = trip?.members ?? <MemberModel>[];
    final currentUserId = ref.read(currentUserProvider)?.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StopDetailSheet(
        stop: targetStop,
        members: members,
        currentUserId: currentUserId,
        canManage: true,
        onEdit: () {
          Navigator.pop(ctx);
          onOpenItinerary();
        },
      ),
    );
  }

  Future<void> _markStopArrived(BuildContext context, WidgetRef ref, ItineraryStop stop) async {
    try {
      final subProvider = ref.read(itineraryProvider(tripId));
      final itineraryState = ref.read(subProvider).asData?.value;
      if (itineraryState == null) return;
      final notifier = ref.read(subProvider.notifier);
      final currentUserId = ref.read(currentUserProvider)?.id ?? 'me';
      await notifier.toggleStopVisited(itineraryState.activeDay, stop.id, currentUserId);
    } catch (e) {
      debugPrint('[OngoingTripHud] mark arrived error: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetStop = activeStop ?? nextStop;
    final isAllDone = totalStops > 0 && visitedStops == totalStops;

    if (isAllDone) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B3B2B), Color(0xFF2C5E43)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.greenBright, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'All Stops Completed! 🎉',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'You visited all $totalStops waypoints scheduled for this trip.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (targetStop == null) {
      return GestureDetector(
        onTap: onOpenItinerary,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFEBE8E3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_location_alt_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No Upcoming Stops',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tap to add stops or view your itinerary schedule.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ],
          ),
        ),
      );
    }

    final progressPct = totalStops > 0 ? (visitedStops / totalStops).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () => _openStopDetail(context, ref, targetStop),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2C1A14), Color(0xFF42281E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Header: Active status pill + Progress
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'ACTIVE STOP',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$visitedStops of $totalStops completed',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),

            // Middle Stop Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: targetStop.type.color.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(
                        targetStop.type.icon,
                        color: targetStop.type.color,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          targetStop.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (targetStop.location != null && targetStop.location!.isNotEmpty)
                          Text(
                            targetStop.location!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        if (targetStop.startTime != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded, size: 12, color: Colors.white.withValues(alpha: 0.5)),
                              const SizedBox(width: 4),
                              Text(
                                targetStop.startTime!.format(context),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Mini Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressPct,
                  minHeight: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),

            const SizedBox(height: 14),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),

            // Action Footer Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        NavigateRouteButton.launchDirectionsUrl(
                          context: context,
                          stops: [targetStop],
                        );
                      },
                      icon: const Icon(Icons.navigation_rounded, size: 16, color: Color(0xFFFF9F69)),
                      label: const Text(
                        'Navigate',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF9F69),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 22,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _markStopArrived(context, ref, targetStop),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.greenBright),
                      label: const Text(
                        'Mark Arrived',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.greenBright,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
