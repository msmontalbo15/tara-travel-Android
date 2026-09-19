import 'dart:math';
import 'package:flutter/material.dart';
import 'expense_model.dart';

/// Payment method used for personal tracking
enum PaymentMode {
  cash,
  ewallet,
  maribank,
  card;

  bool get isCash => this == PaymentMode.cash;
  bool get isDigital => this != PaymentMode.cash;

  String get label {
    switch (this) {
      case PaymentMode.cash:
        return 'Cash on Hand';
      case PaymentMode.ewallet:
        return 'E-Wallet (GCash / Maya)';
      case PaymentMode.maribank:
        return 'MariBank';
      case PaymentMode.card:
        return 'Debit / Credit Card';
    }
  }

  String get shortLabel {
    switch (this) {
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.ewallet:
        return 'E-Wallet';
      case PaymentMode.maribank:
        return 'MariBank';
      case PaymentMode.card:
        return 'Card';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMode.cash:
        return Icons.money_rounded;
      case PaymentMode.ewallet:
        return Icons.account_balance_wallet_rounded;
      case PaymentMode.maribank:
        return Icons.account_balance_rounded;
      case PaymentMode.card:
        return Icons.credit_card_rounded;
    }
  }

  Color get color {
    switch (this) {
      case PaymentMode.cash:
        return const Color(0xFF10B981); // Emerald
      case PaymentMode.ewallet:
        return const Color(0xFF007DFE); // Blue (GCash/Maya)
      case PaymentMode.maribank:
        return const Color(0xFFFF6600); // MariBank Orange
      case PaymentMode.card:
        return const Color(0xFF6366F1); // Indigo
    }
  }
}

/// Represents a private personal expense logged exclusively by this user.
/// Stored in Supabase `personal_expenses` table with private RLS.
class PersonalExpenseItem {
  final String id;
  final String tripId;
  final String userId;
  final String description;
  final double amount;
  final ExpenseCategory category;
  final PaymentMode paymentMode;
  final DateTime date;
  final DateTime createdAt;

  const PersonalExpenseItem({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.description,
    required this.amount,
    required this.category,
    this.paymentMode = PaymentMode.cash,
    required this.date,
    required this.createdAt,
  });

  factory PersonalExpenseItem.fromMap(Map<String, dynamic> map) {
    String categoryRaw = (map['category'] ?? 'custom').toString().toLowerCase();
    if (categoryRaw == 'activity') categoryRaw = 'activities';
    final parsedCategory = ExpenseCategory.values.firstWhere(
      (e) => e.name == categoryRaw,
      orElse: () => ExpenseCategory.custom,
    );

    final paymentModeRaw = (map['payment_mode'] ?? 'cash').toString().toLowerCase();
    PaymentMode parsedPaymentMode;
    switch (paymentModeRaw) {
      case 'ewallet':
      case 'digital':
        parsedPaymentMode = PaymentMode.ewallet;
        break;
      case 'maribank':
        parsedPaymentMode = PaymentMode.maribank;
        break;
      case 'card':
        parsedPaymentMode = PaymentMode.card;
        break;
      case 'cash':
      default:
        parsedPaymentMode = PaymentMode.cash;
        break;
    }

    return PersonalExpenseItem(
      id: '${map['id']}',
      tripId: '${map['trip_id']}',
      userId: '${map['user_id']}',
      description: map['description']?.toString() ?? '',
      amount: double.tryParse((map['amount'] ?? '0').toString()) ?? 0.0,
      category: parsedCategory,
      paymentMode: parsedPaymentMode,
      date: DateTime.tryParse('${map['date']}') ?? DateTime.now(),
      createdAt: DateTime.tryParse('${map['created_at']}') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'user_id': userId,
      'description': description,
      'amount': amount,
      'category': category.name,
      'payment_mode': paymentMode.name,
      'date': date.toIso8601String(),
    };
  }
}

/// Holds the personal budget, cash-on-hand, emergency reserve, and expenses for a single user on a trip.
/// Stored in Supabase `trip_personal_allowances` table with private RLS.
class PersonalAllowanceModel {
  final String? id;
  final String tripId;
  final String userId;
  final double totalAllowance;
  final double emergencyBufferPercent; // e.g. 0.10 for 10%
  final double cashOnHand;
  final List<PersonalExpenseItem> expenses;

