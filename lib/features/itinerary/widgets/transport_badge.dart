import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/itinerary_model.dart';

class TransportBadge extends StatelessWidget {
  final TransportDetail transport;

  const TransportBadge({super.key, required this.transport});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.deepEarth,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(transport.mode.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${transport.mode.label}${transport.vehicleCount != null ? ' (${transport.vehicleCount} vehicles)' : ''}',
                  style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                if (transport.departurePoint != null)
                  Text(
                    '${transport.departurePoint} · ${transport.estimatedDuration}',
                    style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: Colors.white54),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
            child: Text(transport.estimatedDuration, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
