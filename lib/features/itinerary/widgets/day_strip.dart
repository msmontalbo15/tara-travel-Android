import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/weather_model.dart';

class DayStrip extends StatelessWidget {
  final List<String> dayLabels;
  final int activeIndex;
  final List<DayForecast>? weather;
  final void Function(int) onTap;
  final VoidCallback? onAddDay;

  const DayStrip({
    super.key,
    required this.dayLabels,
    required this.activeIndex,
    this.weather,
    required this.onTap,
    this.onAddDay,
  });

  @override
  Widget build(BuildContext context) {
    final totalCount = dayLabels.length + (onAddDay != null ? 1 : 0);

    return SizedBox(
      height: 78,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: totalCount,
        itemBuilder: (context, i) {
          if (i == dayLabels.length && onAddDay != null) {
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onAddDay!();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8, top: 4, bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.2),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'Day',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final active = i == activeIndex;
          final DayForecast? dayWeather = (weather != null && i < weather!.length) ? weather![i] : null;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap(i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8, top: 4, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: active ? AppColors.primary : Colors.white.withValues(alpha: 0.18), width: active ? 1.5 : 1),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayLabels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      color: active ? Colors.white : Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  if (dayWeather != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dayWeather.conditionIcon,
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${dayWeather.tempMax.round()}°',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: active ? Colors.white.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
