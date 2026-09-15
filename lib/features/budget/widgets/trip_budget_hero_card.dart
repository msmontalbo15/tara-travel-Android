import 'package:tara_travel/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import 'budget_ring_chart.dart';

/// Overview card for Trip Expenses.
/// Shows Trip Name, Subtitle, Ring Chart with "% spent",
/// large total budget, remaining amount, and "₱X spent by Y members".
///
/// Supports collapsible mode:
/// - Expanded: full header with ring chart and breakdown.
/// - Collapsed: sleek compact bar showing Total, Remaining, % used, and expand chevron.
class TripBudgetHeroCard extends StatefulWidget {
  final double totalBudget;
  final double totalSpent;
  final int memberCount;
  final String? tripSubtitle;
  final String? tripName;
  final bool? isCollapsed;
  final VoidCallback? onToggleCollapse;

  const TripBudgetHeroCard({
    super.key,
    required this.totalBudget,
    required this.totalSpent,
    this.memberCount = 4,
    this.tripSubtitle,
    this.tripName,
    this.isCollapsed,
    this.onToggleCollapse,
  });

  @override
  State<TripBudgetHeroCard> createState() => _TripBudgetHeroCardState();
}

class _TripBudgetHeroCardState extends State<TripBudgetHeroCard> {
  bool _internalCollapsed = false;

  bool get _isCollapsed => widget.isCollapsed ?? _internalCollapsed;

  void _toggle() {
    if (widget.onToggleCollapse != null) {
      widget.onToggleCollapse!();
    } else {
      setState(() {
        _internalCollapsed = !_internalCollapsed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (widget.totalBudget - widget.totalSpent).clamp(0.0, double.infinity);
    final percentage = widget.totalBudget > 0 ? (widget.totalSpent / widget.totalBudget).clamp(0.0, 1.0) : 0.0;
    final isWarn = percentage > 0.7 && percentage <= 0.9;
    final isDanger = percentage > 0.9;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      child: _isCollapsed
          ? _buildCollapsedCard(
              totalBudget: widget.totalBudget,
              remaining: remaining,
              percentage: percentage,
              isWarn: isWarn,
              isDanger: isDanger,
            )
          : _buildExpandedCard(
              remaining: remaining,
              percentage: percentage,
              isWarn: isWarn,
              isDanger: isDanger,
            ),
    );
  }

  Widget _buildCollapsedCard({
    required double totalBudget,
    required double remaining,
    required double percentage,
    required bool isWarn,
    required bool isDanger,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            const Color(0xFF2C1A14).withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: _toggle,
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            // Total Budget
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.tripName != null && widget.tripName!.isNotEmpty
                        ? widget.tripName!
                        : 'TRIP BUDGET',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB4B2A9),
                      letterSpacing: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '₱${CurrencyUtils.formatAmount(totalBudget)}',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontBody,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Remaining
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: (isDanger
                        ? const Color(0xFFFF6B6B)
                        : (isWarn ? AppColors.amber : const Color(0xFF34D399)))
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (isDanger
                          ? const Color(0xFFFF6B6B)
                          : (isWarn ? AppColors.amber : const Color(0xFF34D399)))
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Remaining',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w500,
                      color: isDanger
                          ? const Color(0xFFFF6B6B)
                          : (isWarn ? AppColors.amber : const Color(0xFF34D399)),
                    ),
                  ),
                  Text(
                    '₱${CurrencyUtils.formatAmount(remaining)}',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontBody,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDanger
                          ? const Color(0xFFFF6B6B)
                          : (isWarn ? AppColors.amber : const Color(0xFF34D399)),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // % Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Text(
                '${(percentage * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Expand Chevron
            Container(
              padding: const EdgeInsets.all(3.5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedCard({
    required double remaining,
    required double percentage,
    required bool isWarn,
    required bool isDanger,
  }) {
    return Column(
      children: [
        // Trip Name Title
        if (widget.tripName != null && widget.tripName!.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.tripName!,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontHeading,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
        ],

        // Hero Header Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trip Expenses Tracker',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontHeading,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.tripSubtitle ?? 'Trip expenses overview',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '${(percentage * 100).toInt()}% used',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: _toggle,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_up_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // The Classic Ring Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.20),
                const Color(0xFF2C1A14).withValues(alpha: 0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              BudgetRingChart(
                percentage: percentage,
                label: 'Spent',
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₱',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            CurrencyUtils.formatAmount(widget.totalBudget),
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontBody,
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Total trip budget',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₱${CurrencyUtils.formatAmount(remaining)} remaining',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDanger
                            ? const Color(0xFFFF6B6B)
                            : (isWarn ? AppColors.amber : const Color(0xFF34D399)),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₱${CurrencyUtils.formatAmount(widget.totalSpent)} spent by ${widget.memberCount} members',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
