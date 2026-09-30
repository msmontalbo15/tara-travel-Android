import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/models/member_model.dart' hide MemberStatus;
import '../../../core/models/trip_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/services/floating_bubble_service.dart';
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
      latitude: lastGps?.latitude ?? 14.5995, // Default Manila center if GPS initializing
      longitude: lastGps?.longitude ?? 120.9842,
      heading: lastGps?.heading ?? 0.0,
      altitude: lastGps?.altitude,
      mapPosition: const Offset(0.48, 0.74),
      photoUrl: profile.profilePhotoUrl,
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
          mapPosition: const Offset(0.5, 0.5),
          photoUrl: m.profilePhotoUrl,
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
    final initialSpread = _calculateGroupSpread(allInitialMembers);

    return NavigationState(
      members: allInitialMembers,
      destination: destination,
      currentTurn: turn,
      isNavigating: true,
      isGroupViewOn: true,
      groupSpreadKm: initialSpread,
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
    final destLat = state.destination.latitude;
    final destLng = state.destination.longitude;

    bool arrivedTriggered = state.isArrived;
    bool departedTriggered = state.hasDepartedStop;

    if (destLat != null && destLng != null && destLat != 0.0 && destLng != 0.0) {
      final stopInfo = LocationBroadcastService.calculateStopEta(
        memberLat: pos.latitude,
        memberLng: pos.longitude,
        destLat: destLat,
        destLng: destLng,
        speedKmh: pos.speed * 3.6,
      );
      distKm = stopInfo.distanceKm;

      // 150m automated arrival geofence
      if (!state.isArrived &&
          LocationBroadcastService.isWithinArrivalGeofence(
            userLat: pos.latitude,
            userLng: pos.longitude,
            destLat: destLat,
            destLng: destLng,
          )) {
        arrivedTriggered = true;
        updatedMembers[myIdx] = updatedMembers[myIdx].copyWith(
          status: MemberStatus.arrived,
          arrivedAt: '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        );
        HapticFeedback.heavyImpact();
      }

      // 200m automated departure geofence at > 15 km/h
      if (state.isArrived &&
          LocationBroadcastService.hasDepartedGeofence(
            userLat: pos.latitude,
            userLng: pos.longitude,
            destLat: destLat,
            destLng: destLng,
            speedKmh: pos.speed * 3.6,
          )) {
        arrivedTriggered = false;
        departedTriggered = true;
        updatedMembers[myIdx] = updatedMembers[myIdx].copyWith(
          status: MemberStatus.enRoute,
        );
      }
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
      isArrived: arrivedTriggered,
      hasDepartedStop: departedTriggered,
      lastDepartedStopName: departedTriggered ? state.destination.name : state.lastDepartedStopName,
      groupSpreadKm: _calculateGroupSpread(updatedMembers),
    );

    _evaluateConvoyAndProximity(updatedMembers);
  }

  static double _calculateGroupSpread(List<NavMember> members) {
    final valid = members
        .where((m) =>
            m.latitude != null &&
            m.longitude != null &&
            m.status != MemberStatus.offline)
        .toList();
    if (valid.length < 2) return 0.0;
    double maxKm = 0.0;
    for (int i = 0; i < valid.length; i++) {
      for (int j = i + 1; j < valid.length; j++) {
        final d = Geolocator.distanceBetween(
              valid[i].latitude!,
              valid[i].longitude!,
              valid[j].latitude!,
              valid[j].longitude!,
            ) /
            1000.0;
        if (d > maxKm) maxKm = d;
      }
    }
    return maxKm;
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
    final destLat = state.destination.latitude ?? 14.5995;
    final destLng = state.destination.longitude ?? 120.9842;

    // 1. Classify Convoy Roles (Lead, Mid, Tail)
    final roles = LocationBroadcastService.classifyConvoyRoles(
      members: members,
      destLat: destLat,
      destLng: destLng,
    );

    // 2. Compute Stop ETAs & update roles for each member
    final enrichedMembers = members.map((m) {
      var updated = m.copyWith(convoyRole: roles[m.id] ?? ConvoyRole.mid);
      if (m.latitude != null && m.longitude != null && destLat != 0.0 && destLng != 0.0) {
        final stopMetrics = LocationBroadcastService.calculateStopEta(
          memberLat: m.latitude!,
          memberLng: m.longitude!,
          destLat: destLat,
          destLng: destLng,
          speedKmh: m.speedKmh,
        );
        updated = updated.copyWith(
          distanceToStopKm: stopMetrics.distanceKm,
          etaToStop: stopMetrics.eta,
          durationToStopMin: stopMetrics.durationMin,
        );
      }
      return updated;
    }).toList();

    String? proactivePrompt;

    for (final m in enrichedMembers) {
      if (m.isMe) continue;
      final distKm = m.distanceKm?.abs() ?? 0.0;

      // Convoy break alert threshold > 2.0 km
      if (distKm > 2.0 || m.isStraggler) {
        alerts.add(ConvoyAlert(
          memberId: m.id,
          memberName: m.name,
          gapKm: distKm,
          estimatedMinutesBehind: (distKm / 0.4).round(),
          timestamp: DateTime.now(),
        ));

        proactivePrompt ??=
            '${m.name} is ${distKm.toStringAsFixed(1)} km behind — suggest a quick pit stop?';
      }

      // Proximity radar threshold <= 30m (0.03 km)
      if (distKm > 0 && distKm <= 0.03 && !foundNearby.contains(m.id)) {
        foundNearby.add(m.id);
        HapticFeedback.heavyImpact();
      }
    }

    final spreadKm = _calculateGroupSpread(enrichedMembers);

    // 3. Sync to Floating Bubble
    final companionsWithDist = enrichedMembers
        .where((m) => !m.isMe && m.distanceKm != null)
        .toList()
      ..sort((a, b) => a.distanceKm!.abs().compareTo(b.distanceKm!.abs()));
    final nearest = companionsWithDist.isNotEmpty ? companionsWithDist.first : null;
    final myMember = enrichedMembers.firstWhere((m) => m.isMe, orElse: () => enrichedMembers.first);

    ref.read(floatingBubbleProvider.notifier).updateConvoyTelemetry(
          nextStopName: state.destination.name,
          nextStopEta: state.destination.eta,
          nextStopDistanceKm: state.destination.distanceKm,
          closestCompanionDistanceKm: nearest?.distanceKm?.abs(),
          closestCompanionName: nearest?.name,
          convoyRole: myMember.convoyRole.name.toUpperCase(),
          convoySpreadKm: spreadKm,
          convoyAlertPrompt: proactivePrompt,
          clearConvoyAlertPrompt: proactivePrompt == null,
        );

    state = state.copyWith(
      members: enrichedMembers,
      convoyAlerts: alerts,
      convoyPrompt: proactivePrompt,
      clearConvoyPrompt: proactivePrompt == null,
      nearbyFoundMembers: foundNearby,
      groupSpreadKm: spreadKm,
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
      clearMeetHalfwayCoord: true,
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
      clearMeetHalfwayCoord: true,
      currentTurn: TurnInstruction(
        distanceLabel: state.destination.distanceKm < 1.0
            ? 'In ${(state.destination.distanceKm * 1000).toInt()} m'
            : 'In ${state.destination.distanceKm.toStringAsFixed(1)} km',
        instruction: 'Resume route toward ${state.destination.name}',
        kmLeft: state.destination.distanceKm,
      ),
    );
  }

  void computeMeetHalfway(NavMember member) {
    // Geographic and normalized midpoint
    final myPos = state.members.firstWhere((m) => m.isMe, orElse: () => state.members.first);
    final midX = (myPos.mapPosition.dx + member.mapPosition.dx) / 2.0;
    final midY = (myPos.mapPosition.dy + member.mapPosition.dy) / 2.0;
    final halfwayOffset = Offset(midX, midY);

    double? midLat;
    double? midLng;
    if (myPos.latitude != null &&
        myPos.longitude != null &&
        member.latitude != null &&
        member.longitude != null) {
      midLat = (myPos.latitude! + member.latitude!) / 2.0;
      midLng = (myPos.longitude! + member.longitude!) / 2.0;
    }

    final midDistKm = ((member.distanceKm?.abs() ?? 2.0) / 2.0);

    state = state.copyWith(
      activeMemberRoute: member,
      meetHalfwayPoint: halfwayOffset,
      meetHalfwayLat: midLat,
      meetHalfwayLng: midLng,
      meetHalfwayTitle: 'Midpoint Rendezvous with ${member.name}',
      currentTurn: TurnInstruction(
        distanceLabel: 'Meet Halfway with ${member.name}',
        instruction: 'Proceed to mutual midpoint rendezvous (~${(midDistKm * 1000).toInt()} m away)',
        kmLeft: midDistKm,
      ),
    );
    HapticFeedback.mediumImpact();
  }

  /// Computes the geographical centroid of all online members (Midpoint Gatherer)
  void computeGroupCentroidRendezvous({List<String>? selectedMemberIds}) {
    final activeMembers = state.members.where((m) {
      if (selectedMemberIds != null && selectedMemberIds.isNotEmpty) {
        return selectedMemberIds.contains(m.id) &&
            m.latitude != null &&
            m.longitude != null;
      }
      return m.latitude != null &&
          m.longitude != null &&
          m.status != MemberStatus.offline;
    }).toList();

    if (activeMembers.isEmpty) return;

    final points = activeMembers
        .map((m) => (lat: m.latitude!, lng: m.longitude!))
        .toList();

    final centroid = LocationBroadcastService.calculateCentroid(points);
    if (centroid == null) return;

    final myPos = state.members.firstWhere((m) => m.isMe, orElse: () => state.members.first);
    double myDistToCentroidKm = 0.0;
    if (myPos.latitude != null && myPos.longitude != null) {
      myDistToCentroidKm = Geolocator.distanceBetween(
            myPos.latitude!,
            myPos.longitude!,
            centroid.lat,
            centroid.lng,
          ) /
          1000.0;
    }

    state = state.copyWith(
      meetHalfwayLat: centroid.lat,
      meetHalfwayLng: centroid.lng,
      meetHalfwayTitle: 'Squad Rendezvous Centroid',
      clearActiveMemberRoute: true,
      currentTurn: TurnInstruction(
        distanceLabel:
            'Rendezvous Centroid (${myDistToCentroidKm < 1.0 ? "${(myDistToCentroidKm * 1000).toInt()} m" : "${myDistToCentroidKm.toStringAsFixed(1)} km"})',
        instruction:
            'Head towards the shared centroid rendezvous point for ${activeMembers.length} travelers',
        kmLeft: myDistToCentroidKm,
      ),
    );
    HapticFeedback.mediumImpact();
  }

  void cancelRendezvous() {
    state = state.copyWith(
      clearMeetHalfwayPoint: true,
      clearMeetHalfwayCoord: true,
      currentTurn: TurnInstruction(
        distanceLabel: state.destination.distanceKm < 1.0
            ? 'In ${(state.destination.distanceKm * 1000).toInt()} m'
            : 'In ${state.destination.distanceKm.toStringAsFixed(1)} km',
        instruction: 'Resume route toward ${state.destination.name}',
        kmLeft: state.destination.distanceKm,
      ),
    );
  }

  void dismissConvoyPrompt() {
    state = state.copyWith(clearConvoyPrompt: true);
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

