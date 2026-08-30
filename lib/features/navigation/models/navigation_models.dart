import 'package:flutter/material.dart';

// ── Member Status ─────────────────────────────────────────────────────────────

enum MemberStatus { enRoute, arrived, offline, paused }

// ── Privacy Mode ──────────────────────────────────────────────────────────────

enum LocationPrivacyMode { exact, approximate, ghost }

// ── Convoy Separation Alert ───────────────────────────────────────────────────

class ConvoyAlert {
  final String memberId;
  final String memberName;
  final double gapKm;
  final int estimatedMinutesBehind;
  final DateTime timestamp;

  const ConvoyAlert({
    required this.memberId,
    required this.memberName,
    required this.gapKm,
    required this.estimatedMinutesBehind,
    required this.timestamp,
  });
}

// ── SOS Panic Beacon ──────────────────────────────────────────────────────────

class SosBeacon {
  final String id;
  final String memberId;
  final String memberName;
  final double lat;
  final double lng;
  final int batteryLevel;
  final String message;
  final DateTime timestamp;

  const SosBeacon({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.lat,
    required this.lng,
    required this.batteryLevel,
    required this.message,
    required this.timestamp,
  });
}

// ── NavMember ─────────────────────────────────────────────────────────────────

class NavMember {
  final String id;
  final String name;
  final String initials;
  final Color color;
  final MemberStatus status;
  final String role;
  final double? speedKmh;
  final String? distanceLabel;   // Human-readable, e.g. "1.4 km ahead"
  final double? distanceKm;      // Signed: positive = ahead, negative = behind
  final String? eta;             // e.g. "4:18 PM"
  final String? arrivedAt;       // e.g. "4:12 PM"
  final bool isMe;
  final String? lastSeenLabel;
  final bool isLocationSharingPaused;
  final Offset mapPosition;      // Normalized 0–1 map coordinates
  final double? latitude;
  final double? longitude;
  final double? heading;
  final double? altitude;
  final int? batteryLevel;       // e.g. 85 (85%)
  final bool isGhostMode;
  final bool isApproximate;
  final bool isSos;
  final String? sosMessage;
  final DateTime? lastPingTime;

  const NavMember({
    required this.id,
    required this.name,
    required this.initials,
    required this.color,
    required this.status,
    required this.role,
    this.speedKmh,
    this.distanceLabel,
    this.distanceKm,
    this.eta,
    this.arrivedAt,
    this.isMe = false,
    this.lastSeenLabel,
    this.isLocationSharingPaused = false,
    this.mapPosition = const Offset(0.5, 0.5),
    this.latitude,
    this.longitude,
    this.heading,
    this.altitude,
    this.batteryLevel,
    this.isGhostMode = false,
    this.isApproximate = false,
    this.isSos = false,
    this.sosMessage,
    this.lastPingTime,
  });

  // ── Convenience getters (for backward compat with widgets) ────
  String? get etaLabel => eta;
  bool get isLocationPaused => isLocationSharingPaused || isGhostMode;
  bool get isOnline => status != MemberStatus.offline && !isLocationPaused;

  NavMember copyWith({
    String? id,
    String? name,
    String? initials,
    Color? color,
    MemberStatus? status,
    String? role,
    double? speedKmh,
    String? distanceLabel,
    double? distanceKm,
    String? eta,
    String? arrivedAt,
    bool? isMe,
    String? lastSeenLabel,
    bool? isLocationSharingPaused,
    Offset? mapPosition,
    double? latitude,
    double? longitude,
    double? heading,
    double? altitude,
    int? batteryLevel,
    bool? isGhostMode,
    bool? isApproximate,
    bool? isSos,
    String? sosMessage,
    DateTime? lastPingTime,
  }) {
    return NavMember(
      id: id ?? this.id,
      name: name ?? this.name,
      initials: initials ?? this.initials,
      color: color ?? this.color,
      status: status ?? this.status,
      role: role ?? this.role,
      speedKmh: speedKmh ?? this.speedKmh,
      distanceLabel: distanceLabel ?? this.distanceLabel,
      distanceKm: distanceKm ?? this.distanceKm,
      eta: eta ?? this.eta,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      isMe: isMe ?? this.isMe,
      lastSeenLabel: lastSeenLabel ?? this.lastSeenLabel,
      isLocationSharingPaused:
          isLocationSharingPaused ?? this.isLocationSharingPaused,
      mapPosition: mapPosition ?? this.mapPosition,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      heading: heading ?? this.heading,
      altitude: altitude ?? this.altitude,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isGhostMode: isGhostMode ?? this.isGhostMode,
      isApproximate: isApproximate ?? this.isApproximate,
      isSos: isSos ?? this.isSos,
      sosMessage: sosMessage ?? this.sosMessage,
      lastPingTime: lastPingTime ?? this.lastPingTime,
    );
  }
}

// ── NavigationState ───────────────────────────────────────────────────────────

class NavigationState {
  final List<NavMember> members;
  final bool isNavigating;
  final bool isGroupViewOn;
  final bool isProximityAlertActive;
  final bool isArrived;
  final bool isCheckedIn;
  final NavDestination destination;
  final TurnInstruction? currentTurn;
  final String nextItineraryLabel;
  final String nextItineraryTime;
  final double groupSpreadKm;
  final NavMember? activeMemberRoute;
  final Offset? meetHalfwayPoint;
  final List<ConvoyAlert> convoyAlerts;
  final SosBeacon? activeSos;
  final LocationPrivacyMode privacyMode;
  final DateTime? ghostUntil;
  final bool isBatterySaver;
  final Set<String> nearbyFoundMembers;

