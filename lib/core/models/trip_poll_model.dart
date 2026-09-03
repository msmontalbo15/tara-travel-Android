// Trip Poll model and option structures for interactive in-chat voting.
//
// Polls are persisted in `public.trip_polls` and votes in `public.trip_poll_votes`.
// All voter display names respect the privacy invariant via
// `MemberModel.formatDisplayName(name, hideSurname: true)`.

// ── Poll Option ───────────────────────────────────────────────────────────────

class PollOption {
  final String id;
  final String text;
  final int voteCount;
  final List<String> voterNames;
  final List<String> voterIds;

  const PollOption({
    required this.id,
    required this.text,
    this.voteCount = 0,
    this.voterNames = const [],
    this.voterIds = const [],
  });

  /// Calculates the percentage of total votes this option holds.
  double percentage(int totalVotes) =>
      totalVotes > 0 ? (voteCount / totalVotes) * 100.0 : 0.0;

  /// Whether the given user has voted for this option.
  bool isVotedBy(String userId) => voterIds.contains(userId);

  PollOption copyWith({
    String? id,
    String? text,
    int? voteCount,
    List<String>? voterNames,
    List<String>? voterIds,
  }) {
    return PollOption(
      id: id ?? this.id,
      text: text ?? this.text,
      voteCount: voteCount ?? this.voteCount,
      voterNames: voterNames ?? this.voterNames,
      voterIds: voterIds ?? this.voterIds,
    );
  }

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'text': text};
}

// ── Poll Category ─────────────────────────────────────────────────────────────

enum PollCategory {
  food,
  departure,
  activity,
  budget,
  custom;

  String get label {
    switch (this) {
      case PollCategory.food:
        return 'Food & Dining';
      case PollCategory.departure:
        return 'Departure Time';
      case PollCategory.activity:
        return 'Activity / Tour';
      case PollCategory.budget:
        return 'Budget / Expense';
      case PollCategory.custom:
        return 'Custom';
    }
  }

  String get emoji {
    switch (this) {
      case PollCategory.food:
        return '🍽️';
      case PollCategory.departure:
        return '⏰';
      case PollCategory.activity:
        return '🏄';
      case PollCategory.budget:
        return '💰';
      case PollCategory.custom:
        return '📊';
    }
  }

  String get dbValue => name;

  static PollCategory fromString(String? value) {
    switch (value) {
      case 'food':
        return PollCategory.food;
      case 'departure':
        return PollCategory.departure;
      case 'activity':
        return PollCategory.activity;
      case 'budget':
        return PollCategory.budget;
      default:
        return PollCategory.custom;
    }
  }
}

// ── Trip Poll ─────────────────────────────────────────────────────────────────

class TripPoll {
  final String id;
  final String tripId;
  final String creatorId;
  final String creatorName;
  final String question;
  final PollCategory category;
  final List<PollOption> options;
  final bool allowMultiple;
  final bool isClosed;
  final String? winnerOptionId;
  final DateTime createdAt;
  final DateTime? closedAt;

  const TripPoll({
    required this.id,
    required this.tripId,
    required this.creatorId,
    required this.creatorName,
    required this.question,
    required this.category,
    required this.options,
    this.allowMultiple = false,
    this.isClosed = false,
    this.winnerOptionId,
    required this.createdAt,
    this.closedAt,
  });

  /// Total votes cast across all options.
  int get totalVotes => options.fold(0, (sum, o) => sum + o.voteCount);

  /// Returns the option IDs that the given user has voted for.
  List<String> userVotedOptionIds(String userId) =>
      options.where((o) => o.isVotedBy(userId)).map((o) => o.id).toList();

  /// Whether the given user has voted at all.
  bool hasUserVoted(String userId) =>
      options.any((o) => o.isVotedBy(userId));

  /// Returns the winning option (highest vote count).
  PollOption? get winnerOption {
    if (winnerOptionId != null) {
      final match = options.where((o) => o.id == winnerOptionId);
      if (match.isNotEmpty) return match.first;
    }
    if (options.isEmpty) return null;
    final sorted = [...options]..sort((a, b) => b.voteCount.compareTo(a.voteCount));
    return sorted.first.voteCount > 0 ? sorted.first : null;
  }

  /// Whether the given user is the poll creator.
  bool isCreator(String userId) => creatorId == userId;

  TripPoll copyWith({
    String? id,
    String? tripId,
    String? creatorId,
    String? creatorName,
    String? question,
    PollCategory? category,
    List<PollOption>? options,
    bool? allowMultiple,
    bool? isClosed,
    String? winnerOptionId,
    DateTime? createdAt,
    DateTime? closedAt,
  }) {
    return TripPoll(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      question: question ?? this.question,
      category: category ?? this.category,
      options: options ?? this.options,
      allowMultiple: allowMultiple ?? this.allowMultiple,
      isClosed: isClosed ?? this.isClosed,
      winnerOptionId: winnerOptionId ?? this.winnerOptionId,
      createdAt: createdAt ?? this.createdAt,
      closedAt: closedAt ?? this.closedAt,
    );
  }

  factory TripPoll.fromRow(Map<String, dynamic> row, {List<Map<String, dynamic>> votes = const []}) {
    final optionsJson = (row['options'] as List?) ?? [];
    final parsedOptions = optionsJson.map((o) {
      final map = o is Map<String, dynamic> ? o : <String, dynamic>{};
      final optionId = map['id']?.toString() ?? '';
      // Filter votes for this option
      final optionVotes = votes.where((v) => v['option_id']?.toString() == optionId).toList();
      return PollOption(
        id: optionId,
        text: map['text']?.toString() ?? '',
        voteCount: optionVotes.length,
        voterIds: optionVotes.map((v) => v['user_id']?.toString() ?? '').toList(),
        voterNames: optionVotes.map((v) => v['voter_name']?.toString() ?? '').toList(),
      );
    }).toList();

    return TripPoll(
      id: row['id'] as String,
      tripId: row['trip_id'] as String,
      creatorId: row['creator_id'] as String,
      creatorName: (row['creator_name'] as String?) ?? 'Anonymous',
      question: row['question'] as String,
      category: PollCategory.fromString(row['category'] as String?),
      options: parsedOptions,
      allowMultiple: row['allow_multiple'] as bool? ?? false,
      isClosed: row['is_closed'] as bool? ?? false,
      winnerOptionId: row['winner_option_id'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      closedAt: row['closed_at'] != null
          ? DateTime.parse(row['closed_at'] as String).toLocal()
          : null,
    );
  }
}
