import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/models/member_model.dart' hide MemberStatus;
import '../../../core/models/trip_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/services/location_broadcast_service.dart';
import '../models/navigation_models.dart';

// The unified navigation provider that manages the entire navigation state with real Supabase data
class NavigationNotifier extends Notifier<NavigationState> {
  StreamSubscription<Position>? _myGpsSub;
  StreamSubscription<Map<String, NavMember>>? _peerSub;
  StreamSubscription<SosBeacon>? _sosSub;

  @override
  NavigationState build() {
    final profile = ref.watch(profileProvider);
    final tripAsync = ref.watch(activeTripProvider);
    final trip = tripAsync.asData?.value;
    final currentUserId = ref.watch(currentUserProvider)?.id ?? 'me';

    final displayName = MemberModel.formatDisplayName(
      profile.displayName,
      hideSurname: profile.hideSurname,
    );

    final lastGps = LocationBroadcastService.instance.lastGpsPosition;

    final me = NavMember(
      id: currentUserId,
      name: displayName,
      initials: profile.initials,
      color: profile.avatarColor,
      status: MemberStatus.enRoute,
      role: 'You',
      isMe: true,
      speedKmh: (lastGps?.speed ?? 0.0) * 3.6,
      distanceLabel: 'On track',
      distanceKm: 0.0,
      batteryLevel: 94,
      latitude: lastGps?.latitude ?? 14.5995, // Default Manila center if GPS initializing
      longitude: lastGps?.longitude ?? 120.9842,
      heading: lastGps?.heading ?? 0.0,
      altitude: lastGps?.altitude,
      mapPosition: const Offset(0.48, 0.74),
    );

    // Dynamic companions from Supabase Trip Members
    final List<NavMember> companions = [];
    if (trip != null && trip.members.isNotEmpty) {
      for (final m in trip.members) {
        if (m.id == currentUserId || m.id == 'me') continue;
        final roleLabel = m.roles.isNotEmpty ? m.roles.first.name : 'Traveler';
        companions.add(NavMember(
          id: m.id,
          name: MemberModel.formatDisplayName(m.name, hideSurname: profile.hideSurname),
          initials: m.initials,
          color: m.color,
          status: m.isOnline ? MemberStatus.enRoute : MemberStatus.offline,
          role: roleLabel,
          isMe: false,
          batteryLevel: 85,
          mapPosition: const Offset(0.5, 0.5),
        ));
      }
    }

    // Destination coordinates from Trip Model
    double destLat = 14.5995;
    double destLng = 120.9842;
    if (trip != null) {
      if (trip.destinationDetails != null) {
        destLat = (trip.destinationDetails!['lat'] as num?)?.toDouble() ??
            (trip.departureLat ?? 14.5995);
        destLng = (trip.destinationDetails!['lng'] as num?)?.toDouble() ??
            (trip.departureLng ?? 120.9842);
      } else if (trip.departureLat != null && trip.departureLng != null) {
        destLat = trip.departureLat!;
        destLng = trip.departureLng!;
      }
    }

    double initialDistanceKm = 4.8;
    if (lastGps != null && (destLat != 0.0 && destLng != 0.0)) {
      final meters = Geolocator.distanceBetween(
        lastGps.latitude,
        lastGps.longitude,
        destLat,
        destLng,
      );
      initialDistanceKm = (meters / 1000.0);
    }

    final destination = trip == null
        ? defaultDestination
        : NavDestination(
            name: trip.name,
            address: trip.destination,
            confirmationCode: 'TARA-${trip.id.length >= 4 ? trip.id.substring(0, 4).toUpperCase() : "TRIP"}',
            distanceKm: initialDistanceKm,
            eta: '${(initialDistanceKm / 0.6).clamp(5, 300).toInt()} min',
            durationMin: (initialDistanceKm / 0.6).clamp(5, 300).toInt(),
            nextStopName: 'Arrive at destination',
            nextStopTime: '${(initialDistanceKm / 0.6).clamp(5, 300).toInt()}m away',
            latitude: destLat,
            longitude: destLng,
          );

    final turn = TurnInstruction(
      distanceLabel: initialDistanceKm < 1.0 ? 'In ${(initialDistanceKm * 1000).toInt()} m' : 'In 300 m',
      instruction: 'Proceed along route toward ${trip?.destination ?? destination.name}',
      kmLeft: initialDistanceKm,
    );

    // Setup broadcast listener and initial hydration on trip change
    if (trip != null) {
      Future.microtask(() {
        _initBroadcast(trip, profile, currentUserId);
      });
    }

    ref.onDispose(() {
      _myGpsSub?.cancel();
      _peerSub?.cancel();
      _sosSub?.cancel();
    });

    final allInitialMembers = [me, ...companions];

    return NavigationState(
      members: allInitialMembers,
      destination: destination,
      currentTurn: turn,
      isNavigating: true,
      isGroupViewOn: true,
      groupSpreadKm: 3.8,
      convoyAlerts: const [],
    );
  }

