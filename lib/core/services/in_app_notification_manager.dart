import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_router.dart';

/// Type of in-app notification event
enum InAppNotificationType {
  expense,
  announcement,
  chat,
  geofenceArrival,
  convoySos,
  weather,
  packing,
  system,
}

/// An in-app floating banner event item
class InAppNotificationItem {
  final String id;
  final InAppNotificationType type;
  final String title;
  final String message;
  final String? subtitle;
  final NotificationPayload payload;
  final Duration duration;
  final DateTime createdAt;
  final bool isUrgent;

  InAppNotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.subtitle,
    required this.payload,
    Duration? duration,
    DateTime? createdAt,
    this.isUrgent = false,
  })  : duration = duration ?? (isUrgent ? const Duration(seconds: 8) : const Duration(seconds: 4)),
        createdAt = createdAt ?? DateTime.now();
}

/// State holding currently visible in-app notification (or null)
class InAppNotificationState {
  final InAppNotificationItem? current;
  final int queueLength;

  const InAppNotificationState({
    this.current,
    this.queueLength = 0,
  });

  InAppNotificationState copyWith({
    InAppNotificationItem? current,
    bool clearCurrent = false,
    int? queueLength,
  }) {
    return InAppNotificationState(
      current: clearCurrent ? null : (current ?? this.current),
      queueLength: queueLength ?? this.queueLength,
    );
  }
}

/// Provider for InAppNotificationManager
final inAppNotificationProvider =
    NotifierProvider<InAppNotificationManager, InAppNotificationState>(
  InAppNotificationManager.new,
);

/// Manager for in-app floating toast banners with queue, timers, and suppression.
class InAppNotificationManager extends Notifier<InAppNotificationState> {
  final Queue<InAppNotificationItem> _queue = Queue<InAppNotificationItem>();
  Timer? _dismissTimer;

  @override
  InAppNotificationState build() {
    ref.onDispose(() {
      _dismissTimer?.cancel();
    });
    return const InAppNotificationState();
  }

  /// Posts a new notification into the floating queue.
  void show(InAppNotificationItem item) {
    // Check screen duplicate suppression
    if (NotificationRouter.instance.shouldSuppress(item.payload.targetScreen)) {
      debugPrint('[InAppNotificationManager] Suppressing banner for ${item.payload.targetScreen} as user is already viewing it.');
      return;
    }

    if (item.isUrgent) {
      // Urgent items (e.g. SOS, urgent announcements) take priority
      _queue.addFirst(item);
    } else {
      _queue.addLast(item);
    }

    if (state.current == null) {
      _showNext();
    } else {
      state = state.copyWith(queueLength: _queue.length);
    }
  }

  /// Dismisses current banner immediately and shows next in queue.
  void dismissCurrent() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _showNext();
  }

  void _showNext() {
    if (_queue.isEmpty) {
      state = const InAppNotificationState();
      return;
    }

    final next = _queue.removeFirst();
    state = InAppNotificationState(
      current: next,
      queueLength: _queue.length,
    );

    _dismissTimer?.cancel();
    _dismissTimer = Timer(next.duration, () {
      dismissCurrent();
    });
  }
}
