import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/trip_model.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/providers/itinerary_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/departure_advisory_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../itinerary/widgets/navigate_route_button.dart';

/// SmartDepartureAdvisoryCard
/// ─────────────────────────────────────────────────────────────────────────────
/// Command-center Departure & Assembly widget mounted on TripDetailScreen (Plan 11):
/// • Displays real-time Assembly countdown and Wheels-Up Hard Deadline.
/// • Customizable Grace Period visual gauge (e.g. 15-min buffer).
/// • Live companion attendance ratio (e.g. "4/6 arrived").
/// • 1-tap "I'm Here / Arrived" button logging member arrival to Day 1 Stop 0.
/// • 1-tap "Navigate to Meet-up" launching Google Maps / Waze.
/// • Automatically transitions to completed badge once convoy departs.
/// ─────────────────────────────────────────────────────────────────────────────
class SmartDepartureAdvisoryCard extends ConsumerStatefulWidget {
  final TripModel trip;

  const SmartDepartureAdvisoryCard({
    super.key,
    required this.trip,
  });

  @override
  ConsumerState<SmartDepartureAdvisoryCard> createState() => _SmartDepartureAdvisoryCardState();
}

class _SmartDepartureAdvisoryCardState extends ConsumerState<SmartDepartureAdvisoryCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Refresh countdown every 30 seconds
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final stopsAsync = ref.watch(itineraryStopsProvider(trip.id));
    final stops = stopsAsync.value ?? [];

    // Stop 0 or first transport stop represents the meet-up
    ItineraryStop? meetUpStop;
    for (final s in stops) {
      if (s.type == StopType.transport || s.title.toLowerCase().contains('meet-up') || s.title.toLowerCase().contains('departure')) {
        meetUpStop = s;
        break;
      }
    }
    meetUpStop ??= stops.isNotEmpty ? stops.first : null;

    final departurePoint = trip.departurePoint ?? meetUpStop?.location;
    if (departurePoint == null || departurePoint.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final advisory = DepartureAdvisoryService.instance.computeState(
      trip: trip,
      meetUpStop: meetUpStop,
    );

    final currentUserId = ref.watch(currentUserProvider)?.id ?? '';
    final hasUserCheckedIn = meetUpStop != null && meetUpStop.checkedInMembers.containsKey(currentUserId);

    Color statusColor;
    Color statusBg;
    String statusBadge;

    switch (advisory.status) {
      case DepartureAdvisoryStatus.onTime:
        statusColor = const Color(0xFF10B981);
        statusBg = const Color(0xFFECFDF5);
        statusBadge = 'ON TIME';
        break;
      case DepartureAdvisoryStatus.approachingGracePeriod:
        statusColor = AppColors.primary;
        statusBg = const Color(0xFFFFF2ED);
        statusBadge = 'ASSEMBLY SOON';
        break;
      case DepartureAdvisoryStatus.withinGracePeriod:
        statusColor = const Color(0xFFEF9F27);
        statusBg = const Color(0xFFFFFBEB);
        statusBadge = 'GRACE PERIOD';
        break;
      case DepartureAdvisoryStatus.delayed:
        statusColor = const Color(0xFFDC2626);
        statusBg = const Color(0xFFFEF2F2);
        statusBadge = 'ROLLING OUT';
        break;
      case DepartureAdvisoryStatus.departed:
        statusColor = const Color(0xFF6366F1);
        statusBg = const Color(0xFFEEF2FF);
        statusBadge = 'DEPARTED';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: statusColor.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Status badge + Headcount pill
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      statusBadge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (advisory.totalCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.group_rounded, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${advisory.arrivedCount}/${advisory.totalCount} Arrived',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.deepEarth),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Meet-up location & headline
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.sand,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.place_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      departurePoint.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepEarth,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      advisory.statusDescription,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Grace period gauge and wheels-up info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 15, color: AppColors.muted),
                const SizedBox(width: 6),
                Text(
                  'Grace Period: ${advisory.gracePeriodMinutes} mins buffer',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.deepEarth),
                ),
                const Spacer(),
                Text(
                  'Wheels-up: ${_formatTime(TimeOfDay.fromDateTime(advisory.wheelsUpTime))}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Action Buttons: Check-in / Arrived & Navigate
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final lat = trip.departureLat ?? meetUpStop?.lat;
                    final lng = trip.departureLng ?? meetUpStop?.lng;
                    if (lat != null && lng != null) {
                      final target = meetUpStop ?? ItineraryStop(
                        id: 'dep',
                        title: departurePoint,
                        type: StopType.transport,
                        lat: lat,
                        lng: lng,
                        location: departurePoint,
                      );
                      NavigateRouteButton.launchDirectionsUrl(
                        context: context,
                        stops: [target],
                      );
                    }
                  },
                  icon: const Icon(Icons.directions_rounded, size: 16),
                  label: const Text('Navigate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.deepEarth,
                    side: const BorderSide(color: AppColors.cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: hasUserCheckedIn
                      ? null
                      : () async {
                          if (meetUpStop == null || currentUserId.isEmpty) return;
                          try {
                            final subProvider = ref.read(itineraryProvider(trip.id));
                            final itineraryState = ref.read(subProvider).asData?.value;
                            if (itineraryState != null) {
                              await ref.read(subProvider.notifier).toggleStopVisited(
                                itineraryState.activeDay,
                                meetUpStop.id,
                                currentUserId,
                              );
                            }
                          } catch (e) {
                            debugPrint('[SmartDepartureAdvisoryCard] check-in error: $e');
                          }
                        },
                  icon: Icon(
                    hasUserCheckedIn ? Icons.check_circle_rounded : Icons.how_to_reg_rounded,
                    size: 16,
                  ),
                  label: Text(hasUserCheckedIn ? 'Arrived ✓' : "I'm Here"),
                  style: FilledButton.styleFrom(
                    backgroundColor: hasUserCheckedIn ? const Color(0xFF10B981) : AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay tod) {
    final h = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final m = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }
}
