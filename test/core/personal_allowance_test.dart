import 'package:flutter_test/flutter_test.dart';
import 'package:tara_travel/core/models/expense_model.dart';
import 'package:tara_travel/core/models/personal_allowance_model.dart';

void main() {
  group('PersonalAllowanceModel Tests', () {
    test('Calculates contingency buffer and operational budget correctly', () {
      const allowance = PersonalAllowanceModel(
        tripId: 'trip-123',
        userId: 'user-456',
        totalAllowance: 10000.0,
        emergencyBufferPercent: 0.10, // 10%
        cashOnHand: 3000.0,
      );

      expect(allowance.contingencyAmount, 1000.0);
      expect(allowance.operationalBudget, 9000.0);
      expect(allowance.totalPersonalSpent, 0.0);
      expect(allowance.remainingCashOnHand, 3000.0);
    });

    test('Accurately segregates cash vs digital spending and remaining cash', () {
      final expenses = [
        PersonalExpenseItem(
          id: 'exp-1',
          tripId: 'trip-123',
          userId: 'user-456',
          description: 'Jeepney fare',
          amount: 50.0,
          category: ExpenseCategory.transport,
          paymentMode: PaymentMode.cash,
          date: DateTime.now(),
          createdAt: DateTime.now(),
        ),
        PersonalExpenseItem(
          id: 'exp-2',
          tripId: 'trip-123',
          userId: 'user-456',
          description: 'Souvenir shirts',
          amount: 1200.0,
          category: ExpenseCategory.custom,
          paymentMode: PaymentMode.digital,
          date: DateTime.now(),
          createdAt: DateTime.now(),
        ),
        PersonalExpenseItem(
          id: 'exp-3',
          tripId: 'trip-123',
          userId: 'user-456',
          description: 'Street food',
          amount: 250.0,
          category: ExpenseCategory.food,
          paymentMode: PaymentMode.cash,
          date: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      ];

      final allowance = PersonalAllowanceModel(
        tripId: 'trip-123',
        userId: 'user-456',
        totalAllowance: 10000.0,
        emergencyBufferPercent: 0.10,
        cashOnHand: 2000.0,
        expenses: expenses,
      );

      expect(allowance.totalPersonalSpent, 1500.0);
      expect(allowance.cashSpent, 300.0);
      expect(allowance.digitalSpent, 1200.0);
      expect(allowance.remainingCashOnHand, 1700.0);
    });

    test('Computes daily safe spend taking into account group liabilities', () {
      final expenses = [
        PersonalExpenseItem(
          id: 'exp-1',
          tripId: 'trip-123',
          userId: 'user-456',
          description: 'Snacks',
          amount: 500.0,
          category: ExpenseCategory.food,
          paymentMode: PaymentMode.cash,
          date: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      ];

      final allowance = PersonalAllowanceModel(
        tripId: 'trip-123',
        userId: 'user-456',
        totalAllowance: 10000.0, // Operational: 9000
        emergencyBufferPercent: 0.10,
        expenses: expenses, // Personal spent: 500
      );

      // Remaining operational before group liability: 8500
      const groupLiability = 2500.0;
      // Remaining operational after group liability: 6000
      expect(allowance.remainingOperational(groupLiability), 6000.0);

      // 3 days remaining: 6000 / 3 = 2000 / day
      expect(allowance.calculateDailySafeSpend(3, groupLiability), 2000.0);

      // 1 day remaining: 6000 / 1 = 6000
      expect(allowance.calculateDailySafeSpend(1, groupLiability), 6000.0);

      // If overspent beyond operational budget
      const excessiveLiability = 9000.0;
      expect(allowance.calculateDailySafeSpend(3, excessiveLiability), 0.0);
    });

    test('Serialization toMap and fromMap roundtrip preserves all values', () {
      const original = PersonalAllowanceModel(
        id: 'allowance-1',
        tripId: 'trip-123',
        userId: 'user-456',
        totalAllowance: 15000.0,
        emergencyBufferPercent: 0.15,
        cashOnHand: 4500.0,
      );

      final map = original.toMap();
      final reconstructed = PersonalAllowanceModel.fromMap(map);

      expect(reconstructed.tripId, original.tripId);
      expect(reconstructed.userId, original.userId);
      expect(reconstructed.totalAllowance, original.totalAllowance);
      expect(reconstructed.emergencyBufferPercent, original.emergencyBufferPercent);
      expect(reconstructed.cashOnHand, original.cashOnHand);
    });
  });
}
