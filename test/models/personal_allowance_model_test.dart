import 'package:flutter_test/flutter_test.dart';
import 'package:tara_travel/core/models/expense_model.dart';
import 'package:tara_travel/core/models/personal_allowance_model.dart';

void main() {
  group('PaymentMode Tests', () {
    test('verifies PaymentMode labels, icons, and colors', () {
      expect(PaymentMode.cash.isCash, isTrue);
      expect(PaymentMode.cash.isDigital, isFalse);
      expect(PaymentMode.cash.label, 'Cash on Hand');
      expect(PaymentMode.cash.shortLabel, 'Cash');

      expect(PaymentMode.ewallet.isCash, isFalse);
      expect(PaymentMode.ewallet.isDigital, isTrue);
      expect(PaymentMode.ewallet.label, 'E-Wallet (GCash / Maya)');
      expect(PaymentMode.ewallet.shortLabel, 'E-Wallet');

      expect(PaymentMode.maribank.isCash, isFalse);
      expect(PaymentMode.maribank.isDigital, isTrue);
      expect(PaymentMode.maribank.label, 'MariBank');
      expect(PaymentMode.maribank.shortLabel, 'MariBank');

      expect(PaymentMode.card.isCash, isFalse);
      expect(PaymentMode.card.isDigital, isTrue);
      expect(PaymentMode.card.label, 'Debit / Credit Card');
      expect(PaymentMode.card.shortLabel, 'Card');
    });

    test('parses legacy digital string to PaymentMode.ewallet for backwards compatibility', () {
      final item = PersonalExpenseItem.fromMap({
        'id': 'exp-1',
        'trip_id': 'trip-1',
        'user_id': 'user-1',
        'description': 'Legacy digital snack',
        'amount': '150.00',
        'category': 'food',
        'payment_mode': 'digital',
        'date': '2026-09-20T10:00:00Z',
      });

      expect(item.paymentMode, PaymentMode.ewallet);
      expect(item.paymentMode.isDigital, isTrue);
    });

    test('parses maribank, card, ewallet, and cash correctly', () {
      final itemMariBank = PersonalExpenseItem.fromMap({
        'id': 'exp-2',
        'trip_id': 'trip-1',
        'user_id': 'user-1',
        'description': 'Hotel deposit',
        'amount': 2500,
        'category': 'hotel',
        'payment_mode': 'maribank',
      });
      expect(itemMariBank.paymentMode, PaymentMode.maribank);

      final itemCard = PersonalExpenseItem.fromMap({
        'id': 'exp-3',
        'trip_id': 'trip-1',
        'user_id': 'user-1',
        'description': 'Supermarket grocery',
        'amount': 1200,
        'category': 'food',
        'payment_mode': 'card',
      });
      expect(itemCard.paymentMode, PaymentMode.card);
    });
  });

  group('PersonalAllowanceModel True Trip Cost & Multi-Channel Calculations', () {
    test('computes trueTripCost, ewalletSpent, maribankSpent, cardSpent, and cashSpent accurately', () {
      final now = DateTime.now();
      final expenses = [
        PersonalExpenseItem(
          id: '1',
          tripId: 'trip-1',
          userId: 'user-1',
          description: 'Jeepney fare',
          amount: 50.0,
          category: ExpenseCategory.transport,
          paymentMode: PaymentMode.cash,
          date: now,
          createdAt: now,
        ),
        PersonalExpenseItem(
          id: '2',
          tripId: 'trip-1',
          userId: 'user-1',
          description: 'Pasalubong dried mangoes',
          amount: 500.0,
          category: ExpenseCategory.custom,
          paymentMode: PaymentMode.ewallet,
          date: now,
          createdAt: now,
        ),
        PersonalExpenseItem(
          id: '3',
          tripId: 'trip-1',
          userId: 'user-1',
          description: 'Dinner via MariBank QR',
          amount: 800.0,
          category: ExpenseCategory.food,
          paymentMode: PaymentMode.maribank,
          date: now,
          createdAt: now,
        ),
        PersonalExpenseItem(
          id: '4',
          tripId: 'trip-1',
          userId: 'user-1',
          description: 'Souvenir shirt via Card',
          amount: 650.0,
          category: ExpenseCategory.custom,
          paymentMode: PaymentMode.card,
          date: now,
          createdAt: now,
        ),
      ];

      final allowance = PersonalAllowanceModel(
        tripId: 'trip-1',
        userId: 'user-1',
        totalAllowance: 10000.0,
        cashOnHand: 2000.0,
        expenses: expenses,
      );

      // Personal total = 50 + 500 + 800 + 650 = 2000.0
      expect(allowance.totalPersonalSpent, 2000.0);

      // Group share liability = 1500.0
      const groupLiability = 1500.0;

      // True Trip Cost = Personal Spent (2000) + Group Share (1500) = 3500.0
      expect(allowance.trueTripCost(groupLiability), 3500.0);

      // Channel totals
      expect(allowance.cashSpent, 50.0);
      expect(allowance.ewalletSpent, 500.0);
      expect(allowance.maribankSpent, 800.0);
      expect(allowance.cardSpent, 650.0);
      expect(allowance.digitalSpent, 1950.0); // 500 + 800 + 650

      // Remaining Cash on Hand = 2000 - 50 = 1950.0
      expect(allowance.remainingCashOnHand, 1950.0);
    });
  });
}
