import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/personal_allowance_model.dart';

/// Supabase repository for managing private personal allowances and personal expenses.
/// Enforces RLS isolation where auth.uid() == user_id.
class PersonalAllowanceRepository {
  final SupabaseClient _supabase;

  PersonalAllowanceRepository({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  /// Fetches the user's personal allowance configuration and associated personal expenses.
  Future<PersonalAllowanceModel?> getPersonalAllowance(
    String tripId,
    String userId,
  ) async {
    try {
      // 1. Fetch allowance settings
      final allowanceResponse = await _supabase
          .from('trip_personal_allowances')
          .select()
          .eq('trip_id', tripId)
          .eq('user_id', userId)
          .maybeSingle();

      // 2. Fetch personal expenses
      final expensesResponse = await _supabase
          .from('personal_expenses')
          .select()
          .eq('trip_id', tripId)
          .eq('user_id', userId)
          .order('date', ascending: false);

      final expenses = (expensesResponse as List)
          .map((e) => PersonalExpenseItem.fromMap((e as Map).cast<String, dynamic>()))
          .toList();

      if (allowanceResponse == null) {
        return null;
      }

      return PersonalAllowanceModel.fromMap(
        (allowanceResponse as Map).cast<String, dynamic>(),
        expenses: expenses,
      );
    } on PostgrestException catch (e) {
      debugPrint('[PersonalAllowanceRepository] getPersonalAllowance PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[PersonalAllowanceRepository] getPersonalAllowance error: $e');
      rethrow;
    }
  }

  /// Upserts personal allowance settings (total allowance, emergency buffer, cash on hand).
  Future<void> savePersonalAllowance(PersonalAllowanceModel allowance) async {
    try {
      await _supabase.from('trip_personal_allowances').upsert(
        {
          'trip_id': allowance.tripId,
          'user_id': allowance.userId,
          'total_allowance': allowance.totalAllowance,
          'emergency_buffer_percent': allowance.emergencyBufferPercent,
          'cash_on_hand': allowance.cashOnHand,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'trip_id,user_id',
      );
    } on PostgrestException catch (e) {
      debugPrint('[PersonalAllowanceRepository] savePersonalAllowance PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[PersonalAllowanceRepository] savePersonalAllowance error: $e');
      rethrow;
    }
  }

  /// Adds a new private personal expense.
  Future<void> addPersonalExpense(PersonalExpenseItem expense) async {
    try {
      await _supabase.from('personal_expenses').insert({
        'id': expense.id,
        'trip_id': expense.tripId,
        'user_id': expense.userId,
        'description': expense.description,
        'amount': expense.amount,
        'category': expense.category.name,
        'payment_mode': expense.paymentMode.name,
        'date': expense.date.toIso8601String(),
        'created_at': expense.createdAt.toIso8601String(),
      });
    } on PostgrestException catch (e) {
      debugPrint('[PersonalAllowanceRepository] addPersonalExpense PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[PersonalAllowanceRepository] addPersonalExpense error: $e');
      rethrow;
    }
  }

  /// Deletes a personal expense.
  Future<void> deletePersonalExpense(String expenseId) async {
    try {
      await _supabase
          .from('personal_expenses')
          .delete()
          .eq('id', expenseId);
    } on PostgrestException catch (e) {
      debugPrint('[PersonalAllowanceRepository] deletePersonalExpense PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[PersonalAllowanceRepository] deletePersonalExpense error: $e');
      rethrow;
    }
  }
}
