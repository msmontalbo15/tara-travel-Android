import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/friend_repository.dart';
import '../models/friend_model.dart';

final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  return FriendRepository();
});

/// Accepted friends list
final friendsProvider = FutureProvider<List<FriendModel>>((ref) async {
  final repo = ref.watch(friendRepositoryProvider);
  return repo.getFriends();
});

/// Realtime subscription that automatically refreshes friends on presence updates
final friendsRealtimePresenceProvider = StreamProvider.autoDispose<void>((ref) {
  final supabase = Supabase.instance.client;
  final currentUserId = supabase.auth.currentUser?.id;
  if (currentUserId == null) return const Stream.empty();

  final channel = supabase.channel('public:friends_presence_$currentUserId');

  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'users',
    callback: (payload) {
      ref.invalidate(friendsProvider);
    },
  );

  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'friends',
    callback: (payload) {
      ref.invalidate(friendsProvider);
      ref.invalidate(incomingRequestsProvider);
      ref.invalidate(outgoingRequestsProvider);
    },
  );

  channel.subscribe();

  ref.onDispose(() {
    supabase.removeChannel(channel);
  });

  return Stream.periodic(const Duration(seconds: 30), (_) {
    ref.invalidate(friendsProvider);
  });
});

/// Real-time currently online friends
final onlineFriendsProvider = Provider<List<FriendModel>>((ref) {
  final friends = ref.watch(friendsProvider).value ?? [];
  return friends.where((f) => f.isCurrentlyOnline).toList();
});

/// Real-time online friends count
final onlineFriendsCountProvider = Provider<int>((ref) {
  return ref.watch(onlineFriendsProvider).length;
});

/// Incoming pending friend requests directed to current user
final incomingRequestsProvider = FutureProvider<List<FriendModel>>((ref) async {
  final repo = ref.watch(friendRepositoryProvider);
  return repo.getIncomingRequests();
});

/// Outgoing pending friend requests sent by current user
final outgoingRequestsProvider = FutureProvider<List<FriendModel>>((ref) async {
  final repo = ref.watch(friendRepositoryProvider);
  return repo.getOutgoingRequests();
});

/// Badge count for pending incoming friend requests
final friendRequestsCountProvider = Provider<int>((ref) {
  final incoming = ref.watch(incomingRequestsProvider);
  return incoming.value?.length ?? 0;
});

/// Search users with annotated friendship status
final searchUsersProvider = FutureProvider.family<List<FriendModel>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final repo = ref.watch(friendRepositoryProvider);
  return repo.searchUsers(query);
});

/// Live lookup single user by ID / code / username
final lookupUserProvider = FutureProvider.family<FriendModel?, String>((ref, query) async {
  if (query.trim().isEmpty) return null;
  final repo = ref.watch(friendRepositoryProvider);
  return repo.lookupUser(query);
});
