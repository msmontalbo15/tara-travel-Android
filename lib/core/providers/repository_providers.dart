// Export gateway Dio provider — re-exported for convenience so consumers
// only need to import repository_providers.dart.
export '../middleware/gateway_dio_client.dart' show gatewayDioProvider;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../repositories/trip_repository.dart';
import '../repositories/expense_repository.dart';
import '../repositories/itinerary_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/packing_repository.dart';
import '../repositories/personal_allowance_repository.dart';
import '../services/connectivity_service.dart';

// ── SERVICES ─────────────────────────────────────────────────────────────────

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService.instance;
});

// ── REPOSITORIES ─────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository();
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});

final itineraryRepositoryProvider = Provider<ItineraryRepository>((ref) {
  return ItineraryRepository();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final packingRepositoryProvider = Provider<PackingRepository>((ref) {
  return PackingRepository();
});

final personalAllowanceRepositoryProvider = Provider<PersonalAllowanceRepository>((ref) {
  return PersonalAllowanceRepository();
});

