import 'package:flutter/material.dart';

/// Supported notification target screen destinations.
enum NotificationTargetScreen {
  itinerary,
  expenses,
  chat,
  packing,
  members,
  navigation,
  tripDetail,
  notifications,
}

/// Standardized notification routing payload.
class NotificationPayload {
  final String? tripId;
  final NotificationTargetScreen targetScreen;
  final String? targetItemId;
  final int? targetDayNumber;
  final Map<String, dynamic>? extra;

  const NotificationPayload({
    this.tripId,
    required this.targetScreen,
    this.targetItemId,
    this.targetDayNumber,
    this.extra,
  });

  factory NotificationPayload.fromMap(Map<String, dynamic> map) {
    final rawTarget = '${map['target_screen'] ?? map['targetScreen'] ?? ''}'.toLowerCase().trim();
    NotificationTargetScreen target;
    switch (rawTarget) {
      case 'itinerary':
      case 'stop':
      case 'arrival':
        target = NotificationTargetScreen.itinerary;
        break;
      case 'expense':
      case 'expenses':
      case 'budget':
        target = NotificationTargetScreen.expenses;
        break;
      case 'chat':
      case 'message':
      case 'announcement':
      case 'poll':
        target = NotificationTargetScreen.chat;
        break;
      case 'packing':
      case 'checklist':
        target = NotificationTargetScreen.packing;
        break;
      case 'member':
      case 'members':
      case 'squad':
        target = NotificationTargetScreen.members;
        break;
      case 'navigation':
      case 'live_nav':
      case 'convoy':
        target = NotificationTargetScreen.navigation;
        break;
      case 'trip':
      case 'trip_detail':
        target = NotificationTargetScreen.tripDetail;
        break;
      default:
        target = NotificationTargetScreen.notifications;
    }

    return NotificationPayload(
      tripId: map['trip_id']?.toString() ?? map['tripId']?.toString(),
      targetScreen: target,
      targetItemId: map['target_item_id']?.toString() ?? map['targetItemId']?.toString(),
      targetDayNumber: map['target_day_number'] is int
          ? map['target_day_number'] as int
          : int.tryParse('${map['target_day_number'] ?? ''}'),
      extra: map['extra'] is Map<String, dynamic> ? map['extra'] as Map<String, dynamic> : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trip_id': tripId,
      'target_screen': targetScreen.name,
      'target_item_id': targetItemId,
      'target_day_number': targetDayNumber,
      'extra': extra,
    };
  }
}

/// Global routing coordinator for notification taps & deep links.
class NotificationRouter {
  NotificationRouter._();
  static final NotificationRouter instance = NotificationRouter._();

  /// Global navigator key attached to MaterialApp in main.dart
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Currently active route name tracked for duplicate suppression.
  String? currentRouteName;

  /// Updates the current active route name.
  void onRouteChange(String? routeName) {
    currentRouteName = routeName;
  }

  /// Evaluates whether an in-app banner for [target] should be suppressed
  /// because the user is already viewing that exact destination.
  bool shouldSuppress(NotificationTargetScreen target) {
    if (currentRouteName == null) return false;
    switch (target) {
      case NotificationTargetScreen.chat:
        return currentRouteName == '/chat';
      case NotificationTargetScreen.itinerary:
        return currentRouteName == '/itinerary';
      case NotificationTargetScreen.expenses:
        return currentRouteName == '/budget';
      case NotificationTargetScreen.packing:
        return currentRouteName == '/packing';
      case NotificationTargetScreen.members:
        return currentRouteName == '/members';
      case NotificationTargetScreen.navigation:
        return currentRouteName == '/navigation';
      case NotificationTargetScreen.tripDetail:
        return currentRouteName == '/trip-detail';
      case NotificationTargetScreen.notifications:
        return currentRouteName == '/notifications';
    }
  }

  /// Dispatches navigation based on payload coordinates.
  Future<bool> navigateTo(NotificationPayload payload) async {
    final nav = navigatorKey.currentState;
    if (nav == null) return false;

    switch (payload.targetScreen) {
      case NotificationTargetScreen.itinerary:
        nav.pushNamed(
          '/itinerary',
          arguments: {
            'targetStopId': payload.targetItemId,
            'targetDayNumber': payload.targetDayNumber,
          },
        );
        return true;

      case NotificationTargetScreen.expenses:
        nav.pushNamed(
          '/budget',
          arguments: {
            'highlightExpenseId': payload.targetItemId,
            'scopeIndex': 1, // Group expenses tab
          },
        );
        return true;

      case NotificationTargetScreen.chat:
        nav.pushNamed(
          '/chat',
          arguments: {
            'highlightMessageId': payload.targetItemId,
          },
        );
        return true;

      case NotificationTargetScreen.packing:
        nav.pushNamed(
          '/packing',
          arguments: {
            'highlightItemId': payload.targetItemId,
          },
        );
        return true;

      case NotificationTargetScreen.members:
        nav.pushNamed('/members');
        return true;

      case NotificationTargetScreen.navigation:
        nav.pushNamed('/navigation');
        return true;

      case NotificationTargetScreen.tripDetail:
        nav.pushNamed('/trip-detail');
        return true;

      case NotificationTargetScreen.notifications:
        nav.pushNamed('/notifications');
        return true;
    }
  }
}
