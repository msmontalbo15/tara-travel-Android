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
    final effectiveDays = days.isEmpty
        ? [ItineraryDay(dayNumber: 1, date: DateTime.now(), stops: const [])]
        : days;
    return ItineraryState(days: effectiveDays, activeDay: 0);
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

  // ── Feature 1: Drag-and-drop reorder ─────────────────────────────

  Future<void> reorderStop(int dayIndex, int oldIndex, int newIndex) async {
    final currentState = state.value;
    if (currentState == null) return;

    final repo = ref.read(itineraryRepositoryProvider);
    final day = currentState.days[dayIndex];
    final stops = List<ItineraryStop>.from(day.stops);

    // ReorderableListView passes newIndex after removal so compensate
    final adjustedNew = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final item = stops.removeAt(oldIndex);
    stops.insert(adjustedNew, item);

    final updatedDay = day.copyWith(stops: stops);
    final updatedDays = List<ItineraryDay>.from(currentState.days);
    updatedDays[dayIndex] = updatedDay;

    state = AsyncData(currentState.copyWith(days: updatedDays));
    await repo.saveItineraryDay(_tripId, updatedDay);
  }

  // ── Feature 2: Update a full stop ─────────────────────────────────

  Future<void> updateStop(int dayIndex, ItineraryStop updated) async {
    final currentState = state.value;
    if (currentState == null) return;

    final repo = ref.read(itineraryRepositoryProvider);
    final day = currentState.days[dayIndex];
    final updatedStops = day.stops.map((s) => s.id == updated.id ? updated : s).toList();
    final updatedDay = day.copyWith(stops: updatedStops);
    final updatedDays = List<ItineraryDay>.from(currentState.days);
    updatedDays[dayIndex] = updatedDay;

    state = AsyncData(currentState.copyWith(days: updatedDays));
    await repo.saveItineraryDay(_tripId, updatedDay);
  }

  // ── Feature 2: Delete a stop ──────────────────────────────────────

  Future<void> deleteStop(int dayIndex, String stopId) async {
    final currentState = state.value;
    if (currentState == null) return;

    final repo = ref.read(itineraryRepositoryProvider);
    final day = currentState.days[dayIndex];
    final updatedStops = day.stops.where((s) => s.id != stopId).toList();
    final updatedDay = day.copyWith(stops: updatedStops);
    final updatedDays = List<ItineraryDay>.from(currentState.days);
    updatedDays[dayIndex] = updatedDay;

    state = AsyncData(currentState.copyWith(days: updatedDays));
    await repo.saveItineraryDay(_tripId, updatedDay);
  }

  // ── Feature 6: Collaborative voting ──────────────────────────────

  Future<void> voteOnStop(
    int dayIndex,
    String stopId,
    String memberId,
    bool upvote,
  ) async {
    final currentState = state.value;
    if (currentState == null) return;

    final repo = ref.read(itineraryRepositoryProvider);
    final day = currentState.days[dayIndex];
    final updatedStops = day.stops.map((s) {
      if (s.id != stopId) return s;
      final updatedVotes = Map<String, bool>.from(s.votes);
      // Toggle: if already voted same way, remove vote
      if (updatedVotes[memberId] == upvote) {
        updatedVotes.remove(memberId);
      } else {
        updatedVotes[memberId] = upvote;
      }
      return s.copyWith(votes: updatedVotes);
    }).toList();

    final updatedDay = day.copyWith(stops: updatedStops);
    final updatedDays = List<ItineraryDay>.from(currentState.days);
    updatedDays[dayIndex] = updatedDay;

    state = AsyncData(currentState.copyWith(days: updatedDays));
    await repo.saveItineraryDay(_tripId, updatedDay);
  }

  // ── Add a new Day to the itinerary ──────────────────────────────
  Future<void> addDay() async {
    final currentState = state.value;
    if (currentState == null) return;

    final repo = ref.read(itineraryRepositoryProvider);
    final nextDayNum = currentState.days.length + 1;
    final lastDate = currentState.days.isNotEmpty
        ? currentState.days.last.date
        : DateTime.now();
    final newDay = ItineraryDay(
      dayNumber: nextDayNum,
      date: lastDate.add(const Duration(days: 1)),
      stops: const [],
    );

    final updatedDays = List<ItineraryDay>.from(currentState.days)..add(newDay);
    state = AsyncData(currentState.copyWith(days: updatedDays, activeDay: nextDayNum - 1));
    await repo.saveItineraryDay(_tripId, newDay);
  }

  // ── Clear all stops in a Day ──────────────────────────────────────
  Future<void> clearDay(int dayIndex) async {
    final currentState = state.value;
    if (currentState == null) return;

    final repo = ref.read(itineraryRepositoryProvider);
    final day = currentState.days[dayIndex];
    final updatedDay = day.copyWith(stops: const []);
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