  void _initBroadcast(TripModel trip, dynamic profile, String currentUserId) {
    LocationBroadcastService.instance.startSession(
      tripId: trip.id,
      userId: currentUserId,
      userName: profile.displayName,
      userInitials: profile.initials,
      userColorValue: profile.avatarColor.toARGB32(),
    );

    // Hydrate peer locations from Supabase database table `member_locations`
    LocationBroadcastService.instance.hydratePeersFromSupabase(
      trip.id,
      trip.members,
      currentUserId,
    );

    // Listen to local device GPS updates
    _myGpsSub?.cancel();
    _myGpsSub = LocationBroadcastService.instance.myGpsStream.listen((pos) {
      _onMyGpsUpdate(pos);
    });

    // Listen to incoming peer broadcast telemetry
    _peerSub?.cancel();
    _peerSub = LocationBroadcastService.instance.peerStream.listen((peers) {
      if (peers.isNotEmpty) {
        _mergePeerMembers(peers);
      }
    });

    _sosSub?.cancel();
    _sosSub = LocationBroadcastService.instance.sosStream.listen((beacon) {
      state = state.copyWith(activeSos: beacon);
      HapticFeedback.heavyImpact();
    });
  }

  void _onMyGpsUpdate(Position pos) {
    final myIdx = state.members.indexWhere((m) => m.isMe);
    if (myIdx < 0) return;

    final currentMe = state.members[myIdx];
    final updatedMe = currentMe.copyWith(
      latitude: pos.latitude,
      longitude: pos.longitude,
      heading: pos.heading,
      speedKmh: pos.speed * 3.6,
      altitude: pos.altitude,
    );

    final updatedMembers = List<NavMember>.from(state.members)..[myIdx] = updatedMe;

    // Recalculate distance to destination
    double distKm = state.destination.distanceKm;
    if (state.destination.latitude != null && state.destination.longitude != null) {
      final meters = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        state.destination.latitude!,
        state.destination.longitude!,
      );
      distKm = meters / 1000.0;
    }

    final updatedDest = NavDestination(
      name: state.destination.name,
      address: state.destination.address,
      confirmationCode: state.destination.confirmationCode,
      distanceKm: distKm,
      eta: '${(distKm / 0.6).clamp(1, 300).toInt()} min',
      durationMin: (distKm / 0.6).clamp(1, 300).toInt(),
      nextStopName: state.destination.nextStopName,
      nextStopTime: state.destination.nextStopTime,
      latitude: state.destination.latitude,
      longitude: state.destination.longitude,
    );