  const PersonalAllowanceModel({
    this.id,
    required this.tripId,
    required this.userId,
    required this.totalAllowance,
    this.emergencyBufferPercent = 0.10,
    this.cashOnHand = 0.0,
    this.expenses = const [],
  });

  /// 10% Emergency reserve amount protected from daily spending
  double get contingencyAmount => totalAllowance * emergencyBufferPercent;

  /// Operational spending allowance (Total - Emergency Buffer)
  double get operationalBudget => max(0.0, totalAllowance - contingencyAmount);

  /// Sum of all solo personal out-of-pocket expenses
  double get totalPersonalSpent =>
      expenses.fold(0.0, (acc, e) => acc + e.amount);

  /// True Trip Cost: Personal solo spending + user's estimated share of group expenses
  double trueTripCost(double myGroupLiability) => totalPersonalSpent + myGroupLiability;

  /// Spent using physical cash
  double get cashSpent => expenses
      .where((e) => e.paymentMode.isCash)
      .fold(0.0, (acc, e) => acc + e.amount);

  /// Spent using non-cash digital methods (E-Wallet, MariBank, Card)
  double get digitalSpent => expenses
      .where((e) => e.paymentMode.isDigital)
      .fold(0.0, (acc, e) => acc + e.amount);

  /// Spent using E-Wallets (GCash / Maya)
  double get ewalletSpent => expenses
      .where((e) => e.paymentMode == PaymentMode.ewallet)
      .fold(0.0, (acc, e) => acc + e.amount);

  /// Spent using MariBank
  double get maribankSpent => expenses
      .where((e) => e.paymentMode == PaymentMode.maribank)
      .fold(0.0, (acc, e) => acc + e.amount);

  /// Spent using Debit / Credit Card
  double get cardSpent => expenses
      .where((e) => e.paymentMode == PaymentMode.card)
      .fold(0.0, (acc, e) => acc + e.amount);

  /// Net cash on hand remaining after cash personal expenses
  double get remainingCashOnHand => max(0.0, cashOnHand - cashSpent);

  /// Remaining operational pocket money taking into account approved group split obligations
  double remainingOperational(double myGroupLiability) {
    return operationalBudget - totalPersonalSpent - myGroupLiability;
  }

  /// Calculates dynamic safe spend per day based on remaining days and group liability
  double calculateDailySafeSpend(int daysRemaining, double myGroupLiability) {
    final remaining = remainingOperational(myGroupLiability);
    if (remaining <= 0) return 0.0;
    final days = max(1, daysRemaining);
    return remaining / days;
  }

  factory PersonalAllowanceModel.fromMap(
    Map<String, dynamic> map, {
    List<PersonalExpenseItem> expenses = const [],
  }) {
    return PersonalAllowanceModel(
      id: map['id']?.toString(),
      tripId: '${map['trip_id']}',
      userId: '${map['user_id']}',
      totalAllowance:
          double.tryParse((map['total_allowance'] ?? '0').toString()) ?? 0.0,
      emergencyBufferPercent: double.tryParse(
              (map['emergency_buffer_percent'] ?? '0.10').toString()) ??
          0.10,
      cashOnHand:
          double.tryParse((map['cash_on_hand'] ?? '0').toString()) ?? 0.0,
      expenses: expenses,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'trip_id': tripId,
      'user_id': userId,
      'total_allowance': totalAllowance,
      'emergency_buffer_percent': emergencyBufferPercent,
      'cash_on_hand': cashOnHand,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  PersonalAllowanceModel copyWith({
    String? id,
    String? tripId,
    String? userId,
    double? totalAllowance,
    double? emergencyBufferPercent,
    double? cashOnHand,
    List<PersonalExpenseItem>? expenses,
  }) {
    return PersonalAllowanceModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      userId: userId ?? this.userId,
      totalAllowance: totalAllowance ?? this.totalAllowance,
      emergencyBufferPercent:
          emergencyBufferPercent ?? this.emergencyBufferPercent,
      cashOnHand: cashOnHand ?? this.cashOnHand,
      expenses: expenses ?? this.expenses,
    );
  }
}
