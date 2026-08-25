/// group_tracking_provider.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// Riverpod providers bridging [LocationTrackingService] (outgoing GPS) and
/// [GroupRideSyncService] (incoming rider positions) for the map UI layer.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/location_tracking_service.dart';
import '../services/group_ride_sync_service.dart';

// ── Own location snapshot stream ─────────────────────────────────────────────

final ownLocationProvider = StreamProvider<LocationSnapshot>((ref) {
  return LocationTrackingService.instance.snapshotStream;
});

// ── Group rider locations stream (keyed by trip ID) ──────────────────────────

final groupRidersProvider =
    StreamProvider.family<Map<String, RiderLocation>, String>((ref, tripId) {
  // Ensure subscription is active for this trip
  GroupRideSyncService.instance.subscribe(tripId);
  ref.onDispose(() {
    GroupRideSyncService.instance.unsubscribe();
  });
  return GroupRideSyncService.instance.ridersStream;
});

// ── Tracking active state notifier ──────────────────────────────────────────

class TrackingActiveNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setTracking(bool active) => state = active;
}

final trackingActiveProvider =
    NotifierProvider<TrackingActiveNotifier, bool>(TrackingActiveNotifier.new);

/// Call this to begin broadcasting the device's GPS to a specific trip.
Future<void> startGroupTracking(String tripId) async {
  await LocationTrackingService.instance.startTracking(tripId);
  GroupRideSyncService.instance.subscribe(tripId);
}

/// Call this to stop all tracking and unsubscribe from the realtime channel.
Future<void> stopGroupTracking() async {
  await LocationTrackingService.instance.stopTracking();
  GroupRideSyncService.instance.unsubscribe();
}
