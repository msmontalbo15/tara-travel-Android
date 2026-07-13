import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AlertBanner extends StatelessWidget {
  final String message;
  final bool isDanger;

  const AlertBanner({
    super.key,
    required this.message,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: isDanger 
            ? const Color(0xFFFF3B30).withValues(alpha: 0.12)
            : AppColors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDanger
              ? const Color(0xFFFF3B30).withValues(alpha: 0.3)
              : AppColors.amber.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Text(
            isDanger ? '⚠️' : '⚠️', // Could use distinct icons
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDanger ? const Color(0xFFFF6B6B) : AppColors.amber,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
