import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_vehicle_model.dart';

/// Repository managing the user's saved vehicles ("My Garage").
/// Persists vehicles partition-aware in encrypted storage and synchronizes with
/// user metadata/profile.
class UserVehiclesRepository {
  static const String _kGaragePrefix = 'user_garage_vehicles_';

  final FlutterSecureStorage _storage;

  UserVehiclesRepository({
    FlutterSecureStorage? storage,
    SupabaseClient? supabase,
  })  : _storage = storage ?? const FlutterSecureStorage();

  String _storageKey(String userId) => '$_kGaragePrefix$userId';

  /// Loads vehicles for a user ID (offline-first from encrypted storage)
  Future<List<UserVehicle>> getVehicles(String userId) async {
    try {
      final raw = await _storage.read(key: _storageKey(userId));
      if (raw != null && raw.isNotEmpty) {
        final List decoded = jsonDecode(raw);
        return decoded
            .map((item) => UserVehicle.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (e) {
      debugPrint('[UserVehiclesRepository] Error reading vehicles: $e');
    }
    return [];
  }

  /// Saves the complete list of vehicles for a user
  Future<void> saveVehicles(String userId, List<UserVehicle> vehicles) async {
    try {
      final encoded = jsonEncode(vehicles.map((v) => v.toJson()).toList());
      await _storage.write(key: _storageKey(userId), value: encoded);
    } catch (e) {
      debugPrint('[UserVehiclesRepository] Error saving vehicles: $e');
      rethrow;
    }
  }

  /// Adds or updates a vehicle
  Future<List<UserVehicle>> upsertVehicle(String userId, UserVehicle vehicle) async {
    final list = await getVehicles(userId);
    final index = list.indexWhere((v) => v.id == vehicle.id);

    List<UserVehicle> updatedList;
    if (index >= 0) {
      updatedList = List.from(list)..[index] = vehicle;
    } else {
      // If it's marked default or first vehicle, ensure other vehicles have isDefault = false
      updatedList = [...list, vehicle];
    }

    if (vehicle.isDefault || updatedList.length == 1) {
      updatedList = updatedList
          .map((v) => v.id == vehicle.id
              ? v.copyWith(isDefault: true)
              : v.copyWith(isDefault: false))
          .toList();
    }

    await saveVehicles(userId, updatedList);
    return updatedList;
  }

  /// Deletes a vehicle by ID
  Future<List<UserVehicle>> deleteVehicle(String userId, String vehicleId) async {
    final list = await getVehicles(userId);
    final updatedList = list.where((v) => v.id != vehicleId).toList();
    
    // If the default vehicle was deleted, promote the first remaining vehicle
    if (updatedList.isNotEmpty && !updatedList.any((v) => v.isDefault)) {
      updatedList[0] = updatedList[0].copyWith(isDefault: true);
    }

    await saveVehicles(userId, updatedList);
    return updatedList;
  }
}
