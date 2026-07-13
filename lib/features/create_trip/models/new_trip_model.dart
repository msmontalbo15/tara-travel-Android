import '../../../core/models/itinerary_model.dart';

class NewTripModel {
  String tripName;
  String destination;
  DateTime? fromDate;
  DateTime? toDate;
  String tripType;
  List<TravelerModel> travelers;
  double? totalBudget;
  String currency;
  bool splitEqually;
  List<BudgetCategory> budgetBreakdown;
  TransportDetail? transportDetail;

  NewTripModel({
    this.tripName = '',
    this.destination = '',
    this.fromDate,
    this.toDate,
    this.tripType = 'Beach',
    List<TravelerModel>? travelers,
    this.totalBudget,
    this.currency = 'Philippine Peso (₱)',
    this.splitEqually = true,
    List<BudgetCategory>? budgetBreakdown,
    this.transportDetail,
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
  final String name;
  final String initials;
  final int color;
  TravelerModel({required this.name, required this.initials, required this.color});
}

class BudgetCategory {
  final String name;
  double amount;
  final int color;
  BudgetCategory({required this.name, required this.amount, required this.color});
}

