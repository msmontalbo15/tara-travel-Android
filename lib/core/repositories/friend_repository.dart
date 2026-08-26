import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/friend_model.dart';

/// Manages all friend/social graph operations against Supabase.
///
/// Schema alignment (000_master_schema.sql):
///   • public.friends  — (user_id, friend_id, status)
///   • public.users    — includes is_online + last_seen for presence
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
          .map((row) => FriendModel.fromMap(row, userId, overrideStatus: FriendStatus.accepted))
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
          .map((row) => FriendModel.fromMap(row, userId, overrideStatus: FriendStatus.incoming))
          .toList();
    } catch (e) {
      debugPrint('[FriendRepository] getIncomingRequests error: $e');
      return [];
    }
  }

  /// Returns outgoing pending friend requests sent by the current user.
  Future<List<FriendModel>> getOutgoingRequests() async {
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
          .eq('status', 'pending');

      return (response as List)
          .map((row) => FriendModel.fromMap(row, userId, overrideStatus: FriendStatus.pending))
          .toList();
    } catch (e) {
      debugPrint('[FriendRepository] getOutgoingRequests error: $e');
      return [];
    }
  }

  /// Fuzzy search users by display_name, email, or exact ID, annotated with
  /// their exact friendship relationship to the current user.
  Future<List<FriendModel>> searchUsers(String query) async {
    final userId = currentUserId;
    final cleanQuery = query.trim();
    if (userId == null || cleanQuery.isEmpty) return [];

    try {
      // 1. Fetch matching users
      final userFilter = cleanQuery.contains('-') && cleanQuery.length >= 32
          ? 'id.eq.$cleanQuery,display_name.ilike.%$cleanQuery%,email.ilike.%$cleanQuery%'
          : 'display_name.ilike.%$cleanQuery%,email.ilike.%$cleanQuery%';

      final userRows = await _supabase
          .from('users')
          .select('id, display_name, email, avatar_url, is_online, last_seen')
          .or(userFilter)
          .neq('id', userId)
          .limit(20);

      final List userList = userRows as List;
      if (userList.isEmpty) return [];

      // 2. Fetch existing relations for the current user to cross-reference
      final relationRows = await _supabase
          .from('friends')
          .select('user_id, friend_id, status')
          .or('user_id.eq.$userId,friend_id.eq.$userId');

      final relationList = relationRows as List;
      final statusMap = <String, FriendStatus>{};

      for (final rel in relationList) {
        final relUserId = rel['user_id'] as String;
        final relFriendId = rel['friend_id'] as String;
        final relStatus = (rel['status'] as String?)?.toLowerCase();

        if (relStatus == 'accepted') {
          final otherId = relUserId == userId ? relFriendId : relUserId;
          statusMap[otherId] = FriendStatus.accepted;
        } else if (relStatus == 'pending') {
          if (relUserId == userId) {
            // Outgoing request sent by me
            statusMap[relFriendId] = FriendStatus.pending;
          } else if (relFriendId == userId) {
            // Incoming request sent to me
            statusMap[relUserId] = FriendStatus.incoming;
          }
        }
      }

      return userList.map((row) {
        final targetId = row['id'] as String;
        final relStatus = statusMap[targetId] ?? FriendStatus.none;
        return FriendModel.fromMap(
          row as Map<String, dynamic>,
          userId,
          overrideStatus: relStatus,
        );
      }).toList();
    } catch (e) {
      debugPrint('[FriendRepository] searchUsers error: $e');
      return [];
    }
  }

  /// Look up a single user by exact ID, display name, or email with relationship status.
  Future<FriendModel?> lookupUser(String codeOrIdOrName) async {
    final userId = currentUserId;
    final input = codeOrIdOrName.trim();
    if (userId == null || input.isEmpty || input == userId) return null;

    try {
      final isUuid = input.contains('-') && input.length >= 32;
      final filter = isUuid
          ? 'id.eq.$input'
          : 'display_name.ilike.$input,email.ilike.$input';

      final List userRows = await _supabase
          .from('users')
          .select('id, display_name, email, avatar_url, is_online, last_seen')
          .or(filter)
          .neq('id', userId)
          .limit(1);

      if (userRows.isEmpty) return null;

      final targetUser = userRows.first as Map<String, dynamic>;
      final targetId = targetUser['id'] as String;

      // Check relation
      final relations = await _supabase
          .from('friends')
          .select('user_id, friend_id, status')
          .or('and(user_id.eq.$userId,friend_id.eq.$targetId),and(user_id.eq.$targetId,friend_id.eq.$userId)');

      FriendStatus status = FriendStatus.none;
      for (final rel in (relations as List)) {
        final relStatus = (rel['status'] as String?)?.toLowerCase();
        if (relStatus == 'accepted') {
          status = FriendStatus.accepted;
          break;
        } else if (relStatus == 'pending') {
          if (rel['user_id'] == userId) {
            status = FriendStatus.pending;
          } else {
            status = FriendStatus.incoming;
          }
        }
      }

      return FriendModel.fromMap(targetUser, userId, overrideStatus: status);
    } catch (e) {
      debugPrint('[FriendRepository] lookupUser error: $e');
      return null;
    }
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Sends a friend request: inserts pending directional row (current user → friend).
  Future<void> sendRequest(String friendId) async {
    final userId = currentUserId;
    if (userId == null) return;
    if (userId == friendId) {
      throw Exception('You cannot add yourself as a friend.');
    }

    try {
      // Upsert directional pending request
      await _supabase.from('friends').upsert(
        {
          'user_id': userId,
          'friend_id': friendId,
          'status': 'pending',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id,friend_id',
      );
    } catch (e) {
      debugPrint('[FriendRepository] sendRequest error: $e');
      rethrow;
    }
  }

  /// Accepts an incoming friend request: updates the requester's row to 'accepted'
  /// and creates the reciprocal row.
  Future<void> acceptRequest(String requesterId) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final now = DateTime.now().toUtc().toIso8601String();

      // 1. Update the incoming row (requester → current user)
      await _supabase
          .from('friends')
          .update({'status': 'accepted', 'updated_at': now})
          .eq('user_id', requesterId)
          .eq('friend_id', userId);

      // 2. Upsert the reciprocal row (current user → requester)
      await _supabase.from('friends').upsert(
        {
          'user_id': userId,
          'friend_id': requesterId,
          'status': 'accepted',
          'updated_at': now,
        },
        onConflict: 'user_id,friend_id',
      );
    } catch (e) {
      debugPrint('[FriendRepository] acceptRequest error: $e');
      rethrow;
    }
  }

  /// Rejects / cancels a request or removes an existing friend (deletes both rows).
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

  /// Alias for cancelling a sent request.
  Future<void> cancelRequest(String friendId) => rejectRequest(friendId);

  /// Alias for removing an accepted friend.
  Future<void> removeFriend(String friendId) => rejectRequest(friendId);

  /// Looks up a user by UUID or display_name and sends them a friend request.
  /// Returns the matched user's display name on success.
  Future<String> addFriendByCode(String codeOrId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Must be logged in.');

    final input = codeOrId.trim();
    if (input.isEmpty) throw Exception('Please enter a valid ID or name.');
    if (input == userId) throw Exception('You cannot add yourself as a friend.');

    try {
      final friend = await lookupUser(input);
      if (friend == null) {
        throw Exception('No user found with that ID, username, or email.');
      }

      if (friend.status == FriendStatus.accepted) {
        throw Exception('${friend.name} is already in your friends list.');
      } else if (friend.status == FriendStatus.pending) {
        throw Exception('A friend request has already been sent to ${friend.name}.');
      } else if (friend.status == FriendStatus.incoming) {
        // They already sent you a request! Auto-accept it!
        await acceptRequest(friend.id);
        return '${friend.name} (Request accepted!)';
      }

      await sendRequest(friend.id);
      return friend.name;
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
          .select('id, display_name, email, avatar_url, is_online')
          .eq('id', userId)
          .maybeSingle();
    } catch (e) {
      debugPrint('[FriendRepository] getCurrentUserProfile error: $e');
      return null;
    }
  }
}
