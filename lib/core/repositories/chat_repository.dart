import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trip_poll_model.dart';

// ── Model ──────────────────────────────────────────────────────────────────────

/// Message type discriminator for rich chat content.
enum ChatMessageType {
  text,
  poll,
  announcement,
  quickTravel,
  itinerarySnippet,
  expenseRequest,
  packingAlert,
  locationDrop,
  media,
  taraBot;

  String get dbValue {
    switch (this) {
      case ChatMessageType.text:
        return 'text';
      case ChatMessageType.poll:
        return 'poll';
      case ChatMessageType.announcement:
        return 'announcement';
      case ChatMessageType.quickTravel:
        return 'quick_travel';
      case ChatMessageType.itinerarySnippet:
        return 'itinerary_snippet';
      case ChatMessageType.expenseRequest:
        return 'expense_request';
      case ChatMessageType.packingAlert:
        return 'packing_alert';
      case ChatMessageType.locationDrop:
        return 'location_drop';
      case ChatMessageType.media:
        return 'media';
      case ChatMessageType.taraBot:
        return 'tara_bot';
    }
  }

  static ChatMessageType fromString(String? value) {
    switch (value) {
      case 'poll':
        return ChatMessageType.poll;
      case 'announcement':
        return ChatMessageType.announcement;
      case 'quick_travel':
        return ChatMessageType.quickTravel;
      case 'itinerary_snippet':
        return ChatMessageType.itinerarySnippet;
      case 'expense_request':
        return ChatMessageType.expenseRequest;
      case 'packing_alert':
        return ChatMessageType.packingAlert;
      case 'location_drop':
        return ChatMessageType.locationDrop;
      case 'media':
        return ChatMessageType.media;
      case 'tara_bot':
        return ChatMessageType.taraBot;
      default:
        return ChatMessageType.text;
    }
  }
}

class ChatMessage {
  final String id;
  final String tripId;
  final String userId;
  final String senderName;
  final String text;
  final DateTime createdAt;
  final bool isMe;
  final bool isPinned;
  final String? pollId;
  final ChatMessageType messageType;
  final Map<String, dynamic>? metadata;
  final Map<String, List<String>> reactions;

  /// True when the message has been dispatched optimistically but not yet
  /// acknowledged by the server. Used to show a subtle pending indicator.
  final bool isPending;

  const ChatMessage({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.senderName,
    required this.text,
    required this.createdAt,
    this.isMe = false,
    this.isPinned = false,
    this.pollId,
    this.messageType = ChatMessageType.text,
    this.metadata,
    this.reactions = const {},
    this.isPending = false,
  });

  String get initials {
    final parts = senderName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return senderName.isNotEmpty ? senderName[0].toUpperCase() : '?';
  }

  ChatMessage copyWith({
    String? id,
    String? tripId,
    String? userId,
    String? senderName,
    String? text,
    DateTime? createdAt,
    bool? isMe,
    bool? isPinned,
    String? pollId,
    ChatMessageType? messageType,
    Map<String, dynamic>? metadata,
    Map<String, List<String>>? reactions,
    bool? isPending,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      userId: userId ?? this.userId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      isMe: isMe ?? this.isMe,
      isPinned: isPinned ?? this.isPinned,
      pollId: pollId ?? this.pollId,
      messageType: messageType ?? this.messageType,
      metadata: metadata ?? this.metadata,
      reactions: reactions ?? this.reactions,
      isPending: isPending ?? this.isPending,
    );
  }

