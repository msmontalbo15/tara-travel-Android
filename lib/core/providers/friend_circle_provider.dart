import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/friend_circle_model.dart';
import '../repositories/friend_circle_repository.dart';
import 'auth_provider.dart';

final friendCircleRepositoryProvider = Provider<FriendCircleRepository>((ref) {
  return FriendCircleRepository();
});

class FriendCirclesNotifier extends AsyncNotifier<List<FriendCircle>> {
  @override
  Future<List<FriendCircle>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    final repo = ref.watch(friendCircleRepositoryProvider);
    return repo.getCircles(user.id);
  }

  Future<void> addOrUpdateCircle(FriendCircle circle) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final repo = ref.read(friendCircleRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await repo.upsertCircle(user.id, circle);
    });
  }

  Future<void> removeCircle(String circleId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final repo = ref.read(friendCircleRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await repo.deleteCircle(user.id, circleId);
    });
  }
}

final friendCirclesProvider =
    AsyncNotifierProvider<FriendCirclesNotifier, List<FriendCircle>>(() {
  return FriendCirclesNotifier();
});
