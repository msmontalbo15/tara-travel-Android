import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/profile_repository.dart';
import 'in_app_notification_manager.dart';
import 'notification_router.dart';

/// Top-level background message handler annotated for AOT entry point.
/// Invoked by Firebase Messaging when the app is in background or terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    debugPrint('[FCM Background] Message received: ${message.messageId}');
    debugPrint('[FCM Background] Data payload: ${message.data}');
  } catch (e) {
    debugPrint('[FCM Background] Error in background handler: $e');
  }
}

/// Firebase Cloud Messaging service managing device wake-up push,
/// token synchronization, and deep-link routing.
class FcmService {
  FcmService._({
    FirebaseMessaging? messaging,
    ProfileRepository? profileRepository,
  })  : _messagingOverride = messaging,
        _profileRepoOverride = profileRepository;

  static final FcmService instance = FcmService._();

  final FirebaseMessaging? _messagingOverride;
  final ProfileRepository? _profileRepoOverride;
  ProfileRepository? _lazyProfileRepo;

  FirebaseMessaging get _messaging => _messagingOverride ?? FirebaseMessaging.instance;
  ProfileRepository get _profileRepo =>
      _profileRepoOverride ?? (_lazyProfileRepo ??= ProfileRepository());

  bool _isInitialized = false;
  String? _currentToken;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _messageOpenedSub;

  /// Whether the FCM service is active and initialized.
  bool get isInitialized => _isInitialized;

  /// The current cached FCM registration token.
  String? get currentToken => _currentToken;

  /// Initializes FCM listeners, permissions, and token sync.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        debugPrint('[FCM] Firebase not initialized; skipping FCM service.');
        return;
      }

      // Register top-level background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Request notification permissions (Android 13+ & iOS)
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

      // Enable foreground heads-up presentation
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Fetch registration token
      _currentToken = await _messaging.getToken();
      debugPrint('[FCM] Token retrieved: ${_currentToken != null ? "${_currentToken!.substring(0, 10)}..." : "null"}');
      if (_currentToken != null) {
        await syncTokenWithSupabase(_currentToken!);
      }

      // Listen for token refresh events
      _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) async {
        _currentToken = newToken;
        debugPrint('[FCM] Token refreshed');
        await syncTokenWithSupabase(newToken);
      });

      // Foreground message listener (App is running)
      _foregroundSub = FirebaseMessaging.onMessage.listen(handleForegroundMessage);

      // Background notification tap listener (App in background)
      _messageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(handleNotificationTap);

      // Cold start: Check if app was launched directly from terminated notification tap
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[FCM] App launched from terminated state via notification: ${initialMessage.messageId}');
        handleNotificationTap(initialMessage);
      }

      _isInitialized = true;
      debugPrint('[FCM] Service initialized successfully.');
    } catch (e, stack) {
      debugPrint('[FCM] Initialization error (non-fatal): $e\n$stack');
    }
  }

  /// Syncs the device token to Supabase `public.users` table for the current user.
  Future<void> syncTokenWithSupabase(String token) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('[FCM] User not authenticated; token sync deferred.');
        return;
      }
      await _profileRepo.updateFcmToken(user.id, token);
    } catch (e) {
      debugPrint('[FCM] Failed to sync token to Supabase: $e');
    }
  }

  /// Subscribes the current device to a trip topic for broadcast alerts.
  Future<void> subscribeToTrip(String tripId) async {
    if (kIsWeb || !_isInitialized || Firebase.apps.isEmpty) return;
    try {
      await _messaging.subscribeToTopic('trip_$tripId');
      debugPrint('[FCM] Subscribed to topic: trip_$tripId');
    } catch (e) {
      debugPrint('[FCM] Error subscribing to trip_$tripId: $e');
    }
  }

  /// Unsubscribes the device from a trip topic.
  Future<void> unsubscribeFromTrip(String tripId) async {
    if (kIsWeb || !_isInitialized || Firebase.apps.isEmpty) return;
    try {
      await _messaging.unsubscribeFromTopic('trip_$tripId');
      debugPrint('[FCM] Unsubscribed from topic: trip_$tripId');
    } catch (e) {
      debugPrint('[FCM] Error unsubscribing from trip_$tripId: $e');
    }
  }

  /// Clears the token on user sign-out to prevent stale cross-user pushes.
  Future<void> handleSignOut() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await _profileRepo.clearFcmToken(user.id);
      }
      if (_isInitialized && Firebase.apps.isNotEmpty) {
        await _messaging.deleteToken();
      }
      _currentToken = null;
      debugPrint('[FCM] Device token deleted on sign-out.');
    } catch (e) {
      debugPrint('[FCM] handleSignOut error: $e');
    }
  }

  /// Handles incoming notifications while the app is in the foreground.
  /// Translates remote message into an in-app banner unless currently suppressed.
  void handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message received: ${message.messageId}');
    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ?? data['title'] ?? 'Tara Travel';
    final body = notification?.body ?? data['body'] ?? data['message'] ?? '';
    final payload = NotificationPayload.fromMap(data);

    // Suppress if the user is already looking at this exact screen
    if (NotificationRouter.instance.shouldSuppress(payload.targetScreen)) {
      debugPrint('[FCM] Suppressing in-app banner for active screen: ${payload.targetScreen}');
      return;
    }

    // Determine type for styling & accent
    InAppNotificationType type;
    switch (payload.targetScreen) {
      case NotificationTargetScreen.chat:
        type = InAppNotificationType.chat;
        break;
      case NotificationTargetScreen.expenses:
        type = InAppNotificationType.expense;
        break;
      case NotificationTargetScreen.navigation:
        type = InAppNotificationType.convoySos;
        break;
      case NotificationTargetScreen.itinerary:
        type = InAppNotificationType.geofenceArrival;
        break;
      case NotificationTargetScreen.packing:
        type = InAppNotificationType.packing;
        break;
      default:
        type = InAppNotificationType.system;
    }

    final isUrgent = data['priority'] == 'high' ||
        data['is_urgent'] == 'true' ||
        type == InAppNotificationType.convoySos;

    final item = InAppNotificationItem(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      title: title,
      message: body,
      subtitle: data['subtitle'],
      payload: payload,
      isUrgent: isUrgent,
    );

    InAppNotificationManager.post(item);
  }

  /// Handles user tapping on a notification banner or system tray alert.
  void handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.data}');
    final payload = NotificationPayload.fromMap(message.data);
    NotificationRouter.instance.navigateTo(payload);
  }

  /// Disposes active stream subscriptions.
  void dispose() {
    _tokenRefreshSub?.cancel();
    _foregroundSub?.cancel();
    _messageOpenedSub?.cancel();
  }
}
