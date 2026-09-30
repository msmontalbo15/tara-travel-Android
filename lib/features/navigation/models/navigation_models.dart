import 'package:flutter/material.dart';

// ── Member Status ─────────────────────────────────────────────────────────────

enum MemberStatus { enRoute, arrived, offline, paused }

// ── Convoy Role ───────────────────────────────────────────────────────────────

enum ConvoyRole {
  /// Foremost traveler setting the convoy pace.
  lead,

  /// Travelers safely clustered within the convoy corridor.
  mid,

  /// Travelers falling behind (>2.0 km gap or slowed down).
  tail,
}

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
  final ConvoyRole convoyRole;
  final double? speedKmh;
  final String? distanceLabel;   // Human-readable, e.g. "1.4 km ahead"
  final double? distanceKm;      // Signed: positive = ahead, negative = behind
  final double? distanceToStopKm;// Distance from member to destination waypoint
  final String? etaToStop;       // e.g. "14 min away"
  final int? durationToStopMin;  // Estimated duration in minutes to destination stop
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
  final String? photoUrl;

  const NavMember({
    required this.id,
    required this.name,
    required this.initials,
    required this.color,
    required this.status,
    required this.role,
    this.convoyRole = ConvoyRole.mid,
    this.speedKmh,
    this.distanceLabel,
    this.distanceKm,
    this.distanceToStopKm,
    this.etaToStop,
    this.durationToStopMin,
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
    this.photoUrl,
  });

  // ── Convenience getters (for backward compat with widgets) ────
  String? get etaLabel => etaToStop ?? eta;
  bool get isLocationPaused => isLocationSharingPaused || isGhostMode;
  bool get isOnline => status != MemberStatus.offline && !isLocationPaused;
  bool get isLead => convoyRole == ConvoyRole.lead;
  bool get isMid => convoyRole == ConvoyRole.mid;
  bool get isTail => convoyRole == ConvoyRole.tail;
  bool get isStraggler =>
      convoyRole == ConvoyRole.tail && (distanceKm?.abs() ?? 0.0) > 2.0;

  NavMember copyWith({
    String? id,
    String? name,
    String? initials,
    Color? color,
    MemberStatus? status,
    String? role,
    ConvoyRole? convoyRole,
    double? speedKmh,
    String? distanceLabel,
    double? distanceKm,
    double? distanceToStopKm,
    String? etaToStop,
    int? durationToStopMin,
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
    String? photoUrl,
  }) {
    return NavMember(
      id: id ?? this.id,
      name: name ?? this.name,
      initials: initials ?? this.initials,
      color: color ?? this.color,
      status: status ?? this.status,
      role: role ?? this.role,
      convoyRole: convoyRole ?? this.convoyRole,
      speedKmh: speedKmh ?? this.speedKmh,
      distanceLabel: distanceLabel ?? this.distanceLabel,
      distanceKm: distanceKm ?? this.distanceKm,
      distanceToStopKm: distanceToStopKm ?? this.distanceToStopKm,
      etaToStop: etaToStop ?? this.etaToStop,
      durationToStopMin: durationToStopMin ?? this.durationToStopMin,
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
      photoUrl: photoUrl ?? this.photoUrl,
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
  final double? meetHalfwayLat;
  final double? meetHalfwayLng;
  final String? meetHalfwayTitle;
  final List<ConvoyAlert> convoyAlerts;
  final String? convoyPrompt;
  final SosBeacon? activeSos;
  final LocationPrivacyMode privacyMode;
  final DateTime? ghostUntil;
  final bool isBatterySaver;
  final Set<String> nearbyFoundMembers;
  final bool hasDepartedStop;
  final String? lastDepartedStopName;

  const NavigationState({
    required this.members,
    this.isNavigating = false,
    this.isGroupViewOn = false,
    this.isProximityAlertActive = false,
    this.isArrived = false,
    this.isCheckedIn = false,
    required this.destination,
    this.currentTurn,
    this.nextItineraryLabel = 'No upcoming stop',
    this.nextItineraryTime = '--',
    this.groupSpreadKm = 2.1,
    this.activeMemberRoute,
    this.meetHalfwayPoint,
    this.meetHalfwayLat,
    this.meetHalfwayLng,
    this.meetHalfwayTitle,
    this.convoyAlerts = const [],
    this.convoyPrompt,
    this.activeSos,
    this.privacyMode = LocationPrivacyMode.exact,
    this.ghostUntil,
    this.isBatterySaver = false,
    this.nearbyFoundMembers = const {},
    this.hasDepartedStop = false,
    this.lastDepartedStopName,
  });

  // ── Convenience getters (for backward compat with widgets) ────
  String get destinationName => activeMemberRoute != null
      ? 'To ${activeMemberRoute!.name}'
      : destination.name;
  bool get groupViewOn => isGroupViewOn;
  bool get isLive => isNavigating;
  String get etaLabel => activeMemberRoute != null
      ? (activeMemberRoute!.etaToStop ?? activeMemberRoute!.eta ?? destination.eta)
      : destination.eta;
  double get distanceKm => activeMemberRoute != null
      ? (activeMemberRoute!.distanceKm?.abs() ?? destination.distanceKm)
      : destination.distanceKm;
  int get durationMin => destination.durationMin;
  List<NavMember> get companions => members.where((m) => !m.isMe).toList();
  bool get isGhostActive => privacyMode == LocationPrivacyMode.ghost ||
      (ghostUntil != null && ghostUntil!.isAfter(DateTime.now()));
  NavMember? get convoyLead =>
      members.where((m) => m.convoyRole == ConvoyRole.lead).firstOrNull;
  List<NavMember> get convoyStragglers =>
      members.where((m) => m.isStraggler).toList();
  NavMember? get tailMember =>
      members.where((m) => m.convoyRole == ConvoyRole.tail).firstOrNull;

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
    double? meetHalfwayLat,
    double? meetHalfwayLng,
    String? meetHalfwayTitle,
    bool clearMeetHalfwayCoord = false,
    List<ConvoyAlert>? convoyAlerts,
    String? convoyPrompt,
    bool clearConvoyPrompt = false,
    SosBeacon? activeSos,
    bool clearActiveSos = false,
    LocationPrivacyMode? privacyMode,
    DateTime? ghostUntil,
    bool clearGhostUntil = false,
    bool? isBatterySaver,
    Set<String>? nearbyFoundMembers,
    bool? hasDepartedStop,
    String? lastDepartedStopName,
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
      meetHalfwayLat: clearMeetHalfwayCoord
          ? null
          : (meetHalfwayLat ?? this.meetHalfwayLat),
      meetHalfwayLng: clearMeetHalfwayCoord
          ? null
          : (meetHalfwayLng ?? this.meetHalfwayLng),
      meetHalfwayTitle: clearMeetHalfwayCoord
          ? null
          : (meetHalfwayTitle ?? this.meetHalfwayTitle),
      convoyAlerts: convoyAlerts ?? this.convoyAlerts,
      convoyPrompt: clearConvoyPrompt
          ? null
          : (convoyPrompt ?? this.convoyPrompt),
      activeSos: clearActiveSos ? null : (activeSos ?? this.activeSos),
      privacyMode: privacyMode ?? this.privacyMode,
      ghostUntil:
          clearGhostUntil ? null : (ghostUntil ?? this.ghostUntil),
      isBatterySaver: isBatterySaver ?? this.isBatterySaver,
      nearbyFoundMembers: nearbyFoundMembers ?? this.nearbyFoundMembers,
      hasDepartedStop: hasDepartedStop ?? this.hasDepartedStop,
      lastDepartedStopName: lastDepartedStopName ?? this.lastDepartedStopName,
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

