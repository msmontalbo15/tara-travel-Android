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
  final bool isDraft;
  final String? coverEmoji;
  final String inviteCode;
  final String? ownerId;
  // New metadata fields
  final String? coverColor;
  final String? departurePoint;
  final String? departureMapUrl;
  final Map<String, dynamic>? destinationDetails;

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
    this.isDraft = false,
    this.coverEmoji,
    this.inviteCode = '',
    this.ownerId,
    this.coverColor,
    this.departurePoint,
    this.departureMapUrl,
    this.destinationDetails,
  });

  double get totalSpent => expenses
      .where((e) => e.status == ExpenseStatus.approved)
      .fold(0, (sum, e) => sum + e.amount);

  double get remainingBudget => totalBudget - totalSpent;

  /// Returns true if essential trip details (destination, budget, or valid dates) are missing/unspecified
  bool get isIncomplete =>
      isDraft ||
      destination.trim().isEmpty ||
      destination.trim().toUpperCase() == 'TBD' ||
      name.trim().isEmpty ||
      name.trim().toLowerCase() == 'my trip' ||
      name.trim().toLowerCase() == 'draft trip';

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
    bool? isDraft,
    String? coverEmoji,
    String? inviteCode,
    String? ownerId,
    String? coverColor,
    String? departurePoint,
    String? departureMapUrl,
    Map<String, dynamic>? destinationDetails,
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
      isDraft: isDraft ?? this.isDraft,
      coverEmoji: coverEmoji ?? this.coverEmoji,
      inviteCode: inviteCode ?? this.inviteCode,
      ownerId: ownerId ?? this.ownerId,
      coverColor: coverColor ?? this.coverColor,
      departurePoint: departurePoint ?? this.departurePoint,
      departureMapUrl: departureMapUrl ?? this.departureMapUrl,
      destinationDetails: destinationDetails ?? this.destinationDetails,
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
    final isDraft = map['is_draft'] == true || status == 'draft';
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
      isDraft: isDraft,
      coverEmoji: map['cover_emoji']?.toString(),
      inviteCode: map['invite_code']?.toString() ?? '',
      ownerId: map['owner_id']?.toString() ?? map['ownerId']?.toString(),
      coverColor: map['cover_color']?.toString(),
      departurePoint: map['departure_point']?.toString(),
      departureMapUrl: map['departure_map_url']?.toString(),
      destinationDetails: map['destination_details'] != null
          ? (map['destination_details'] as Map).cast<String, dynamic>()
          : null,
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
      'is_draft': isDraft,
      'status': isDraft ? 'draft' : (isArchived ? 'archived' : 'planned'),
      'cover_emoji': coverEmoji,
      'invite_code': inviteCode,
      'owner_id': ownerId,
      'cover_color': coverColor,
      'departure_point': departurePoint,
      'departure_map_url': departureMapUrl,
      'destination_details': destinationDetails,
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
      'status': isDraft ? 'draft' : (isArchived ? 'archived' : 'planned'),
      if (inviteCode.isNotEmpty) 'invite_code': inviteCode,
      if (coverColor != null) 'cover_color': coverColor,
      if (departurePoint != null) 'departure_point': departurePoint,
      if (departureMapUrl != null) 'departure_map_url': departureMapUrl,
      if (destinationDetails != null) 'destination_details': destinationDetails,
    };
  }
}
