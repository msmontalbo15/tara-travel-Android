import 'package:flutter/material.dart';

enum VehicleType {
  sedan,
  suv,
  auv,
  van,
  motorcycle,
  bicycle,
  other;

  String get label {
    switch (this) {
      case VehicleType.sedan:
        return 'Sedan / Hatchback';
      case VehicleType.suv:
        return 'SUV / Crossover';
      case VehicleType.auv:
        return 'AUV / MPV';
      case VehicleType.van:
        return 'Van';
      case VehicleType.motorcycle:
        return 'Motorcycle / Scooter';
      case VehicleType.bicycle:
        return 'Bicycle / E-Bike';
      case VehicleType.other:
        return 'Other Vehicle';
    }
  }

  String get emoji {
    switch (this) {
      case VehicleType.sedan:
        return '🚗';
      case VehicleType.suv:
        return '🚙';
      case VehicleType.auv:
        return '🚐';
      case VehicleType.van:
        return '🚐';
      case VehicleType.motorcycle:
        return '🏍️';
      case VehicleType.bicycle:
        return '🚲';
      case VehicleType.other:
        return '🚘';
    }
  }

  IconData get icon {
    switch (this) {
      case VehicleType.sedan:
        return Icons.directions_car_rounded;
      case VehicleType.suv:
        return Icons.directions_car_filled_rounded;
      case VehicleType.auv:
      case VehicleType.van:
        return Icons.airport_shuttle_rounded;
      case VehicleType.motorcycle:
        return Icons.two_wheeler_rounded;
      case VehicleType.bicycle:
        return Icons.pedal_bike_rounded;
      case VehicleType.other:
        return Icons.drive_eta_rounded;
    }
  }

  /// Sensible Philippine highway/city average km/L estimate
  double get defaultKmPerLiter {
    switch (this) {
      case VehicleType.sedan:
        return 14.0;
      case VehicleType.suv:
        return 10.5;
      case VehicleType.auv:
        return 12.0;
      case VehicleType.van:
        return 9.5;
      case VehicleType.motorcycle:
        return 38.0;
      case VehicleType.bicycle:
        return 0.0;
      case VehicleType.other:
        return 11.0;
    }
  }
}

enum FuelType {
  gasoline,
  diesel,
  electric;

  String get label {
    switch (this) {
      case FuelType.gasoline:
        return 'Gasoline';
      case FuelType.diesel:
        return 'Diesel';
      case FuelType.electric:
        return 'Electric (EV)';
    }
  }

  String get emoji {
    switch (this) {
      case FuelType.gasoline:
        return '⛽';
      case FuelType.diesel:
        return '🛢️';
      case FuelType.electric:
        return '⚡';
    }
  }
}

class UserVehicle {
  final String id;
  final String userId;
  final String name;
  final VehicleType type;
  final FuelType fuelType;
  final double kmPerLiter;
  final String? plateNumber;
  final bool isDefault;
  final DateTime createdAt;

  const UserVehicle({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.fuelType = FuelType.gasoline,
    required this.kmPerLiter,
    this.plateNumber,
    this.isDefault = false,
    required this.createdAt,
  });

  UserVehicle copyWith({
    String? id,
    String? userId,
    String? name,
    VehicleType? type,
    FuelType? fuelType,
    double? kmPerLiter,
    String? plateNumber,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return UserVehicle(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      fuelType: fuelType ?? this.fuelType,
      kmPerLiter: kmPerLiter ?? this.kmPerLiter,
      plateNumber: plateNumber ?? this.plateNumber,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'type': type.name,
      'fuelType': fuelType.name,
      'kmPerLiter': kmPerLiter,
      'plateNumber': plateNumber,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserVehicle.fromJson(Map<String, dynamic> json) {
    return UserVehicle(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? 'My Vehicle',
      type: VehicleType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => VehicleType.sedan,
      ),
      fuelType: FuelType.values.firstWhere(
        (e) => e.name == json['fuelType'],
        orElse: () => FuelType.gasoline,
      ),
      kmPerLiter: (json['kmPerLiter'] as num?)?.toDouble() ?? 12.0,
      plateNumber: json['plateNumber'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
