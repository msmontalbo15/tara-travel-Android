import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Animated horizontal progress bar showing estimated spend vs. daily budget.
/// Color coding: green < 80%, amber 80–100%, red > 100%.
class DayBudgetBar extends StatelessWidget {
  final double spent;
  final double dailyBudget;

  const DayBudgetBar({
    super.key,
    required this.spent,
    required this.dailyBudget,
  });

  Color get _barColor {
    if (dailyBudget <= 0) return AppColors.primary;
    final ratio = spent / dailyBudget;
    if (ratio > 1.0) return const Color(0xFFEF4444);
    if (ratio > 0.8) return const Color(0xFFEF9F27);
    return const Color(0xFF10B981);
  }

  String _fmt(double v) =>
      '₱${v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final ratio = dailyBudget > 0 ? (spent / dailyBudget).clamp(0.0, 1.0) : 0.0;
    final remaining = (dailyBudget - spent);
    final over = remaining < 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded, size: 14, color: _barColor),
              const SizedBox(width: 6),
              Text(
                'Day budget  •  ${_fmt(spent)} spent',
                style: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.deepEarth),
              ),
              const Spacer(),
              Text(
                over ? '${_fmt(remaining.abs())} over' : '${_fmt(remaining)} left',
                style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w700, color: _barColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: ratio),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 7,
                backgroundColor: AppColors.surfaceLight,
                valueColor: AlwaysStoppedAnimation(_barColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
