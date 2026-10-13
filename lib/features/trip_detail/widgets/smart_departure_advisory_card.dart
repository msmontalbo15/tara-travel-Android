import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/trip_model.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/providers/itinerary_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/departure_advisory_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../itinerary/widgets/navigate_route_button.dart';
import '../../itinerary/widgets/stop_detail_sheet.dart';

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
  final ItineraryStop? nextStop;
  final DateTime? nextStopDate;
  final VoidCallback? onOpenItinerary;

  const SmartDepartureAdvisoryCard({
    super.key,
    required this.trip,
    this.nextStop,
    this.nextStopDate,
    this.onOpenItinerary,
  });

  @override
  ConsumerState<SmartDepartureAdvisoryCard> createState() => _SmartDepartureAdvisoryCardState();
}

class _SmartDepartureAdvisoryCardState extends ConsumerState<SmartDepartureAdvisoryCard> {
  Timer? _ticker;
  late final PageController _pageController;
  int _currentPage = 0;
  bool _hasAutoTransitioned = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Refresh countdown every 30 seconds
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _openStopDetail(ItineraryStop targetStop) {
    final trip = widget.trip;
    final currentUserId = ref.read(currentUserProvider)?.id ?? '';
    final canManage = trip.ownerId == currentUserId ||
        trip.members.any((m) => m.id == currentUserId && m.isOrganizer);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StopDetailSheet(
        stop: targetStop,
        members: trip.members,
        currentUserId: currentUserId,
        canManage: canManage,
        onEdit: () {
          Navigator.pop(ctx);
          widget.onOpenItinerary?.call();
        },
        onCheckIn: () async {
          try {
            final subProvider = ref.read(itineraryProvider(trip.id));
            final itineraryState = ref.read(subProvider).asData?.value;
            if (itineraryState != null) {
              await ref.read(subProvider.notifier).toggleStopVisited(
                itineraryState.activeDay,
                targetStop.id,
                currentUserId,
              );
              ref.invalidate(itineraryStopsProvider(trip.id));
            }
          } catch (e) {
            debugPrint('[SmartDepartureAdvisoryCard] check-in error: $e');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final stopsAsync = ref.watch(itineraryStopsProvider(trip.id));
    final stops = stopsAsync.value ?? [];

    // Stop 0 or first transport stop represents the meet-up
    ItineraryStop? meetUpStop;
    for (final s in stops) {
      if (s.type == StopType.transport ||
          s.title.toLowerCase().contains('meet-up') ||
          s.title.toLowerCase().contains('departure')) {
        meetUpStop = s;
        break;
      }
    }
    meetUpStop ??= widget.nextStop ?? (stops.isNotEmpty ? stops.first : null);

    final departurePoint = trip.departurePoint ?? meetUpStop?.location;
    if (departurePoint == null || departurePoint.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final advisory = DepartureAdvisoryService.instance.computeState(
      trip: trip,
      meetUpStop: meetUpStop,
    );

    // Identify next itinerary stop after meet-up stop
    ItineraryStop? nextItineraryStop;
    for (final s in stops) {
      if (s.id != meetUpStop?.id && !s.isCompleted) {
        nextItineraryStop = s;
        break;
      }
    }
    if (nextItineraryStop == null && stops.length > 1) {
      nextItineraryStop = stops.firstWhere(
        (s) => s.id != meetUpStop?.id,
        orElse: () => stops.last,
      );
    }

    // Auto-advance to next itinerary stop if all members arrived
    final allMembersArrived = advisory.totalCount > 0 &&
        advisory.arrivedCount >= advisory.totalCount;
    final canSwipeToNext = (advisory.isDeparted || allMembersArrived) &&
        nextItineraryStop != null &&
        nextItineraryStop.id != meetUpStop?.id;

    if (allMembersArrived &&
        canSwipeToNext &&
        !_hasAutoTransitioned &&
        _currentPage == 0) {
      _hasAutoTransitioned = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.animateToPage(
            1,
            duration: const Duration(milliseconds: 550),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    }

    final currentUserId = ref.watch(currentUserProvider)?.id ?? '';
    final isOrganizer = trip.ownerId == currentUserId ||
        trip.members.any((m) => m.id == currentUserId && m.isOrganizer);
    final hasUserCheckedIn = meetUpStop != null &&
        meetUpStop.checkedInMembers.containsKey(currentUserId);

    Color statusColor;
    Color statusBg;
    String statusBadge;

    switch (advisory.status) {
      case DepartureAdvisoryStatus.onTime:
        statusColor = const Color(0xFF10B981);
        statusBg = const Color(0xFFECFDF5);
        statusBadge = 'NEXT UP · ON TIME';
        break;
      case DepartureAdvisoryStatus.approachingGracePeriod:
        statusColor = AppColors.primary;
        statusBg = const Color(0xFFFFF2ED);
        statusBadge = 'NEXT UP · ASSEMBLY SOON';
        break;
      case DepartureAdvisoryStatus.withinGracePeriod:
        statusColor = const Color(0xFFEF9F27);
        statusBg = const Color(0xFFFFFBEB);
        statusBadge = 'NEXT UP · GRACE PERIOD';
        break;
      case DepartureAdvisoryStatus.delayed:
        statusColor = const Color(0xFFDC2626);
        statusBg = const Color(0xFFFEF2F2);
        statusBadge = 'NEXT UP · ROLLING OUT';
        break;
      case DepartureAdvisoryStatus.departed:
        statusColor = const Color(0xFF6366F1);
        statusBg = const Color(0xFFEEF2FF);
        statusBadge = 'NEXT UP · DEPARTED';
        break;
    }

    final targetStop = meetUpStop ??
        ItineraryStop(
          id: 'dep',
          title: 'Meet-up & Assembly',
          type: StopType.transport,
          lat: trip.departureLat,
          lng: trip.departureLng,
          location: departurePoint,
        );

    final assemblyCard = _buildAssemblyCard(
      context: context,
      trip: trip,
      targetStop: targetStop,
      meetUpStop: meetUpStop,
      departurePoint: departurePoint,
      advisory: advisory,
      statusColor: statusColor,
      statusBg: statusBg,
      statusBadge: statusBadge,
      hasUserCheckedIn: hasUserCheckedIn,
      isOrganizer: isOrganizer,
      currentUserId: currentUserId,
      canSwipeToNext: canSwipeToNext,
      allMembersArrived: allMembersArrived,
    );

    if (!canSwipeToNext) {
      return assemblyCard;
    }

    final nextStopCard = _buildNextItineraryStopCard(
      context: context,
      trip: trip,
      nextStop: nextItineraryStop,
      currentUserId: currentUserId,
      allMembersArrived: allMembersArrived,
      isDeparted: advisory.isDeparted,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 300,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              assemblyCard,
              nextStopCard,
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Dots Indicator and Quick Navigation Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPageIndicatorDot(
              isActive: _currentPage == 0,
              onTap: () {
                _pageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
            const SizedBox(width: 6),
            _buildPageIndicatorDot(
              isActive: _currentPage == 1,
              onTap: () {
                _pageController.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPageIndicatorDot({required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: isActive ? 20 : 6,
        height: 6,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : const Color(0xFFD1D5DB),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  Widget _buildAssemblyCard({
    required BuildContext context,
    required TripModel trip,
    required ItineraryStop targetStop,
    required ItineraryStop? meetUpStop,
    required String departurePoint,
    required DepartureAdvisoryState advisory,
    required Color statusColor,
    required Color statusBg,
    required String statusBadge,
    required bool hasUserCheckedIn,
    required bool isOrganizer,
    required String currentUserId,
    required bool canSwipeToNext,
    required bool allMembersArrived,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _openStopDetail(targetStop);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.35),
            width: 1.2,
          ),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Status badge + Headcount pill + Swipe hint / Chevron
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
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
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
                      color: allMembersArrived
                          ? const Color(0xFFECFDF5)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: allMembersArrived
                          ? Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          allMembersArrived
                              ? Icons.check_circle_rounded
                              : Icons.group_rounded,
                          size: 13,
                          color: allMembersArrived
                              ? const Color(0xFF10B981)
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          allMembersArrived
                              ? 'All Arrived ✓'
                              : '${advisory.arrivedCount}/${advisory.totalCount} Arrived',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: allMembersArrived
                                ? const Color(0xFF047857)
                                : AppColors.deepEarth,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (canSwipeToNext) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        1,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.sand,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Next stop',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Color(0xFFB0B0B8),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 10),

            // Meet-up location & headline
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.place_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meetUpStop?.title ?? 'Meet-up & Assembly',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepEarth,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              departurePoint.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        advisory.statusDescription,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Grace period gauge and wheels-up info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 14, color: AppColors.muted),
                  const SizedBox(width: 6),
                  Text(
                    'Grace: ${advisory.gracePeriodMinutes} mins',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.deepEarth,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Wheels-up: ${_formatTime(TimeOfDay.fromDateTime(advisory.wheelsUpTime))}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Transport mode & Vehicle details
            if ((trip.transportMode != null && trip.transportMode!.trim().isNotEmpty) ||
                (trip.transportMeta != null && trip.transportMeta!.isNotEmpty)) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.sand.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder, width: 0.8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car_filled_rounded, size: 13, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        () {
                          final meta = trip.transportMeta;
                          if (meta != null && meta.isNotEmpty) {
                            final mode = meta['mode']?.toString() ?? '';
                            if (mode == 'rental') {
                              final days = meta['rental_days'] ?? 1;
                              final driver = meta['has_driver'] == true ? 'with driver' : 'self-drive';
                              return 'Charter: $days-day van rental ($driver)';
                            }
                            if (mode == 'commute') {
                              final fare = meta['fare_per_pax'];
                              final hub = meta['transit_hub_name'] ?? 'Transit';
                              return fare != null ? 'Commute: ₱$fare/pax via $hub' : 'Commute: $hub';
                            }
                            final vName = meta['vehicle_name'] ?? 'Personal Vehicle';
                            final kml = meta['kml'];
                            return kml != null ? 'Vehicle: $vName ($kml km/L)' : 'Vehicle: $vName';
                          }
                          final mode = trip.transportMode ?? '';
                          return mode.isNotEmpty ? 'Transport: ${mode[0].toUpperCase()}${mode.substring(1)}' : 'Land Transport';
                        }(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepEarth,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Action Buttons: Check-in / Arrived & Navigate
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final lat = trip.departureLat ?? meetUpStop?.lat;
                      final lng = trip.departureLng ?? meetUpStop?.lng;
                      if (lat != null && lng != null) {
                        final target = meetUpStop ??
                            ItineraryStop(
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
                    icon: const Icon(Icons.directions_rounded, size: 15),
                    label: const Text('Navigate'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.deepEarth,
                      side: const BorderSide(color: AppColors.cardBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                                ref.invalidate(itineraryStopsProvider(trip.id));
                              }
                            } catch (e) {
                              debugPrint('[SmartDepartureAdvisoryCard] check-in error: $e');
                            }
                          },
                    icon: Icon(
                      hasUserCheckedIn ? Icons.check_circle_rounded : Icons.how_to_reg_rounded,
                      size: 15,
                    ),
                    label: Text(hasUserCheckedIn ? 'Arrived ✓' : "I'm Here"),
                    style: FilledButton.styleFrom(
                      backgroundColor: hasUserCheckedIn ? const Color(0xFF10B981) : AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),

            if (isOrganizer && !advisory.isDeparted && meetUpStop != null) ...[
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () async {
                    final stopId = meetUpStop.id;
                    try {
                      final subProvider = ref.read(itineraryProvider(trip.id));
                      final itineraryState = ref.read(subProvider).asData?.value;
                      if (itineraryState != null) {
                        await ref.read(subProvider.notifier).toggleStopVisited(
                          itineraryState.activeDay,
                          stopId,
                          currentUserId,
                        );
                        ref.invalidate(itineraryStopsProvider(trip.id));
                      }
                    } catch (e) {
                      debugPrint('[SmartDepartureAdvisoryCard] roll-out error: $e');
                    }
                  },
                  icon: const Icon(Icons.rocket_launch_rounded, size: 13, color: AppColors.primary),
                  label: const Text(
                    'Depart Now / Rolling Out (Organizer Action)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNextItineraryStopCard({
    required BuildContext context,
    required TripModel trip,
    required ItineraryStop nextStop,
    required String currentUserId,
    required bool allMembersArrived,
    required bool isDeparted,
  }) {
    final typeColor = nextStop.type.color;
    final timeStr = nextStop.startTime != null
        ? _formatTime(nextStop.startTime!)
        : 'Upcoming';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _openStopDetail(nextStop);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: typeColor.withValues(alpha: 0.35),
            width: 1.2,
          ),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Header: Next Stop Badge + Back to Assembly Trigger
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: typeColor.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(nextStop.type.icon, size: 11, color: typeColor),
                      const SizedBox(width: 4),
                      Text(
                        'NEXT DESTINATION · $timeStr',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: typeColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_rounded, size: 12, color: AppColors.textSecondary),
                        SizedBox(width: 3),
                        Text(
                          'Assembly',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Stop Title & Location
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(nextStop.type.icon, color: typeColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nextStop.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepEarth,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (nextStop.location != null && nextStop.location!.trim().isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.place_outlined, size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                nextStop.location!.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (nextStop.notes != null && nextStop.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          nextStop.notes!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Transition Context Pill (Departed or All Arrived)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: allMembersArrived ? const Color(0xFFECFDF5) : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: allMembersArrived
                    ? Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25))
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    allMembersArrived
                        ? Icons.check_circle_outline_rounded
                        : (isDeparted ? Icons.flight_takeoff_rounded : Icons.info_outline_rounded),
                    size: 14,
                    color: allMembersArrived ? const Color(0xFF10B981) : AppColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      allMembersArrived
                          ? 'All members arrived at assembly. Ready for next stop!'
                          : 'Convoy rolling out towards this stop.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: allMembersArrived ? const Color(0xFF047857) : AppColors.deepEarth,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Action Buttons: Navigate & Full Itinerary
            Row(
              children: [
                if (nextStop.lat != null && nextStop.lng != null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        NavigateRouteButton.launchDirectionsUrl(
                          context: context,
                          stops: [nextStop],
                        );
                      },
                      icon: const Icon(Icons.directions_rounded, size: 15),
                      label: const Text('Navigate'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.deepEarth,
                        side: const BorderSide(color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      widget.onOpenItinerary?.call();
                    },
                    icon: const Icon(Icons.map_outlined, size: 15),
                    label: const Text('View Timeline'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
