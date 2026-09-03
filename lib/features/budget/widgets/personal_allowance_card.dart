import 'package:flutter/material.dart';
import '../../../core/models/personal_allowance_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import 'set_allowance_sheet.dart';

/// Hero presentation card for a traveler's personal trip allowance.
class PersonalAllowanceCard extends StatelessWidget {
  final String tripId;
  final PersonalAllowanceModel? allowance;
  final double myGroupLiability;
  final String? tripDestination;
  final String? tripName;

  const PersonalAllowanceCard({
    super.key,
    required this.tripId,
    required this.allowance,
    required this.myGroupLiability,
    this.tripDestination,
    this.tripName,
  });

  @override
  Widget build(BuildContext context) {
    if (allowance == null || allowance!.totalAllowance <= 0) {
      return _buildEmptyCard(context);
    }

    final total = allowance!.totalAllowance;
    final personalSpent = allowance!.totalPersonalSpent;
    final contingency = allowance!.contingencyAmount;
    final remaining = allowance!.remainingOperational(myGroupLiability);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.deepEarth, Color(0xFF3D2319)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with title and edit button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Color(0xFFF0997B),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        tripDestination != null && tripDestination!.isNotEmpty
                            ? 'MY ALLOWANCE · ${tripDestination!.toUpperCase()}'
                            : 'MY TRIP ALLOWANCE',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: Color(0xFFD1D5DB),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => SetAllowanceSheet.show(
                  context,
                  tripId: tripId,
                  currentAllowance: allowance!.totalAllowance,
                  currentBufferPercent: allowance!.emergencyBufferPercent,
                  currentCashOnHand: allowance!.cashOnHand,
                ),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined,
                          size: 13, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
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
          const SizedBox(height: 12),

          // Trip Name
          if (tripName != null && tripName!.isNotEmpty) ...[
            Text(
              tripName!,
              style: const TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
          ],

          // Total Allowance Large Number
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  '₱${CurrencyUtils.formatAmount(total)}',
                  style: const TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'total budget',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3-Pill Breakdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                _metricItem(
                  label: 'Solo Spent',
                  amount: '₱${CurrencyUtils.formatAmount(personalSpent)}',
                  color: const Color(0xFFF0997B),
                ),
                _divider(),
                _metricItem(
                  label: 'Group Share',
                  amount: '₱${CurrencyUtils.formatAmount(myGroupLiability)}',
                  color: const Color(0xFFEF9F27),
                ),
                _divider(),
                _metricItem(
                  label: 'Safe Left',
                  amount: '₱${CurrencyUtils.formatAmount(remaining)}',
                  color: remaining >= 0
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Multi-Segment Visual Stacked Bar
          if (total > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    if (personalSpent > 0)
                      Expanded(
                        flex: (personalSpent / total * 1000).toInt().clamp(1, 1000),
                        child: Container(color: const Color(0xFFF0997B)),
                      ),
                    if (myGroupLiability > 0)
                      Expanded(
                        flex: (myGroupLiability / total * 1000).toInt().clamp(1, 1000),
                        child: Container(color: const Color(0xFFEF9F27)),
                      ),
                    if (contingency > 0)
                      Expanded(
                        flex: (contingency / total * 1000).toInt().clamp(1, 1000),
                        child: Container(color: const Color(0xFFF59E0B)),
                      ),
                    if (remaining > 0)
                      Expanded(
                        flex: (remaining / total * 1000).toInt().clamp(1, 1000),
                        child: Container(color: const Color(0xFF10B981)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _legendDot(const Color(0xFFF0997B), 'Spent'),
                _legendDot(const Color(0xFFEF9F27), 'Group'),
                _legendDot(const Color(0xFFF59E0B), 'Buffer'),
                _legendDot(const Color(0xFF10B981), 'Available'),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Emergency Buffer Pill
          if (contingency > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF9F27).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFEF9F27).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      size: 13, color: Color(0xFFEF9F27)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '₱${CurrencyUtils.formatAmount(contingency)} (${(allowance!.emergencyBufferPercent * 100).toInt()}%) Emergency Reserve',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF59E0B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _metricItem({
    required String label,
    required String amount,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.sand,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            tripDestination != null
                ? 'Track Your $tripDestination Allowance'
                : 'Track Your Personal Allowance',
            style: const TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.deepEarth,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          const Text(
            'Set your personal spending target for souvenirs, snacks, and solo activities without affecting group bills.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => SetAllowanceSheet.show(context, tripId: tripId),
            icon: const Icon(Icons.add, size: 16),
            label: const Text(
              'Set Personal Allowance',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
