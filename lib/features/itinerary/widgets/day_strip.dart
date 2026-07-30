import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/weather_model.dart';

class DayStrip extends StatelessWidget {
  final List<String> dayLabels;
  final int activeIndex;
  final List<DayForecast>? weather;
  final void Function(int) onTap;

  const DayStrip({
    super.key,
    required this.dayLabels,
    required this.activeIndex,
    this.weather,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: dayLabels.length,
        itemBuilder: (context, i) {
          final active = i == activeIndex;
          final DayForecast? dayWeather = (weather != null && i < weather!.length) ? weather![i] : null;

          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8, top: 4, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: active ? AppColors.primary : Colors.white.withValues(alpha: 0.15), width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayLabels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  if (dayWeather != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dayWeather.conditionIcon,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${dayWeather.tempMax.round()}°',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: active ? Colors.white.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.5),
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
