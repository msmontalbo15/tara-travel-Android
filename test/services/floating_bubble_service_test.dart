import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tara_travel/core/services/floating_bubble_service.dart';

void main() {
  group('FloatingBubbleNotifier Tests', () {
    test('Shows and hides bubble with telemetry data', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(floatingBubbleProvider.notifier);

      expect(container.read(floatingBubbleProvider).isVisible, isFalse);

      notifier.showBubble(
        tripId: 'trip-abc',
        nextStopName: 'Baguio Grand Terminal',
        nextStopEta: '10:30 AM',
        nextStopDistanceKm: 14.5,
      );

      final state = container.read(floatingBubbleProvider);
      expect(state.isVisible, isTrue);
      expect(state.nextStopName, 'Baguio Grand Terminal');
      expect(state.nextStopDistanceKm, 14.5);

      notifier.toggleExpanded();
      expect(container.read(floatingBubbleProvider).isExpanded, isTrue);

      notifier.hideBubble();
      expect(container.read(floatingBubbleProvider).isVisible, isFalse);
    });

    test('Magnetic snap to edge positions correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(floatingBubbleProvider.notifier);

      // Drag to left half of 400px wide screen
      notifier.updatePosition(const Offset(80, 250), const Size(400, 800));
      expect(container.read(floatingBubbleProvider).position.dx, 16.0);

      // Drag to right half of 400px wide screen
      notifier.updatePosition(const Offset(350, 250), const Size(400, 800));
      // 400 - 56 - 16 = 328
      expect(container.read(floatingBubbleProvider).position.dx, 328.0);
    });
  });
}
