import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Handles high-volume, urgent itinerary alarms, lock screen wake-up banners,
/// and exact alarm triggers for travelers even when Tara Travel is closed or screen is off.
class ItineraryAlarmService {
  ItineraryAlarmService._();
  static final ItineraryAlarmService instance = ItineraryAlarmService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Channel IDs
  static const String urgentChannelId = 'tara_urgent_itinerary_alarm';
  static const String urgentChannelName = 'Urgent Itinerary Alarms';
  static const String urgentChannelDesc =
      'High-urgency audio alarms for departure times, transit, and upcoming stops';

  static const String standardChannelId = 'tara_standard_itinerary_channel';
  static const String standardChannelName = 'Itinerary Reminders';
  static const String standardChannelDesc =
      'Upcoming stop advisories and casual itinerary reminders';

  /// Initializes timezone data and native Android/iOS notification channel pipelines.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create Android Notification Channels
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidPlatform =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidPlatform != null) {
          // 1. High-Urgency Alarm Channel (Routes to USAGE_ALARM stream, high priority, wakes screen)
          const AndroidNotificationChannel urgentChannel = AndroidNotificationChannel(
            urgentChannelId,
            urgentChannelName,
            description: urgentChannelDesc,
            importance: Importance.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('tara_urgent_alert'),
            enableVibration: true,
            audioAttributesUsage: AudioAttributesUsage.alarm,
          );

          // 2. Standard Channel for general reminders
          const AndroidNotificationChannel standardChannel = AndroidNotificationChannel(
            standardChannelId,
            standardChannelName,
            description: standardChannelDesc,
            importance: Importance.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('tara_urgent_alert'),
            enableVibration: true,
          );

          await androidPlatform.createNotificationChannel(urgentChannel);
          await androidPlatform.createNotificationChannel(standardChannel);
        }
      }

      _isInitialized = true;
      debugPrint('[ItineraryAlarmService] Native alarm notification channels initialized.');
    } catch (e, st) {
      debugPrint('[ItineraryAlarmService] Initialization failed: $e\n$st');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[ItineraryAlarmService] Notification tapped: ${response.payload}');
    // Deep-link routing can hook into payload
  }

  /// Schedules an exact urgent alarm for an upcoming itinerary stop or departure.
  /// Wakes device CPU and turns screen on if screen is off.
  Future<void> scheduleStopAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    bool isUrgent = true,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    final now = DateTime.now();
    if (scheduledDate.isBefore(now)) return;

    final tz.TZDateTime tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      isUrgent ? urgentChannelId : standardChannelId,
      isUrgent ? urgentChannelName : standardChannelName,
      channelDescription: isUrgent ? urgentChannelDesc : standardChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      sound: const RawResourceAndroidNotificationSound('tara_urgent_alert'),
      playSound: true,
      fullScreenIntent: isUrgent, // Wakes the lock screen
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: isUrgent ? AudioAttributesUsage.alarm : AudioAttributesUsage.notification,
      vibrationPattern: Int64List.fromList([0, 800, 300, 800, 300, 1000]),
      styleInformation: BigTextStyleInformation(body),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'tara_urgent_alert.caf',
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduled,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    debugPrint(
      '[ItineraryAlarmService] Scheduled stop alarm id=$id for $tzScheduled (Urgent: $isUrgent)',
    );
  }

  /// Cancels an existing stop alarm by ID.
  Future<void> cancelAlarm(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancels all scheduled alarms.
  Future<void> cancelAllAlarms() async {
    await _notificationsPlugin.cancelAll();
  }
}
