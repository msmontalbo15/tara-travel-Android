import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/models/personal_allowance_model.dart';
import '../../../core/models/trip_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';

/// Dynamic daily burn-rate card with animated velocity gauge and contextual tips.
class DailyPacingCard extends StatelessWidget {
  final TripModel trip;
  final PersonalAllowanceModel allowance;
  final double myGroupLiability;

  const DailyPacingCard({
    super.key,
    required this.trip,
    required this.allowance,
    required this.myGroupLiability,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // Days remaining in trip
    final tripEnd = DateTime(trip.toDate.year, trip.toDate.month, trip.toDate.day);
    final daysRemaining = max(1, tripEnd.difference(todayStart).inDays + 1);

    final dailySafe = allowance.calculateDailySafeSpend(daysRemaining, myGroupLiability);

    // Calculate today's spent
    final todaySpent = allowance.expenses
        .where((e) {
          final d = DateTime(e.date.year, e.date.month, e.date.day);
          return d.isAtSameMomentAs(todayStart);
        })
        .fold(0.0, (acc, e) => acc + e.amount);

    final ratio = dailySafe > 0 ? (todaySpent / dailySafe).clamp(0.0, 1.5) : 0.0;
    final barRatio = ratio.clamp(0.0, 1.0);
    final isOver = dailySafe > 0 && todaySpent > dailySafe;

    Color statusColor;
    IconData statusIcon;
    String statusText;
    String tipText;
    if (isOver) {
      statusColor = const Color(0xFFEF4444);
      statusIcon = Icons.warning_amber_rounded;
      statusText = 'Over budget';
      tipText = 'You\'ve exceeded today\'s target by ₱${CurrencyUtils.formatAmount(todaySpent - dailySafe)}. Try to cut back tomorrow.';
    } else if (ratio > 0.8) {
      statusColor = const Color(0xFFEF9F27);
      statusIcon = Icons.trending_up_rounded;
      statusText = 'Near limit';
      tipText = 'Only ₱${CurrencyUtils.formatAmount(dailySafe - todaySpent)} left for today. Consider free activities.';
    } else if (ratio > 0.5) {
      statusColor = const Color(0xFF10B981);
      statusIcon = Icons.trending_flat_rounded;
      statusText = 'On pace';
      tipText = 'You\'re spending at a healthy rate. Keep it up!';
    } else {
      statusColor = const Color(0xFF10B981);
      statusIcon = Icons.check_circle_outline_rounded;
      statusText = 'Under pace';
      tipText = 'Plenty of room — you could splurge on a treat!';
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(statusIcon, size: 14, color: statusColor),
                      ),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'Safe-to-Spend Today',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepEarth,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
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
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Big Amount Display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    '₱${CurrencyUtils.formatAmount(max(0.0, dailySafe - todaySpent))}',
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: isOver ? const Color(0xFFEF4444) : AppColors.deepEarth,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'left today',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Animated pacing bar with gradient
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                Stack(
                  children: [
                    // Background
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    // Fill
                    FractionallySizedBox(
                      widthFactor: barRatio,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isOver
                                ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                                : ratio > 0.8
                                    ? [const Color(0xFFF59E0B), const Color(0xFFEF9F27)]
                                    : [const Color(0xFF34D399), const Color(0xFF10B981)],
                          ),
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 10,
                          color: Color(0xFF9CA3AF),
                        ),
                        children: [
                          const TextSpan(text: 'Spent '),
                          TextSpan(
                            text: '₱${CurrencyUtils.formatAmount(todaySpent)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 10,
                          color: Color(0xFF9CA3AF),
                        ),
                        children: [
                          const TextSpan(text: 'Target '),
                          TextSpan(
                            text: '₱${CurrencyUtils.formatAmount(dailySafe)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Contextual tip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.04),
              border: Border(top: BorderSide(color: statusColor.withValues(alpha: 0.1))),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, size: 14, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$tipText  ·  $daysRemaining day${daysRemaining > 1 ? 's' : ''} remaining',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      color: statusColor.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
