import 'package:flutter_test/flutter_test.dart';
import 'package:tara_travel/core/services/crashlytics_service.dart';
import 'package:tara_travel/core/services/fcm_service.dart';
import 'package:tara_travel/core/services/notification_router.dart';

void main() {
  group('Dual-Cloud FCM & Remote Notification Tests', () {
    test('NotificationPayload parses chat push data map correctly', () {
      final map = {
        'trip_id': 'trip-baguio-101',
        'target_screen': 'chat',
        'target_item_id': 'msg-999',
        'priority': 'high',
      };

      final payload = NotificationPayload.fromMap(map);
      expect(payload.tripId, 'trip-baguio-101');
      expect(payload.targetScreen, NotificationTargetScreen.chat);
      expect(payload.targetItemId, 'msg-999');
    });

    test('NotificationPayload parses expense push data with extra metadata', () {
      final map = {
        'tripId': 'trip-elyu-202',
        'targetScreen': 'expenses',
        'targetItemId': 'exp-555',
        'extra': {'amount': 1500, 'category': 'Food'},
      };

      final payload = NotificationPayload.fromMap(map);
      expect(payload.tripId, 'trip-elyu-202');
      expect(payload.targetScreen, NotificationTargetScreen.expenses);
      expect(payload.targetItemId, 'exp-555');
      expect(payload.extra?['amount'], 1500);
    });

    test('NotificationPayload correctly parses convoy SOS navigation alerts', () {
      final map = {
        'trip_id': 'trip-sagada-303',
        'target_screen': 'convoy',
        'is_urgent': 'true',
      };

      final payload = NotificationPayload.fromMap(map);
      expect(payload.tripId, 'trip-sagada-303');
      expect(payload.targetScreen, NotificationTargetScreen.navigation);
    });

    test('NotificationRouter duplicate suppression matches active route', () {
      final router = NotificationRouter.instance;

      router.onRouteChange('/chat');
      expect(router.shouldSuppress(NotificationTargetScreen.chat), isTrue);
      expect(router.shouldSuppress(NotificationTargetScreen.expenses), isFalse);

      router.onRouteChange('/budget');
      expect(router.shouldSuppress(NotificationTargetScreen.expenses), isTrue);
      expect(router.shouldSuppress(NotificationTargetScreen.chat), isFalse);

      router.onRouteChange('/itinerary');
      expect(router.shouldSuppress(NotificationTargetScreen.itinerary), isTrue);

      router.onRouteChange('/home');
      expect(router.shouldSuppress(NotificationTargetScreen.chat), isFalse);
      expect(router.shouldSuppress(NotificationTargetScreen.expenses), isFalse);
    });

    test('CrashlyticsService records non-fatal error gracefully without throwing', () async {
      final crashlytics = CrashlyticsService.instance;
      expect(crashlytics.isInitialized, isFalse);

      // Safe invocation even if Firebase native runtime is uninitialized
      await expectLater(
        crashlytics.recordError(
          Exception('Simulated network timeout'),
          StackTrace.current,
          reason: 'Offline cache recovery testing',
        ),
        completes,
      );

      await expectLater(
        crashlytics.setCustomKey('test_mode', true),
        completes,
      );

      await expectLater(
        crashlytics.log('Breadcrumb: User navigated to offline map'),
        completes,
      );
    });

    test('FcmService initial state is safe before platform initialization', () {
      final fcm = FcmService.instance;
      expect(fcm.isInitialized, isFalse);
      expect(fcm.currentToken, isNull);
    });
  });
}
