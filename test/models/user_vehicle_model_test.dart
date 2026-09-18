import 'package:flutter_test/flutter_test.dart';
import 'package:tara_travel/core/models/user_vehicle_model.dart';
import 'package:tara_travel/core/services/fuel_price_service.dart';

void main() {
  group('UserVehicle Model Tests', () {
    test('creates UserVehicle and serializes to/from JSON correctly', () {
      final now = DateTime.now();
      final vehicle = UserVehicle(
        id: 'v-123',
        userId: 'u-456',
        name: 'Toyota Vios 1.5G',
        type: VehicleType.sedan,
        fuelType: FuelType.gasoline,
        kmPerLiter: 14.5,
        plateNumber: 'ABC 1234',
        isDefault: true,
        createdAt: now,
      );

      final json = vehicle.toJson();
      expect(json['id'], 'v-123');
      expect(json['name'], 'Toyota Vios 1.5G');
      expect(json['kmPerLiter'], 14.5);
      expect(json['isDefault'], true);

      final fromJson = UserVehicle.fromJson(json);
      expect(fromJson.id, vehicle.id);
      expect(fromJson.type, VehicleType.sedan);
      expect(fromJson.fuelType, FuelType.gasoline);
      expect(fromJson.kmPerLiter, 14.5);
      expect(fromJson.plateNumber, 'ABC 1234');
      expect(fromJson.isDefault, true);
    });

    test('defaultKmPerLiter returns realistic Philippine vehicle estimates', () {
      expect(VehicleType.sedan.defaultKmPerLiter, 14.0);
      expect(VehicleType.motorcycle.defaultKmPerLiter, 38.0);
      expect(VehicleType.van.defaultKmPerLiter, 9.5);
      expect(VehicleType.bicycle.defaultKmPerLiter, 0.0);
    });
  });

  group('FuelPriceService Tests', () {
    test('calculateLitersNeeded returns correct consumption', () {
      // 140 km distance with 14 km/L = 10 Liters
      final liters = FuelPriceService.calculateLitersNeeded(140.0, 14.0);
      expect(liters, 10.0);
    });

    test('calculateFuelCost computes accurate expense with custom price', () {
      // 140 km distance, 14 km/L (10 Liters) at ₱60.00/L = ₱600.00
      final cost = FuelPriceService.calculateFuelCost(
        distanceKm: 140.0,
        kmPerLiter: 14.0,
        fuelType: FuelType.gasoline,
        customPricePerLiter: 60.0,
      );
      expect(cost, 600.0);
    });

    test('calculatePassengerShare divides fuel and tolls fairly', () {
      // ₱600 fuel + ₱200 tolls = ₱800 / 4 passengers = ₱200 each
      final share = FuelPriceService.calculatePassengerShare(
        totalFuelCost: 600.0,
        tollCost: 200.0,
        passengerCount: 4,
      );
      expect(share, 200.0);
    });
  });
}
