import 'package:flutter_riverpod/flutter_riverpod.dart';
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
