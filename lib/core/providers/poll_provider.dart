import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

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

    // Initial fetch of raw polls and votes
    final raw = await repo.getPollsAndVotesRaw(tripId);
    _rawPolls = raw.polls;
    _rawVotes = raw.votes;

    // Build initial polls from raw data
    final initialPolls = _computePolls();

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

    return initialPolls;
  }

  List<TripPoll> _computePolls() {
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
    return polls;
  }

  /// Rebuilds the poll list with current vote data.
  void _rebuildState() {
    state = AsyncData(_computePolls());
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

  /// Casts a vote for the given option (optimistic update with rollback).
  Future<void> castVote({
    required String pollId,
    required String optionId,
    required String voterName,
    String? currentUserId,
  }) async {
    final tripId = ref.read(selectedTripIdProvider);
    if (tripId == null) return;

    final uid = currentUserId ?? _currentUserId;
    if (uid != null) {
      // Optimistic local addition
      _rawVotes.removeWhere((v) =>
          v['poll_id'] == pollId &&
          v['user_id'] == uid &&
          v['option_id'] == optionId);
      _rawVotes.add({
        'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
        'poll_id': pollId,
        'trip_id': tripId,
        'user_id': uid,
        'voter_name': voterName,
        'option_id': optionId,
        'created_at': DateTime.now().toIso8601String(),
      });
      _rebuildState();
    }

    final repo = ref.read(pollRepositoryProvider);
    try {
      await repo.castVote(
        pollId: pollId,
        tripId: tripId,
        optionId: optionId,
        voterName: voterName,
      );
    } catch (e) {
      debugPrint('[PollsNotifier] castVote error, reverting optimistic: $e');
      if (uid != null) {
        _rawVotes.removeWhere((v) =>
            v['poll_id'] == pollId &&
            v['user_id'] == uid &&
            v['option_id'] == optionId &&
            v['id'].toString().startsWith('temp_'));
        _rebuildState();
      }
      rethrow;
    }
  }

  /// Removes/undoes a vote for the given option (optimistic update with rollback).
  Future<void> removeVote({
    required String pollId,
    required String optionId,
    String? currentUserId,
  }) async {
    final uid = currentUserId ?? _currentUserId;
    Map<String, dynamic>? backup;
    if (uid != null) {
      final idx = _rawVotes.indexWhere((v) =>
          v['poll_id'] == pollId &&
          v['user_id'] == uid &&
          v['option_id'] == optionId);
      if (idx != -1) {
        backup = _rawVotes[idx];
        _rawVotes.removeAt(idx);
        _rebuildState();
      }
    }

    final repo = ref.read(pollRepositoryProvider);
    try {
      await repo.removeVote(pollId: pollId, optionId: optionId);
    } catch (e) {
      debugPrint('[PollsNotifier] removeVote error, reverting: $e');
      if (backup != null) {
        _rawVotes.add(backup);
        _rebuildState();
      }
      rethrow;
    }
  }

  /// Toggles a vote — casts if not yet voted, removes (undo) if already voted.
  Future<void> toggleVote({
    required TripPoll poll,
    required String optionId,
    required String currentUserId,
    required String voterName,
  }) async {
    final alreadyVoted = poll.options
        .any((o) => o.id == optionId && o.isVotedBy(currentUserId));

    if (alreadyVoted) {
      await removeVote(
        pollId: poll.id,
        optionId: optionId,
        currentUserId: currentUserId,
      );
    } else {
      // For single-choice polls, remove all previous votes first
      if (!poll.allowMultiple) {
        for (final opt in poll.options) {
          if (opt.isVotedBy(currentUserId)) {
            await removeVote(
              pollId: poll.id,
              optionId: opt.id,
              currentUserId: currentUserId,
            );
          }
        }
      }
      await castVote(
        pollId: poll.id,
        optionId: optionId,
        voterName: voterName,
        currentUserId: currentUserId,
      );
    }
  }

  /// Retracts / undoes all votes cast by the current user on this poll.
  Future<void> undoAllVotes({
    required TripPoll poll,
    required String currentUserId,
  }) async {
    for (final opt in poll.options) {
      if (opt.isVotedBy(currentUserId)) {
        await removeVote(
          pollId: poll.id,
          optionId: opt.id,
          currentUserId: currentUserId,
        );
      }
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
