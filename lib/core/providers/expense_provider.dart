import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';
import 'repository_providers.dart';

/// Scoped expense fetcher provider per trip.
final expenseProvider = FutureProvider.family<List<ExpenseModel>, String>((ref, tripId) async {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getExpenses(tripId);
});

class ExpenseSummary {
  final double totalSpent;
  final double totalPending;

  const ExpenseSummary({
    this.totalSpent = 0.0,
    this.totalPending = 0.0,
  });
}

/// Memoized provider computing total spent and pending expenses per trip.
final expenseSummaryProvider = Provider.autoDispose.family<ExpenseSummary, String>((ref, tripId) {
  final expenses = ref.watch(expenseProvider(tripId)).asData?.value ?? const <ExpenseModel>[];
  final spent = expenses
      .where((e) => e.status == ExpenseStatus.approved)
      .fold<double>(0.0, (s, e) => s + e.amount);
  final pending = expenses
      .where((e) => e.status == ExpenseStatus.pending)
      .fold<double>(0.0, (s, e) => s + e.amount);

  return ExpenseSummary(
    totalSpent: spent,
    totalPending: pending,
  );
});

