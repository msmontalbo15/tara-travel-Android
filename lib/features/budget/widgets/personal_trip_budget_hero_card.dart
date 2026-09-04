import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/models/personal_allowance_model.dart';
import 'set_allowance_sheet.dart';

/// Hero presentation card for the "Budget" screen — focusing on personal budget
/// with a trip expenses summary (as requested by the user).
///
/// Features:
/// - Personal budget headline (large total budget).
/// - Remaining operational funds (in Emerald green).
/// - Slim spent bar & % used.
/// - Integrated trip expenses summary pill row (Solo Spent, Group Liability share, Remaining).
class PersonalTripBudgetHeroCard extends StatelessWidget {
  final String tripId;
  final PersonalAllowanceModel? allowance;
  final double myGroupLiability;
  final double tripTotalBudget;
  final double tripTotalSpent;
  final String? tripDestination;
  final String? tripName;

  const PersonalTripBudgetHeroCard({
    super.key,
    required this.tripId,
    required this.allowance,
    required this.myGroupLiability,
    required this.tripTotalBudget,
    required this.tripTotalSpent,
    this.tripDestination,
    this.tripName,
  });

  @override
  Widget build(BuildContext context) {
    final hasPersonal = allowance != null && allowance!.totalAllowance > 0;
    final total = hasPersonal ? allowance!.totalAllowance : tripTotalBudget;
    final personalSpent = hasPersonal ? allowance!.totalPersonalSpent : 0.0;
    final effectiveSpent = personalSpent + myGroupLiability;
    final remaining = hasPersonal
        ? allowance!.remainingOperational(myGroupLiability)
        : (tripTotalBudget - tripTotalSpent).clamp(0.0, double.infinity);
    final percentage = total > 0 ? (effectiveSpent / total).clamp(0.0, 1.0) : 0.0;
    final isDanger = percentage >= 0.9;

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
          // Header row with "MY BUDGET & ALLOWANCE" and Edit button
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
              InkWell(
                onTap: () => SetAllowanceSheet.show(
                  context,
                  tripId: tripId,
                  currentAllowance: allowance?.totalAllowance ?? 0,
                  currentBufferPercent: allowance?.emergencyBufferPercent ?? 0.1,
                  currentCashOnHand: allowance?.cashOnHand ?? 0,
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
                _summaryItem('Group Share', '₱${CurrencyUtils.formatAmount(myGroupLiability)}', const Color(0xFFEF9F27)),
                _summaryDivider(),
                _summaryItem('Trip Total', '₱${CurrencyUtils.formatAmount(tripTotalSpent)}', Colors.white70),
              ],
            ),
          ),
        ],
      ),
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
