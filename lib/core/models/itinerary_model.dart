import 'package:flutter/material.dart';

enum StopType { hotel, activity, food, transport, custom }

extension StopTypeX on StopType {
  String get label {
    switch (this) {
      case StopType.hotel:
        return 'Hotel';
      case StopType.activity:
        return 'Activity';
      case StopType.food:
        return 'Food';
      case StopType.transport:
        return 'Transport';
      case StopType.custom:
        return 'Custom';
    }
  }

  IconData get icon {
    switch (this) {
      case StopType.hotel:
        return Icons.hotel_rounded;
      case StopType.activity:
        return Icons.explore_rounded;
      case StopType.food:
        return Icons.restaurant_rounded;
      case StopType.transport:
        return Icons.directions_car_rounded;
      case StopType.custom:
        return Icons.place_rounded;
    }
  }

  Color get color {
    switch (this) {
      case StopType.hotel:
        return const Color(0xFF3B82F6); // blue
      case StopType.activity:
        return const Color(0xFF10B981); // green
      case StopType.food:
        return const Color(0xFFEF9F27); // amber
      case StopType.transport:
        return const Color(0xFFD85A30); // coral
      case StopType.custom:
        return const Color(0xFF8B5CF6); // purple
    }
  }
}

enum TransportCategory { land, air, sea, eco }

enum TransportMode {
  car,
  motorcycle,
  commute,
  jeepney,
  tricycle,
  bus,
  vanHire,
  ferry,
  plane,
  bike,
  other,
}

extension TransportModeX on TransportMode {
  String get label {
    switch (this) {
      case TransportMode.car:
        return 'Private Vehicle';
      case TransportMode.motorcycle:
        return 'Motorcycle';
      case TransportMode.commute:
        return 'Public Commute';
      case TransportMode.jeepney:
        return 'Jeepney / E-Jeep';
      case TransportMode.tricycle:
        return 'Tricycle';
      case TransportMode.bus:
        return 'Bus';
      case TransportMode.vanHire:
        return 'Van Rental';
      case TransportMode.ferry:
        return 'Ferry / Fastcraft';
      case TransportMode.plane:
        return 'Flight / Plane';
      case TransportMode.bike:
        return 'Bicycle';
      case TransportMode.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case TransportMode.car:
        return '🚗';
      case TransportMode.motorcycle:
        return '🏍️';
      case TransportMode.commute:
        return '🚌';
      case TransportMode.jeepney:
        return '🚐';
      case TransportMode.tricycle:
        return '🛺';
      case TransportMode.bus:
        return '🚌';
      case TransportMode.vanHire:
        return '🚐';
      case TransportMode.ferry:
        return '⛴️';
      case TransportMode.plane:
        return '✈️';
      case TransportMode.bike:
        return '🚲';
      case TransportMode.other:
        return '🚘';
    }
  }

  TransportCategory get category {
    switch (this) {
      case TransportMode.plane:
        return TransportCategory.air;
      case TransportMode.ferry:
        return TransportCategory.sea;
      case TransportMode.bike:
        return TransportCategory.eco;
      case TransportMode.car:
      case TransportMode.motorcycle:
      case TransportMode.commute:
      case TransportMode.jeepney:
      case TransportMode.tricycle:
      case TransportMode.bus:
      case TransportMode.vanHire:
      case TransportMode.other:
        return TransportCategory.land;
    }
  }

  /// Average cruising speed in km/h for smart estimate calculations
  double get averageSpeedKmh {
    switch (this) {
      case TransportMode.plane:
        return 500.0;
      case TransportMode.ferry:
        return 35.0;
      case TransportMode.bike:
        return 18.0;
      case TransportMode.motorcycle:
        return 45.0;
      case TransportMode.car:
      case TransportMode.vanHire:
        return 55.0;
      case TransportMode.bus:
      case TransportMode.commute:
        return 40.0;
      case TransportMode.jeepney:
      case TransportMode.tricycle:
        return 25.0;
      case TransportMode.other:
        return 40.0;
    }
  }
}

