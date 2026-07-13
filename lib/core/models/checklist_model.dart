class ChecklistItemModel {
  final String id;
  final String title;
  final String category;
  final bool isPacked;
  final String? assignedMemberId; // Member ID
  final bool isAiSuggested;

  ChecklistItemModel({
    required this.id,
    required this.title,
    required this.category,
    this.isPacked = false,
    this.assignedMemberId,
    this.isAiSuggested = false,
  });

  factory ChecklistItemModel.fromMap(Map<String, dynamic> map) {
    return ChecklistItemModel(
      id: map['id'],
      title: map['title'],
      category: map['category'],
      isPacked: map['is_packed'] ?? false,
      assignedMemberId: map['assigned_member_id'],
      isAiSuggested: map['is_ai_suggested'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'is_packed': isPacked,
      'assigned_member_id': assignedMemberId,
      'is_ai_suggested': isAiSuggested,
    };
  }
}
