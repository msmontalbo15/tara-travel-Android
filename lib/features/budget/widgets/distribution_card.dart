import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class DistributionCard extends StatelessWidget {
  const DistributionCard({super.key});

  @override
  Widget build(BuildContext context) {
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
          // SVG implementation placeholder using a custom painter or stack
          _buildPieChart(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                _buildLegendRow('Accommodation', '49%', const Color(0xFF007AFF)),
                _buildLegendRow('Food', '25%', AppColors.amber),
                _buildLegendRow('Transport', '13%', AppColors.primary),
                _buildLegendRow('Activities', '13%', const Color(0xFF34C759)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        children: [
          // Using a simple Stack with overlapping CircularProgressIndicators for a "ring chart" effect
          // In a real app, a custom painter or a chart library would be used
          CustomPaint(
            size: const Size(110, 110),
            painter: _DistributionRingPainter(),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '₱36,500',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepEarth,
                  ),
                ),
                Text(
                  'spent',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
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
                fontFamily: 'DM Sans',
                fontSize: 12,
                color: AppColors.deepEarth,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            pct,
            style: const TextStyle(
              fontFamily: 'DM Sans',
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
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 9;
    const strokeWidth = 18.0;

    final paintAccom = Paint()
      ..color = const Color(0xFF007AFF)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final paintFood = Paint()
      ..color = const Color(0xFFEF9F27)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final paintTrans = Paint()
      ..color = const Color(0xFFD85A30)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final paintAct = Paint()
      ..color = const Color(0xFF34C759)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Based on HTML arc ratios
    const startScale = -1.5708; // -90 degrees in radians
    
    // Accom: 49%
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startScale, 3.14159 * 2 * 0.49, false, paintAccom);
    
    // Food: 25%
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startScale + (3.14159 * 2 * 0.49), 3.14159 * 2 * 0.25, false, paintFood);
    
    // Transport: 13%
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startScale + (3.14159 * 2 * 0.74), 3.14159 * 2 * 0.13, false, paintTrans);
    
    // Activities: 13%
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startScale + (3.14159 * 2 * 0.87), 3.14159 * 2 * 0.13, false, paintAct);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
