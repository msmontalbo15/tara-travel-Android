import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';

/// Total Budget hero card strictly derived from trip budget and approved expenses.
/// Designed to reflect the clean dark container layout from the reference template
/// using Tara Travel's brand tokens (Playfair Display for headings, Deep Earth gradient,
/// Emerald Green remaining balance, and a slim spent bar).
class BudgetOverviewCard extends StatelessWidget {
  final double totalBudget;
  final double totalSpent;
  final int memberCount;
  final String? tripSubtitle;
  final String? tripName;

  const BudgetOverviewCard({
    super.key,
    required this.totalBudget,
    required this.totalSpent,
    this.memberCount = 4,
    this.tripSubtitle,
    this.tripName,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (totalBudget - totalSpent).clamp(0.0, double.infinity);
    final percentage = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = totalSpent > totalBudget && totalBudget > 0;
    final isDanger = percentage >= 0.9 || isOverBudget;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C1A14), // Deep Earth background
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "TOTAL BUDGET" Caption
          const Text(
            'TOTAL BUDGET',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB4B2A9),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),

          // Big ₱10,000 Amount (DM Sans)
          Text(
            '₱${CurrencyUtils.formatAmount(totalBudget)}',
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
                'Spent ₱${CurrencyUtils.formatAmount(totalSpent)}',
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
    );
  }
}