  const NavigationState({
    required this.members,
    this.isNavigating = false,
    this.isGroupViewOn = false,
    this.isProximityAlertActive = false,
    this.isArrived = false,
    this.isCheckedIn = false,
    required this.destination,
    this.currentTurn,
    this.nextItineraryLabel = 'Sunset at White Beach',
    this.nextItineraryTime = '5:30 PM',
    this.groupSpreadKm = 2.1,
    this.activeMemberRoute,
    this.meetHalfwayPoint,
    this.convoyAlerts = const [],
    this.activeSos,
    this.privacyMode = LocationPrivacyMode.exact,
    this.ghostUntil,
    this.isBatterySaver = false,
    this.nearbyFoundMembers = const {},
  });

  // ── Convenience getters (for backward compat with widgets) ────
  String get destinationName => activeMemberRoute != null
      ? 'To ${activeMemberRoute!.name}'
      : destination.name;
  bool get groupViewOn => isGroupViewOn;
  bool get isLive => isNavigating;
  String get etaLabel => activeMemberRoute != null
      ? (activeMemberRoute!.eta ?? destination.eta)
      : destination.eta;
  double get distanceKm => activeMemberRoute != null
      ? (activeMemberRoute!.distanceKm?.abs() ?? destination.distanceKm)
      : destination.distanceKm;
  int get durationMin => destination.durationMin;
  bool get isGhostActive => privacyMode == LocationPrivacyMode.ghost ||
      (ghostUntil != null && ghostUntil!.isAfter(DateTime.now()));

  NavigationState copyWith({
    List<NavMember>? members,
    bool? isNavigating,
    bool? isGroupViewOn,
    bool? isProximityAlertActive,
    bool? isArrived,
    bool? isCheckedIn,
    NavDestination? destination,
    TurnInstruction? currentTurn,
    String? nextItineraryLabel,
    String? nextItineraryTime,
    double? groupSpreadKm,
    NavMember? activeMemberRoute,
    bool clearActiveMemberRoute = false,
    Offset? meetHalfwayPoint,
    bool clearMeetHalfwayPoint = false,
    List<ConvoyAlert>? convoyAlerts,
    SosBeacon? activeSos,
    bool clearActiveSos = false,
    LocationPrivacyMode? privacyMode,
    DateTime? ghostUntil,
    bool clearGhostUntil = false,
    bool? isBatterySaver,
    Set<String>? nearbyFoundMembers,
  }) {
    return NavigationState(
      members: members ?? this.members,
      isNavigating: isNavigating ?? this.isNavigating,
      isGroupViewOn: isGroupViewOn ?? this.isGroupViewOn,
      isProximityAlertActive:
          isProximityAlertActive ?? this.isProximityAlertActive,
      isArrived: isArrived ?? this.isArrived,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      destination: destination ?? this.destination,
      currentTurn: currentTurn ?? this.currentTurn,
      nextItineraryLabel: nextItineraryLabel ?? this.nextItineraryLabel,
      nextItineraryTime: nextItineraryTime ?? this.nextItineraryTime,
      groupSpreadKm: groupSpreadKm ?? this.groupSpreadKm,
      activeMemberRoute: clearActiveMemberRoute
          ? null
          : (activeMemberRoute ?? this.activeMemberRoute),
      meetHalfwayPoint: clearMeetHalfwayPoint
          ? null
          : (meetHalfwayPoint ?? this.meetHalfwayPoint),
      convoyAlerts: convoyAlerts ?? this.convoyAlerts,
      activeSos: clearActiveSos ? null : (activeSos ?? this.activeSos),
      privacyMode: privacyMode ?? this.privacyMode,
      ghostUntil:
          clearGhostUntil ? null : (ghostUntil ?? this.ghostUntil),
      isBatterySaver: isBatterySaver ?? this.isBatterySaver,
      nearbyFoundMembers: nearbyFoundMembers ?? this.nearbyFoundMembers,
    );
  }
}

// ── NavDestination ────────────────────────────────────────────────────────────

class NavDestination {
  final String name;
  final String address;
  final String confirmationCode;
  final double distanceKm;
  final String eta;
  final int durationMin;
  final String nextStopName;
  final String nextStopTime;
  final double? latitude;
  final double? longitude;

  const NavDestination({
    required this.name,
    required this.address,
    required this.confirmationCode,
    required this.distanceKm,
    required this.eta,
    required this.durationMin,
    required this.nextStopName,
    required this.nextStopTime,
    this.latitude,
    this.longitude,
  });
}

// ── TurnInstruction ───────────────────────────────────────────────────────────

class TurnInstruction {
  final String distanceLabel;
  final String instruction;
  final double kmLeft;

  const TurnInstruction({
    required this.distanceLabel,
    required this.instruction,
    required this.kmLeft,
  });
}

// ── NavStatus (alias enum kept for widget backward compat) ────────────────────
/// @deprecated Use [MemberStatus] directly. This alias is for
/// backward-compatible references in older widget code.
typedef NavStatus = MemberStatus;

// ── Defaults ──────────────────────────────────────────────────────────────────

const defaultDestination = NavDestination(
  name: 'No active destination',
  address: 'Set a destination from your trip itinerary',
  confirmationCode: '',
  distanceKm: 0,
  eta: '--',
  durationMin: 0,
  nextStopName: 'No upcoming stop',
  nextStopTime: '--',
);

const defaultTurn = TurnInstruction(
  distanceLabel: 'No turn yet',
  instruction: 'Start navigation to receive directions',
  kmLeft: 0,
);

const defaultMembers = <NavMember>[];

