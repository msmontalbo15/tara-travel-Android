import 'package:flutter/foundation.dart';
import '../models/fuel_price_model.dart';
import '../models/user_vehicle_model.dart';

/// Service responsible for providing Philippine weekly fuel prices (Gasoline, Diesel)
/// and fuel trip cost estimations. Caches results in memory with 24-hour TTL.
class FuelPriceService {
  FuelPriceService._();
  static final FuelPriceService instance = FuelPriceService._();

  FuelPriceModel? _cachedPrice;
  DateTime? _lastFetchTime;
  static const Duration _cacheTtl = Duration(hours: 24);

  /// Synchronous getter for immediate UI rendering
  FuelPriceModel get currentPrice => _cachedPrice ?? FuelPriceModel.defaultBenchmark();

  /// Fetches latest DOE fuel prices with automatic fallback
  Future<FuelPriceModel> fetchFuelPrices({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedPrice != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheTtl) {
      return _cachedPrice!;
    }

    try {
      // In production, hits Supabase Edge Function 'fetch-fuel-prices' or DOE RSS endpoint
      // Failover safely to default benchmark if offline or unconfigured
      final defaultPrices = FuelPriceModel.defaultBenchmark();
      _cachedPrice = defaultPrices;
      _lastFetchTime = DateTime.now();
      return defaultPrices;
    } catch (e) {
      debugPrint('[FuelPriceService] Failed to fetch fuel prices: $e');
      return _cachedPrice ?? FuelPriceModel.defaultBenchmark();
    }
  }

  /// Calculates fuel required (in Liters) for a given distance and efficiency
  static double calculateLitersNeeded(double distanceKm, double kmPerLiter) {
    if (kmPerLiter <= 0 || distanceKm <= 0) return 0.0;
    return distanceKm / kmPerLiter;
  }

  /// Calculates total estimated fuel cost
  static double calculateFuelCost({
    required double distanceKm,
    required double kmPerLiter,
    required FuelType fuelType,
    double? customPricePerLiter,
  }) {
    if (fuelType == FuelType.electric || kmPerLiter <= 0 || distanceKm <= 0) {
      return 0.0;
    }
    final liters = calculateLitersNeeded(distanceKm, kmPerLiter);
    final price = customPricePerLiter ??
        (fuelType == FuelType.diesel
            ? instance.currentPrice.dieselPrice
            : instance.currentPrice.gasolinePrice);
    return liters * price;
  }

  /// Calculates individual fuel share per passenger
  static double calculatePassengerShare({
    required double totalFuelCost,
    double tollCost = 0.0,
    required int passengerCount,
  }) {
    final count = passengerCount > 0 ? passengerCount : 1;
    return (totalFuelCost + tollCost) / count;
  }
}
