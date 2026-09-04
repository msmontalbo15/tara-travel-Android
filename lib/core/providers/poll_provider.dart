import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trip_poll_model.dart';
import '../repositories/chat_repository.dart';
import 'selected_trip_provider.dart';

// ── Poll Repository Provider ──────────────────────────────────────────────────

final pollRepositoryProvider = Provider<ChatRepository>((ref) => ChatRepository());

// ── Polls Stream Provider (per trip) ──────────────────────────────────────────

/// Streams all polls for the active trip, merged with live vote counts.
class PollsNotifier extends AsyncNotifier<List<TripPoll>> {
  StreamSubscription<List<Map<String, dynamic>>>? _pollsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _votesSub;

  List<Map<String, dynamic>> _rawPolls = [];
  List<Map<String, dynamic>> _rawVotes = [];

  @override
  Future<List<TripPoll>> build() async {
    final tripId = ref.watch(selectedTripIdProvider);

    _pollsSub?.cancel();
    _votesSub?.cancel();
    _pollsSub = null;
    _votesSub = null;
    _rawPolls = [];
    _rawVotes = [];

    if (tripId == null) return [];

    final repo = ref.read(pollRepositoryProvider);

    // Initial fetch
    final polls = await repo.getPolls(tripId);

    // Subscribe to real-time poll changes
    _pollsSub = repo.pollsStream(tripId).listen(
      (rows) {
        _rawPolls = rows.cast<Map<String, dynamic>>();
        _rebuildState();
      },
      onError: (e) {
        debugPrint('[PollsNotifier] pollsStream error: $e');
      },
    );

    // Subscribe to real-time vote changes
    _votesSub = repo.pollVotesStream(tripId).listen(
      (rows) {
        _rawVotes = rows.cast<Map<String, dynamic>>();
        _rebuildState();
      },
      onError: (e) {
        debugPrint('[PollsNotifier] votesStream error: $e');
      },
    );

    ref.onDispose(() {
      _pollsSub?.cancel();
      _votesSub?.cancel();
    });

    return polls;
  }

  /// Rebuilds the poll list with current vote data.
  void _rebuildState() {
    final votesByPoll = <String, List<Map<String, dynamic>>>{};
    for (final v in _rawVotes) {
      final pid = v['poll_id']?.toString() ?? '';
      votesByPoll.putIfAbsent(pid, () => []).add(v);
    }

    final polls = _rawPolls.map((row) {
      return TripPoll.fromRow(row, votes: votesByPoll[row['id']] ?? []);
    }).toList();

    // Sort by created_at descending (newest first)
    polls.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    state = AsyncData(polls);
  }

  /// Creates a new travel poll.
  Future<TripPoll?> createPoll({
    required String question,
    required List<String> optionTexts,
    required String category,
    required String creatorName,
    bool allowMultiple = false,
  }) async {
    final tripId = ref.read(selectedTripIdProvider);
    if (tripId == null) return null;

    final repo = ref.read(pollRepositoryProvider);
    return repo.createPoll(
      tripId: tripId,
      question: question,
      optionTexts: optionTexts,
      category: category,
      creatorName: creatorName,
      allowMultiple: allowMultiple,
    );
  }

  /// Casts a vote for the given option (optimistic update).
  Future<void> castVote({
    required String pollId,
    required String optionId,
    required String voterName,
  }) async {
    final tripId = ref.read(selectedTripIdProvider);
    if (tripId == null) return;

    final repo = ref.read(pollRepositoryProvider);
    await repo.castVote(
      pollId: pollId,
      tripId: tripId,
      optionId: optionId,
      voterName: voterName,
    );
    // Real-time stream will push the update automatically
  }

  /// Removes a vote for the given option.
  Future<void> removeVote({
    required String pollId,
    required String optionId,
  }) async {
    final repo = ref.read(pollRepositoryProvider);
    await repo.removeVote(pollId: pollId, optionId: optionId);
  }

  /// Toggles a vote — casts if not yet voted, removes if already voted.
  Future<void> toggleVote({
    required TripPoll poll,
    required String optionId,
    required String currentUserId,
    required String voterName,
  }) async {
    final alreadyVoted = poll.options
        .any((o) => o.id == optionId && o.isVotedBy(currentUserId));

    if (alreadyVoted) {
      await removeVote(pollId: poll.id, optionId: optionId);
    } else {
      // For single-choice polls, remove all previous votes first
      if (!poll.allowMultiple) {
        for (final opt in poll.options) {
          if (opt.isVotedBy(currentUserId)) {
            await removeVote(pollId: poll.id, optionId: opt.id);
          }
        }
      }
      await castVote(
        pollId: poll.id,
        optionId: optionId,
        voterName: voterName,
      );
    }
  }

  /// Adds a crowdsourced option to an open poll.
  Future<void> addOption({
    required String pollId,
    required String optionText,
  }) async {
    final repo = ref.read(pollRepositoryProvider);
    await repo.addPollOption(
      pollId: pollId,
      optionText: optionText,
    );
  }

  /// Closes a poll and auto-resolves the winner.
  Future<void> closePoll(String pollId) async {
    final polls = state.value ?? [];
    final poll = polls.where((p) => p.id == pollId).firstOrNull;
    if (poll == null) return;

    // Determine winner by highest vote count
    final winner = poll.winnerOption;

    final repo = ref.read(pollRepositoryProvider);
    await repo.closePoll(
      pollId: pollId,
      winnerOptionId: winner?.id,
    );
  }
}

final pollsProvider =
    AsyncNotifierProvider<PollsNotifier, List<TripPoll>>(PollsNotifier.new);

// ── Single Poll Lookup (by pollId) ────────────────────────────────────────────

/// Convenience provider to find a single poll by its ID from the polls list.
final singlePollProvider = Provider.family<TripPoll?, String>((ref, pollId) {
  final polls = ref.watch(pollsProvider).value ?? [];
  final matches = polls.where((p) => p.id == pollId);
  return matches.isNotEmpty ? matches.first : null;
});
