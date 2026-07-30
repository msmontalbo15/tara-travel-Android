import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/friend_model.dart';

class FriendRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  Future<List<FriendModel>> getFriends() async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      // Assuming a `friends` table with user_id, friend_id, and status
      // And a foreign key from friend_id to users.id
      final response = await _supabase
          .from('friends')
          .select('*, friendData:users!friend_id(id, display_name, email, avatar_url, is_online, last_seen)')
          .eq('user_id', userId);

      return (response as List)
          .map((row) => FriendModel.fromMap(row, userId))
          .toList();
    } catch (e) {
      debugPrint('[FriendRepository] getFriends error: $e');
      return [];
    }
  }

  Future<List<FriendModel>> searchUsers(String query) async {
    final userId = currentUserId;
    if (userId == null || query.trim().isEmpty) return [];

    try {
      final response = await _supabase
          .from('users')
          .select('id, display_name, email, avatar_url')
          .or('display_name.ilike.%${query.trim()}%,email.ilike.%${query.trim()}%')
          .neq('id', userId)
          .limit(20);

      return (response as List).map((row) {
        return FriendModel.fromMap(row, userId);
      }).toList();
    } catch (e) {
      debugPrint('[FriendRepository] searchUsers error: $e');
      return [];
    }
  }

  Future<void> sendRequest(String friendId) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _supabase.from('friends').insert({
        'user_id': userId,
        'friend_id': friendId,
        'status': 'pending',
      });
      // Also insert reciprocal request if needed depending on DB design
      await _supabase.from('friends').insert({
        'user_id': friendId,
        'friend_id': userId,
        'status': 'pending',
      });
    } catch (e) {
      debugPrint('[FriendRepository] sendRequest error: $e');
    }
  }

  Future<void> acceptRequest(String friendId) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _supabase
          .from('friends')
          .update({'status': 'accepted'})
          .eq('user_id', userId)
          .eq('friend_id', friendId);
          
      await _supabase
          .from('friends')
          .update({'status': 'accepted'})
          .eq('user_id', friendId)
          .eq('friend_id', userId);
    } catch (e) {
      debugPrint('[FriendRepository] acceptRequest error: $e');
    }
  }

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
    }
  }

  /// Looks up a user by their UUID or display name and sends a friend request.
  /// Returns the matched user's name on success, throws on failure.
  Future<String> addFriendByCode(String codeOrId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Must be logged in.');

    final input = codeOrId.trim();
    if (input.isEmpty) throw Exception('Please enter a valid ID or name.');
    if (input == userId) throw Exception('You cannot add yourself as a friend.');

    try {
      // Try exact UUID match first, then fall back to display_name match
      final List response = await _supabase
          .from('users')
          .select('id, display_name')
          .or('id.eq.$input,display_name.ilike.$input')
          .neq('id', userId)
          .limit(1);

      if (response.isEmpty) {
        throw Exception('No user found with that ID or name.');
      }

      final targetId = response.first['id'] as String;
      final targetName = response.first['display_name'] as String? ?? 'User';

      await sendRequest(targetId);
      return targetName;
    } catch (e) {
      debugPrint('[FriendRepository] addFriendByCode error: $e');
      rethrow;
    }
  }

  /// Returns the current user's profile for display in the QR code modal.
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('users')
          .select('id, display_name, avatar_url')
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('[FriendRepository] getCurrentUserProfile error: $e');
      return null;
    }
  }
}
