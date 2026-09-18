import 'package:flutter_test/flutter_test.dart';
import 'package:tara_travel/core/services/notification_router.dart';

void main() {
  group('NotificationRouter & Payload Tests', () {
    test('Correctly maps raw string target into NotificationTargetScreen', () {
      final payload1 = NotificationPayload.fromMap({
        'trip_id': 'trip-123',
        'target_screen': 'itinerary',
        'target_item_id': 'stop-456',
        'target_day_number': 2,
      });

      expect(payload1.tripId, 'trip-123');
      expect(payload1.targetScreen, NotificationTargetScreen.itinerary);
      expect(payload1.targetItemId, 'stop-456');
      expect(payload1.targetDayNumber, 2);

      final payload2 = NotificationPayload.fromMap({
        'target_screen': 'expenses',
        'target_item_id': 'exp-789',
      });
      expect(payload2.targetScreen, NotificationTargetScreen.expenses);
      expect(payload2.targetItemId, 'exp-789');

      final payload3 = NotificationPayload.fromMap({
        'target_screen': 'chat',
      });
      expect(payload3.targetScreen, NotificationTargetScreen.chat);
    });

    test('shouldSuppress checks currentRouteName accurately', () {
      final router = NotificationRouter.instance;

      router.onRouteChange('/chat');
      expect(router.shouldSuppress(NotificationTargetScreen.chat), isTrue);
      expect(router.shouldSuppress(NotificationTargetScreen.itinerary), isFalse);

      router.onRouteChange('/budget');
      expect(router.shouldSuppress(NotificationTargetScreen.expenses), isTrue);
      expect(router.shouldSuppress(NotificationTargetScreen.chat), isFalse);

      router.onRouteChange('/itinerary');
      expect(router.shouldSuppress(NotificationTargetScreen.itinerary), isTrue);
    });
  });
}
