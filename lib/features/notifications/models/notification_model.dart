enum NotificationCategory {
  expense,
  message,
  payment,
  proximity,
  weather,
}

class NotificationItem {
  final String id;
  final NotificationCategory category;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.category,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  NotificationItem copyWith({
    String? id,
    NotificationCategory? category,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
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
    );
  }
}
