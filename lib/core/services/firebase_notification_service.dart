import 'fcm_service.dart';

/// Legacy facade for Firebase notification operations, delegating to [FcmService].
class FirebaseNotificationService {
  FirebaseNotificationService._();
  static final FirebaseNotificationService instance = FirebaseNotificationService._();

  bool get isInitialized => FcmService.instance.isInitialized;
  String? get currentToken => FcmService.instance.currentToken;

  Future<void> initialize() => FcmService.instance.initialize();
  Future<void> subscribeToTrip(String tripId) => FcmService.instance.subscribeToTrip(tripId);
  Future<void> unsubscribeFromTrip(String tripId) => FcmService.instance.unsubscribeFromTrip(tripId);
  Future<void> persistToken(String token) => FcmService.instance.syncTokenWithSupabase(token);
}
