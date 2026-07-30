import 'package:flutter/material.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/theme/app_colors.dart';

/// Shows contextual suggestion chips when a day has fewer than 3 stops.
/// Tapping a chip pre-fills the [AddStopForm] by calling [onSuggest].
class SmartSuggestionChips extends StatelessWidget {
  final ItineraryDay day;
  final void Function(StopType type, String suggestedTitle) onSuggest;

  const SmartSuggestionChips({
    super.key,
    required this.day,
    required this.onSuggest,
  });

  static const _suggestions = [
    (StopType.food, 'Breakfast', Icons.free_breakfast_rounded),
    (StopType.food, 'Lunch Stop', Icons.lunch_dining_rounded),
    (StopType.hotel, 'Accommodation', Icons.hotel_rounded),
    (StopType.activity, 'Sightseeing', Icons.photo_camera_rounded),
    (StopType.transport, 'Transfer', Icons.directions_car_rounded),
    (StopType.food, 'Dinner', Icons.dinner_dining_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    // Only show when day has fewer than 3 stops
    if (day.stops.length >= 3) return const SizedBox.shrink();

    // Filter out stop types already heavily represented
    final existingTitles = day.stops.map((s) => s.title.toLowerCase()).toSet();
    final suggestions = _suggestions
        .where((s) => !existingTitles.contains(s.$2.toLowerCase()))
        .take(4)
        .toList();

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 13, color: AppColors.primary),
              const SizedBox(width: 5),
              Text(
                'Quick add',
                style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary.withValues(alpha: 0.85)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((s) {
              final type = s.$1;
              final title = s.$2;
              final icon = s.$3;
              return GestureDetector(
                onTap: () => onSuggest(type, title),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: type.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: type.color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 13, color: type.color),
                      const SizedBox(width: 5),
                      Text(
                        'Add $title',
                        style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w600, color: type.color),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
