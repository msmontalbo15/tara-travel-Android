import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/friend_model.dart';

/// Manages all friend/social graph operations against Supabase.
///
/// Schema alignment (000_master_schema.sql):
///   • public.friends  — reciprocal rows (user_id, friend_id, status)
///   • public.users    — includes is_online + last_seen for presence
///
/// Presence fields (is_online, last_seen) are now queried from users via
/// a JOIN in getIncomingRequests / getFriends to keep the join efficient.
class FriendRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns all accepted friends for the current user, with live presence
  /// data (is_online, last_seen) from public.users.
  Future<List<FriendModel>> getFriends() async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('friends')
          .select(
            'id, status, '
            'friendData:users!friend_id('
            '  id, display_name, email, avatar_url, is_online, last_seen'
            ')',
          )
          .eq('user_id', userId)
          .eq('status', 'accepted');

      return (response as List)
          .map((row) => FriendModel.fromMap(row, userId))
          .toList();
    } catch (e) {
      debugPrint('[FriendRepository] getFriends error: $e');
      return [];
    }
  }

  /// Returns incoming pending friend requests directed at the current user.
  Future<List<FriendModel>> getIncomingRequests() async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('friends')
          .select(
            'id, status, '
            'friendData:users!user_id('
            '  id, display_name, email, avatar_url, is_online, last_seen'
            ')',
          )
          .eq('friend_id', userId)
          .eq('status', 'pending');

      return (response as List)
          .map((row) => FriendModel.fromMap(row, userId))
          .toList();
    } catch (e) {
      debugPrint('[FriendRepository] getIncomingRequests error: $e');
      return [];
    }
  }

  /// Fuzzy search users by display_name or email (excludes current user and
  /// already-added friends).
  Future<List<FriendModel>> searchUsers(String query) async {
    final userId = currentUserId;
    if (userId == null || query.trim().isEmpty) return [];

    try {
      final response = await _supabase
          .from('users')
          .select('id, display_name, email, avatar_url, is_online, last_seen')
          .or(
            'display_name.ilike.%${query.trim()}%,'
            'email.ilike.%${query.trim()}%',
          )
          .neq('id', userId)
          .limit(20);

      return (response as List)
          .map((row) => FriendModel.fromMap(row, userId))
          .toList();
    } catch (e) {
      debugPrint('[FriendRepository] searchUsers error: $e');
      return [];
    }
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Sends a friend request: inserts reciprocal rows (A→B pending, B→A pending).
  Future<void> sendRequest(String friendId) async {
    final userId = currentUserId;
    if (userId == null) return;
    if (userId == friendId) {
      throw Exception('You cannot add yourself as a friend.');
    }

    try {
      // Reciprocal insert; ON CONFLICT DO NOTHING prevents duplicate key errors
      // if a request already exists in either direction.
      await _supabase.from('friends').upsert([
        {'user_id': userId,   'friend_id': friendId, 'status': 'pending'},
        {'user_id': friendId, 'friend_id': userId,   'status': 'pending'},
      ], onConflict: 'user_id,friend_id');
    } catch (e) {
      debugPrint('[FriendRepository] sendRequest error: $e');
      rethrow;
    }
  }

  /// Accepts a friend request: updates both reciprocal rows to 'accepted'.
  Future<void> acceptRequest(String requesterId) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      // Update the incoming row (requester → current user)
      await _supabase
          .from('friends')
          .update({'status': 'accepted', 'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('user_id', requesterId)
          .eq('friend_id', userId);

      // Update the reciprocal row (current user → requester)
      await _supabase
          .from('friends')
          .update({'status': 'accepted', 'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('user_id', userId)
          .eq('friend_id', requesterId);
    } catch (e) {
      debugPrint('[FriendRepository] acceptRequest error: $e');
      rethrow;
    }
  }

  /// Rejects / removes a friend: deletes both reciprocal rows.
  Future<void> rejectRequest(String friendId) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _supabase
          .from('friends')
          .delete()
          .eq('user_id', userId)
          .eq('friend_id', friendId);

      await _supabase
          .from('friends')
          .delete()
          .eq('user_id', friendId)
          .eq('friend_id', userId);
    } catch (e) {
      debugPrint('[FriendRepository] rejectRequest error: $e');
      rethrow;
    }
  }

  /// Looks up a user by UUID or display_name and sends them a friend request.
  /// Returns the matched user's display name on success.
  Future<String> addFriendByCode(String codeOrId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Must be logged in.');

    final input = codeOrId.trim();
    if (input.isEmpty) throw Exception('Please enter a valid ID or name.');
    if (input == userId) throw Exception('You cannot add yourself as a friend.');

    try {
      final List response = await _supabase
          .from('users')
          .select('id, display_name')
          .or('id.eq.$input,display_name.ilike.$input')
          .neq('id', userId)
          .limit(1);

      if (response.isEmpty) {
        throw Exception('No user found with that ID or name.');
      }

      final targetId   = response.first['id'] as String;
      final targetName = response.first['display_name'] as String? ?? 'User';

      await sendRequest(targetId);
      return targetName;
    } catch (e) {
      debugPrint('[FriendRepository] addFriendByCode error: $e');
      rethrow;
    }
  }

  /// Returns the current user's public profile for the QR-code share modal.
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      return await _supabase
          .from('users')
          .select('id, display_name, avatar_url, is_online')
          .eq('id', userId)
          .maybeSingle();
    } catch (e) {
      debugPrint('[FriendRepository] getCurrentUserProfile error: $e');
      return null;
    }
  }
}
