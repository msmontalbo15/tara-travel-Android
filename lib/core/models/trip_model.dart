import 'member_model.dart';
import 'expense_model.dart';

class TripModel {
  final String id;
  final String name;
  final String destination;
  final DateTime fromDate;
  final DateTime toDate;
  final String tripType;
  final double totalBudget;
  final bool splitEqually;
  final List<MemberModel> members;
  final List<ExpenseModel> expenses;
  final bool isArchived;
  final String? coverEmoji;
  final String inviteCode;

  TripModel({
    required this.id,
    required this.name,
    required this.destination,
    required this.fromDate,
    required this.toDate,
    required this.tripType,
    required this.totalBudget,
    this.splitEqually = true,
    this.members = const [],
    this.expenses = const [],
    this.isArchived = false,
    this.coverEmoji,
    this.inviteCode = '',
  });

  double get totalSpent => expenses
      .where((e) => e.status == ExpenseStatus.approved)
      .fold(0, (sum, e) => sum + e.amount);

  double get remainingBudget => totalBudget - totalSpent;

  TripModel copyWith({
    String? id,
    String? name,
    String? destination,
    DateTime? fromDate,
    DateTime? toDate,
    String? tripType,
    double? totalBudget,
    bool? splitEqually,
    List<MemberModel>? members,
    List<ExpenseModel>? expenses,
    bool? isArchived,
    String? coverEmoji,
    String? inviteCode,
  }) {
    return TripModel(
      id: id ?? this.id,
      name: name ?? this.name,
      destination: destination ?? this.destination,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      tripType: tripType ?? this.tripType,
      totalBudget: totalBudget ?? this.totalBudget,
      splitEqually: splitEqually ?? this.splitEqually,
      members: members ?? this.members,
      expenses: expenses ?? this.expenses,
      isArchived: isArchived ?? this.isArchived,
      coverEmoji: coverEmoji ?? this.coverEmoji,
      inviteCode: inviteCode ?? this.inviteCode,
    );
  }

  factory TripModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      return DateTime.parse('$value');
    }

    final membersRaw = (map['members'] ?? map['trip_members']) as List?;
    final expensesRaw = (map['expenses'] as List?) ?? const [];

    final status = '${map['status'] ?? ''}'.toLowerCase();
    return TripModel(
      id: '${map['id']}',
      name: map['name']?.toString() ?? 'Untitled Trip',
      destination: map['destination']?.toString() ?? 'No destination',
      // Accept both local (from_date) and Supabase (start_date) keys
      fromDate: parseDate(map['from_date'] ?? map['start_date']),
      toDate: parseDate(map['to_date'] ?? map['end_date']),
      tripType: (map['trip_type'] ?? map['type'] ?? 'beach').toString(),
      totalBudget: double.tryParse((map['total_budget'] ?? map['budget'] ?? '0').toString()) ?? 0.0,
      splitEqually: map['split_equally'] ?? map['split_method'] == 'equal',
      members: membersRaw
              ?.map((m) => MemberModel.fromMap((m as Map).cast<String, dynamic>()))
              .toList() ??
          [],
      expenses: expensesRaw
          .map((e) => ExpenseModel.fromMap((e as Map).cast<String, dynamic>()))
          .toList(),
      isArchived: map['is_archived'] == true ||
          status == 'archived' ||
          status == 'completed',
      coverEmoji: map['cover_emoji']?.toString(),
      inviteCode: map['invite_code']?.toString() ?? '',
    );
  }

  /// toMap for local Sembast cache — uses snake_case keys consistent with DB
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'destination': destination,
      // Use Supabase-compatible keys everywhere (local + remote)
      'start_date': fromDate.toIso8601String(),
      'end_date': toDate.toIso8601String(),
      'type': tripType,
      'budget': totalBudget,
      'split_method': splitEqually ? 'equal' : 'fixed',
      'members': members.map((m) => m.toMap()).toList(),
      'expenses': expenses.map((e) => e.toMap()).toList(),
      'is_archived': isArchived,
      'cover_emoji': coverEmoji,
      'invite_code': inviteCode,
    };
  }

  /// Produces the exact payload expected by Supabase (no nested objects)
  Map<String, dynamic> toSupabaseInsert(String ownerId) {
    return {
      'id': id,
      'name': name,
      'destination': destination,
      'start_date': fromDate.toIso8601String(),
      'end_date': toDate.toIso8601String(),
      'type': tripType.toLowerCase(),
      'budget': totalBudget,
      'split_method': splitEqually ? 'equal' : 'fixed',
      'owner_id': ownerId,
      'status': isArchived ? 'archived' : 'planned',
    };
  }
}
