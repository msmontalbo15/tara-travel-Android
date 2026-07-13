enum ActivityType {
  expenseLogged,
  expenseApproved,
  expenseRejected,
  paymentMade,
  paymentConfirmed,
  memberJoined,
  memberRoleChanged,
  itineraryStopAdded,
  itineraryStopChanged,
  packingUpdated,
  tripCreated,
  tripUpdated,
  contributionRequested,
}

extension ActivityTypeX on ActivityType {
  String get emoji {
    switch (this) {
      case ActivityType.expenseLogged:
        return '💸';
      case ActivityType.expenseApproved:
        return '✅';
      case ActivityType.expenseRejected:
        return '❌';
      case ActivityType.paymentMade:
        return '💳';
      case ActivityType.paymentConfirmed:
        return '✔️';
      case ActivityType.memberJoined:
        return '👋';
      case ActivityType.memberRoleChanged:
        return '🎖️';
      case ActivityType.itineraryStopAdded:
        return '📍';
      case ActivityType.itineraryStopChanged:
        return '✏️';
      case ActivityType.packingUpdated:
        return '🎒';
      case ActivityType.tripCreated:
        return '🌏';
      case ActivityType.tripUpdated:
        return '📝';
      case ActivityType.contributionRequested:
        return '📬';
    }
  }
}

class ActivityItem {
  final String id;
  final ActivityType type;
  final String actorName;
  final String actorInitials;
  final int actorColor;
  final String description;
  final DateTime timestamp;

  const ActivityItem({
    required this.id,
    required this.type,
    required this.actorName,
    required this.actorInitials,
    required this.actorColor,
    required this.description,
    required this.timestamp,
  });
}
