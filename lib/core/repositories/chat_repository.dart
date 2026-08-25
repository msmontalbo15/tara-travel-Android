import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

/// Pure Supabase data source for trip chat messages.
/// All reads and writes go directly to `public.trip_messages`.
/// RLS policies enforce per-trip member access.
class ChatRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get _uid => _supabase.auth.currentUser?.id;
  bool get _isAuthenticated => _uid != null;

  // ────────────────────────────────────────────────────────────────
  // READ
  // ────────────────────────────────────────────────────────────────

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

  // ────────────────────────────────────────────────────────────────
  // STREAM
  // ────────────────────────────────────────────────────────────────

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

  // ────────────────────────────────────────────────────────────────
  // WRITE
  // ────────────────────────────────────────────────────────────────

  /// Sends a message by inserting directly into `trip_messages` in Supabase.
  /// Returns the confirmed ChatMessage on success, null if not authenticated.
  Future<ChatMessage?> sendMessage({
    required String tripId,
    required String text,
    required String senderName,
  }) async {
    if (!_isAuthenticated || text.trim().isEmpty) return null;
    final uid = _uid!;

    try {
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

      return ChatMessage.fromRow(row, uid);
    } on PostgrestException catch (e) {
      debugPrint('[ChatRepository] sendMessage PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ChatRepository] sendMessage error: $e');
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
}
