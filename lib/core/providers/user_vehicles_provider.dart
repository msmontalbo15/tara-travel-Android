import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_vehicle_model.dart';
import '../repositories/user_vehicles_repository.dart';
import 'auth_provider.dart';

final userVehiclesRepositoryProvider = Provider<UserVehiclesRepository>((ref) {
  return UserVehiclesRepository();
});

class UserVehiclesNotifier extends AsyncNotifier<List<UserVehicle>> {
  @override
  Future<List<UserVehicle>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    final repo = ref.watch(userVehiclesRepositoryProvider);
    return repo.getVehicles(user.id);
  }

  Future<void> addOrUpdateVehicle(UserVehicle vehicle) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final repo = ref.read(userVehiclesRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await repo.upsertVehicle(user.id, vehicle);
    });
  }

  Future<void> removeVehicle(String vehicleId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final repo = ref.read(userVehiclesRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await repo.deleteVehicle(user.id, vehicleId);
    });
  }
}

final userVehiclesProvider =
    AsyncNotifierProvider<UserVehiclesNotifier, List<UserVehicle>>(() {
  return UserVehiclesNotifier();
});

final defaultUserVehicleProvider = Provider<UserVehicle?>((ref) {
  final vehiclesAsync = ref.watch(userVehiclesProvider);
  return vehiclesAsync.maybeWhen(
    data: (list) {
      if (list.isEmpty) return null;
      return list.firstWhere((v) => v.isDefault, orElse: () => list.first);
    },
    orElse: () => null,
  );
});
