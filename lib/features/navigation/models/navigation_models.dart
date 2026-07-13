import 'package:flutter/material.dart';

// ── Member Status ─────────────────────────────────────────────────────────────

enum MemberStatus { enRoute, arrived, offline, paused }

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
  });

  // ── Convenience getters (for backward compat with widgets) ────
  String? get etaLabel => eta;
  bool get isLocationPaused => isLocationSharingPaused;
  bool get isOnline => status != MemberStatus.offline;

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
  });

  // ── Convenience getters (for backward compat with widgets) ────
  String get destinationName => destination.name;
  bool get groupViewOn => isGroupViewOn;
  bool get isLive => isNavigating;
  String get etaLabel => destination.eta;
  double get distanceKm => destination.distanceKm;
  int get durationMin => destination.durationMin;

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

  const NavDestination({
    required this.name,
    required this.address,
    required this.confirmationCode,
    required this.distanceKm,
    required this.eta,
    required this.durationMin,
    required this.nextStopName,
    required this.nextStopTime,
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
