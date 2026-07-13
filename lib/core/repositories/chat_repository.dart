import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
}

class ChatRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get _uid => _supabase.auth.currentUser?.id;
  bool get isOnline => _uid != null;

  /// Fetches the last [limit] messages for [tripId], oldest first.
  Future<List<ChatMessage>> getMessages(String tripId, {int limit = 100}) async {
    if (!isOnline) return [];
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
    } catch (e) {
      debugPrint('[ChatRepository] getMessages error: $e');
      return [];
    }
  }

  /// Real-time stream — emits the FULL sorted list on every change.
  Stream<List<ChatMessage>> messagesStream(String tripId) {
    if (!isOnline) return const Stream.empty();
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

  /// Sends a message; returns the saved row or null on failure.
  Future<ChatMessage?> sendMessage({
    required String tripId,
    required String text,
    required String senderName,
  }) async {
    if (!isOnline || text.trim().isEmpty) return null;
    try {
      final row = await _supabase
          .from('trip_messages')
          .insert({
            'trip_id': tripId,
            'user_id': _uid!,
            'sender_name': senderName,
            'content': text.trim(),
          })
          .select()
          .single();
      return ChatMessage.fromRow(row, _uid!);
    } catch (e) {
      debugPrint('[ChatRepository] sendMessage error: $e');
      return null;
    }
  }

  /// Deletes a message — only if owned by the current user.
  Future<void> deleteMessage(String messageId) async {
    if (!isOnline) return;
    try {
      await _supabase
          .from('trip_messages')
          .delete()
          .eq('id', messageId)
          .eq('user_id', _uid!);
    } catch (e) {
      debugPrint('[ChatRepository] deleteMessage error: $e');
    }
  }
}
