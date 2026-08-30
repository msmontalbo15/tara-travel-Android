// location_broadcast_service.dart
// ─────────────────────────────────────────────────────────────────────────────
// Real-Time Ephemeral Location Broadcasting & Peer Telemetry Engine.
//
// Uses Supabase Realtime Ephemeral Broadcast channels (`trip:location:{trip_id}`)
// for sub-150ms peer-to-peer telemetry streaming without database disk I/O.
//
// Features:
// • Adaptive speed-based GPS sampling (Stationary 60s/25m, Walking 15s/10m, Driving 5s/30m)
// • Approximate location fuzzing (~500m privacy bubble)
// • Ghost Mode broadcast suppression & duration timers
// • Emergency SOS Panic Beacon real-time priority broadcasting
// • Periodic PostGIS checkpoint sync to `member_locations`
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/member_model.dart' hide MemberStatus;
import '../../features/navigation/models/navigation_models.dart';
import 'connectivity_service.dart';

class LocationBroadcastService {
  LocationBroadcastService._();
  static final LocationBroadcastService instance = LocationBroadcastService._();

  // ── State ──────────────────────────────────────────────────────────────────
  RealtimeChannel? _broadcastChannel;
  String? _activeTripId;
  StreamSubscription<Position>? _gpsSubscription;
  StreamSubscription<bool>? _connectivitySub;
  Timer? _adaptiveTimer;
  Timer? _checkpointTimer;

  Position? _lastGpsPosition;
  DateTime? _lastBroadcastTime;
  Position? _lastBroadcastPosition;

  // Local user metadata
  String? _userId;
  String? _userName;
  String? _userInitials;
  int? _userColorValue;
  final int _batteryLevel = 92;

  // Privacy & Battery settings
  LocationPrivacyMode _privacyMode = LocationPrivacyMode.exact;
  DateTime? _ghostUntil;
  bool _isBatterySaver = false;

  // Local GPS stream
  final StreamController<Position> _myGpsStreamController =
      StreamController<Position>.broadcast();

  // Peer telemetry state: memberId -> NavMember
  final Map<String, NavMember> _peerMembers = {};
  final StreamController<Map<String, NavMember>> _peerStreamController =
      StreamController<Map<String, NavMember>>.broadcast();

  // SOS Beacon stream
  final StreamController<SosBeacon> _sosStreamController =
      StreamController<SosBeacon>.broadcast();

  Stream<Position> get myGpsStream => _myGpsStreamController.stream;
  Stream<Map<String, NavMember>> get peerStream => _peerStreamController.stream;
  Stream<SosBeacon> get sosStream => _sosStreamController.stream;
  Map<String, NavMember> get currentPeers => Map.unmodifiable(_peerMembers);
  Position? get lastGpsPosition => _lastGpsPosition;
  LocationPrivacyMode get privacyMode => _privacyMode;
  DateTime? get ghostUntil => _ghostUntil;
  bool get isBatterySaver => _isBatterySaver;

  // ── Start / Stop ───────────────────────────────────────────────────────────

  /// Initialize and start broadcasting & listening for [tripId].
  Future<void> startSession({
    required String tripId,
    required String userId,
    required String userName,
    required String userInitials,
    required int userColorValue,
  }) async {
    if (_activeTripId == tripId && _broadcastChannel != null) return;
    await stopSession();

    _activeTripId = tripId;
    _userId = userId;
    _userName = userName;
    _userInitials = userInitials;
    _userColorValue = userColorValue;

    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      debugPrint('[LocationBroadcast] Permission permanently denied');
      return;
    }

    // Subscribe to broadcast channel
    _subscribeChannel(tripId);

