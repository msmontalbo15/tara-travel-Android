import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/providers/trip_provider.dart';
import '../models/navigation_models.dart';

// The unified navigation provider that manages the entire navigation state
class NavigationNotifier extends Notifier<NavigationState> {
  @override
  NavigationState build() {
    final profile = ref.watch(profileProvider);
    final tripAsync = ref.watch(activeTripProvider);
    final trip = tripAsync.asData?.value;

    final me = NavMember(
      id: 'me',
      name: profile.displayName,
      initials: profile.initials,
      color: profile.avatarColor,
      status: MemberStatus.enRoute,
      role: 'You',
      isMe: true,
    );

    final destination = trip == null
        ? defaultDestination
        : NavDestination(
            name: trip.name,
            address: trip.destination,
            confirmationCode: '',
            distanceKm: 0,
            eta: '--',
            durationMin: 0,
            nextStopName: 'Open itinerary',
            nextStopTime: '--',
          );

    return NavigationState(
      members: [me],
      destination: destination,
      currentTurn: defaultTurn,
      isNavigating: false,
      isGroupViewOn: true,
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
}

final navigationProvider = NotifierProvider<NavigationNotifier, NavigationState>(NavigationNotifier.new);
