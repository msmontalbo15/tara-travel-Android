import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trip_model.dart';
import '../models/member_model.dart';
import '../providers/repository_providers.dart';
import '../providers/selected_trip_provider.dart';
import '../providers/profile_provider.dart';

// ── All Trips ─────────────────────────────────────────────────────────────────
//
// Fetches all trips the current user owns or is a member of.
// Re-fetches whenever the provider is invalidated (e.g. after createTrip).

final allTripsProvider = FutureProvider<List<TripModel>>((ref) async {
  final repo = ref.watch(tripRepositoryProvider);
  return repo.getTrips();
});

// ── Active Trip ───────────────────────────────────────────────────────────────
//
// Alias for selectedTripProvider. Falls back to the first trip
// in the list if no trip is explicitly selected (e.g. on the Home screen
// before the user taps into a trip).

final activeTripProvider = FutureProvider<TripModel?>((ref) async {
  // If a trip is explicitly selected (and not archived), use that.
  final selected = await ref.watch(selectedTripProvider.future);
  if (selected != null && !selected.isArchived) return selected;

  // Fallback: prioritize ongoing trips first, then upcoming planning trips, then any active trip.
  final trips = await ref.watch(allTripsProvider.future);
  if (trips.isEmpty) return null;
  final ongoingTrips = trips.where((t) => t.isOngoing).toList();
  if (ongoingTrips.isNotEmpty) return ongoingTrips.first;
  final planningTrips = trips.where((t) => t.isPlanning).toList();
  if (planningTrips.isNotEmpty) return planningTrips.first;
  final activeUpcoming =
      trips.where((t) => !t.isDraft && !t.isArchived).toList();
  if (activeUpcoming.isNotEmpty) return activeUpcoming.first;
  return null;
});

// ── Trip Status Provider ───────────────────────────────────────────────────────
//
// Single source of truth for dynamic trip status (draft, planning, ongoing, completed).

final tripStatusProvider =
    Provider.family<TripStatus, TripModel>((ref, trip) => trip.status);

// ── Current Member ─────────────────────────────────────────────────────────────
//
// Resolves the MemberModel of the logged-in user in the active trip.
// Falls back to an Organizer role if user is trip creator or default member.

final currentMemberProvider = Provider.family<MemberModel?, TripModel?>((ref, trip) {
  if (trip == null) return null;
  final authRepo = ref.watch(authRepositoryProvider);
  final profile = ref.watch(profileProvider);
  final currentUserId = authRepo.currentUser?.id;
  final effectiveUserName =
      profile.effectiveName.isNotEmpty ? profile.effectiveName : 'Organizer';

  if (currentUserId == null) {
    return trip.members.firstWhere(
      (m) => m.roles.contains(MemberRole.organizer),
      orElse: () => trip.members.isNotEmpty
          ? trip.members.first
          : MemberModel(
              id: 'local_organizer',
              name: effectiveUserName,
              initials: profile.initials.isNotEmpty ? profile.initials : 'ORG',
              color: profile.avatarColor,
              roles: const [MemberRole.organizer],
            ),
    );
  }

  return trip.members.firstWhere(
    (m) => m.id == currentUserId,
    orElse: () {
      if (trip.ownerId == currentUserId || trip.members.isEmpty) {
        return MemberModel(
          id: currentUserId,
          name: effectiveUserName,
          initials: profile.initials.isNotEmpty ? profile.initials : 'ME',
          color: profile.avatarColor,
          roles: const [MemberRole.organizer],
        );
      }
      return MemberModel(
        id: currentUserId,
        name: profile.effectiveName.isNotEmpty ? profile.effectiveName : 'Member',
        initials: profile.initials.isNotEmpty ? profile.initials : 'ME',
        color: const Color(0xFF6B7280),
        roles: const [MemberRole.member],
      );
    },
  );
});

