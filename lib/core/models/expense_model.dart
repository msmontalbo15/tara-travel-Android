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
  final String paidById; // Member ID
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

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    String categoryRaw = (map['category'] ?? 'custom').toString().toLowerCase();
    if (categoryRaw == 'activity') categoryRaw = 'activities';
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
}