    state = state.copyWith(
      members: updatedMembers,
      destination: updatedDest,
    );
  }

  void _mergePeerMembers(Map<String, NavMember> peers) {
    final updatedList = List<NavMember>.from(state.members);
    for (final peer in peers.values) {
      final idx = updatedList.indexWhere((m) => m.id == peer.id);
      if (idx >= 0) {
        updatedList[idx] = peer;
      } else {
        updatedList.add(peer);
      }
    }
    state = state.copyWith(members: updatedList);
    _evaluateConvoyAndProximity(updatedList);
  }

  void _evaluateConvoyAndProximity(List<NavMember> members) {
    final alerts = <ConvoyAlert>[];
    final foundNearby = Set<String>.from(state.nearbyFoundMembers);

    for (final m in members) {
      if (m.isMe) continue;
      final distKm = m.distanceKm?.abs() ?? 0.0;

      // Convoy break alert threshold > 2.0 km
      if (distKm > 2.0) {
        alerts.add(ConvoyAlert(
          memberId: m.id,
          memberName: m.name,
          gapKm: distKm,
          estimatedMinutesBehind: (distKm / 0.4).round(),
          timestamp: DateTime.now(),
        ));
      }

      // Proximity radar threshold <= 30m (0.03 km)
      if (distKm > 0 && distKm <= 0.03 && !foundNearby.contains(m.id)) {
        foundNearby.add(m.id);
        HapticFeedback.heavyImpact();
      }
    }

    state = state.copyWith(
      convoyAlerts: alerts,
      nearbyFoundMembers: foundNearby,
    );
  }

  void toggleGroupView() {
    state = state.copyWith(isGroupViewOn: !state.isGroupViewOn);
  }

  void setNavigating(bool val) {
    state = state.copyWith(isNavigating: val);
  }

  void setProximityAlert(bool val) {
    state = state.copyWith(isProximityAlertActive: val);
  }

  void setArrived(bool val) {
    state = state.copyWith(isArrived: val);
  }

  void checkIn() {
    state = state.copyWith(isCheckedIn: true);
  }

  void updateMembers(List<NavMember> newMembers) {
    state = state.copyWith(members: newMembers);
  }

  // ── Member Routing (Member-as-Waypoint) ────────────────────────────────────

  void navigateToMember(NavMember member) {
    state = state.copyWith(
      activeMemberRoute: member,
      clearMeetHalfwayPoint: true,
      currentTurn: TurnInstruction(
        distanceLabel: 'Head toward ${member.name}',
        instruction: 'Follow route to ${member.name} (${member.distanceLabel ?? 'En route'})',
        kmLeft: member.distanceKm?.abs() ?? 1.2,
      ),
    );
    HapticFeedback.selectionClick();
  }

  void cancelMemberNavigation() {
    state = state.copyWith(
      clearActiveMemberRoute: true,
      clearMeetHalfwayPoint: true,
      currentTurn: const TurnInstruction(
        distanceLabel: 'In 300 m',
        instruction: 'Turn right at White Beach Access Road',
        kmLeft: 4.8,
      ),
    );
  }

  void computeMeetHalfway(NavMember member) {
    // Geographic or normalized midpoint
    final myPos = state.members.firstWhere((m) => m.isMe, orElse: () => state.members.first);
    final midX = (myPos.mapPosition.dx + member.mapPosition.dx) / 2.0;
    final midY = (myPos.mapPosition.dy + member.mapPosition.dy) / 2.0;
    final halfwayOffset = Offset(midX, midY);

    final midDistKm = ((member.distanceKm?.abs() ?? 2.0) / 2.0);

    state = state.copyWith(
      activeMemberRoute: member,
      meetHalfwayPoint: halfwayOffset,
      currentTurn: TurnInstruction(
        distanceLabel: 'Meet Halfway with ${member.name}',
        instruction: 'Proceed to mutual midpoint rendezvous (~${(midDistKm * 1000).toInt()} m away)',
        kmLeft: midDistKm,
      ),
    );
    HapticFeedback.mediumImpact();
  }

  // ── Privacy & Battery ──────────────────────────────────────────────────────

  void setPrivacyMode(LocationPrivacyMode mode, {Duration? duration}) {
    LocationBroadcastService.instance.setPrivacyMode(mode, duration: duration);
    state = state.copyWith(
      privacyMode: mode,
      ghostUntil: duration != null ? DateTime.now().add(duration) : null,
      clearGhostUntil: mode != LocationPrivacyMode.ghost,
    );
  }

  void toggleBatterySaver() {
    final nextVal = !state.isBatterySaver;
    LocationBroadcastService.instance.setBatterySaver(nextVal);
    state = state.copyWith(isBatterySaver: nextVal);
  }

  // ── Convoy & SOS Management ────────────────────────────────────────────────

  void dismissConvoyAlert(String memberId) {
    final updated = state.convoyAlerts.where((a) => a.memberId != memberId).toList();
    state = state.copyWith(convoyAlerts: updated);
  }

  Future<void> triggerSos(String message) async {
    await LocationBroadcastService.instance.broadcastSos(message);
    final myPos = state.members.firstWhere((m) => m.isMe, orElse: () => state.members.first);
    final beacon = SosBeacon(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      memberId: myPos.id,
      memberName: myPos.name,
      lat: myPos.latitude ?? 14.5995,
      lng: myPos.longitude ?? 120.9842,
      batteryLevel: myPos.batteryLevel ?? 80,
      message: message,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(activeSos: beacon);
  }

  void dismissSos() {
    state = state.copyWith(clearActiveSos: true);
  }
}

final navigationProvider =
    NotifierProvider<NavigationNotifier, NavigationState>(NavigationNotifier.new);

