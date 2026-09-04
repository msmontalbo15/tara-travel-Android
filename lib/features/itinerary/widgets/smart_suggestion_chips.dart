import 'package:flutter/material.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/theme/app_colors.dart';

/// Collapsible Quick Add Template chips with progressive disclosure.
class SmartSuggestionChips extends StatefulWidget {
  final ItineraryDay day;
  final void Function(StopType type, String suggestedTitle) onSuggest;

  const SmartSuggestionChips({
    super.key,
    required this.day,
    required this.onSuggest,
  });

  @override
  State<SmartSuggestionChips> createState() => _SmartSuggestionChipsState();
}

class _SmartSuggestionChipsState extends State<SmartSuggestionChips> {
  bool _isExpanded = false;

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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isExpanded
                ? AppColors.primary.withValues(alpha: 0.25)
                : AppColors.dividerLight,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header toggle
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Quick Add Templates',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _isExpanded ? 'Hide' : '${_templates.length} ideas',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.warmMuted.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.muted,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Chips Drawer
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: SizedBox(
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
                        onTap: () => widget.onSuggest(type, title),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: type.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: type.color.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 14, color: type.color),
                              const SizedBox(width: 6),
                              Text(
                                '+ $title',
                                style: TextStyle(
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
