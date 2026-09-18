import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';

class DistributionCategory {
  final String label;
  final double amount;
  final Color color;

  const DistributionCategory({
    required this.label,
    required this.amount,
    required this.color,
  });
}

class DistributionCard extends StatelessWidget {
  final double? totalSpent;
  final List<DistributionCategory>? categories;

  const DistributionCard({
    super.key,
    this.totalSpent,
    this.categories,
  });

  static const List<DistributionCategory> _defaultCategories = [
    DistributionCategory(label: 'Accommodation', amount: 17885, color: Color(0xFF007AFF)),
    DistributionCategory(label: 'Food', amount: 9125, color: AppColors.amber),
    DistributionCategory(label: 'Transport', amount: 4745, color: AppColors.primary),
    DistributionCategory(label: 'Activities', amount: 4745, color: Color(0xFF34C759)),
  ];

  @override
  Widget build(BuildContext context) {
    final activeCategories = categories ?? _defaultCategories;
    final total = totalSpent ?? activeCategories.fold<double>(0.0, (sum, c) => sum + c.amount);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildPieChart(total, activeCategories),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: activeCategories.map((c) {
                final pct = total > 0 ? ((c.amount / total) * 100).round() : 0;
                return _buildLegendRow(c.label, '$pct%', c.color);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(double total, List<DistributionCategory> cats) {
    final ratios = cats.map((c) => total > 0 ? c.amount / total : 0.0).toList();
    final colors = cats.map((c) => c.color).toList();

    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(110, 110),
            painter: _DistributionRingPainter(ratios: ratios, colors: colors),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  CurrencyUtils.formatCurrency(total),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepEarth,
                  ),
                ),
                Text(
                  'spent',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String label, String pct, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.deepEarth,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            pct,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.deepEarth,
            ),
          ),
        ],
      ),
    );
  }
}

class _DistributionRingPainter extends CustomPainter {
  final List<double> ratios;
  final List<Color> colors;

  _DistributionRingPainter({required this.ratios, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 9;
    const strokeWidth = 18.0;

    double currentAngle = -math.pi / 2; // -90 degrees in radians
    for (int i = 0; i < ratios.length && i < colors.length; i++) {
      final sweepAngle = 2 * math.pi * ratios[i];
      if (sweepAngle <= 0) continue;

      final paint = Paint()
        ..color = colors[i]
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        sweepAngle,
        false,
        paint,
      );
      currentAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DistributionRingPainter oldDelegate) {
    return oldDelegate.ratios != ratios || oldDelegate.colors != colors;
  }
}
