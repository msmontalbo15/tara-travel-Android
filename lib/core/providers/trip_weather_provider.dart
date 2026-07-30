import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/weather_model.dart';

final tripWeatherProvider = FutureProvider.family<List<DayForecast>, String>((ref, tripId) async {
  // Mock forecast for the trip
  // In a real implementation, you would fetch weather data based on the trip's destination and dates
  return WeatherData.mock().forecast;
});
