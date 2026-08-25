import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../utils/transit_conflict_helper.dart';

/// Visual connector and warning badge rendered between consecutive itinerary stops.
class InterStopTransitBadge extends StatelessWidget {
  final TransitConflictInfo info;

  const InterStopTransitBadge({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    // If no distance, no transit time, and no warning, do not render extra badge
    if (info.distanceKm == null && info.estimatedTransitMinutes == null && !info.hasWarning) {
      return const SizedBox.shrink();
    }

    final hasConflict = info.hasOverlapConflict;
    final isTight = info.isTightBuffer;

    Color badgeBg;
    Color badgeBorder;
    Color textColor;
    IconData icon;

    if (hasConflict) {
      badgeBg = const Color(0xFFEF4444).withValues(alpha: 0.12);
      badgeBorder = const Color(0xFFEF4444).withValues(alpha: 0.35);
      textColor = const Color(0xFFDC2626);
      icon = Icons.error_outline_rounded;
    } else if (isTight) {
      badgeBg = const Color(0xFFF59E0B).withValues(alpha: 0.14);
      badgeBorder = const Color(0xFFF59E0B).withValues(alpha: 0.4);
      textColor = const Color(0xFFD97706);
      icon = Icons.warning_amber_rounded;
    } else {
      badgeBg = Colors.white.withValues(alpha: 0.85);
      badgeBorder = AppColors.dividerLight;
      textColor = AppColors.muted;
      icon = Icons.directions_car_filled_rounded;
    }

    final List<String> parts = [];
    if (info.estimatedTransitMinutes != null) {
      parts.add('~${info.estimatedTransitMinutes} min transit');
    }
    if (info.distanceKm != null) {
      final kmStr = info.distanceKm! < 1.0
          ? '${(info.distanceKm! * 1000).round()} m'
          : '${info.distanceKm!.toStringAsFixed(1)} km';
      parts.add(kmStr);
    }
    if (info.timeGapMinutes != null && !hasConflict && info.timeGapMinutes! > 0) {
      parts.add('${info.timeGapMinutes}m buffer');
    }

    return Padding(
      padding: const EdgeInsets.only(left: 48, right: 12, bottom: 10, top: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: badgeBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: badgeBorder, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                info.warningMessage ?? parts.join(' · '),
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  fontWeight: info.hasWarning ? FontWeight.w700 : FontWeight.w600,
                  color: textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
