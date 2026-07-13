import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'budget_ring_chart.dart';

class BudgetOverviewCard extends StatelessWidget {
  final double totalBudget;
  final double totalSpent;
  final int memberCount;
  final String? tripSubtitle;

  const BudgetOverviewCard({
    super.key,
    required this.totalBudget,
    required this.totalSpent,
    this.memberCount = 4,
    this.tripSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = totalBudget - totalSpent;
    final percentage = (totalSpent / totalBudget).clamp(0.0, 1.0);
    final isWarn = percentage > 0.7 && percentage <= 0.9;
    final isDanger = percentage > 0.9;

    return Column(
      children: [
        // Hero Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Budget Tracker',
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                Text(
                  tripSubtitle ?? 'Trip budget overview',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
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
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // The Ring Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.18),
                const Color(0xFF2C1A14).withValues(alpha: 0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
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
                            fontFamily: 'DM Sans',
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.4),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          totalBudget.toStringAsFixed(0).replaceAllMapped(
                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
                            (Match m) => '${m[1]},'
                          ),
                          style: const TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total trip budget',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₱${remaining.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} remaining',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDanger 
                            ? const Color(0xFFFF6B6B) 
                            : (isWarn ? AppColors.amber : const Color(0xFF34C759)),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₱${totalSpent.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} spent by $memberCount members',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
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