class ItineraryStop {
  final String id;
  final String title;
  final String? notes;
  final StopType type;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final double? estimatedCost;
  /// Multi-member assignment — primary storage.
  final List<String> assignedMemberIds;
  final String? location;
  final double? lat;
  final double? lng;
  final String? confirmationNumber;
  final TransportMode? transportMode;
  // Photo gallery
  final List<String> photoUrls;
  // Booking attachments
  final List<String> attachmentUrls;
  /// Per-member arrival map: { userId → arrival DateTime }.
  /// Replaces the old flat `checkedInMemberIds` list.
  final Map<String, DateTime> checkedInMembers;
  final DateTime? visitedAt;
  final List<String> checkInPhotoUrls;

  ItineraryStop({
    required this.id,
    required this.title,
    this.notes,
    required this.type,
    this.startTime,
    this.endTime,
    this.estimatedCost,
    /// Accepts either [assignedMemberIds] (multi) or legacy [assignedMemberId] (single).
    List<String>? assignedMemberIds,
    @Deprecated('Use assignedMemberIds') String? assignedMemberId,
    this.location,
    this.lat,
    this.lng,
    this.confirmationNumber,
    this.transportMode,
    this.photoUrls = const [],
    this.attachmentUrls = const [],
    this.checkedInMembers = const {},
    this.visitedAt,
    this.checkInPhotoUrls = const [],
    // Legacy compat: accept flat list and convert to map with DateTime.now()
    @Deprecated('Use checkedInMembers') List<String>? checkedInMemberIds,
  }) : assignedMemberIds = assignedMemberIds ??
           (assignedMemberId != null && assignedMemberId.isNotEmpty
               ? [assignedMemberId]
               : const []);

  /// Legacy compat: first assigned member (or null if unassigned).
  String? get assignedMemberId =>
      assignedMemberIds.isNotEmpty ? assignedMemberIds.first : null;

  bool get isAssigned => assignedMemberIds.isNotEmpty;

  /// Flat list of checked-in member IDs (backward compat for UI code).
  List<String> get checkedInMemberIds => checkedInMembers.keys.toList();

  /// Whether this stop is fully fulfilled (at least one member arrived or timestamp logged).
  bool get isCompleted => visitedAt != null || checkedInMembers.isNotEmpty;

  /// Whether this stop has any member currently checked in.
  bool get hasArrived => checkedInMembers.isNotEmpty;

  /// Formatted arrival timestamp (e.g. "Arrived 3:42 PM").
  String? get arrivedAtLabel {
    if (visitedAt == null) return null;
    final h = visitedAt!.hour;
    final m = visitedAt!.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final displayHour = h % 12 == 0 ? 12 : h % 12;
    return 'Arrived $displayHour:$m $period';
  }

  /// Formatted arrival time for a specific member.
  String? memberArrivedAtLabel(String memberId) {
    final ts = checkedInMembers[memberId];
    if (ts == null) return null;
    final local = ts.toLocal();
    final h = local.hour;
    final m = local.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final displayHour = h % 12 == 0 ? 12 : h % 12;
    return '$displayHour:$m $period';
  }

  String get duration {
    if (startTime == null || endTime == null) return '';
    final startMinutes = startTime!.hour * 60 + startTime!.minute;
    final endMinutes = endTime!.hour * 60 + endTime!.minute;
    final diff = endMinutes - startMinutes;
    if (diff <= 0) return '';
    final h = diff ~/ 60;
    final m = diff % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }



  ItineraryStop copyWith({
    String? id,
    String? title,
    String? notes,
    StopType? type,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    double? estimatedCost,
    List<String>? assignedMemberIds,
    String? location,
    double? lat,
    double? lng,
    String? confirmationNumber,
    TransportMode? transportMode,
    List<String>? photoUrls,
    List<String>? attachmentUrls,
    Map<String, DateTime>? checkedInMembers,
    DateTime? visitedAt,
    List<String>? checkInPhotoUrls,
    /// Set to true to explicitly clear [visitedAt] to null.
    bool clearVisitedAt = false,
  }) {
    return ItineraryStop(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      assignedMemberIds: assignedMemberIds ?? this.assignedMemberIds,
      location: location ?? this.location,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      confirmationNumber: confirmationNumber ?? this.confirmationNumber,
      transportMode: transportMode ?? this.transportMode,
      photoUrls: photoUrls ?? this.photoUrls,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      checkedInMembers: checkedInMembers ?? this.checkedInMembers,
      visitedAt: clearVisitedAt ? null : (visitedAt ?? this.visitedAt),
      checkInPhotoUrls: checkInPhotoUrls ?? this.checkInPhotoUrls,
    );
  }
}

