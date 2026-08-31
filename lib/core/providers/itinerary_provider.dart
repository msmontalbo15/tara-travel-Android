import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/itinerary_model.dart';
import '../providers/repository_providers.dart';
import '../providers/trip_provider.dart';

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



  // ── Add a new Day to the itinerary ──────────────────────────────
  Future<ItineraryDay?> addDay({DateTime? customDate}) async {
    final currentState = state.value;
    if (currentState == null) return null;

    final repo = ref.read(itineraryRepositoryProvider);
    final tripRepo = ref.read(tripRepositoryProvider);
    final nextDayNum = currentState.days.length + 1;

    final trip = await tripRepo.getTripById(_tripId);

    DateTime nextDate;
    if (customDate != null) {
      nextDate = customDate;
    } else if (currentState.days.isNotEmpty) {
      final lastDate = currentState.days.last.date;
      nextDate = DateTime(lastDate.year, lastDate.month, lastDate.day + 1);
    } else {
      nextDate = trip?.fromDate ?? DateTime.now();
    }

    final newDay = ItineraryDay(
      dayNumber: nextDayNum,
      date: nextDate,
      stops: const [],
    );

    final updatedDays = List<ItineraryDay>.from(currentState.days)..add(newDay);
    state = AsyncData(currentState.copyWith(
      days: updatedDays,
      activeDay: nextDayNum - 1,
    ));

    // If the new date exceeds the trip's toDate, extend the trip's end_date
    if (trip != null && nextDate.isAfter(trip.toDate)) {
      try {
        final updatedTrip = trip.copyWith(toDate: nextDate);
        await tripRepo.updateTrip(updatedTrip);
        ref.invalidate(activeTripProvider);
        ref.invalidate(allTripsProvider);
      } catch (e) {
        debugPrint('[ItineraryNotifier] Error extending trip end_date: $e');
      }
    }

    await repo.saveItineraryDay(_tripId, newDay);
    return newDay;
  }

  // ── Clear all stops in a Day ──────────────────────────────────────
  Future<void> clearDay(int dayIndex) async {
    final currentState = state.value;
    if (currentState == null) return;

    final repo = ref.read(itineraryRepositoryProvider);
    final day = currentState.days[dayIndex];
    final stopIds = day.stops.map((s) => s.id).toList();

    final updatedDay = day.copyWith(stops: const []);
    final updatedDays = List<ItineraryDay>.from(currentState.days);
    updatedDays[dayIndex] = updatedDay;

    state = AsyncData(currentState.copyWith(days: updatedDays));
    if (stopIds.isNotEmpty) {
      await repo.deleteStops(stopIds);
    }
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
      return s.copyWith(
        checkedInMemberIds: ids,
        visitedAt: nowVisited,
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
      return s.copyWith(
        checkedInMemberIds: memberIds,
        visitedAt: nowVisited,
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

    // Save both source and destination days to sync day_number and sort_order in Supabase
    await repo.saveItineraryDay(_tripId, updatedFromDay);
    await repo.saveItineraryDay(_tripId, updatedToDay);
  }

  // ── Duplicate Day's Stops into a new Day ─────────────────────────
  Future<void> duplicateDay(int dayIndex) async {
    final currentState = state.value;
    if (currentState == null) return;

    final repo = ref.read(itineraryRepositoryProvider);
    final tripRepo = ref.read(tripRepositoryProvider);
    final sourceDay = currentState.days[dayIndex];
    final nextDayNum = currentState.days.length + 1;
    final lastDate = currentState.days.isNotEmpty
        ? currentState.days.last.date
        : DateTime.now();

    final newDayDate = DateTime(lastDate.year, lastDate.month, lastDate.day + 1);

    final clonedStops = sourceDay.stops.map((s) {
      return s.copyWith(
        id: const Uuid().v4(),
        visitedAt: null,
        checkedInMemberIds: const [],
      );
    }).toList();

    final newDay = ItineraryDay(
      dayNumber: nextDayNum,
      date: newDayDate,
      stops: clonedStops,
    );

    final updatedDays = List<ItineraryDay>.from(currentState.days)..add(newDay);
    state = AsyncData(currentState.copyWith(days: updatedDays, activeDay: nextDayNum - 1));

    // If duplicated day extends past trip end_date, synchronize end_date to Supabase
    final trip = await tripRepo.getTripById(_tripId);
    if (trip != null && newDayDate.isAfter(trip.toDate)) {
      try {
        final updatedTrip = trip.copyWith(toDate: newDayDate);
        await tripRepo.updateTrip(updatedTrip);
        ref.invalidate(activeTripProvider);
        ref.invalidate(allTripsProvider);
      } catch (e) {
        debugPrint('[ItineraryNotifier] Error extending trip end_date on duplicateDay: $e');
      }
    }

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
    final tripRepo = ref.read(tripRepositoryProvider);
    final dayToDelete = currentState.days[dayIndex];
    final stopIds = dayToDelete.stops.map((s) => s.id).toList();

    final trip = await tripRepo.getTripById(_tripId);

    final updatedDays = List<ItineraryDay>.from(currentState.days)..removeAt(dayIndex);

    // Re-index remaining days and adjust consecutive calendar dates
    final tripStart = trip?.fromDate ?? currentState.days.first.date;
    final reindexedDays = updatedDays.asMap().entries.map((entry) {
      final i = entry.key;
      final d = entry.value;
      return d.copyWith(
        dayNumber: i + 1,
        date: DateTime(tripStart.year, tripStart.month, tripStart.day + i),
      );
    }).toList();

    final newActiveDay = (dayIndex >= reindexedDays.length)
        ? reindexedDays.length - 1
        : dayIndex;

    state = AsyncData(currentState.copyWith(days: reindexedDays, activeDay: newActiveDay));

    // 1. Delete all stops belonging to the deleted day from Supabase
    if (stopIds.isNotEmpty) {
      await repo.deleteStops(stopIds);
    }

    // 2. Persist re-indexed days & updated day_number for their stops to Supabase
    for (final d in reindexedDays) {
      await repo.saveItineraryDay(_tripId, d);
    }

    // 3. Purge any orphan stops with day_number higher than the new total days in Supabase
    await repo.deleteStopsBeyondDay(_tripId, reindexedDays.length);

    // 4. Shorten trip end_date in the `trips` table in Supabase so the deleted day doesn't reappear
    if (trip != null) {
      try {
        final newEndDate = DateTime(
          tripStart.year,
          tripStart.month,
          tripStart.day + (reindexedDays.length - 1),
        );
        final updatedTrip = trip.copyWith(toDate: newEndDate);
        await tripRepo.updateTrip(updatedTrip);
        ref.invalidate(activeTripProvider);
        ref.invalidate(allTripsProvider);
      } catch (e) {
        debugPrint('[ItineraryNotifier] Error updating trip end_date on deleteDay: $e');
      }
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