  factory ChatMessage.fromRow(
    Map<String, dynamic> row,
    String currentUserId,
  ) {
    final name = (row['sender_name'] as String?)?.trim() ?? 'Unknown';

    Map<String, dynamic>? meta;
    if (row['metadata'] != null && row['metadata'] is Map) {
      meta = Map<String, dynamic>.from(row['metadata'] as Map);
    }

    final reactMap = <String, List<String>>{};
    if (row['reactions'] != null && row['reactions'] is Map) {
      final rawMap = row['reactions'] as Map;
      rawMap.forEach((k, v) {
        if (v is List) {
          reactMap[k.toString()] = v.map((e) => e.toString()).toList();
        }
      });
    }

    return ChatMessage(
      id: row['id'] as String,
      tripId: row['trip_id'] as String,
      userId: row['user_id'] as String,
      senderName: name,
      text: row['content'] as String? ?? '',
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      isMe: (row['user_id'] as String) == currentUserId,
      isPinned: row['is_pinned'] as bool? ?? false,
      pollId: row['poll_id'] as String?,
      messageType: ChatMessageType.fromString(row['message_type'] as String?),
      metadata: meta,
      reactions: reactMap,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'trip_id': tripId,
        'user_id': userId,
        'sender_name': senderName,
        'content': text,
        'created_at': createdAt.toUtc().toIso8601String(),
        'is_pinned': isPinned,
        'poll_id': pollId,
        'message_type': messageType.dbValue,
        'metadata': metadata,
        'reactions': reactions,
      };
}

// ── Repository ─────────────────────────────────────────────────────────────────

/// Pure Supabase data source for trip chat messages, polls, and votes.
/// All reads and writes go directly to `public.trip_messages`, `public.trip_polls`,
/// and `public.trip_poll_votes`. RLS policies enforce per-trip member access.
class ChatRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get _uid => _supabase.auth.currentUser?.id;
  bool get _isAuthenticated => _uid != null;

  // ════════════════════════════════════════════════════════════════
  // MESSAGES — READ
  // ════════════════════════════════════════════════════════════════

