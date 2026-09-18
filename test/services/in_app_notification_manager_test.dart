import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tara_travel/core/services/in_app_notification_manager.dart';
import 'package:tara_travel/core/services/notification_router.dart';

void main() {
  group('InAppNotificationManager Tests', () {
    test('Shows notification and puts it in current state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      NotificationRouter.instance.onRouteChange('/home');

      final item = InAppNotificationItem(
        id: 'toast-1',
        type: InAppNotificationType.expense,
        title: 'New Expense',
        message: 'Juan paid ₱500 for lunch',
        payload: const NotificationPayload(
          targetScreen: NotificationTargetScreen.expenses,
        ),
      );

      container.read(inAppNotificationProvider.notifier).show(item);

      final state = container.read(inAppNotificationProvider);
      expect(state.current, isNotNull);
      expect(state.current!.title, 'New Expense');
      expect(state.queueLength, 0);
    });

    test('Suppresses notification when user is already viewing the target screen', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      NotificationRouter.instance.onRouteChange('/chat');

      final chatItem = InAppNotificationItem(
        id: 'toast-2',
        type: InAppNotificationType.chat,
        title: 'New Message',
        message: 'Hey everyone!',
        payload: const NotificationPayload(
          targetScreen: NotificationTargetScreen.chat,
        ),
      );

      container.read(inAppNotificationProvider.notifier).show(chatItem);

      final state = container.read(inAppNotificationProvider);
      expect(state.current, isNull);
    });

    test('Urgent notifications are prioritized at head of queue', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      NotificationRouter.instance.onRouteChange('/home');
      final notifier = container.read(inAppNotificationProvider.notifier);

      final regularItem1 = InAppNotificationItem(
        id: 'reg-1',
        type: InAppNotificationType.packing,
        title: 'Packing Update',
        message: 'Items packed',
        payload: const NotificationPayload(targetScreen: NotificationTargetScreen.packing),
      );
      final regularItem2 = InAppNotificationItem(
        id: 'reg-2',
        type: InAppNotificationType.weather,
        title: 'Weather Alert',
        message: 'Sunny day',
        payload: const NotificationPayload(targetScreen: NotificationTargetScreen.itinerary),
      );
      final urgentItem = InAppNotificationItem(
        id: 'urgent-1',
        type: InAppNotificationType.convoySos,
        title: 'Convoy SOS',
        message: 'Car tire punctured',
        isUrgent: true,
        payload: const NotificationPayload(targetScreen: NotificationTargetScreen.navigation),
      );

      notifier.show(regularItem1); // Current item
      notifier.show(regularItem2); // In queue
      notifier.show(urgentItem);   // In queue, should jump ahead of regularItem2

      notifier.dismissCurrent();

      final state = container.read(inAppNotificationProvider);
      expect(state.current?.id, 'urgent-1');
    });
  });
}
