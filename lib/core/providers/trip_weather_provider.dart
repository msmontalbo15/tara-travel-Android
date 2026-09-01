import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/weather_model.dart';
import '../models/trip_model.dart';
import '../services/weather_service.dart';
import 'trip_provider.dart';
import 'selected_trip_provider.dart';

/// Singleton instance provider for WeatherService
final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

/// Multi-day live weather forecast for a specific trip, aligned to trip dates.
final tripWeatherProvider =
    FutureProvider.family<List<DayForecast>, String>((ref, tripId) async {
  final weatherService = ref.watch(weatherServiceProvider);

  // 1. Check selected trip first for fast O(1) resolution
  TripModel? targetTrip;
  final selectedTrip = await ref.watch(selectedTripProvider.future);
  if (selectedTrip?.id == tripId) {
    targetTrip = selectedTrip;
  }

  // 2. Search in all trips if not currently selected
  if (targetTrip == null) {
    final allTrips = await ref.watch(allTripsProvider.future);
    final match = allTrips.where((t) => t.id == tripId).toList();
    if (match.isNotEmpty) {
      targetTrip = match.first;
    }
  }

  if (targetTrip == null) {
    return WeatherData.mock().forecast;
  }

  return weatherService.getTripForecast(targetTrip);
});

/// Real-time live current weather telemetry for a specific trip's destination.
final tripCurrentWeatherProvider =
    FutureProvider.family<WeatherData, String>((ref, tripId) async {
  final weatherService = ref.watch(weatherServiceProvider);

  TripModel? targetTrip;
  final selectedTrip = await ref.watch(selectedTripProvider.future);
  if (selectedTrip?.id == tripId) {
    targetTrip = selectedTrip;
  }

  if (targetTrip == null) {
    final allTrips = await ref.watch(allTripsProvider.future);
    final match = allTrips.where((t) => t.id == tripId).toList();
    if (match.isNotEmpty) {
      targetTrip = match.first;
    }
  }

  if (targetTrip == null) {
    return WeatherData.mock();
  }

  final coords = await weatherService.resolveTripCoordinates(targetTrip);
  if (coords == null) {
    return WeatherData.mock();
  }

  return weatherService.fetchWeather(
    lat: coords.lat,
    lng: coords.lng,
    fromDate: targetTrip.fromDate,
    toDate: targetTrip.toDate,
  );
});
