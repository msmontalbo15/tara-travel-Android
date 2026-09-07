import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';

/// isOnlineProvider
/// ─────────────────────────────────────────────────────────────────────────────
/// Reactive boolean provider that reflects real internet connectivity.
/// Seeded with the synchronous cached state and updates via the socket stream.
/// ─────────────────────────────────────────────────────────────────────────────
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final service = ConnectivityService.instance;
  // Emit initial cached state immediately
  yield service.cachedIsOnline;
  // Yield subsequent network changes
  yield* service.onlineStream;
});
