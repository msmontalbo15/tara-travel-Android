import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/expense_model.dart';
import '../models/personal_allowance_model.dart';
import 'repository_providers.dart';
import 'trip_provider.dart';

/// Fetches the current user's personal allowance configuration and solo expenses for a trip.
final personalAllowanceProvider =
    FutureProvider.family<PersonalAllowanceModel?, String>((ref, tripId) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;

  final repo = ref.watch(personalAllowanceRepositoryProvider);
  return repo.getPersonalAllowance(tripId, userId);
});

/// Computes the current authenticated user's estimated group liability for the active trip.
final myGroupLiabilityProvider = Provider.family<double, String>((ref, tripId) {
  final tripAsync = ref.watch(activeTripProvider);
  return tripAsync.when(
    data: (trip) {
      if (trip == null || trip.members.isEmpty) return 0.0;
      final approvedTotal = trip.expenses
          .where((e) => e.status == ExpenseStatus.approved)
          .fold(0.0, (acc, e) => acc + e.amount);
      return approvedTotal / trip.members.length;
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

/// Controller to mutate personal allowance state and invalidate providers.
class PersonalAllowanceController {
  final Ref _ref;

  PersonalAllowanceController(this._ref);

  Future<void> setAllowance({
    required String tripId,
    required double totalAllowance,
    double emergencyBufferPercent = 0.10,
    double cashOnHand = 0.0,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final repo = _ref.read(personalAllowanceRepositoryProvider);
    final current = await _ref.read(personalAllowanceProvider(tripId).future);

    final updated = PersonalAllowanceModel(
      id: current?.id,
      tripId: tripId,
      userId: userId,
      totalAllowance: totalAllowance,
      emergencyBufferPercent: emergencyBufferPercent,
      cashOnHand: cashOnHand,
      expenses: current?.expenses ?? const [],
    );

    await repo.savePersonalAllowance(updated);
    _ref.invalidate(personalAllowanceProvider(tripId));
  }

  Future<void> addPersonalExpense({
    required String tripId,
    required String description,
    required double amount,
    required ExpenseCategory category,
    PaymentMode paymentMode = PaymentMode.cash,
    DateTime? date,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final repo = _ref.read(personalAllowanceRepositoryProvider);
    final item = PersonalExpenseItem(
      id: const Uuid().v4(),
      tripId: tripId,
      userId: userId,
      description: description,
      amount: amount,
      category: category,
      paymentMode: paymentMode,
      date: date ?? DateTime.now(),
      createdAt: DateTime.now(),
    );

    await repo.addPersonalExpense(item);
    _ref.invalidate(personalAllowanceProvider(tripId));
  }

  Future<void> deletePersonalExpense({
    required String tripId,
    required String expenseId,
  }) async {
    final repo = _ref.read(personalAllowanceRepositoryProvider);
    await repo.deletePersonalExpense(expenseId);
    _ref.invalidate(personalAllowanceProvider(tripId));
  }

  Future<void> updateCashOnHand({
    required String tripId,
    required double newCashOnHand,
  }) async {
    final current = await _ref.read(personalAllowanceProvider(tripId).future);
    if (current == null) return;

    final updated = current.copyWith(cashOnHand: newCashOnHand);
    final repo = _ref.read(personalAllowanceRepositoryProvider);
    await repo.savePersonalAllowance(updated);
    _ref.invalidate(personalAllowanceProvider(tripId));
  }
}

final personalAllowanceControllerProvider =
    Provider<PersonalAllowanceController>((ref) {
  return PersonalAllowanceController(ref);
});
