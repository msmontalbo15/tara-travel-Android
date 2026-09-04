import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum ExpenseCategory {
  hotel,
  food,
  activities,
  transport,
  custom,
}

enum ExpenseStatus {
  pending,
  approved,
  rejected,
}

class ExpenseModel {
  final String id;
  final String description;
  final double amount;
  final ExpenseCategory category;
  final String paidById; // Member ID / User UUID
  final DateTime date;
  final ExpenseStatus status;
  final String? receiptPhotoUrl;
  final String? rejectionNote;

  ExpenseModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.paidById,
    required this.date,
    this.status = ExpenseStatus.pending,
    this.receiptPhotoUrl,
    this.rejectionNote,
  });

  bool get isApproved => status == ExpenseStatus.approved;
  bool get isPending => status == ExpenseStatus.pending;
  bool get isRejected => status == ExpenseStatus.rejected;

  String get categoryLabel {
    switch (category) {
      case ExpenseCategory.hotel:
        return 'Accommodation';
      case ExpenseCategory.food:
        return 'Food & Dining';
      case ExpenseCategory.activities:
        return 'Activities & Tours';
      case ExpenseCategory.transport:
        return 'Transportation';
      case ExpenseCategory.custom:
        return 'Other / Misc';
    }
  }

  String get categoryEmoji {
    switch (category) {
      case ExpenseCategory.hotel:
        return '🏨';
      case ExpenseCategory.food:
        return '🍽️';
      case ExpenseCategory.activities:
        return '🏝️';
      case ExpenseCategory.transport:
        return '🚐';
      case ExpenseCategory.custom:
        return '📦';
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case ExpenseCategory.hotel:
        return Icons.hotel_rounded;
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.activities:
        return Icons.local_activity_rounded;
      case ExpenseCategory.transport:
        return Icons.directions_bus_rounded;
      case ExpenseCategory.custom:
        return Icons.receipt_long_rounded;
    }
  }

  Color get categoryColor {
    switch (category) {
      case ExpenseCategory.hotel:
        return const Color(0xFF8B5CF6); // Purple
      case ExpenseCategory.food:
        return AppColors.primary; // Coral
      case ExpenseCategory.activities:
        return const Color(0xFF10B981); // Emerald Green
      case ExpenseCategory.transport:
        return const Color(0xFF3B82F6); // Blue
      case ExpenseCategory.custom:
        return const Color(0xFFF0997B); // Light Coral / Sand accent
    }
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    String categoryRaw = (map['category'] ?? 'custom').toString().toLowerCase();
    if (categoryRaw == 'activity') categoryRaw = 'activities';
    if (categoryRaw == 'accommodation') categoryRaw = 'hotel';
    if (categoryRaw == 'flights' || categoryRaw == 'ride') categoryRaw = 'transport';
    final parsedCategory = ExpenseCategory.values.firstWhere(
      (e) => e.name == categoryRaw,
      orElse: () => ExpenseCategory.custom,
    );
    return ExpenseModel(
      id: '${map['id']}',
      description: map['description']?.toString() ?? '',
      amount: double.tryParse((map['amount'] ?? '0').toString()) ?? 0.0,
      category: parsedCategory,
      paidById: '${map['paid_by_user_id'] ?? map['paid_by_id'] ?? ''}',
      date: DateTime.parse('${map['created_at'] ?? map['date']}'),
      status: ExpenseStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'pending'),
        orElse: () => ExpenseStatus.pending,
      ),
      receiptPhotoUrl: map['receipt_url'] ?? map['receipt_photo_url'],
      rejectionNote: map['rejection_note']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'category': category.name,
      'paid_by_user_id': paidById,
      'created_at': date.toIso8601String(),
      'status': status.name,
      'receipt_url': receiptPhotoUrl,
      'rejection_note': rejectionNote,
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? description,
    double? amount,
    ExpenseCategory? category,
    String? paidById,
    DateTime? date,
    ExpenseStatus? status,
    String? receiptPhotoUrl,
    String? rejectionNote,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paidById: paidById ?? this.paidById,
      date: date ?? this.date,
      status: status ?? this.status,
      receiptPhotoUrl: receiptPhotoUrl ?? this.receiptPhotoUrl,
      rejectionNote: rejectionNote ?? this.rejectionNote,
    );
  }
}
