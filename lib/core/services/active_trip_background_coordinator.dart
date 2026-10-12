import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/itinerary_model.dart';
import '../providers/trip_provider.dart';
import '../providers/itinerary_provider.dart';
import 'itinerary_alarm_service.dart';
import 'trip_foreground_service.dart';

/// Coordinator that automatically evaluates active trips for today,
/// starts the background foreground keep-alive service, and schedules
/// high-urgency alarms for upcoming itinerary stops.
class ActiveTripBackgroundCoordinator {
  ActiveTripBackgroundCoordinator(this.ref);

  final Ref ref;

  /// Syncs foreground keep-alive and stop alarms for the active trip.
  Future<void> syncActiveTripBackgroundState() async {
    try {
      final activeTrip = await ref.read(activeTripProvider.future);
      if (activeTrip == null) {
        // No active trip -> ensure background keep-alive is shut down
        await TripForegroundService.instance.stopActiveTripMonitoring();
        return;
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tripStart = DateTime(
        activeTrip.fromDate.year,
        activeTrip.fromDate.month,
        activeTrip.fromDate.day,
      );
      final tripEnd = DateTime(
        activeTrip.toDate.year,
        activeTrip.toDate.month,
        activeTrip.toDate.day,
        23,
        59,
        59,
      );

      final isTripActiveToday = !today.isBefore(tripStart) && !today.isAfter(tripEnd) && !activeTrip.isArchived;

      if (!isTripActiveToday) {
        await TripForegroundService.instance.stopActiveTripMonitoring();
        return;
      }

      // ── 1. Fetch Today's Stops ─────────────────────────────────────
      final subProvider = ref.read(itineraryProvider(activeTrip.id));
      final itineraryState = await ref.read(subProvider.future);
      
      ItineraryStop? nextUpcomingStop;
      DateTime? nextStopTime;

      for (final day in itineraryState.days) {
        final dayDate = DateTime(day.date.year, day.date.month, day.date.day);
        if (dayDate == today) {
          for (final stop in day.stops) {
            if (stop.isCompleted || stop.startTime == null) continue;

            final stopDateTime = DateTime(
              today.year,
              today.month,
              today.day,
              stop.startTime!.hour,
              stop.startTime!.minute,
            );

            if (stopDateTime.isAfter(now)) {
              if (nextStopTime == null || stopDateTime.isBefore(nextStopTime)) {
                nextStopTime = stopDateTime;
                nextUpcomingStop = stop;
              }

              // ── 2. Schedule Urgent Exact Alarms ──────────────────
              // (15 minutes before stop time for high urgency alert)
              final alertDateTime = stopDateTime.subtract(const Duration(minutes: 15));
              final alarmId = stop.id.hashCode;

              await ItineraryAlarmService.instance.scheduleStopAlarm(
                id: alarmId,
                title: '🚨 Next Stop: ${stop.title}',
                body: '15 minutes until arrival at ${stop.location ?? stop.title}. Gather your belongings!',
                scheduledDate: alertDateTime.isAfter(now) ? alertDateTime : stopDateTime,
                isUrgent: true,
                payload: 'trip:${activeTrip.id}:stop:${stop.id}',
              );
            }
          }
        }
      }

      // ── 3. Start or Update Persistent Foreground Service ───────────
      String? nextStopFormattedTime;
      if (nextStopTime != null && nextUpcomingStop?.startTime != null) {
        final h = nextUpcomingStop!.startTime!.hour;
        final m = nextUpcomingStop.startTime!.minute.toString().padLeft(2, '0');
        final period = h >= 12 ? 'PM' : 'AM';
        final displayHour = h % 12 == 0 ? 12 : h % 12;
        nextStopFormattedTime = '$displayHour:$m $period';
      }

      await TripForegroundService.instance.startActiveTripMonitoring(
        tripTitle: activeTrip.name,
        nextStopName: nextUpcomingStop?.title,
        nextStopTime: nextStopFormattedTime,
      );

      debugPrint(
        '[ActiveTripBackgroundCoordinator] Synced background keep-alive & alarms for ${activeTrip.name}. Next stop: ${nextUpcomingStop?.title}',
      );
    } catch (e, st) {
      debugPrint('[ActiveTripBackgroundCoordinator] Sync failed: $e\n$st');
    }
  }
}

/// Riverpod provider exposing ActiveTripBackgroundCoordinator
final activeTripBackgroundCoordinatorProvider =
    Provider<ActiveTripBackgroundCoordinator>((ref) {
  return ActiveTripBackgroundCoordinator(ref);
});
