import '../../../core/models/itinerary_model.dart';

class NewTripModel {
  String tripName;
  String destination;
  double? destinationLat;
  double? destinationLng;
  DateTime? fromDate;
  DateTime? toDate;
  String tripType;
  List<TravelerModel> travelers;
  double? totalBudget;
  double? personalAllowance;
  String currency;
  bool splitEqually;
  String splitMode; // 'equal', 'fixed', 'percentage', 'treat'
  List<BudgetCategory> budgetBreakdown;
  TransportDetail? transportDetail;
  String? departurePoint;
  double? departureLat;
  double? departureLng;
  String? departureMapUrl;
  bool isMapEnabled;
  String journeyMode; // 'standard', 'adventure', 'multi_point'
  List<String> destinationHubs;

  NewTripModel({
    this.tripName = '',
    this.destination = '',
    this.destinationLat,
    this.destinationLng,
    this.fromDate,
    this.toDate,
    this.tripType = 'rides_meets',
    List<TravelerModel>? travelers,
    this.totalBudget,
    this.personalAllowance,
    this.currency = 'Philippine Peso (₱)',
    this.splitEqually = true,
    this.splitMode = 'equal',
    List<BudgetCategory>? budgetBreakdown,
    this.transportDetail,
    this.departurePoint,
    this.departureLat,
    this.departureLng,
    this.departureMapUrl,
    this.isMapEnabled = true,
    this.journeyMode = 'standard',
    List<String>? destinationHubs,
  })  : travelers = travelers ?? [],
        destinationHubs = destinationHubs ?? [],
        budgetBreakdown = budgetBreakdown ??
            [
              BudgetCategory(name: 'Accommodation', amount: 0, color: 0xFFD85A30, icon: '🏨'),
              BudgetCategory(name: 'Food & Dining', amount: 0, color: 0xFFF59E0B, icon: '🍽️'),
              BudgetCategory(name: 'Activities & Tours', amount: 0, color: 0xFF10B981, icon: '🏝️'),
              BudgetCategory(name: 'Transportation', amount: 0, color: 0xFF3B82F6, icon: '🚐'),
            ];

  Map<String, dynamic> buildDestinationDetails() {
    return {
      'is_map_enabled': isMapEnabled,
      'journey_mode': journeyMode,
      if (destinationHubs.isNotEmpty) 'hubs': destinationHubs,
    };
  }
}

class TravelerModel {
  final String id;
  final String name;
  final String initials;
  final int color;
  final String? profilePhotoUrl;

  TravelerModel({
    this.id = '',
    required this.name,
    required this.initials,
    required this.color,
    this.profilePhotoUrl,
  });
}

class BudgetCategory {
  final String name;
  double amount;
  final int color;
  final String icon;

  BudgetCategory({
    required this.name,
    required this.amount,
    required this.color,
    this.icon = '📦',
  });
}

