import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sembast/sembast.dart';
import '../services/database_service.dart';
import '../services/session_cache_service.dart';

// ── Model ──────────────────────────────────────────────────────────────────────

class ChatMessage {
  final String id;
  final String tripId;
  final String userId;
  final String senderName;
  final String text;
  final DateTime createdAt;
  final bool isMe;

  const ChatMessage({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.senderName,
    required this.text,
    required this.createdAt,
    this.isMe = false,
  });

  String get initials {
    final parts = senderName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return senderName.isNotEmpty ? senderName[0].toUpperCase() : '?';
  }

  factory ChatMessage.fromRow(
    Map<String, dynamic> row,
    String currentUserId,
  ) {
    final name = (row['sender_name'] as String?)?.trim() ?? 'Unknown';
    return ChatMessage(
      id: row['id'] as String,
      tripId: row['trip_id'] as String,
      userId: row['user_id'] as String,
      senderName: name,
      text: row['content'] as String? ?? '',
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      isMe: (row['user_id'] as String) == currentUserId,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'trip_id': tripId,
        'user_id': userId,
        'sender_name': senderName,
        'content': text,
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}

// ── Repository ─────────────────────────────────────────────────────────────────

/// Maximum number of messages kept in the local session cache per trip.
const int _kCacheLimit = 100;

class ChatRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DatabaseService _db = DatabaseService.instance;
  final SessionCacheService _cache = SessionCacheService.instance;

  String? get _uid => _supabase.auth.currentUser?.id;
  bool get _isAuthenticated => _uid != null;

  StoreRef<String, Map<String, dynamic>> get _store =>
      _db.getStore(DatabaseService.chatStore);

  // ────────────────────────────────────────────────────────────────
  // READ
  // ────────────────────────────────────────────────────────────────

  /// Fetches the last [limit] messages for [tripId], oldest first.
  ///
  /// Strategy: try Supabase → write-through to Sembast → return.
  /// On network failure: return from local Sembast cache (last [_kCacheLimit]).
  Future<List<ChatMessage>> getMessages(String tripId,
      {int limit = _kCacheLimit}) async {
    if (!_isAuthenticated) return _loadLocalMessages(tripId, limit: limit);

    try {
      final rows = await _supabase
          .from('trip_messages')
          .select()
          .eq('trip_id', tripId)
          .order('created_at', ascending: true)
          .limit(limit);

      final messages = (rows as List<dynamic>)
          .map((r) => ChatMessage.fromRow(r as Map<String, dynamic>, _uid!))
          .toList();

      // Write-through cache — evict old records for this trip first
      await _writeThroughCache(tripId, messages);
      await _cache.stamp(DatabaseService.chatStore);

      return messages;
    } catch (e) {
      debugPrint('[ChatRepository] getMessages error: $e — serving cache');
      return _loadLocalMessages(tripId, limit: limit);
    }
  }

  /// Loads cached messages from Sembast for [tripId].
  Future<List<ChatMessage>> _loadLocalMessages(String tripId,
      {int limit = _kCacheLimit}) async {
    try {
      final db = await _db.database;
      final snapshots = await _store.find(
        db,
        finder: Finder(
          filter: Filter.equals('trip_id', tripId),
          sortOrders: [SortOrder('created_at')],
          limit: limit,
        ),
      );
      final uid = _uid ?? '';
      return snapshots
          .map((s) => ChatMessage(
                id: s.key,
                tripId: s.value['trip_id'] as String? ?? tripId,
                userId: s.value['user_id'] as String? ?? '',
                senderName: s.value['sender_name'] as String? ?? 'Unknown',
                text: s.value['content'] as String? ?? '',
                createdAt: DateTime.tryParse(
                            s.value['created_at'] as String? ?? '') ??
                        DateTime.now(),
                isMe: (s.value['user_id'] as String?) == uid,
              ))
          .toList();
    } catch (e) {
      debugPrint('[ChatRepository] _loadLocalMessages error: $e');
      return [];
    }
  }

  /// Persists [messages] to Sembast, replacing any existing records for this trip.
  Future<void> _writeThroughCache(
      String tripId, List<ChatMessage> messages) async {
    try {
      final db = await _db.database;
      await db.transaction((txn) async {
        // Delete all cached messages for this trip first to avoid stale entries
        final existing = await _store.find(
          txn,
          finder: Finder(filter: Filter.equals('trip_id', tripId)),
        );
        for (final snap in existing) {
          await _store.record(snap.key).delete(txn);
        }
        // Write fresh set (bounded by _kCacheLimit)
        final toCache =
            messages.length > _kCacheLimit ? messages.sublist(messages.length - _kCacheLimit) : messages;
        for (final msg in toCache) {
          await _store.record(msg.id).put(txn, msg.toMap());
        }
      });
    } catch (e) {
      debugPrint('[ChatRepository] _writeThroughCache error: $e');
    }
  }

  // ────────────────────────────────────────────────────────────────
  // STREAM
  // ────────────────────────────────────────────────────────────────

  /// Real-time stream — emits the FULL sorted list on every Supabase change.
  /// Falls back to a one-shot local stream when not authenticated.
  Stream<List<ChatMessage>> messagesStream(String tripId) {
    if (!_isAuthenticated) {
      return Stream.fromFuture(_loadLocalMessages(tripId));
    }
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

  // ────────────────────────────────────────────────────────────────
  // WRITE
  // ────────────────────────────────────────────────────────────────

  /// Sends a message; returns the saved row or null on failure.
  ///
  /// Optimistic local write is performed first for instant UI feedback.
  /// On Supabase success the local record is updated with the real UUID.
  Future<ChatMessage?> sendMessage({
    required String tripId,
    required String text,
    required String senderName,
  }) async {
    if (!_isAuthenticated || text.trim().isEmpty) return null;
    final uid = _uid!;

    // Optimistic local write with a temporary ID
    final tempId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final optimistic = ChatMessage(
      id: tempId,
      tripId: tripId,
      userId: uid,
      senderName: senderName,
      text: text.trim(),
      createdAt: now,
      isMe: true,
    );

    try {
      final db = await _db.database;
      await _store.record(tempId).put(db, optimistic.toMap());

      final row = await _supabase
          .from('trip_messages')
          .insert({
            'trip_id': tripId,
            'user_id': uid,
            'sender_name': senderName,
            'content': text.trim(),
          })
          .select()
          .single();

      final confirmed = ChatMessage.fromRow(row, uid);

      // Replace temp record with confirmed one
      await db.transaction((txn) async {
        await _store.record(tempId).delete(txn);
        await _store.record(confirmed.id).put(txn, confirmed.toMap());
      });

      return confirmed;
    } catch (e) {
      debugPrint('[ChatRepository] sendMessage error: $e');
      // Return the optimistic message so the UI reflects it even on error
      return optimistic;
    }
  }

  /// Deletes a message — only if owned by the current user.
  Future<void> deleteMessage(String messageId) async {
    if (!_isAuthenticated) return;

    // Local delete first for instant UI response
    try {
      final db = await _db.database;
      await _store.record(messageId).delete(db);
    } catch (e) {
      debugPrint('[ChatRepository] local deleteMessage error: $e');
    }

    // Remote delete
    try {
      await _supabase
          .from('trip_messages')
          .delete()
          .eq('id', messageId)
          .eq('user_id', _uid!);
    } catch (e) {
      debugPrint('[ChatRepository] remote deleteMessage error: $e');
    }
  }
}