    // Subscribe to device GPS stream
    _gpsSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).listen(_onGpsUpdate, onError: (err) {
      debugPrint('[LocationBroadcast] GPS stream error: $err');
    });

    // Start periodic adaptive evaluation loop
    _adaptiveTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _evaluateAdaptiveBroadcast();
    });

    // Checkpoint to Supabase DB every 45s for offline recovery
    _checkpointTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      _checkpointToPostgres();
    });

    // Reconnection monitoring
    _connectivitySub =
        ConnectivityService.instance.onlineStream.listen((online) {
      if (online && _broadcastChannel == null && _activeTripId != null) {
        _subscribeChannel(_activeTripId!);
      }
    });
  }

  /// Stop broadcasting and unsubscribe.
  Future<void> stopSession() async {
    _gpsSubscription?.cancel();
    _gpsSubscription = null;
    _adaptiveTimer?.cancel();
    _adaptiveTimer = null;
    _checkpointTimer?.cancel();
    _checkpointTimer = null;
    _connectivitySub?.cancel();
    _connectivitySub = null;

    if (_broadcastChannel != null) {
      try {
        Supabase.instance.client.removeChannel(_broadcastChannel!);
      } catch (_) {}
      _broadcastChannel = null;
    }

    _activeTripId = null;
    _peerMembers.clear();
    _peerStreamController.add({});
  }

  // ── Realtime Broadcast Channel ─────────────────────────────────────────────

  void _subscribeChannel(String tripId) {
    try {
      final channelName = 'trip:location:$tripId';
      _broadcastChannel = Supabase.instance.client.channel(channelName);

      _broadcastChannel!
          .onBroadcast(
            event: 'location_update',
            callback: (payload) => _handlePeerLocationPayload(payload),
          )
          .onBroadcast(
            event: 'sos_beacon',
            callback: (payload) => _handlePeerSosPayload(payload),
          )
          .subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          debugPrint('[LocationBroadcast] Subscribed to $channelName');
          _broadcastCurrentLocation(force: true);
        }
      });
    } catch (e) {
      debugPrint('[LocationBroadcast] Subscribe exception: $e');
    }
  }

  // ── Privacy & Battery Controls ─────────────────────────────────────────────

  void setPrivacyMode(LocationPrivacyMode mode, {Duration? duration}) {
    _privacyMode = mode;
    if (mode == LocationPrivacyMode.ghost && duration != null) {
      _ghostUntil = DateTime.now().add(duration);
    } else if (mode != LocationPrivacyMode.ghost) {
      _ghostUntil = null;
    }
    _broadcastCurrentLocation(force: true);
  }

  void setBatterySaver(bool enabled) {
    _isBatterySaver = enabled;
  }

  // ── Adaptive Speed-Based Sampling ──────────────────────────────────────────

  void _onGpsUpdate(Position pos) {
    _lastGpsPosition = pos;
    _myGpsStreamController.add(pos);
    _evaluateAdaptiveBroadcast();
  }

  void _evaluateAdaptiveBroadcast() {
    final pos = _lastGpsPosition;
    if (pos == null || _activeTripId == null || _userId == null) return;

    final now = DateTime.now();
    final lastTime = _lastBroadcastTime;
    final lastPos = _lastBroadcastPosition;

    // Check Ghost Mode expiry
    if (_ghostUntil != null && now.isAfter(_ghostUntil!)) {
      _ghostUntil = null;
      _privacyMode = LocationPrivacyMode.exact;
    }

    if (_privacyMode == LocationPrivacyMode.ghost) {
      return; // Do not broadcast location in Ghost Mode
    }

    final speedKmh = pos.speed * 3.6; // m/s to km/h

    // Interval & displacement thresholds based on speed
    int intervalSec;
    double displacementMeters;

    if (_isBatterySaver) {
      intervalSec = 60;
      displacementMeters = 50.0;
    } else if (speedKmh < 3.0) {
      // Stationary
      intervalSec = 60;
      displacementMeters = 25.0;
    } else if (speedKmh < 15.0) {
      // Walking / Jogging
      intervalSec = 15;
      displacementMeters = 10.0;
    } else {
      // Driving / Transit
      intervalSec = 5;
      displacementMeters = 30.0;
    }

    bool shouldSend = false;

    if (lastTime == null || lastPos == null) {
      shouldSend = true;
    } else {
      final elapsedSec = now.difference(lastTime).inSeconds;
      final distance = Geolocator.distanceBetween(
        lastPos.latitude,
        lastPos.longitude,
        pos.latitude,
        pos.longitude,
      );

      if (elapsedSec >= intervalSec || distance >= displacementMeters) {
        shouldSend = true;
      }
    }

    if (shouldSend) {
      _broadcastCurrentLocation();
    }
  }

  // ── Broadcast Payloads ─────────────────────────────────────────────────────

  Future<void> _broadcastCurrentLocation({bool force = false}) async {
    final pos = _lastGpsPosition;
    final channel = _broadcastChannel;
    final tripId = _activeTripId;
    final userId = _userId;

    if (channel == null || tripId == null || userId == null) return;

    final isGhost = _privacyMode == LocationPrivacyMode.ghost;
    final isApprox = _privacyMode == LocationPrivacyMode.approximate;

    double lat = pos?.latitude ?? 0.0;
    double lng = pos?.longitude ?? 0.0;

    // Approximate fuzzing (~500m bubble) for privacy mode
    if (isApprox && pos != null) {
      final randAngle = (userId.hashCode % 360) * (math.pi / 180.0);
      const radiusDeg = 0.0045; // ~500m in degrees
      lat += radiusDeg * math.cos(randAngle);
      lng += radiusDeg * math.sin(randAngle);
    }

    final payload = {
      'member_id': userId,
      'name': _userName ?? 'Traveler',
      'initials': _userInitials ?? 'T',
      'color': _userColorValue ?? 0xFFD85A30,
      'lat': lat,
      'lng': lng,
      'speed_kmh': (pos?.speed ?? 0.0) * 3.6,
      'heading': pos?.heading ?? 0.0,
      'altitude': pos?.altitude ?? 0.0,
      'battery_level': _batteryLevel,
      'is_ghost': isGhost,
      'is_approximate': isApprox,
      'is_sos': false,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      await channel.sendBroadcastMessage(
        event: 'location_update',
        payload: payload,
      );
      _lastBroadcastTime = DateTime.now();
      _lastBroadcastPosition = pos;
    } catch (e) {
      debugPrint('[LocationBroadcast] Broadcast send error: $e');
    }
  }

  /// Broadcast high-priority SOS emergency beacon.
  Future<void> broadcastSos(String message) async {
    final pos = _lastGpsPosition;
    final channel = _broadcastChannel;
    final userId = _userId;
    if (channel == null || userId == null) return;

    final beacon = SosBeacon(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      memberId: userId,
      memberName: _userName ?? 'Companion',
      lat: pos?.latitude ?? 0.0,
      lng: pos?.longitude ?? 0.0,
      batteryLevel: _batteryLevel,
      message: message,
      timestamp: DateTime.now(),
    );

    try {
      await channel.sendBroadcastMessage(
        event: 'sos_beacon',
        payload: {
          'id': beacon.id,
          'member_id': beacon.memberId,
          'member_name': beacon.memberName,
          'lat': beacon.lat,
          'lng': beacon.lng,
          'battery_level': beacon.batteryLevel,
          'message': beacon.message,
          'timestamp': beacon.timestamp.toIso8601String(),
        },
      );
      _sosStreamController.add(beacon);
    } catch (e) {
      debugPrint('[LocationBroadcast] SOS broadcast error: $e');
    }
  }

  // ── Peer Ingestion ─────────────────────────────────────────────────────────

  void _handlePeerLocationPayload(Map<String, dynamic> payload) {
    try {
      final memberId = payload['member_id'] as String?;
      if (memberId == null || memberId == _userId) return;

      final isGhost = payload['is_ghost'] == true;
      final isApprox = payload['is_approximate'] == true;
      final isSos = payload['is_sos'] == true;
      final lat = (payload['lat'] as num?)?.toDouble() ?? 0.0;
      final lng = (payload['lng'] as num?)?.toDouble() ?? 0.0;
      final speedKmh = (payload['speed_kmh'] as num?)?.toDouble() ?? 0.0;
      final battery = (payload['battery_level'] as num?)?.toInt() ?? 80;
      final timestamp = DateTime.tryParse(payload['timestamp']?.toString() ?? '') ??
          DateTime.now();

      // Compute normalized 0–1 map offset for 2D painter fallback
      final myPos = _lastGpsPosition;
      double distanceKm = 0.0;
      String distanceLabel = 'Nearby';
      Offset mapPosition = const Offset(0.5, 0.5);

      if (myPos != null && lat != 0.0 && lng != 0.0) {
        final meters = Geolocator.distanceBetween(
          myPos.latitude,
          myPos.longitude,
          lat,
          lng,
        );
        distanceKm = meters / 1000.0;
        distanceLabel = distanceKm < 1.0
            ? '${meters.toInt()} m'
            : '${distanceKm.toStringAsFixed(1)} km';

        // Normalized relative position
        final dLat = lat - myPos.latitude;
        final dLng = lng - myPos.longitude;
        mapPosition = Offset(
          (0.5 + dLng * 20).clamp(0.05, 0.95),
          (0.5 - dLat * 20).clamp(0.05, 0.95),
        );
      }

      final peer = NavMember(
        id: memberId,
        name: payload['name']?.toString() ?? 'Traveler',
        initials: payload['initials']?.toString() ?? 'T',
        color: Color((payload['color'] as int?) ?? 0xFFD85A30),
        status: isGhost
            ? MemberStatus.paused
            : (speedKmh > 1.0 ? MemberStatus.enRoute : MemberStatus.arrived),
        role: 'Traveler',
        speedKmh: speedKmh,
        distanceKm: distanceKm,
        distanceLabel: distanceLabel,
        eta: '${(distanceKm / 0.7).clamp(1, 120).toInt()} min',
        latitude: lat,
        longitude: lng,
        heading: (payload['heading'] as num?)?.toDouble(),
        altitude: (payload['altitude'] as num?)?.toDouble(),
        batteryLevel: battery,
        isGhostMode: isGhost,
        isApproximate: isApprox,
        isSos: isSos,
        sosMessage: payload['sos_message']?.toString(),
        lastPingTime: timestamp,
        mapPosition: mapPosition,
      );

      _peerMembers[memberId] = peer;
      _peerStreamController.add(Map.unmodifiable(_peerMembers));
    } catch (e) {
      debugPrint('[LocationBroadcast] Peer parse error: $e');
    }
  }

  void _handlePeerSosPayload(Map<String, dynamic> payload) {
    try {
      final beacon = SosBeacon(
        id: payload['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        memberId: payload['member_id']?.toString() ?? '',
        memberName: payload['member_name']?.toString() ?? 'Companion',
        lat: (payload['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (payload['lng'] as num?)?.toDouble() ?? 0.0,
        batteryLevel: (payload['battery_level'] as num?)?.toInt() ?? 50,
        message: payload['message']?.toString() ?? 'Emergency SOS Regroup Needed!',
        timestamp: DateTime.tryParse(payload['timestamp']?.toString() ?? '') ??
            DateTime.now(),
      );

      _sosStreamController.add(beacon);
    } catch (e) {
      debugPrint('[LocationBroadcast] SOS parse error: $e');
    }
  }

  // ── Database Hydration & Checkpoint ─────────────────────────────────────────

  /// Hydrate initial peer locations directly from Supabase `member_locations`
  Future<void> hydratePeersFromSupabase(
    String tripId,
    List<MemberModel> tripMembers,
    String myUserId,
  ) async {
    try {
      final res = await Supabase.instance.client
          .from('member_locations')
          .select()
          .eq('trip_id', tripId);

      final myPos = _lastGpsPosition;
      for (final row in res) {
        final memberId = row['member_id'] as String?;
        if (memberId == null || memberId == myUserId) continue;

        final memberModel = tripMembers.firstWhere(
          (m) => m.id == memberId,
          orElse: () => MemberModel(
            id: memberId,
            name: 'Traveler',
            initials: 'T',
            color: const Color(0xFFD85A30),
            isOnline: true,
          ),
        );

        final lat = (row['latitude'] as num?)?.toDouble() ?? 0.0;
        final lng = (row['longitude'] as num?)?.toDouble() ?? 0.0;
        final speed = (row['speed'] as num?)?.toDouble() ?? 0.0;
        final heading = (row['heading'] as num?)?.toDouble();
        final altitude = (row['altitude'] as num?)?.toDouble();
        final isOnline = row['is_online'] == true;

        double distanceKm = 0.0;
        String distanceLabel = 'Nearby';
        if (myPos != null && lat != 0.0 && lng != 0.0) {
          final meters = Geolocator.distanceBetween(
            myPos.latitude,
            myPos.longitude,
            lat,
            lng,
          );
          distanceKm = meters / 1000.0;
          distanceLabel = distanceKm < 1.0
              ? '${meters.toInt()} m'
              : '${distanceKm.toStringAsFixed(1)} km';
        }

        final roleLabel = memberModel.roles.isNotEmpty
            ? memberModel.roles.first.name
            : 'Traveler';

        final peer = NavMember(
          id: memberId,
          name: memberModel.name,
          initials: memberModel.initials,
          color: memberModel.color,
          status: isOnline
              ? (speed > 1.0 ? MemberStatus.enRoute : MemberStatus.arrived)
              : MemberStatus.offline,
          role: roleLabel,
          speedKmh: speed * 3.6,
          distanceKm: distanceKm,
          distanceLabel: distanceLabel,
          eta: '${(distanceKm / 0.7).clamp(1, 120).toInt()} min',
          latitude: lat,
          longitude: lng,
          heading: heading,
          altitude: altitude,
          batteryLevel: 85,
          mapPosition: const Offset(0.5, 0.5),
        );

        _peerMembers[memberId] = peer;
      }
      if (_peerMembers.isNotEmpty) {
        _peerStreamController.add(Map.unmodifiable(_peerMembers));
      }
    } catch (e) {
      debugPrint('[LocationBroadcast] Hydrate peers error: $e');
    }
  }

  Future<void> _checkpointToPostgres() async {
    final pos = _lastGpsPosition;
    final tripId = _activeTripId;
    if (pos == null || tripId == null || _privacyMode == LocationPrivacyMode.ghost) {
      return;
    }

    try {
      await Supabase.instance.client.rpc('update_member_location', params: {
        'p_trip_id': tripId,
        'p_lat': pos.latitude,
        'p_lng': pos.longitude,
        'p_heading': pos.heading,
        'p_speed': pos.speed,
        'p_altitude': pos.altitude,
      });
    } catch (_) {
      // Ignored for broadcast architecture
    }
  }

  void dispose() {
    stopSession();
    _myGpsStreamController.close();
    _peerStreamController.close();
    _sosStreamController.close();
  }
}
