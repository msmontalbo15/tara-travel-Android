import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/models/personal_allowance_model.dart';
import 'set_allowance_sheet.dart';

/// Hero presentation card for the "Budget" screen — focusing on personal budget
/// with a trip expenses summary (as requested by the user).
///
/// Supports collapsible mode:
/// - Expanded: full budget headline, remaining amount, spent bar, and 3-pill summary.
/// - Collapsed: sleek compact bar showing Total, Remaining, % used, and expand chevron.
class PersonalTripBudgetHeroCard extends StatefulWidget {
  final String tripId;
  final PersonalAllowanceModel? allowance;
  final double myGroupLiability;
  final double tripTotalBudget;
  final double tripTotalSpent;
  final String? tripDestination;
  final String? tripName;
  final bool? isCollapsed;
  final VoidCallback? onToggleCollapse;

  const PersonalTripBudgetHeroCard({
    super.key,
    required this.tripId,
    required this.allowance,
    required this.myGroupLiability,
    required this.tripTotalBudget,
    required this.tripTotalSpent,
    this.tripDestination,
    this.tripName,
    this.isCollapsed,
    this.onToggleCollapse,
  });

  @override
  State<PersonalTripBudgetHeroCard> createState() => _PersonalTripBudgetHeroCardState();
}

class _PersonalTripBudgetHeroCardState extends State<PersonalTripBudgetHeroCard> {
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
    final hasPersonal = widget.allowance != null && widget.allowance!.totalAllowance > 0;
    final total = hasPersonal ? widget.allowance!.totalAllowance : widget.tripTotalBudget;
    final personalSpent = hasPersonal ? widget.allowance!.totalPersonalSpent : 0.0;
    final effectiveSpent = personalSpent + widget.myGroupLiability;
    final remaining = hasPersonal
        ? widget.allowance!.remainingOperational(widget.myGroupLiability)
        : (widget.tripTotalBudget - widget.tripTotalSpent).clamp(0.0, double.infinity);
    final percentage = total > 0 ? (effectiveSpent / total).clamp(0.0, 1.0) : 0.0;
    final isDanger = percentage >= 0.9;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      child: Container(
        width: double.infinity,
        padding: _isCollapsed
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
            : const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: BoxDecoration(
          color: const Color(0xFF2C1A14), // Deep Earth background
          borderRadius: BorderRadius.circular(_isCollapsed ? 18 : 24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: _isCollapsed ? 12 : 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _isCollapsed
            ? _buildCollapsedCard(
                hasPersonal: hasPersonal,
                total: total,
                remaining: remaining,
                effectiveSpent: effectiveSpent,
                percentage: percentage,
                isDanger: isDanger,
              )
            : _buildExpandedCard(
                context: context,
                hasPersonal: hasPersonal,
                total: total,
                remaining: remaining,
                effectiveSpent: effectiveSpent,
                personalSpent: personalSpent,
                percentage: percentage,
                isDanger: isDanger,
              ),
      ),
    );
  }

  Widget _buildCollapsedCard({
    required bool hasPersonal,
    required double total,
    required double remaining,
    required double effectiveSpent,
    required double percentage,
    required bool isDanger,
  }) {
    return InkWell(
      onTap: _toggle,
      borderRadius: BorderRadius.circular(14),
      child: Row(
        children: [
          // Total Budget with tiny caption
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasPersonal ? 'MY BUDGET' : 'TOTAL BUDGET',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB4B2A9),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '₱${CurrencyUtils.formatAmount(total)}',
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

          // Remaining Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: (isDanger ? const Color(0xFFFF6B6B) : const Color(0xFF34D399)).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (isDanger ? const Color(0xFFFF6B6B) : const Color(0xFF34D399)).withValues(alpha: 0.3),
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
                    color: isDanger ? const Color(0xFFFF6B6B) : const Color(0xFF34D399),
                  ),
                ),
                Text(
                  '₱${CurrencyUtils.formatAmount(remaining)}',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontBody,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDanger ? const Color(0xFFFF6B6B) : const Color(0xFF34D399),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // % Used Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${(percentage * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
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
    );
  }

  Widget _buildExpandedCard({
    required BuildContext context,
    required bool hasPersonal,
    required double total,
    required double remaining,
    required double effectiveSpent,
    required double personalSpent,
    required double percentage,
    required bool isDanger,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with "MY BUDGET & ALLOWANCE", Adjust button, and Collapse toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              hasPersonal ? 'MY TRIP BUDGET' : 'TOTAL BUDGET',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB4B2A9),
                letterSpacing: 1.5,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => SetAllowanceSheet.show(
                    context,
                    tripId: widget.tripId,
                    currentAllowance: widget.allowance?.totalAllowance ?? 0,
                    currentBufferPercent: widget.allowance?.emergencyBufferPercent ?? 0.1,
                    currentCashOnHand: widget.allowance?.cashOnHand ?? 0,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tune_rounded, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          hasPersonal ? 'Adjust' : 'Set Personal',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Collapse button
                InkWell(
                  onTap: _toggle,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(3.5),
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
        const SizedBox(height: 6),

        // Big ₱ Amount (DM Sans)
        Text(
          '₱${CurrencyUtils.formatAmount(total)}',
          style: const TextStyle(
            fontFamily: AppTextStyles.fontBody,
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
            height: 1.1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 14),

        // Remaining Row (Label + Emerald Green Value)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Remaining',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFFB4B2A9),
              ),
            ),
            Text(
              '₱${CurrencyUtils.formatAmount(remaining)}',
              style: TextStyle(
                fontFamily: AppTextStyles.fontBody,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: isDanger ? const Color(0xFFFF6B6B) : const Color(0xFF34D399),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Slim Horizontal Spent Bar (matching template)
        Stack(
          children: [
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: isDanger ? const Color(0xFFFF6B6B) : AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Spent ₱X · % Used
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Spent ₱${CurrencyUtils.formatAmount(effectiveSpent)}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFFB4B2A9),
              ),
            ),
            Text(
              '${(percentage * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB4B2A9),
              ),
            ),
          ],
        ),

        // Trip Expenses Summary Pill Row (Connecting personal to trip summary)
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryItem('Pocket Spent', '₱${CurrencyUtils.formatAmount(personalSpent)}', const Color(0xFFF0997B)),
              _summaryDivider(),
              _summaryItem('Group Share', '₱${CurrencyUtils.formatAmount(widget.myGroupLiability)}', const Color(0xFFEF9F27)),
              _summaryDivider(),
              _summaryItem('Trip Total', '₱${CurrencyUtils.formatAmount(widget.tripTotalSpent)}', Colors.white70),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            color: Colors.white.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _summaryDivider() {
    return Container(
      width: 1,
      height: 20,
      color: Colors.white.withValues(alpha: 0.12),
    );
  }
}
