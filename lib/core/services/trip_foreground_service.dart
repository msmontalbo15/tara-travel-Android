import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Entry point executed by flutter_foreground_task in the background isolate.
@pragma('vm:entry-point')
void startTripForegroundTask() {
  FlutterForegroundTask.setTaskHandler(TripForegroundTaskHandler());
}

/// Task handler executing while the trip is actively running in the background.
class TripForegroundTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('[TripForegroundTask] Started at $timestamp');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Periodic light tick (e.g., checks every 5 minutes if next stop status needs updating)
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isStopping) async {
    debugPrint('[TripForegroundTask] Destroyed at $timestamp, isStopping: $isStopping');
  }

  @override
  void onNotificationButtonPressed(String id) {
    debugPrint('[TripForegroundTask] Notification button pressed: $id');
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }

  @override
  void onNotificationDismissed() {
    debugPrint('[TripForegroundTask] Notification dismissed');
  }
}

/// Manages starting, updating, and stopping the background foreground service
/// for active trip days so the operating system never terminates Tara Travel.
class TripForegroundService {
  TripForegroundService._();
  static final TripForegroundService instance = TripForegroundService._();

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  /// Initializes foreground task configuration.
  void initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'tara_active_trip_foreground',
        channelName: 'Tara Active Trip Service',
        channelDescription:
            'Keeps Tara Travel alive during active trip days for stop alerts and live navigation.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(300000), // Check every 5 mins
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// Starts the persistent foreground service when an active trip is detected today.
  Future<void> startActiveTripMonitoring({
    required String tripTitle,
    String? nextStopName,
    String? nextStopTime,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final String notificationText = nextStopName != null
        ? 'Next: $nextStopName${nextStopTime != null ? ' at $nextStopTime' : ''}'
        : 'Active trip monitoring enabled for today.';

    try {
      if (await FlutterForegroundTask.isRunningService) {
        await updateActiveTripStatus(
          title: '🌴 $tripTitle (Active)',
          text: notificationText,
        );
        _isRunning = true;
        return;
      }

      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: '🌴 $tripTitle (Active)',
        notificationText: notificationText,
        callback: startTripForegroundTask,
      );
      _isRunning = true;
      debugPrint('[TripForegroundService] Active trip foreground service started.');
    } catch (e) {
      debugPrint('[TripForegroundService] Failed to start foreground service: $e');
    }
  }

  /// Updates the status bar notification text dynamically (e.g. as next stop changes).
  Future<void> updateActiveTripStatus({
    required String title,
    required String text,
  }) async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: text,
      );
    }
  }

  /// Stops the background service when the trip day ends.
  Future<void> stopActiveTripMonitoring() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
      _isRunning = false;
      debugPrint('[TripForegroundService] Active trip foreground service stopped.');
    }
  }
}
