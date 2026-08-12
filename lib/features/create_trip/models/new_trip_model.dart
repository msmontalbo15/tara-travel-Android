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
  List<BudgetCategory> budgetBreakdown;
  TransportDetail? transportDetail;
  int? coverColor;
  String? departurePoint;
  String? departureMapUrl;

  NewTripModel({
    this.tripName = '',
    this.destination = '',
    this.destinationLat,
    this.destinationLng,
    this.fromDate,
    this.toDate,
    this.tripType = 'Beach',
    List<TravelerModel>? travelers,
    this.totalBudget,
    this.currency = 'Philippine Peso (₱)',
    this.splitEqually = true,
    List<BudgetCategory>? budgetBreakdown,
    this.transportDetail,
    this.coverColor,
    this.departurePoint,
    this.departureMapUrl,
  })  : travelers = travelers ??
            [],
        budgetBreakdown = budgetBreakdown ??
            [
              BudgetCategory(name: 'Accommodation', amount: 0, color: 0xFFD85A30),
              BudgetCategory(name: 'Food', amount: 0, color: 0xFFF59E0B),
              BudgetCategory(name: 'Activities', amount: 0, color: 0xFF10B981),
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
  BudgetCategory({required this.name, required this.amount, required this.color});
}

