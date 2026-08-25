import 'package:flutter/material.dart';
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
    final tripRepo = ref.watch(tripRepositoryProvider);
    final trip = await tripRepo.getTripById(_tripId);

    final days = await repo.getItinerary(
      _tripId,
      startDate: trip?.fromDate,
      endDate: trip?.toDate,
    );
    days.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    final effectiveDays = days.isEmpty
        ? [
            ItineraryDay(
              dayNumber: 1,
              date: trip?.fromDate ?? DateTime.now(),
              stops: const [],
            ),
          ]
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

  // ── Member Check-In: toggle a member's presence on a stop ────
  Future<void> checkInMember(int dayIndex, String stopId, String memberId) async {
    final currentState = state.value;
    if (currentState == null) return;

    final repo = ref.read(itineraryRepositoryProvider);
    final day = currentState.days[dayIndex];
    final updatedStops = day.stops.map((s) {
      if (s.id != stopId) return s;
      final ids = List<String>.from(s.checkedInMemberIds);
      if (ids.contains(memberId)) {
        ids.remove(memberId);
      } else {
        ids.add(memberId);
      }
      // If no one is checked in, remove arrived timestamp
      final nowVisited = ids.isNotEmpty ? (s.visitedAt ?? DateTime.now()) : null;
      final newStatus = ids.isNotEmpty ? StopStatus.arrived : StopStatus.approved;
      return s.copyWith(
        checkedInMemberIds: ids,
        visitedAt: nowVisited,
        status: newStatus,
      );
    }).toList();

    final updatedDay = day.copyWith(stops: updatedStops);
    final updatedDays = List<ItineraryDay>.from(currentState.days);
    updatedDays[dayIndex] = updatedDay;

    state = AsyncData(currentState.copyWith(days: updatedDays));
    await repo.saveItineraryDay(_tripId, updatedDay);
  }

  // ── Toggle entire stop as visited (own account check-in) ─────
  Future<void> toggleStopVisited(
    int dayIndex,
    String stopId,
    String memberId,
  ) async {
    final currentState = state.value;
    if (currentState == null) return;

    final repo = ref.read(itineraryRepositoryProvider);
    final day = currentState.days[dayIndex];
    final updatedStops = day.stops.map((s) {
      if (s.id != stopId) return s;
      final isNowVisited = !s.isCompleted;
      final ids = List<String>.from(s.checkedInMemberIds);
      if (isNowVisited && !ids.contains(memberId)) {
        ids.add(memberId);
      } else if (!isNowVisited) {
        ids.remove(memberId);
      }
      return s.copyWith(
        status: isNowVisited ? StopStatus.arrived : StopStatus.approved,
        visitedAt: isNowVisited ? DateTime.now() : null,
        checkedInMemberIds: ids,
      );
    }).toList();

    final updatedDay = day.copyWith(stops: updatedStops);
    final updatedDays = List<ItineraryDay>.from(currentState.days);
    updatedDays[dayIndex] = updatedDay;

    state = AsyncData(currentState.copyWith(days: updatedDays));
    await repo.saveItineraryDay(_tripId, updatedDay);
  }

  // ── Update checked-in members directly (Roll Call Sheet) ─────────
  Future<void> updateCheckedInMembers(
    int dayIndex,
    String stopId,
    List<String> memberIds,
  ) async {
    final currentState = state.value;
    if (currentState == null) return;

    final repo = ref.read(itineraryRepositoryProvider);
    final day = currentState.days[dayIndex];
    final updatedStops = day.stops.map((s) {
      if (s.id != stopId) return s;
      final nowVisited = memberIds.isNotEmpty ? (s.visitedAt ?? DateTime.now()) : null;
      final newStatus = memberIds.isNotEmpty ? StopStatus.arrived : StopStatus.approved;
      return s.copyWith(
        checkedInMemberIds: memberIds,
        visitedAt: nowVisited,
        status: newStatus,
      );
    }).toList();

    final updatedDay = day.copyWith(stops: updatedStops);
    final updatedDays = List<ItineraryDay>.from(currentState.days);
    updatedDays[dayIndex] = updatedDay;

    state = AsyncData(currentState.copyWith(days: updatedDays));
    await repo.saveItineraryDay(_tripId, updatedDay);
  }

  // ── Move a Stop to another Day ─────────────────────────────────────
  Future<void> moveStopToDay(int fromDayIndex, int toDayIndex, String stopId) async {
    final currentState = state.value;
    if (currentState == null || fromDayIndex == toDayIndex) return;

    final repo = ref.read(itineraryRepositoryProvider);
    final fromDay = currentState.days[fromDayIndex];
    final toDay = currentState.days[toDayIndex];

    final stopToMove = fromDay.stops.firstWhere((s) => s.id == stopId, orElse: () => fromDay.stops.first);
    final updatedFromStops = fromDay.stops.where((s) => s.id != stopId).toList();
    final updatedToStops = List<ItineraryStop>.from(toDay.stops)..add(stopToMove);

    final updatedFromDay = fromDay.copyWith(stops: updatedFromStops);
    final updatedToDay = toDay.copyWith(stops: updatedToStops);

    final updatedDays = List<ItineraryDay>.from(currentState.days);
    updatedDays[fromDayIndex] = updatedFromDay;
    updatedDays[toDayIndex] = updatedToDay;

    state = AsyncData(currentState.copyWith(days: updatedDays, activeDay: toDayIndex));

    await repo.deleteStop(stopId);
    await repo.saveItineraryDay(_tripId, updatedToDay);
  }

  // ── Duplicate Day's Stops into a new Day ─────────────────────────
  Future<void> duplicateDay(int dayIndex) async {
    final currentState = state.value;
    if (currentState == null) return;

    final repo = ref.read(itineraryRepositoryProvider);
    final sourceDay = currentState.days[dayIndex];
    final nextDayNum = currentState.days.length + 1;
    final lastDate = currentState.days.isNotEmpty
        ? currentState.days.last.date
        : DateTime.now();

    final clonedStops = sourceDay.stops.map((s) {
      final newId = 'cloned_${DateTime.now().millisecondsSinceEpoch}_${s.id}';
      return s.copyWith(
        id: newId,
        status: StopStatus.pending,
        visitedAt: null,
        checkedInMemberIds: const [],
      );
    }).toList();

    final newDay = ItineraryDay(
      dayNumber: nextDayNum,
      date: DateTime(lastDate.year, lastDate.month, lastDate.day + 1),
      stops: clonedStops,
    );

    final updatedDays = List<ItineraryDay>.from(currentState.days)..add(newDay);
    state = AsyncData(currentState.copyWith(days: updatedDays, activeDay: nextDayNum - 1));
    await repo.saveItineraryDay(_tripId, newDay);
  }

  // ── Shift Schedule by minutes (+30m, +60m, -30m, -60m) ───────────
  Future<void> shiftDaySchedule(int dayIndex, int minutesOffset) async {
    final currentState = state.value;
    if (currentState == null || minutesOffset == 0) return;

    final repo = ref.read(itineraryRepositoryProvider);
    final day = currentState.days[dayIndex];

    TimeOfDay? shiftTime(TimeOfDay? time) {
      if (time == null) return null;
      final totalMin = time.hour * 60 + time.minute + minutesOffset;
      final clampedMin = totalMin.clamp(0, 23 * 60 + 59);
      return TimeOfDay(hour: clampedMin ~/ 60, minute: clampedMin % 60);
    }

    final updatedStops = day.stops.map((s) {
      return s.copyWith(
        startTime: shiftTime(s.startTime),
        endTime: shiftTime(s.endTime),
      );
    }).toList();

    final updatedDay = day.copyWith(stops: updatedStops);
    final updatedDays = List<ItineraryDay>.from(currentState.days);
    updatedDays[dayIndex] = updatedDay;

    state = AsyncData(currentState.copyWith(days: updatedDays));
    await repo.saveItineraryDay(_tripId, updatedDay);
  }

  // ── Delete a Day from the Itinerary ──────────────────────────────
  Future<void> deleteDay(int dayIndex) async {
    final currentState = state.value;
    if (currentState == null || currentState.days.length <= 1) return;

    final repo = ref.read(itineraryRepositoryProvider);
    final dayToDelete = currentState.days[dayIndex];

    // Delete stops belonging to this day
    for (final stop in dayToDelete.stops) {
      await repo.deleteStop(stop.id);
    }

    final updatedDays = List<ItineraryDay>.from(currentState.days)..removeAt(dayIndex);

    // Re-index remaining days
    final reindexedDays = updatedDays.asMap().entries.map((entry) {
      final i = entry.key;
      final d = entry.value;
      return d.copyWith(dayNumber: i + 1);
    }).toList();

    final newActiveDay = (dayIndex >= reindexedDays.length)
        ? reindexedDays.length - 1
        : dayIndex;

    state = AsyncData(currentState.copyWith(days: reindexedDays, activeDay: newActiveDay));

    for (final d in reindexedDays) {
      await repo.saveItineraryDay(_tripId, d);
    }
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
