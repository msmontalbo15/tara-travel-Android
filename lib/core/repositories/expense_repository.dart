import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense_model.dart';
import '../services/database_service.dart';
import 'package:sembast/sembast.dart';

class ExpenseRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DatabaseService _db = DatabaseService.instance;

  StoreRef<String, Map<String, dynamic>> get _expenseStore =>
      _db.getStore(DatabaseService.expenseStore);

  // ────────────────────────────────────────────────────────────────
  // READ
  // ────────────────────────────────────────────────────────────────

  /// Fetches expenses for a trip — Supabase first, local cache fallback.
  Future<List<ExpenseModel>> getExpenses(String tripId) async {
    final db = await _db.database;

    try {
      final response = await _supabase
          .from('expenses')
          .select()
          .eq('trip_id', tripId)
          .order('created_at', ascending: false);

      final expenses = (response as List)
          .map((json) =>
              ExpenseModel.fromMap((json as Map).cast<String, dynamic>()))
          .toList();

      // Cache locally
      await db.transaction((txn) async {
        for (final expense in expenses) {
          await _expenseStore.record(expense.id).put(txn, {
            ...expense.toMap(),
            'trip_id': tripId,
          });
        }
      });

      return expenses;
    } catch (e) {
      debugPrint('[ExpenseRepository] getExpenses error: $e');
      final snapshots = await _expenseStore.find(
        db,
        finder: Finder(filter: Filter.equals('trip_id', tripId)),
      );
      return snapshots.map((s) => ExpenseModel.fromMap(s.value)).toList();
    }
  }

  // ────────────────────────────────────────────────────────────────
  // WRITE
  // ────────────────────────────────────────────────────────────────

  /// Adds a new expense — optimistic local write + Supabase sync.
  Future<void> addExpense(String tripId, ExpenseModel expense) async {
    final db = await _db.database;

    // Optimistic local write
    await _expenseStore.record(expense.id).put(db, {
      ...expense.toMap(),
      'trip_id': tripId,
    });

    try {
      await _supabase.from('expenses').insert({
        'id': expense.id,
        'trip_id': tripId,
        'description': expense.description,
        'amount': expense.amount,
        'category': expense.category.name,
        'paid_by_user_id': expense.paidById,
        'status': expense.status.name,
        'created_at': expense.date.toIso8601String(),
        'receipt_url': expense.receiptPhotoUrl,
      });
    } catch (e) {
      debugPrint('[ExpenseRepository] addExpense sync error: $e');
    }
  }

  /// Updates expense status (approve / reject).
  Future<void> updateStatus(
    String expenseId,
    ExpenseStatus status, {
    String? note,
  }) async {
    final db = await _db.database;

    await _expenseStore.record(expenseId).update(db, {
      'status': status.name,
      'rejection_note': note,
    });

    try {
      await _supabase.from('expenses').update({
        'status': status.name,
        'rejection_note': note,
        'approved_by': _supabase.auth.currentUser?.id,
      }).eq('id', expenseId);
    } catch (e) {
      debugPrint('[ExpenseRepository] updateStatus sync error: $e');
    }
  }

  /// Deletes an expense (local + Supabase).
  Future<void> deleteExpense(String expenseId) async {
    final db = await _db.database;
    await _expenseStore.record(expenseId).delete(db);

    try {
      await _supabase.from('expenses').delete().eq('id', expenseId);
    } catch (e) {
      debugPrint('[ExpenseRepository] deleteExpense sync error: $e');
    }
  }
}