class TransportDetail {
  final TransportMode mode;
  final int? vehicleCount;
  final String? departurePoint;
  final double? departureLat;
  final double? departureLng;
  final String? flightNumber;
  final String? pierName;
  final String? operatorName;
  final String? bookingReference;
  final String estimatedDuration;
  final double? gasCostShare;
  final double? estimatedCost;
  final bool splitGas;
  final String? notes;

  // ── Plan 6 Tri-Modal Land Transport Extensions ─────────────────────────
  final String? tripTransportMode; // 'private' | 'commute' | 'rental'
  // Mode A: Private specs
  final String? vehicleId;
  final String? vehicleName;
  final String? vehicleType;
  final String? fuelType;
  final double? kmPerLiter;
  final bool splitTolls;
  final double? estimatedTollCost;
  // Mode B: Commute specs
  final String? commuteType; // 'bus' | 'jeepney' | 'tricycle' | 'uv_express'
  final String? transitHubName;
  final double? farePerPax;
  final String? dropOffPoint;
  // Mode C: Rental specs
  final String? rentalType; // 'van_hire' | 'car_rental' | 'coaster'
  final double? dailyRate;
  final int? rentalDays;
  final bool hasDriver;
  final double? driverFeePerDay;
  final bool fuelIncluded;
  final bool tollsIncluded;
  final double? totalRentalCost;

  const TransportDetail({
    required this.mode,
    this.vehicleCount,
    this.departurePoint,
    this.departureLat,
    this.departureLng,
    this.flightNumber,
    this.pierName,
    this.operatorName,
    this.bookingReference,
    this.estimatedDuration = '',
    this.gasCostShare,
    this.estimatedCost,
    this.splitGas = false,
    this.notes,
    this.tripTransportMode,
    this.vehicleId,
    this.vehicleName,
    this.vehicleType,
    this.fuelType,
    this.kmPerLiter,
    this.splitTolls = false,
    this.estimatedTollCost,
    this.commuteType,
    this.transitHubName,
    this.farePerPax,
    this.dropOffPoint,
    this.rentalType,
    this.dailyRate,
    this.rentalDays,
    this.hasDriver = true,
    this.driverFeePerDay,
    this.fuelIncluded = false,
    this.tollsIncluded = false,
    this.totalRentalCost,
  });

  Map<String, dynamic> toMap() {
    return {
      'mode': tripTransportMode ?? mode.name,
      'legacy_mode': mode.name,
      if (vehicleCount != null) 'vehicle_count': vehicleCount,
      if (departurePoint != null) 'departure_point': departurePoint,
      if (departureLat != null) 'departure_lat': departureLat,
      if (departureLng != null) 'departure_lng': departureLng,
      if (operatorName != null) 'operator_name': operatorName,
      if (bookingReference != null) 'booking_reference': bookingReference,
      'estimated_duration': estimatedDuration,
      if (gasCostShare != null) 'gas_cost_share': gasCostShare,
      if (estimatedCost != null) 'estimated_cost': estimatedCost,
      'split_gas': splitGas,
      if (notes != null) 'notes': notes,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (vehicleName != null) 'vehicle_name': vehicleName,
      if (vehicleType != null) 'vehicle_type': vehicleType,
      if (fuelType != null) 'fuel_type': fuelType,
      if (kmPerLiter != null) 'kml': kmPerLiter,
      'split_tolls': splitTolls,
      if (estimatedTollCost != null) 'estimated_toll_cost': estimatedTollCost,
      if (commuteType != null) 'commute_type': commuteType,
      if (transitHubName != null) 'transit_hub_name': transitHubName,
      if (farePerPax != null) 'fare_per_pax': farePerPax,
      if (dropOffPoint != null) 'drop_off_point': dropOffPoint,
      if (rentalType != null) 'rental_type': rentalType,
      if (dailyRate != null) 'daily_rate': dailyRate,
      if (rentalDays != null) 'rental_days': rentalDays,
      'has_driver': hasDriver,
      if (driverFeePerDay != null) 'driver_fee_per_day': driverFeePerDay,
      'fuel_included': fuelIncluded,
      'tolls_included': tollsIncluded,
      if (totalRentalCost != null) 'total_rental_cost': totalRentalCost,
    };
  }

