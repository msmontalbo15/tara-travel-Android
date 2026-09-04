import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';

/// Category Breakdown chart following Tara Travel brand identity
/// and the reference template (Summary spent/remaining bar, itemized rows with color dots,
/// category emojis, amount, and percentage of budget).
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
    final remaining = (totalBudget - totalSpent).clamp(0.0, double.infinity);
    final spentPct = totalBudget > 0 ? (totalSpent / totalBudget * 100).clamp(0.0, 100.0) : 0.0;
    final remainingPct = (100.0 - spentPct).clamp(0.0, 100.0);

    // Ensure standard categories exist for clear presentation
    final standardCategories = ['food', 'hotel', 'transport', 'activities', 'custom'];
    final displayEntries = <String, double>{};
    for (final cat in standardCategories) {
      if (categoryTotals.containsKey(cat) && categoryTotals[cat]! > 0) {
        displayEntries[cat] = categoryTotals[cat]!;
      }
    }
    // Include any other categories present
    categoryTotals.forEach((key, val) {
      if (!displayEntries.containsKey(key) && val > 0) {
        displayEntries[key] = val;
      }
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Caption (matching template)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.sand,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pie_chart_outline_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'CATEGORY BREAKDOWN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.warmMuted,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Horizontal Progress Bar (Spent vs Remaining)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (spentPct > 0)
                    Flexible(
                      flex: (spentPct * 10).toInt().clamp(1, 1000),
                      child: Container(
                        color: AppColors.primary,
                      ),
                    ),
                  Expanded(
                    flex: ((100.0 - spentPct) * 10).toInt().clamp(1, 1000),
                    child: Container(
                      color: const Color(0xFFF3F4F6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Pacing subtext
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₱${CurrencyUtils.formatAmount(totalSpent)} spent',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepEarth,
                ),
              ),
              Text(
                '₱${CurrencyUtils.formatAmount(remaining)} remaining',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF047857),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF0F0F0), height: 1),
          const SizedBox(height: 12),

          // Itemized category list
          if (displayEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'No approved expenses logged yet.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            )
          else
            ...displayEntries.entries.map((entry) {
              final catPct = totalBudget > 0
                  ? (entry.value / totalBudget * 100).clamp(0.0, 100.0)
                  : (totalSpent > 0 ? (entry.value / totalSpent * 100) : 0.0);
              final color = _getColorForCategory(entry.key);
              final emoji = _getEmojiForCategory(entry.key);
              final label = _getLabelForCategory(entry.key);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Dot
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Emoji
                        Text(emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        // Label
                        Expanded(
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.deepEarth,
                            ),
                          ),
                        ),
                        // Amount & %
                        Text(
                          '₱${CurrencyUtils.formatAmount(entry.value)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepEarth,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${catPct.toStringAsFixed(0)}%',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Micro Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (catPct / 100).clamp(0.0, 1.0),
                        backgroundColor: const Color(0xFFF3F4F6),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 4),
          const Divider(color: Color(0xFFF0F0F0), height: 1),
          const SizedBox(height: 12),

          // Remaining Row
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF10B981), width: 2),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Remaining',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF047857),
                  ),
                ),
              ),
              Text(
                '₱${CurrencyUtils.formatAmount(remaining)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF047857),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: Text(
                  '${remainingPct.toStringAsFixed(0)}%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (remainingPct / 100).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return AppColors.primary;
      case 'hotel':
      case 'accommodation':
        return const Color(0xFF8B5CF6);
      case 'transport':
      case 'flights':
        return const Color(0xFF3B82F6);
      case 'activities':
      case 'activity':
        return const Color(0xFFEF9F27);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  String _getEmojiForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return '🍽️';
      case 'hotel':
      case 'accommodation':
        return '🏨';
      case 'transport':
      case 'flights':
        return '🚐';
      case 'activities':
      case 'activity':
        return '🏝️';
      default:
        return '📦';
    }
  }

  String _getLabelForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return 'Food';
      case 'hotel':
      case 'accommodation':
        return 'Accommodation';
      case 'transport':
      case 'flights':
        return 'Transport';
      case 'activities':
      case 'activity':
        return 'Activities';
      default:
        return 'Other';
    }
  }
}
