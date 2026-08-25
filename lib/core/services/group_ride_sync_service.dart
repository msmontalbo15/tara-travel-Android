/// group_ride_sync_service.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// Real-time synchronisation of group rider locations via Supabase Realtime.
///
/// Manages a Supabase Realtime channel subscription for `member_locations`
/// filtered by trip ID. Designed for Philippine infrastructure constraints:
///
/// • Catches WebSocket disconnect exceptions gracefully — no unhandled states.
/// • Exponential backoff reconnection (1s → 2s → 4s → … max 30s).
/// • While offline, retains the last known position of every rider with an
///   `isStale` flag so the UI can render a "Signal Lost" badge or reduced
///   opacity instead of removing the marker entirely.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'connectivity_service.dart';

/// A rider's live or last-known location state.
class RiderLocation {
  final String memberId;
  final String tripId;
  final double lat;
  final double lng;
  final double heading;
  final double speed;
  final bool isOnline;
  final DateTime lastUpdated;

  /// `true` when the last update is older than [_staleThreshold] or the
  /// WebSocket is currently disconnected.
  final bool isStale;

  const RiderLocation({
    required this.memberId,
    required this.tripId,
    required this.lat,
    required this.lng,
    required this.heading,
    required this.speed,
    required this.isOnline,
    required this.lastUpdated,
    required this.isStale,
  });

  RiderLocation copyWith({bool? isStale}) => RiderLocation(
        memberId: memberId,
        tripId: tripId,
        lat: lat,
        lng: lng,
        heading: heading,
        speed: speed,
        isOnline: isOnline,
        lastUpdated: lastUpdated,
        isStale: isStale ?? this.isStale,
      );
}

class GroupRideSyncService {
  GroupRideSyncService._();
  static final GroupRideSyncService instance = GroupRideSyncService._();

  // ── State ────────────────────────────────────────────────────────────────
  RealtimeChannel? _channel;
  String? _activeTripId;
  StreamSubscription<bool>? _connectivitySub;

  /// Map of memberId → last known [RiderLocation].
  final Map<String, RiderLocation> _riders = {};

  /// Broadcast stream of the full rider map on every update.
  final StreamController<Map<String, RiderLocation>> _ridersController =
      StreamController<Map<String, RiderLocation>>.broadcast();

  Stream<Map<String, RiderLocation>> get ridersStream =>
      _ridersController.stream;
  Map<String, RiderLocation> get currentRiders =>
      Map.unmodifiable(_riders);

  // ── Reconnection Backoff ───────────────────────────────────────────────
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  static const int _maxBackoffSeconds = 30;
  static const Duration _staleThreshold = Duration(seconds: 15);

  // ── Subscribe ──────────────────────────────────────────────────────────

  /// Subscribe to live location updates for [tripId].
  void subscribe(String tripId) {
    if (_activeTripId == tripId && _channel != null) return;
    unsubscribe();

    _activeTripId = tripId;
    _reconnectAttempts = 0;

    _connectChannel(tripId);

    // Monitor connectivity to mark riders stale on disconnect
    _connectivitySub = ConnectivityService.instance.onlineStream.listen((online) {
      if (!online) {
        _markAllStale();
      } else if (_channel == null) {
        _scheduleReconnect();
      }
    });
  }

  void _connectChannel(String tripId) {
    try {
      _channel = Supabase.instance.client.channel('ride:$tripId');

      _channel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'member_locations',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'trip_id',
              value: tripId,
            ),
            callback: (payload) {
              _onPayload(payload);
            },
          )
          .subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          _reconnectAttempts = 0;
          debugPrint('[GroupRideSync] Subscribed to ride:$tripId');
        } else if (status == RealtimeSubscribeStatus.closed) {
          debugPrint('[GroupRideSync] Channel closed for ride:$tripId');
          _markAllStale();
          _scheduleReconnect();
        }
      });
    } catch (e) {
      debugPrint('[GroupRideSync] Channel subscribe error: $e');
      _markAllStale();
      _scheduleReconnect();
    }
  }

  /// Gracefully unsubscribe.
  void unsubscribe() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _connectivitySub?.cancel();
    _connectivitySub = null;

    if (_channel != null) {
      try {
        Supabase.instance.client.removeChannel(_channel!);
      } catch (_) {}
      _channel = null;
    }

    _activeTripId = null;
    _riders.clear();
    _ridersController.add({});
  }

  // ── Payload Handler ────────────────────────────────────────────────────

  void _onPayload(PostgresChangePayload payload) {
    try {
      final record = payload.newRecord;
      if (record.isEmpty) return;

      final memberId = record['member_id'] as String?;
      if (memberId == null) return;

      final lastUpdated = DateTime.tryParse(
              record['last_updated']?.toString() ?? '') ??
          DateTime.now();

      final rider = RiderLocation(
        memberId: memberId,
        tripId: record['trip_id'] as String? ?? _activeTripId ?? '',
        lat: (record['latitude'] as num?)?.toDouble() ?? 0,
        lng: (record['longitude'] as num?)?.toDouble() ?? 0,
        heading: (record['heading'] as num?)?.toDouble() ?? 0,
        speed: (record['speed'] as num?)?.toDouble() ?? 0,
        isOnline: record['is_online'] as bool? ?? true,
        lastUpdated: lastUpdated,
        isStale: DateTime.now().difference(lastUpdated) > _staleThreshold,
      );

      _riders[memberId] = rider;
      _ridersController.add(Map.unmodifiable(_riders));
    } catch (e) {
      debugPrint('[GroupRideSync] Payload parse error: $e');
    }
  }

  // ── Stale Management ──────────────────────────────────────────────────

  void _markAllStale() {
    bool changed = false;
    for (final entry in _riders.entries) {
      if (!entry.value.isStale) {
        _riders[entry.key] = entry.value.copyWith(isStale: true);
        changed = true;
      }
    }
    if (changed) {
      _ridersController.add(Map.unmodifiable(_riders));
    }
  }

  // ── Exponential Backoff Reconnection ──────────────────────────────────

  void _scheduleReconnect() {
    if (_activeTripId == null) return;
    _reconnectTimer?.cancel();

    final delaySeconds = math.min(
      (1 << _reconnectAttempts).clamp(1, _maxBackoffSeconds),
      _maxBackoffSeconds,
    );
    _reconnectAttempts++;

    debugPrint(
        '[GroupRideSync] Reconnecting in ${delaySeconds}s (attempt $_reconnectAttempts)');

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      final tripId = _activeTripId;
      if (tripId == null) return;

      if (ConnectivityService.instance.cachedIsOnline) {
        _connectChannel(tripId);
      } else {
        _scheduleReconnect();
      }
    });
  }

  void dispose() {
    unsubscribe();
    _ridersController.close();
  }
}