  factory TransportDetail.fromMap(Map<String, dynamic> map) {
    final modeStr = map['legacy_mode'] ?? map['mode'] ?? 'car';
    final parsedMode = TransportMode.values.firstWhere(
      (m) => m.name == modeStr,
      orElse: () => TransportMode.car,
    );

    return TransportDetail(
      mode: parsedMode,
      vehicleCount: (map['vehicle_count'] as num?)?.toInt(),
      departurePoint: map['departure_point'] as String?,
      departureLat: (map['departure_lat'] as num?)?.toDouble(),
      departureLng: (map['departure_lng'] as num?)?.toDouble(),
      flightNumber: map['flight_number'] as String?,
      pierName: map['pier_name'] as String?,
      operatorName: map['operator_name'] as String?,
      bookingReference: map['booking_reference'] as String?,
      estimatedDuration: map['estimated_duration'] as String? ?? '',
      gasCostShare: (map['gas_cost_share'] as num?)?.toDouble(),
      estimatedCost: (map['estimated_cost'] as num?)?.toDouble(),
      splitGas: map['split_gas'] as bool? ?? false,
      notes: map['notes'] as String?,
      tripTransportMode: map['mode'] as String?,
      vehicleId: map['vehicle_id'] as String?,
      vehicleName: map['vehicle_name'] as String?,
      vehicleType: map['vehicle_type'] as String?,
      fuelType: map['fuel_type'] as String?,
      kmPerLiter: (map['kml'] as num?)?.toDouble(),
      splitTolls: map['split_tolls'] as bool? ?? false,
      estimatedTollCost: (map['estimated_toll_cost'] as num?)?.toDouble(),
      commuteType: map['commute_type'] as String?,
      transitHubName: map['transit_hub_name'] as String?,
      farePerPax: (map['fare_per_pax'] as num?)?.toDouble(),
      dropOffPoint: map['drop_off_point'] as String?,
      rentalType: map['rental_type'] as String?,
      dailyRate: (map['daily_rate'] as num?)?.toDouble(),
      rentalDays: (map['rental_days'] as num?)?.toInt(),
      hasDriver: map['has_driver'] as bool? ?? true,
      driverFeePerDay: (map['driver_fee_per_day'] as num?)?.toDouble(),
      fuelIncluded: map['fuel_included'] as bool? ?? false,
      tollsIncluded: map['tolls_included'] as bool? ?? false,
      totalRentalCost: (map['total_rental_cost'] as num?)?.toDouble(),
    );
  }
}

class ItineraryDay {
  final int dayNumber;
  final DateTime date;
  TransportDetail? transport;
  List<ItineraryStop> stops;

  ItineraryDay({
    required this.dayNumber,
    required this.date,
    this.transport,
    this.stops = const [],
  });

  /// Feature 3 — total estimated cost for this day.
  double get totalDayCost =>
      stops.fold(0.0, (sum, s) => sum + (s.estimatedCost ?? 0.0));

  /// Stops that have been marked completed / arrived.
  int get completedStops => stops.where((s) => s.isCompleted).length;

  ItineraryDay copyWith({
    int? dayNumber,
    DateTime? date,
    TransportDetail? transport,
    List<ItineraryStop>? stops,
  }) {
    return ItineraryDay(
      dayNumber: dayNumber ?? this.dayNumber,
      date: date ?? this.date,
      transport: transport ?? this.transport,
      stops: stops ?? this.stops,
    );
  }

  String get routeSummary {
    if (transport == null) return '';
    final mode = transport!.mode;
    final from = transport!.departurePoint ?? '';
    final vehicles = transport!.vehicleCount != null ? '(${transport!.vehicleCount} vehicles)' : '';
    return '${mode.emoji} ${mode.label} $vehicles · $from · ${transport!.estimatedDuration}';
  }
}
