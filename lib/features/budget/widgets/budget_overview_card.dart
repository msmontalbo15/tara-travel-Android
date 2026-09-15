import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';

/// Total Budget hero card strictly derived from trip budget and approved expenses.
/// Designed to reflect the clean dark container layout from the reference template
/// using Tara Travel's brand tokens (Playfair Display for headings, Deep Earth gradient,
/// Emerald Green remaining balance, and a slim spent bar).
class BudgetOverviewCard extends StatefulWidget {
  final double totalBudget;
  final double totalSpent;
  final int memberCount;
  final String? tripSubtitle;
  final String? tripName;
  final bool? isCollapsed;
  final VoidCallback? onToggleCollapse;

  const BudgetOverviewCard({
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
  State<BudgetOverviewCard> createState() => _BudgetOverviewCardState();
}

class _BudgetOverviewCardState extends State<BudgetOverviewCard> {
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
    final isOverBudget = widget.totalSpent > widget.totalBudget && widget.totalBudget > 0;
    final isDanger = percentage >= 0.9 || isOverBudget;

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
            ? InkWell(
                onTap: _toggle,
                borderRadius: BorderRadius.circular(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'TOTAL BUDGET',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB4B2A9),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '₱${CurrencyUtils.formatAmount(widget.totalBudget)}',
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
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "TOTAL BUDGET" Row with collapse toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL BUDGET',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB4B2A9),
                          letterSpacing: 1.5,
                        ),
                      ),
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
                  const SizedBox(height: 6),

          // Big ₱10,000 Amount (DM Sans)
          Text(
            '₱${CurrencyUtils.formatAmount(widget.totalBudget)}',
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
          const SizedBox(height: 16),

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
                  color: isDanger ? const Color(0xFFFF6B6B) : const Color(0xFF34D399), // Emerald
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
                'Spent ₱${CurrencyUtils.formatAmount(widget.totalSpent)}',
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
        ],
      ),
    ),
  );
  }
}
