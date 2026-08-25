import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense_model.dart';

/// Pure Supabase data source for trip expenses.
/// All operations hit the Supabase `expenses` table directly.
/// RLS policies enforce row-level isolation per trip member.
class ExpenseRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ────────────────────────────────────────────────────────────────
  // READ
  // ────────────────────────────────────────────────────────────────

  /// Fetches all expenses for a trip, ordered newest first.
  Future<List<ExpenseModel>> getExpenses(String tripId) async {
    try {
      final response = await _supabase
          .from('expenses')
          .select()
          .eq('trip_id', tripId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ExpenseModel.fromMap((json as Map).cast<String, dynamic>()))
          .toList();
    } on PostgrestException catch (e) {
      debugPrint('[ExpenseRepository] getExpenses PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ExpenseRepository] getExpenses error: $e');
      rethrow;
    }
  }

  // ────────────────────────────────────────────────────────────────
  // WRITE
  // ────────────────────────────────────────────────────────────────

  /// Adds a new expense to Supabase.
  Future<void> addExpense(String tripId, ExpenseModel expense) async {
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
    } on PostgrestException catch (e) {
      debugPrint('[ExpenseRepository] addExpense PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ExpenseRepository] addExpense error: $e');
      rethrow;
    }
  }

  /// Updates expense status (approve / reject).
  /// Organizer or Treasurer roles only — enforced via RLS + UI guard.
  Future<void> updateStatus(
    String expenseId,
    ExpenseStatus status, {
    String? note,
  }) async {
    try {
      await _supabase.from('expenses').update({
        'status': status.name,
        'rejection_note': note,
        'approved_by': _supabase.auth.currentUser?.id,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', expenseId);
    } on PostgrestException catch (e) {
      debugPrint('[ExpenseRepository] updateStatus PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ExpenseRepository] updateStatus error: $e');
      rethrow;
    }
  }

  /// Deletes an expense permanently from Supabase.
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _supabase.from('expenses').delete().eq('id', expenseId);
    } on PostgrestException catch (e) {
      debugPrint('[ExpenseRepository] deleteExpense PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ExpenseRepository] deleteExpense error: $e');
      rethrow;
    }
  }
}
