import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Firebase Cloud Messaging integration for Tara Travel.
///
/// Handles:
/// - FCM device token retrieval and refresh
/// - Trip topic subscription/unsubscription (`trip_{tripId}`)
/// - Foreground notification display
/// - Token persistence to `users.fcm_token` in Supabase
///
/// Firebase packages (`firebase_core`, `firebase_messaging`) must be added
/// to pubspec.yaml. Until they are installed, this service operates as a
/// no-op stub that logs warnings — ensuring the rest of the app compiles
/// and runs without Firebase dependencies blocking development.
class FirebaseNotificationService {
  FirebaseNotificationService._();
  static final FirebaseNotificationService instance = FirebaseNotificationService._();

  bool _isInitialized = false;
  String? _currentToken;

  /// Whether Firebase has been successfully initialized.
  bool get isInitialized => _isInitialized;

  /// The current FCM device token, or null if not yet retrieved.
  String? get currentToken => _currentToken;

  /// Initializes Firebase and requests notification permissions.
  /// Call this once from main.dart after Supabase initialization.
  ///
  /// Returns silently if Firebase packages are not yet installed.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Dynamic import check — if firebase_core is not installed,
      // this will be handled by the stub pattern below.
      debugPrint('[FCM] Firebase notification service initializing...');

      // NOTE: When firebase_core and firebase_messaging are added to
      // pubspec.yaml, uncomment the following lines:
      //
      // await Firebase.initializeApp();
      // final messaging = FirebaseMessaging.instance;
      //
      // // Request permission (iOS & Android 13+)
      // final settings = await messaging.requestPermission(
      //   alert: true,
      //   badge: true,
      //   sound: true,
      //   provisional: false,
      // );
      // debugPrint('[FCM] Permission: ${settings.authorizationStatus}');
      //
      // // Get FCM token
      // _currentToken = await messaging.getToken();
      // debugPrint('[FCM] Token: $_currentToken');
      //
      // // Listen for token refresh
      // messaging.onTokenRefresh.listen((newToken) {
      //   _currentToken = newToken;
      //   _persistToken(newToken);
      // });
      //
      // // Foreground message handler
      // FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      //
      // // Background tap handler (when notification is tapped)
      // FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      //
      // // Persist initial token to Supabase
      // if (_currentToken != null) {
      //   await _persistToken(_currentToken!);
      // }

      _isInitialized = true;
      debugPrint('[FCM] Firebase notification service ready (stub mode).');
    } catch (e) {
      debugPrint('[FCM] Initialization error (non-fatal): $e');
    }
  }

  /// Subscribes the device to a trip's FCM topic.
  /// All messages published to `trip_{tripId}` will be received.
  Future<void> subscribeToTrip(String tripId) async {
    if (!_isInitialized) return;
    try {
      // await FirebaseMessaging.instance.subscribeToTopic('trip_$tripId');
      debugPrint('[FCM] Subscribed to topic: trip_$tripId');
    } catch (e) {
      debugPrint('[FCM] subscribeToTrip error: $e');
    }
  }

  /// Unsubscribes from a trip's FCM topic.
  Future<void> unsubscribeFromTrip(String tripId) async {
    if (!_isInitialized) return;
    try {
      // await FirebaseMessaging.instance.unsubscribeFromTopic('trip_$tripId');
      debugPrint('[FCM] Unsubscribed from topic: trip_$tripId');
    } catch (e) {
      debugPrint('[FCM] unsubscribeFromTrip error: $e');
    }
  }

  /// Persists the FCM token to the current user's profile in Supabase.
  Future<void> persistToken(String token) async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      await Supabase.instance.client
          .from('users')
          .update({'fcm_token': token})
          .eq('id', uid);
      debugPrint('[FCM] Token persisted to users.fcm_token');
    } catch (e) {
      debugPrint('[FCM] _persistToken error: $e');
    }
  }

  // /// Handles foreground messages (app is open).
  // void _handleForegroundMessage(RemoteMessage message) {
  //   debugPrint('[FCM] Foreground message: ${message.notification?.title}');
  //   // Show an in-app banner or update the chat badge
  // }
  //
  // /// Handles notification taps (app was in background).
  // void _handleNotificationTap(RemoteMessage message) {
  //   debugPrint('[FCM] Notification tap: ${message.data}');
  //   // Navigate to /chat or specific poll
  // }
}
