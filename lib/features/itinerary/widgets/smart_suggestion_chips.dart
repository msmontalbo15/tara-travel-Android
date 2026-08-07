import 'package:flutter/material.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/theme/app_colors.dart';

/// Shows quick add template chips that pre-fill the [AddStopForm] when tapped.
class SmartSuggestionChips extends StatelessWidget {
  final ItineraryDay day;
  final void Function(StopType type, String suggestedTitle) onSuggest;

  const SmartSuggestionChips({
    super.key,
    required this.day,
    required this.onSuggest,
  });

  static const _templates = [
    (StopType.food, 'Breakfast', Icons.free_breakfast_rounded),
    (StopType.food, 'Lunch', Icons.lunch_dining_rounded),
    (StopType.food, 'Dinner', Icons.dinner_dining_rounded),
    (StopType.hotel, 'Hotel / Stay', Icons.hotel_rounded),
    (StopType.activity, 'Sightseeing', Icons.photo_camera_rounded),
    (StopType.activity, 'Beach & Nature', Icons.beach_access_rounded),
    (StopType.activity, 'Shopping', Icons.shopping_bag_rounded),
    (StopType.transport, 'Transfer / Ride', Icons.directions_car_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text(
                'Quick Add Templates',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              Text(
                'Tap to pre-fill stop',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 10,
                  color: AppColors.warmMuted.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _templates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final type = _templates[i].$1;
                final title = _templates[i].$2;
                final icon = _templates[i].$3;

                return GestureDetector(
                  onTap: () => onSuggest(type, title),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: type.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: type.color.withValues(alpha: 0.35), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 14, color: type.color),
                        const SizedBox(width: 6),
                        Text(
                          '+ $title',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: type.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
