import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/itinerary_model.dart';
import '../providers/repository_providers.dart';

// ── Itinerary State ───────────────────────────────────────────────────────────

class ItineraryState {
  final List<ItineraryDay> days;
  final int activeDay;

  const ItineraryState({
    required this.days,
    this.activeDay = 0,
  });

  ItineraryState copyWith({
    List<ItineraryDay>? days,
    int? activeDay,
  }) {
    return ItineraryState(
      days: days ?? this.days,
      activeDay: activeDay ?? this.activeDay,
    );
  }
}

// ── Itinerary Notifier ────────────────────────────────────────────────────────
// Riverpod v3 family-notifier pattern: store the arg passed in via the provider
// factory and use it in all mutations.

class ItineraryNotifier extends AsyncNotifier<ItineraryState> {
  // Injected by the provider factory below.
  late final String _tripId;

  @override
  Future<ItineraryState> build() async {
    final repo = ref.watch(itineraryRepositoryProvider);
    final days = await repo.getItinerary(_tripId);
    days.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    return ItineraryState(days: days, activeDay: 0);
  }

  // ── Mutations ─────────────────────────────────────────────────────

  void setActiveDay(int dayIndex) {
    state.whenData((s) {
      state = AsyncData(s.copyWith(activeDay: dayIndex));
    });
  }

  Future<void> addStop(int dayIndex, ItineraryStop stop) async {
    final currentState = state.value;
    if (currentState == null) return;

    final repo = ref.read(itineraryRepositoryProvider);
    final day = currentState.days[dayIndex];
    final updatedStops = List<ItineraryStop>.from(day.stops)..add(stop);
    final updatedDay = day.copyWith(stops: updatedStops);
    final updatedDays = List<ItineraryDay>.from(currentState.days);
    updatedDays[dayIndex] = updatedDay;

    state = AsyncData(currentState.copyWith(days: updatedDays));
    await repo.saveItineraryDay(_tripId, updatedDay);
  }

  Future<void> updateStopStatus(
    int dayIndex,
    String stopId,
    StopStatus status,
  ) async {
    final currentState = state.value;
    if (currentState == null) return;

    final repo = ref.read(itineraryRepositoryProvider);
    final day = currentState.days[dayIndex];
    final updatedStops = day.stops.map((s) {
      if (s.id == stopId) return s.copyWith(status: status);
      return s;
    }).toList();
    final updatedDay = day.copyWith(stops: updatedStops);
    final updatedDays = List<ItineraryDay>.from(currentState.days);
    updatedDays[dayIndex] = updatedDay;

    state = AsyncData(currentState.copyWith(days: updatedDays));
    await repo.saveItineraryDay(_tripId, updatedDay);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────
// Family of providers, keyed by tripId. Each creates a fresh ItineraryNotifier
// with its own _tripId injected.

final itineraryProvider = Provider.autoDispose
    .family<AsyncNotifierProvider<ItineraryNotifier, ItineraryState>, String>(
  (ref, tripId) {
    return AsyncNotifierProvider<ItineraryNotifier, ItineraryState>(() {
      return ItineraryNotifier().._tripId = tripId;
    });
  },
);
