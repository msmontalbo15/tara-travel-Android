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
  String currency;
  bool splitEqually;
  String splitMode; // 'equal', 'fixed', 'percentage', 'treat'
  List<BudgetCategory> budgetBreakdown;
  TransportDetail? transportDetail;
  String? departurePoint;
  double? departureLat;
  double? departureLng;
  String? departureMapUrl;

  NewTripModel({
    this.tripName = '',
    this.destination = '',
    this.destinationLat,
    this.destinationLng,
    this.fromDate,
    this.toDate,
    this.tripType = 'beach',
    List<TravelerModel>? travelers,
    this.totalBudget,
    this.currency = 'Philippine Peso (₱)',
    this.splitEqually = true,
    this.splitMode = 'equal',
    List<BudgetCategory>? budgetBreakdown,
    this.transportDetail,
    this.departurePoint,
    this.departureLat,
    this.departureLng,
    this.departureMapUrl,
  })  : travelers = travelers ?? [],
        budgetBreakdown = budgetBreakdown ??
            [
              BudgetCategory(name: 'Accommodation', amount: 0, color: 0xFFD85A30, icon: '🏨'),
              BudgetCategory(name: 'Food & Dining', amount: 0, color: 0xFFF59E0B, icon: '🍽️'),
              BudgetCategory(name: 'Activities & Tours', amount: 0, color: 0xFF10B981, icon: '🏝️'),
              BudgetCategory(name: 'Transportation', amount: 0, color: 0xFF3B82F6, icon: '🚐'),
            ];
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