  /// Fetches the last [limit] messages for [tripId] from Supabase, oldest first.
  Future<List<ChatMessage>> getMessages(String tripId,
      {int limit = 100}) async {
    if (!_isAuthenticated) return [];

    try {
      final rows = await _supabase
          .from('trip_messages')
          .select()
          .eq('trip_id', tripId)
          .order('created_at', ascending: true)
          .limit(limit);

      return (rows as List<dynamic>)
          .map((r) => ChatMessage.fromRow(r as Map<String, dynamic>, _uid!))
          .toList();
    } on PostgrestException catch (e) {
      debugPrint('[ChatRepository] getMessages PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ChatRepository] getMessages error: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // MESSAGES — STREAM
  // ════════════════════════════════════════════════════════════════

  /// Real-time stream — emits the full sorted message list on every Supabase change.
  Stream<List<ChatMessage>> messagesStream(String tripId) {
    if (!_isAuthenticated) return const Stream.empty();

    return _supabase
        .from('trip_messages')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .order('created_at', ascending: true)
        .map((rows) => rows
            .cast<Map<String, dynamic>>()
            .map((r) => ChatMessage.fromRow(r, _uid ?? ''))
            .toList());
  }

  // ════════════════════════════════════════════════════════════════
  // MESSAGES — WRITE
  // ════════════════════════════════════════════════════════════════

  /// Sends a message by inserting directly into `trip_messages` in Supabase.
  /// Returns the confirmed ChatMessage on success, null if not authenticated.
  Future<ChatMessage?> sendMessage({
    required String tripId,
    required String text,
    required String senderName,
    ChatMessageType messageType = ChatMessageType.text,
    String? pollId,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isAuthenticated || text.trim().isEmpty) return null;
    final uid = _uid!;

    try {
      final insertData = <String, dynamic>{
        'trip_id': tripId,
        'user_id': uid,
        'sender_name': senderName,
        'content': text.trim(),
        'message_type': messageType.dbValue,
        'poll_id': pollId,
      };
      if (metadata != null) {
        insertData['metadata'] = metadata;
      }

      final row = await _supabase
          .from('trip_messages')
          .insert(insertData)
          .select()
          .single();

      return ChatMessage.fromRow(row, uid);
    } on PostgrestException catch (e) {
      debugPrint('[ChatRepository] sendMessage PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ChatRepository] sendMessage error: $e');
      rethrow;
    }
  }

  /// Toggles an emoji reaction from the current user on a message.
  Future<void> toggleReaction({
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    if (!_isAuthenticated) return;
    try {
      final msgRow = await _supabase
          .from('trip_messages')
          .select('reactions')
          .eq('id', messageId)
          .single();

      final rawReactions = (msgRow['reactions'] as Map<String, dynamic>?) ?? {};
      final reactions = <String, List<String>>{};
      rawReactions.forEach((k, v) {
        if (v is List) {
          reactions[k] = v.map((e) => e.toString()).toList();
        }
      });

      final currentUsers = reactions[emoji] ?? [];
      if (currentUsers.contains(userId)) {
        currentUsers.remove(userId);
        if (currentUsers.isEmpty) {
          reactions.remove(emoji);
        } else {
          reactions[emoji] = currentUsers;
        }
      } else {
        reactions[emoji] = [...currentUsers, userId];
      }

      await _supabase
          .from('trip_messages')
          .update({'reactions': reactions})
          .eq('id', messageId);
    } on PostgrestException catch (e) {
      debugPrint('[ChatRepository] toggleReaction PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ChatRepository] toggleReaction error: $e');
      rethrow;
    }
  }

  /// Deletes a message from Supabase — only if owned by the current user.
  Future<void> deleteMessage(String messageId) async {
    if (!_isAuthenticated) return;

    try {
      await _supabase
          .from('trip_messages')
          .delete()
          .eq('id', messageId)
          .eq('user_id', _uid!);
    } on PostgrestException catch (e) {
      debugPrint('[ChatRepository] deleteMessage PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ChatRepository] deleteMessage error: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // PINNED MESSAGES
  // ════════════════════════════════════════════════════════════════

  /// Toggles the pinned state of a message.
  Future<void> togglePinMessage(String messageId, bool isPinned) async {
    if (!_isAuthenticated) return;
    try {
      await _supabase
          .from('trip_messages')
          .update({'is_pinned': isPinned})
          .eq('id', messageId);
    } on PostgrestException catch (e) {
      debugPrint('[ChatRepository] togglePinMessage PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ChatRepository] togglePinMessage error: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // POLLS — CREATE
  // ════════════════════════════════════════════════════════════════

  /// Creates a new trip poll and posts a poll-type message in chat.
  /// Returns the created [TripPoll] or null if unauthenticated.
  Future<TripPoll?> createPoll({
    required String tripId,
    required String question,
    required List<String> optionTexts,
    required String category,
    required String creatorName,
    bool allowMultiple = false,
  }) async {
    if (!_isAuthenticated || question.trim().isEmpty) return null;
    final uid = _uid!;

    try {
      // Build options JSONB array with sequential IDs
      final options = optionTexts.asMap().entries.map((e) => {
            'id': '${e.key + 1}',
            'text': e.value.trim(),
          }).toList();

      final pollRow = await _supabase
          .from('trip_polls')
          .insert({
            'trip_id': tripId,
            'creator_id': uid,
            'creator_name': creatorName,
            'question': question.trim(),
            'options': options,
            'category': category,
            'allow_multiple': allowMultiple,
          })
          .select()
          .single();

      final pollId = pollRow['id'] as String;

      // Post a poll-type message in the chat stream
      await sendMessage(
        tripId: tripId,
        text: '📊 $creatorName created a poll: "$question"',
        senderName: creatorName,
        messageType: ChatMessageType.poll,
        pollId: pollId,
      );

      return TripPoll.fromRow(pollRow);
    } on PostgrestException catch (e) {
      debugPrint('[ChatRepository] createPoll PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ChatRepository] createPoll error: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // POLLS — VOTE
  // ════════════════════════════════════════════════════════════════

  /// Casts a vote for the given option. Uses upsert to handle toggle semantics.
  Future<void> castVote({
    required String pollId,
    required String tripId,
    required String optionId,
    required String voterName,
  }) async {
    if (!_isAuthenticated) return;
    try {
      await _supabase.from('trip_poll_votes').insert({
        'poll_id': pollId,
        'trip_id': tripId,
        'user_id': _uid!,
        'voter_name': voterName,
        'option_id': optionId,
      });
    } on PostgrestException catch (e) {
      // Unique constraint violation = already voted for this option
      if (e.code == '23505') {
        debugPrint('[ChatRepository] castVote: already voted for option $optionId');
        return;
      }
      debugPrint('[ChatRepository] castVote PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ChatRepository] castVote error: $e');
      rethrow;
    }
  }

  /// Removes a vote for the given option.
  Future<void> removeVote({
    required String pollId,
    required String optionId,
  }) async {
    if (!_isAuthenticated) return;
    try {
      await _supabase
          .from('trip_poll_votes')
          .delete()
          .eq('poll_id', pollId)
          .eq('user_id', _uid!)
          .eq('option_id', optionId);
    } on PostgrestException catch (e) {
      debugPrint('[ChatRepository] removeVote PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ChatRepository] removeVote error: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // POLLS — CLOSE & RESOLVE WINNER
  // ════════════════════════════════════════════════════════════════

  /// Closes a poll and optionally sets the winner option.
  Future<void> closePoll({
    required String pollId,
    String? winnerOptionId,
  }) async {
    if (!_isAuthenticated) return;
    try {
      await _supabase.from('trip_polls').update({
        'is_closed': true,
        'winner_option_id': winnerOptionId,
        'closed_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', pollId);
    } on PostgrestException catch (e) {
      debugPrint('[ChatRepository] closePoll PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ChatRepository] closePoll error: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // POLLS — READ & STREAM
  // ════════════════════════════════════════════════════════════════

  /// Fetches all polls for a trip with their votes.
  Future<List<TripPoll>> getPolls(String tripId) async {
    if (!_isAuthenticated) return [];
    try {
      final pollRows = await _supabase
          .from('trip_polls')
          .select()
          .eq('trip_id', tripId)
          .order('created_at', ascending: false);

      final voteRows = await _supabase
          .from('trip_poll_votes')
          .select()
          .eq('trip_id', tripId);

      final votesByPoll = <String, List<Map<String, dynamic>>>{};
      for (final v in (voteRows as List)) {
        final map = v as Map<String, dynamic>;
        final pid = map['poll_id']?.toString() ?? '';
        votesByPoll.putIfAbsent(pid, () => []).add(map);
      }

      return (pollRows as List)
          .map((r) {
            final map = r as Map<String, dynamic>;
            return TripPoll.fromRow(map, votes: votesByPoll[map['id']] ?? []);
          })
          .toList();
    } on PostgrestException catch (e) {
      debugPrint('[ChatRepository] getPolls PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ChatRepository] getPolls error: $e');
      rethrow;
    }
  }

  /// Real-time stream of all polls for a trip.
  Stream<List<Map<String, dynamic>>> pollsStream(String tripId) {
    if (!_isAuthenticated) return const Stream.empty();
    return _supabase
        .from('trip_polls')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .order('created_at', ascending: false);
  }

  /// Real-time stream of all votes for a given trip.
  Stream<List<Map<String, dynamic>>> pollVotesStream(String tripId) {
    if (!_isAuthenticated) return const Stream.empty();
    return _supabase
        .from('trip_poll_votes')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId);
  }

  /// Adds a new crowdsourced option to an existing open poll.
  Future<void> addPollOption({
    required String pollId,
    required String optionText,
  }) async {
    if (!_isAuthenticated || optionText.trim().isEmpty) return;
    try {
      final pollRow = await _supabase
          .from('trip_polls')
          .select('options')
          .eq('id', pollId)
          .single();

      final currentOpts = (pollRow['options'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final newId = '${currentOpts.length + 1}';
      currentOpts.add({'id': newId, 'text': optionText.trim()});

      await _supabase
          .from('trip_polls')
          .update({'options': currentOpts})
          .eq('id', pollId);
    } on PostgrestException catch (e) {
      debugPrint('[ChatRepository] addPollOption PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ChatRepository] addPollOption error: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // MEDIA UPLOAD
  // ════════════════════════════════════════════════════════════════

  /// Uploads a chat image to Supabase Storage and returns its public URL.
  Future<String?> uploadChatMedia({
    required String tripId,
    required String localFilePath,
  }) async {
    try {
      final file = File(localFilePath);
      if (!file.existsSync()) return null;

      final ext = localFilePath.split('.').last.toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '$tripId/chat_$timestamp.$ext';

      // Use avatars bucket (publicly readable) for reliable uploads
      await _supabase.storage.from('avatars').upload(
        storagePath,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      debugPrint('[ChatRepository] uploadChatMedia error: $e');
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // FCM TOKEN
  // ════════════════════════════════════════════════════════════════

  /// Stores the FCM device token for the current user.
  Future<void> updateFcmToken(String token) async {
    if (!_isAuthenticated) return;
    try {
      await _supabase
          .from('users')
          .update({'fcm_token': token})
          .eq('id', _uid!);
    } catch (e) {
      debugPrint('[ChatRepository] updateFcmToken error: $e');
    }
  }
}
