import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';

/// Reactive provider exposing device internet connectivity state (`true` = online, `false` = offline).
/// Backed by [ConnectivityService.instance.onlineStream] and seeded with [cachedIsOnline].
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final service = ConnectivityService.instance;
  // Emit initial cached status immediately
  yield service.cachedIsOnline;
  // Yield subsequent changes
  yield* service.onlineStream;
});
