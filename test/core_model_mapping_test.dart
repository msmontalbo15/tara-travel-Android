import 'package:flutter_test/flutter_test.dart';
import 'package:tara_travel/core/models/expense_model.dart';
import 'package:tara_travel/core/models/trip_model.dart';

void main() {
  test('TripModel parses Supabase trip schema keys', () {
    final trip = TripModel.fromMap({
      'id': 'trip-1',
      'name': 'Weekend Trip',
      'destination': 'Baguio',
      'start_date': '2026-04-15',
      'end_date': '2026-04-17',
      'type': 'city',
      'budget': 12000,
      'trip_members': const [],
      'expenses': const [],
      'status': 'planned',
    });

    expect(trip.id, 'trip-1');
    expect(trip.tripType, 'city');
    expect(trip.totalBudget, 12000);
    expect(trip.fromDate.year, 2026);
    expect(trip.isArchived, false);
  });

  test('ExpenseModel parses Supabase expense schema keys', () {
    final expense = ExpenseModel.fromMap({
      'id': 'exp-1',
      'description': 'Lunch',
      'amount': 500,
      'category': 'food',
      'paid_by_user_id': 'user-1',
      'created_at': '2026-04-15T10:00:00.000Z',
      'status': 'approved',
    });

    expect(expense.id, 'exp-1');
    expect(expense.paidById, 'user-1');
    expect(expense.category, ExpenseCategory.food);
    expect(expense.status, ExpenseStatus.approved);
  });

  test('TripModel and ExpenseModel parse string amounts and budgets safely', () {
    final trip = TripModel.fromMap({
      'id': 'c5983da2-40e4-4d9f-9d5a-977392495b55',
      'name': 'Baguio',
      'destination': 'Benguet',
      'start_date': '2026-07-11',
      'end_date': '2026-07-12',
      'budget': '5000.00',
      'type': 'adventure',
      'status': 'planned',
    });

    expect(trip.totalBudget, 5000.0);
    expect(trip.name, 'Baguio');

    final expense = ExpenseModel.fromMap({
      'id': 'exp-2',
      'description': 'Taxi',
      'amount': '150.50',
      'category': 'transport',
      'paid_by_user_id': 'user-2',
      'created_at': '2026-07-11T12:00:00Z',
      'status': 'pending',
    });

    expect(expense.amount, 150.5);
  });
}
