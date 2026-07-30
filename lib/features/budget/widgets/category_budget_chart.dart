import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class CategoryBudgetChart extends StatelessWidget {
  final Map<String, double> categoryTotals;
  final double totalBudget;
  final double totalSpent;

  const CategoryBudgetChart({
    super.key,
    required this.categoryTotals,
    required this.totalBudget,
    required this.totalSpent,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryTotals.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: const Text(
          'No approved expenses yet.',
          style: TextStyle(fontFamily: 'DM Sans', color: AppColors.warmMuted),
          textAlign: TextAlign.center,
        ),
      );
    }

    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate maximum amount to scale the bars properly. We scale relative to totalSpent,
    // or we could scale relative to the max category. Let's scale relative to max category.
    final maxAmount = sortedEntries.isNotEmpty ? sortedEntries.first.value : 1.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sortedEntries.map((entry) {
          final pct = totalSpent > 0 ? (entry.value / totalSpent) * 100 : 0.0;
          final fillRatio = maxAmount > 0 ? entry.value / maxAmount : 0.0;
          final color = _getColorForCategory(entry.key);

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.deepEarth,
                      ),
                    ),
                    Text(
                      '₱${entry.value.toStringAsFixed(0)} (${pct.toStringAsFixed(0)}%)',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Container(
                          height: 8,
                          width: constraints.maxWidth,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          height: 8,
                          width: constraints.maxWidth * fillRatio,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'flights':
      case 'transport':
        return const Color(0xFF4A90E2); // Blue
      case 'accommodation':
        return const Color(0xFF9B51E0); // Purple
      case 'food':
        return const Color(0xFFF2994A); // Orange
      case 'activities':
        return const Color(0xFFEB5757); // Red
      case 'shopping':
        return const Color(0xFF27AE60); // Green
      default:
        return const Color(0xFF828282); // Gray
    }
  }
}
