import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/friend_repository.dart';
import '../models/friend_model.dart';

final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  return FriendRepository();
});

final friendsProvider = FutureProvider<List<FriendModel>>((ref) async {
  final repo = ref.watch(friendRepositoryProvider);
  return repo.getFriends();
});

final searchUsersProvider = FutureProvider.family<List<FriendModel>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final repo = ref.watch(friendRepositoryProvider);
  return repo.searchUsers(query);
});
