import 'package:flutter/material.dart';

enum StopType { hotel, activity, food, transport, custom }

enum StopStatus { pending, approved, rejected, arrived }

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

extension StopStatusX on StopStatus {
  String get label {
    switch (this) {
      case StopStatus.pending:
        return 'Pending';
      case StopStatus.approved:
        return 'Approved';
      case StopStatus.rejected:
        return 'Rejected';
      case StopStatus.arrived:
        return 'Arrived';
    }
  }

  Color get color {
    switch (this) {
      case StopStatus.pending:
        return const Color(0xFFEF9F27);
      case StopStatus.approved:
        return const Color(0xFF10B981);
      case StopStatus.rejected:
        return const Color(0xFFEF4444);
      case StopStatus.arrived:
        return const Color(0xFF3B82F6);
    }
  }
}

enum TransportMode {
  car,
  motorcycle,
  bus,
  plane,
  ferry,
  jeepney,
  vanHire,
  bike,
  other,
}

extension TransportModeX on TransportMode {
  String get label {
    switch (this) {
      case TransportMode.car:
        return 'Car';
      case TransportMode.motorcycle:
        return 'Motorcycle';
      case TransportMode.bus:
        return 'Bus';
      case TransportMode.plane:
        return 'Plane';
      case TransportMode.ferry:
        return 'Ferry';
      case TransportMode.jeepney:
        return 'Jeepney';
      case TransportMode.vanHire:
        return 'Van Hire';
      case TransportMode.bike:
        return 'Bike';
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
      case TransportMode.bus:
        return '🚌';
      case TransportMode.plane:
        return '✈️';
      case TransportMode.ferry:
        return '⛴️';
      case TransportMode.jeepney:
        return '🚐';
      case TransportMode.vanHire:
        return '🚐';
      case TransportMode.bike:
        return '🚲';
      case TransportMode.other:
        return '🛺';
    }
  }
}

class ItineraryStop {
  final String id;
  final String title;
  final String? notes;
  final StopType type;
  StopStatus status;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final double? estimatedCost;
  final String? assignedMemberId;
  final String? location;
  final double? lat;
  final double? lng;
  final String? confirmationNumber;
  final TransportMode? transportMode;

  ItineraryStop({
    required this.id,
    required this.title,
    this.notes,
    required this.type,
    this.status = StopStatus.pending,
    this.startTime,
    this.endTime,
    this.estimatedCost,
    this.assignedMemberId,
    this.location,
    this.lat,
    this.lng,
    this.confirmationNumber,
    this.transportMode,
  });

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
    StopStatus? status,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    double? estimatedCost,
    String? assignedMemberId,
    String? location,
    double? lat,
    double? lng,
    String? confirmationNumber,
    TransportMode? transportMode,
  }) {
    return ItineraryStop(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      assignedMemberId: assignedMemberId ?? this.assignedMemberId,
      location: location ?? this.location,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      confirmationNumber: confirmationNumber ?? this.confirmationNumber,
      transportMode: transportMode ?? this.transportMode,
    );
  }
}

class TransportDetail {
  final TransportMode mode;
  final int? vehicleCount;
  final String? departurePoint;
  final String? flightNumber;
  final String? pierName;
  final String estimatedDuration;
  final double? gasCostShare;
  final bool splitGas;

  const TransportDetail({
    required this.mode,
    this.vehicleCount,
    this.departurePoint,
    this.flightNumber,
    this.pierName,
    this.estimatedDuration = '',
    this.gasCostShare,
    this.splitGas = false,
  });
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
