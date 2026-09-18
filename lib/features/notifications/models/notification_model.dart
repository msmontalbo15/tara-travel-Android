enum NotificationCategory {
  expense,
  message,
  payment,
  proximity,
  weather,
  packing,
}

class NotificationItem {
  final String id;
  final NotificationCategory category;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? tripId;
  final String? targetScreen;
  final String? targetItemId;

  NotificationItem({
    required this.id,
    required this.category,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.tripId,
    this.targetScreen,
    this.targetItemId,
  });

  NotificationItem copyWith({
    String? id,
    NotificationCategory? category,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? tripId,
    String? targetScreen,
    String? targetItemId,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      tripId: tripId ?? this.tripId,
      targetScreen: targetScreen ?? this.targetScreen,
      targetItemId: targetItemId ?? this.targetItemId,
    );
  }

  factory NotificationItem.fromDb(Map<String, dynamic> row) {
    final type = '${row['type'] ?? ''}'.toLowerCase();
    NotificationCategory category;
    switch (type) {
      case 'expense':
      case 'expense_logged':
        category = NotificationCategory.expense;
        break;
      case 'message':
      case 'chat':
        category = NotificationCategory.message;
        break;
      case 'payment':
      case 'settlement':
        category = NotificationCategory.payment;
        break;
      case 'proximity':
      case 'location':
        category = NotificationCategory.proximity;
        break;
      case 'packing':
      case 'packing_reminder':
        category = NotificationCategory.packing;
        break;
      default:
        category = NotificationCategory.weather;
    }

    return NotificationItem(
      id: '${row['id']}',
      category: category,
      title: row['title']?.toString() ?? 'Notification',
      message: row['body']?.toString() ?? '',
      timestamp: DateTime.tryParse('${row['created_at']}') ?? DateTime.now(),
      isRead: row['read'] == true,
      tripId: row['trip_id']?.toString(),
      targetScreen: row['target_screen']?.toString() ?? (row['data'] is Map ? (row['data'] as Map)['target_screen']?.toString() : null),
      targetItemId: row['target_item_id']?.toString() ?? (row['data'] is Map ? (row['data'] as Map)['target_item_id']?.toString() : null),
    );
  }
}
