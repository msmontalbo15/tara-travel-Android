import 'package:flutter/material.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep; // 1-based
  final int totalSteps;
  final String label;

  final bool isDark;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.label,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      'Step $currentStep of $totalSteps — $label',
      style: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 12,
        color: isDark ? const Color(0xFF9C7B70) : const Color(0xFF9CA3AF),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
