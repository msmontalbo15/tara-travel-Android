import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/trip_model.dart';
import '../../../core/providers/packing_provider.dart';
import '../../../core/theme/app_colors.dart';
import 'edit_trip_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Planning Recommendations Card — Smart Checklist for Incomplete Trip Items
// ─────────────────────────────────────────────────────────────────────────────

/// A data class representing a single planning gap to surface.
class _PlanningItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _PlanningItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });
}

/// Renders a comprehensive planning checklist for trips in [TripStatus.planning].
///
/// Evaluates trip data (itinerary, budget, members, logistics, packing) and
/// surfaces every gap as a tappable action row. Collapses when dismissed.
class PlanningRecommendationsCard extends ConsumerStatefulWidget {
  final TripModel trip;
  final int totalStops;

  const PlanningRecommendationsCard({
    super.key,
    required this.trip,
    required this.totalStops,
  });

  @override
  ConsumerState<PlanningRecommendationsCard> createState() =>
      _PlanningRecommendationsCardState();
}

class _PlanningRecommendationsCardState
    extends ConsumerState<PlanningRecommendationsCard>
    with SingleTickerProviderStateMixin {
  bool _isCollapsed = true;

  late final AnimationController _collapseController;
  late final Animation<double> _collapseAnimation;

  @override
  void initState() {
    super.initState();
    _collapseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _collapseAnimation = CurvedAnimation(
      parent: _collapseController,
      curve: Curves.easeOutCubic,
    );
    // Start collapsed
    _collapseController.value = 0.0;
  }

  @override
  void dispose() {
    _collapseController.dispose();
    super.dispose();
  }

  void _toggleCollapse() {
    setState(() => _isCollapsed = !_isCollapsed);
    if (_isCollapsed) {
      _collapseController.reverse();
    } else {
      _collapseController.forward();
    }
  }

  List<_PlanningItem> _buildItems(BuildContext context, int packingTotal, int packingPacked) {
    final trip = widget.trip;
    final items = <_PlanningItem>[];

    // 1. Itinerary stops
    if (widget.totalStops == 0) {
      items.add(_PlanningItem(
        icon: Icons.add_circle_outline_rounded,
        label: 'Add itinerary stops',
        subtitle: 'Plan your day-by-day activities',
        accentColor: AppColors.amber,
        onTap: () => Navigator.pushNamed(context, '/itinerary'),
      ));
    }

    // 2. Budget
    if (trip.totalBudget <= 0) {
      items.add(_PlanningItem(
        icon: Icons.savings_outlined,
        label: 'Set a trip budget',
        subtitle: 'Track spending & split expenses',
        accentColor: const Color(0xFF3B82F6),
        onTap: () => Navigator.pushNamed(context, '/budget'),
      ));
    }

    // 3. Members
    if (trip.members.length <= 1) {
      items.add(_PlanningItem(
        icon: Icons.person_add_outlined,
        label: 'Invite trip members',
        subtitle: 'Share the invite code with your squad',
        accentColor: AppColors.greenBright,
        onTap: () => Navigator.pushNamed(context, '/members'),
      ));
    }

    // 4. Departure & transport
    final hasDeparture = trip.departurePoint != null && trip.departurePoint!.trim().isNotEmpty;
    final hasTransport = trip.transportMode != null && trip.transportMode!.trim().isNotEmpty;
    if (!hasDeparture && !hasTransport) {
      items.add(_PlanningItem(
        icon: Icons.near_me_rounded,
        label: 'Set departure & transport',
        subtitle: 'Where to meet & how to get there',
        accentColor: AppColors.primary,
        onTap: () => EditTripSheet.show(context, trip),
      ));
    }

    // 5. Packing
    if (packingTotal == 0) {
      items.add(_PlanningItem(
        icon: Icons.inventory_2_outlined,
        label: 'Start your packing list',
        subtitle: 'AI-powered suggestions for your trip',
        accentColor: AppColors.purple,
        onTap: () => Navigator.pushNamed(context, '/packing'),
      ));
    } else if (packingPacked < packingTotal) {
      items.add(_PlanningItem(
        icon: Icons.checklist_rounded,
        label: 'Finish packing ($packingPacked/$packingTotal)',
        subtitle: '${packingTotal - packingPacked} items remaining',
        accentColor: AppColors.purple,
        onTap: () => Navigator.pushNamed(context, '/packing'),
      ));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;

    // Only show for planning status
    if (trip.status != TripStatus.planning) return const SizedBox.shrink();

    // Read packing state
    final packingProviderInst = ref.watch(packingProvider(trip.id));
    final packingState = ref.watch(packingProviderInst);
    final packingTotal = packingState.totalItems;
    final packingPacked = packingState.packedItems;

    final items = _buildItems(context, packingTotal, packingPacked);

    // All items complete — celebratory state
    if (items.isEmpty) {
      return _AllSetCard(onDismiss: () {});
    }

    final completedCount = 5 - items.length; // out of 5 possible checks
    final daysAway = trip.fromDate.difference(
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    ).inDays;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.amber.withValues(alpha: 0.30),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.amber.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────
          GestureDetector(
            onTap: _toggleCollapse,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.amberLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 18,
                      color: AppColors.amberText,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Planning Checklist',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          daysAway > 0
                              ? '$completedCount of 5 ready · $daysAway days to go'
                              : '$completedCount of 5 ready',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Progress ring
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: completedCount / 5),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutCubic,
                            builder: (_, val, __) => CircularProgressIndicator(
                              value: val,
                              strokeWidth: 3,
                              strokeCap: StrokeCap.round,
                              backgroundColor: const Color(0xFFF2F2F7),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                completedCount >= 4
                                    ? AppColors.greenBright
                                    : AppColors.amber,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          '$completedCount',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: completedCount >= 4
                                ? AppColors.greenBright
                                : AppColors.amberText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 2),
                  AnimatedRotation(
                    turns: _isCollapsed ? -0.25 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Collapsible Items ───────────────────────────────────
          SizeTransition(
            sizeFactor: _collapseAnimation,
            axisAlignment: -1.0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mini progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: completedCount / 5),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (_, val, __) => LinearProgressIndicator(
                        value: val,
                        minHeight: 4,
                        backgroundColor: const Color(0xFFF2F2F7),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          completedCount >= 4
                              ? AppColors.greenBright
                              : AppColors.amber,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Recommendation rows
                  ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: _RecommendationRow(item: item),
                      )),
                ],
              ),
            ),
          ),

          // Bottom padding when collapsed
          if (_isCollapsed) const SizedBox(height: 14),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual Recommendation Row
// ─────────────────────────────────────────────────────────────────────────────

class _RecommendationRow extends StatelessWidget {
  final _PlanningItem item;
  const _RecommendationRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: item.accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, size: 17, color: item.accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Color(0xFFC7C7CC),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// All-Set Celebration Card
// ─────────────────────────────────────────────────────────────────────────────

class _AllSetCard extends StatelessWidget {
  final VoidCallback onDismiss;
  const _AllSetCard({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.greenBright.withValues(alpha: 0.30),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.greenBright.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.greenBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.greenBright,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You\'re all set! 🎉',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Everything looks good for your trip',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.greenBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '5/5',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.greenBright,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
