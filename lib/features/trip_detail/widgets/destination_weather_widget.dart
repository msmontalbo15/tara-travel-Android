import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/trip_weather_provider.dart';
import '../../../core/models/weather_model.dart';

/// DestinationWeatherWidget
/// ─────────────────────────────────────────────────────────────────────────────
/// Displays real-time live weather telemetry for the trip destination:
/// • Temperature (°C) & WMO Weather Condition emoji/label.
/// • Rain probability percentage & UV Index badge.
/// • High-contrast warning tag if severe weather alert is active.
/// ─────────────────────────────────────────────────────────────────────────────
class DestinationWeatherWidget extends ConsumerWidget {
  final String tripId;
  final String destinationName;
  final String? nextStopTitle;
  final String? stopLocation;
  final String? primaryAddress;

  const DestinationWeatherWidget({
    super.key,
    required this.tripId,
    required this.destinationName,
    this.nextStopTitle,
    this.stopLocation,
    @Deprecated('Use stopLocation') this.primaryAddress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(tripCurrentWeatherProvider(tripId));

    return weatherAsync.when(
      data: (weather) => _buildWeatherCard(context, weather),
      loading: () => _buildLoadingCard(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Intelligently extracts the city or municipality from a location address string,
  /// falling back to [fallbackDestination] if necessary.
  /// (e.g. "Station 2, Balabag, Malay, Aklan" -> "Malay",
  ///       "Mines View Park, Baguio City, Benguet" -> "Baguio City").
  String? _extractCity(String? address, String fallbackDestination) {
    if (address == null || address.trim().isEmpty) {
      final cleanFallback = fallbackDestination.trim();
      return cleanFallback.isNotEmpty ? cleanFallback : null;
    }

    final rawParts = address
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (rawParts.isEmpty) {
      final cleanFallback = fallbackDestination.trim();
      return cleanFallback.isNotEmpty ? cleanFallback : null;
    }

    // Filter out common country names or postal codes
    final countryOrZip = RegExp(
      r'^(philippines|ph|pilipinas|japan|korea|united states|usa|us|singapore|malaysia|thailand|indonesia|taiwan|vietnam|\d{4,6})$',
      caseSensitive: false,
    );
    final parts =
        rawParts.where((p) => !countryOrZip.hasMatch(p.toLowerCase())).toList();

    if (parts.isEmpty) {
      final cleanFallback = fallbackDestination.trim();
      return cleanFallback.isNotEmpty ? cleanFallback : null;
    }

    // 1. Check if any segment explicitly contains "City" or "Mun."
    final cityKeywordRegex =
        RegExp(r'\b(city|municipality|mun\.)\b', caseSensitive: false);
    for (final part in parts.reversed) {
      if (cityKeywordRegex.hasMatch(part)) {
        return part;
      }
    }

    // 2. If address has 3 or more segments (e.g. [Street, Barangay, City, Province]):
    // The penultimate segment is typically the city/municipality.
    if (parts.length >= 3) {
      return parts[parts.length - 2];
    }

    // 3. If address has 2 segments:
    // e.g. "Baguio, Benguet" -> first is city; "Mines View, Baguio" -> second is city
    if (parts.length == 2) {
      final first = parts[0];
      final second = parts[1];
      if (second.toLowerCase() == fallbackDestination.toLowerCase() ||
          cityKeywordRegex.hasMatch(second)) {
        return second;
      }
      return first;
    }

    // 4. Single segment: fallback to trip destination name if available
    if (fallbackDestination.trim().isNotEmpty) {
      return fallbackDestination.trim();
    }
    return parts.first;
  }

  Widget _buildWeatherCard(BuildContext context, WeatherData weather) {
    final isRainy = weather.rainProbability >= 40;
    final effectiveTitle = nextStopTitle != null && nextStopTitle!.trim().isNotEmpty
        ? nextStopTitle!.trim()
        : destinationName.trim();
    final effectiveLocation = stopLocation ?? primaryAddress;
    final city = _extractCity(effectiveLocation, destinationName);

    // Only show city badge/tag if it isn't redundant with the stop title
    final shouldShowCity = city != null &&
        city.trim().isNotEmpty &&
        !effectiveTitle.toLowerCase().contains(city.toLowerCase().trim());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isRainy
              ? [const Color(0xFF1E2A38), const Color(0xFF2C3E50)]
              : [const Color(0xFF2C1A14), const Color(0xFF3F271E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.wb_sunny_outlined,
                size: 14,
                color: AppColors.amber,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                    children: [
                      const TextSpan(text: 'NEXT DESTINATION • '),
                      TextSpan(
                        text: effectiveTitle.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (shouldShowCity) ...[
                        TextSpan(
                          text: ' ($city)',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (weather.hasAlert) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.red.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 12, color: AppColors.red),
                      const SizedBox(width: 4),
                      Text(
                        weather.alertLevel ?? 'ALERT',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                weather.conditionIcon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weather.temperature.round()}°C',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    weather.condition,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.70),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _buildTelemetryBadge(
                icon: Icons.water_drop_rounded,
                label: '${weather.rainProbability.round()}% Rain',
                color: weather.rainProbability > 30 ? const Color(0xFF64B5F6) : Colors.white70,
              ),
              const SizedBox(width: 8),
              _buildTelemetryBadge(
                icon: Icons.wb_twilight_rounded,
                label: 'UV ${weather.uvIndex}',
                color: weather.uvIndex >= 8 ? AppColors.amber : Colors.white70,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 85,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C1A14).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 130,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
