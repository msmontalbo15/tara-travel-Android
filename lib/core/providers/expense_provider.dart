import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';
import 'repository_providers.dart';

/// Scoped expense fetcher provider per trip.
final expenseProvider = FutureProvider.family<List<ExpenseModel>, String>((ref, tripId) async {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getExpenses(tripId);
});
