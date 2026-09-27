/// optimize_route_modal.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// Modal dialog previewing TSP route optimization ("Find Best Way") for an
/// itinerary day. Shows distance savings and allows 1-tap reordering.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/providers/itinerary_provider.dart';
import '../../../core/services/route_optimization_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/feedback/app_feedback.dart';

class OptimizeRouteModal extends ConsumerStatefulWidget {
  final ItineraryDay day;
  final int dayIndex;
  final String tripId;

  const OptimizeRouteModal({
    super.key,
    required this.day,
    required this.dayIndex,
    required this.tripId,
  });

  static Future<void> show(
    BuildContext context, {
    required ItineraryDay day,
    required int dayIndex,
    required String tripId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OptimizeRouteModal(
        day: day,
        dayIndex: dayIndex,
        tripId: tripId,
      ),
    );
  }

  @override
  ConsumerState<OptimizeRouteModal> createState() => _OptimizeRouteModalState();
}

class _OptimizeRouteModalState extends ConsumerState<OptimizeRouteModal> {
  bool _isLoading = true;
  OptimizationResult? _result;
  List<ItineraryStop>? _reorderedStops;
  String? _errorMessage;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _runOptimization();
  }

  Future<void> _runOptimization() async {
    final candidateStops = widget.day.stops
        .where((s) => s.lat != null && s.lng != null)
        .toList();

    if (candidateStops.length < 3) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Need at least 3 stops with map locations to optimize sequence.';
        });
      }
      return;
    }

    final points = candidateStops.map((s) => LatLng(s.lat!, s.lng!)).toList();

    // Respect pinned stops (e.g. hotel check-in or fixed reservations)
    final pinned = <int>{};
    for (int i = 0; i < candidateStops.length; i++) {
      if (candidateStops[i].type == StopType.hotel) {
        pinned.add(i);
      }
    }

    try {
      final res = await RouteOptimizationService.instance.optimize(
        OptimizationRequest(points: points, pinnedIndices: pinned),
      );

      // Map back into reordered stops list
      final reordered = <ItineraryStop>[];
      for (final origIdx in res.optimizedOrder) {
        reordered.add(candidateStops[origIdx]);
      }

      // Append any stops that didn't have coordinates at the end
      for (final stop in widget.day.stops) {
        if (stop.lat == null || stop.lng == null) {
          reordered.add(stop);
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _result = res;
          _reorderedStops = reordered;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not calculate optimal route. Please try again.';
        });
      }
    }
  }

  Future<void> _applyOptimization() async {
    if (_reorderedStops == null) return;
    setState(() => _isApplying = true);

    try {
      HapticFeedback.mediumImpact();
      final subProvider = ref.read(itineraryProvider(widget.tripId));
      await ref
          .read(subProvider.notifier)
          .setDayStops(widget.dayIndex, _reorderedStops!);

      if (mounted) {
        Navigator.pop(context);
        AppFeedback.showSuccess(
          context,
          'Route optimized! Saved ${_result?.savedDistanceKm.toStringAsFixed(1)} km',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isApplying = false);
        AppFeedback.showError(context, 'Failed to save reordered stops.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.deepEarth,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Optimize Day ${widget.day.dayNumber} Route',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontHeading,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Reorder stops to minimize total driving distance',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white60),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Content state
          if (_isLoading) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Calculating fastest stop sequence...',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.amber, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ] else if (_result != null) ...[
            // Savings summary banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _result!.savedDistanceKm > 0.05
                    ? AppColors.greenBright.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _result!.savedDistanceKm > 0.05
                    ? AppColors.greenBright.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ORIGINAL DISTANCE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_result!.originalDistanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white70,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white38, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'OPTIMIZED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.greenBright,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_result!.optimizedDistanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.greenBright,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_result!.savedDistanceKm > 0.05)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.greenBright,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '-${_result!.savedPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Reordered Stops Preview List
            const Text(
              'Proposed Sequence:',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),

            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _reorderedStops!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (ctx, i) {
                  final stop = _reorderedStops![i];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            stop.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // CTA Button
            ElevatedButton(
              onPressed: _isApplying ? null : _applyOptimization,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isApplying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Apply Optimized Sequence',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
