/// location_tracking_service.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// High-accuracy GPS stream service for group ride tracking.
///
/// Captures Latitude, Longitude, Heading, Speed, and Altitude from the device
/// GPS via [geolocator]. Syncs to Supabase PostGIS every 3 seconds.
///
/// Network resilience (critical for PH mountain/rural passes):
/// • Locally queues outgoing GPS pings when the network drops.
/// • Bulk-flushes the queue once a stable connection is re-established.
/// • Uses [ConnectivityService] to detect online/offline state.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'connectivity_service.dart';

/// A queued GPS ping awaiting network sync.
class _QueuedPing {
  final String tripId;
  final double lat;
  final double lng;
  final double heading;
  final double speed;
  final double altitude;
  final DateTime timestamp;

  const _QueuedPing({
    required this.tripId,
    required this.lat,
    required this.lng,
    required this.heading,
    required this.speed,
    required this.altitude,
    required this.timestamp,
  });
}

/// Snapshot of the device's current location telemetry.
class LocationSnapshot {
  final double lat;
  final double lng;
  final double heading;
  final double speed;
  final double altitude;
  final DateTime timestamp;

  const LocationSnapshot({
    required this.lat,
    required this.lng,
    required this.heading,
    required this.speed,
    required this.altitude,
    required this.timestamp,
  });
}

class LocationTrackingService {
  LocationTrackingService._();
  static final LocationTrackingService instance = LocationTrackingService._();

  // ── State ────────────────────────────────────────────────────────────────
  StreamSubscription<Position>? _positionSub;
  Timer? _syncTimer;
  String? _activeTripId;
  LocationSnapshot? _lastSnapshot;
  bool _isTracking = false;

  /// Broadcast controller that emits the latest [LocationSnapshot].
  final StreamController<LocationSnapshot> _snapshotController =
      StreamController<LocationSnapshot>.broadcast();
  Stream<LocationSnapshot> get snapshotStream => _snapshotController.stream;
  LocationSnapshot? get lastSnapshot => _lastSnapshot;
  bool get isTracking => _isTracking;

  // ── Offline Queue ───────────────────────────────────────────────────────
  final Queue<_QueuedPing> _offlineQueue = Queue<_QueuedPing>();
  static const int _maxQueueSize = 500;

  // ── Sync Interval ───────────────────────────────────────────────────────
  static const Duration _syncInterval = Duration(seconds: 3);

  // ── Start / Stop ────────────────────────────────────────────────────────

  /// Begin high-accuracy GPS tracking for [tripId].
  Future<void> startTracking(String tripId) async {
    if (_isTracking && _activeTripId == tripId) return;
    await stopTracking();

    _activeTripId = tripId;
    _isTracking = true;

    // Ensure permissions are granted
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      debugPrint('[LocationTracking] Permission permanently denied');
      _isTracking = false;
      return;
    }

    // Subscribe to GPS position stream
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // metres — avoid noisy stationary pings
      ),
    ).listen(_onPosition, onError: (e) {
      debugPrint('[LocationTracking] GPS stream error: $e');
    });

    // Periodic sync to Supabase
    _syncTimer = Timer.periodic(_syncInterval, (_) => _syncToSupabase());
  }

  /// Stop GPS tracking and flush any remaining queued pings.
  Future<void> stopTracking() async {
    _isTracking = false;
    _activeTripId = null;
    await _positionSub?.cancel();
    _positionSub = null;
    _syncTimer?.cancel();
    _syncTimer = null;
    await _flushQueue();
  }

  // ── GPS Callback ────────────────────────────────────────────────────────

  void _onPosition(Position pos) {
    final snapshot = LocationSnapshot(
      lat: pos.latitude,
      lng: pos.longitude,
      heading: pos.heading,
      speed: pos.speed,
      altitude: pos.altitude,
      timestamp: DateTime.now(),
    );
    _lastSnapshot = snapshot;
    _snapshotController.add(snapshot);
  }

  // ── Supabase Sync ──────────────────────────────────────────────────────

  Future<void> _syncToSupabase() async {
    final snapshot = _lastSnapshot;
    final tripId = _activeTripId;
    if (snapshot == null || tripId == null) return;

    final online = ConnectivityService.instance.cachedIsOnline;
    if (!online) {
      _enqueue(tripId, snapshot);
      return;
    }

    // Flush offline queue first (order matters for trajectory accuracy)
    await _flushQueue();

    // Then push the current live position
    try {
      await Supabase.instance.client.rpc('update_member_location', params: {
        'p_trip_id': tripId,
        'p_lat': snapshot.lat,
        'p_lng': snapshot.lng,
        'p_heading': snapshot.heading,
        'p_speed': snapshot.speed,
        'p_altitude': snapshot.altitude,
      });
    } catch (e) {
      debugPrint('[LocationTracking] Sync RPC error: $e');
      _enqueue(tripId, snapshot);
    }
  }

  // ── Offline Queue Management ──────────────────────────────────────────

  void _enqueue(String tripId, LocationSnapshot snapshot) {
    if (_offlineQueue.length >= _maxQueueSize) {
      _offlineQueue.removeFirst(); // FIFO eviction
    }
    _offlineQueue.add(_QueuedPing(
      tripId: tripId,
      lat: snapshot.lat,
      lng: snapshot.lng,
      heading: snapshot.heading,
      speed: snapshot.speed,
      altitude: snapshot.altitude,
      timestamp: snapshot.timestamp,
    ));
  }

  /// Bulk-flush queued pings to Supabase once connection is restored.
  Future<void> _flushQueue() async {
    if (_offlineQueue.isEmpty) return;

    final online = ConnectivityService.instance.cachedIsOnline;
    if (!online) return;

    final batch = List<_QueuedPing>.from(_offlineQueue);
    _offlineQueue.clear();

    for (final ping in batch) {
      try {
        await Supabase.instance.client.rpc('update_member_location', params: {
          'p_trip_id': ping.tripId,
          'p_lat': ping.lat,
          'p_lng': ping.lng,
          'p_heading': ping.heading,
          'p_speed': ping.speed,
          'p_altitude': ping.altitude,
        });
      } catch (e) {
        // Re-queue failed pings at the front so ordering is preserved
        _offlineQueue.addFirst(ping);
        debugPrint('[LocationTracking] Queue flush error, re-queued: $e');
        break; // Stop flushing on first failure to avoid thundering herd
      }
    }
  }

  /// Dispose resources on app shutdown.
  void dispose() {
    stopTracking();
    _snapshotController.close();
  }
}
