import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_model.dart';
import 'trip_provider.dart';
import 'profile_provider.dart';

class ActivityState {
  final List<ActivityItem> items;
  final String? filterMember;
  final ActivityType? filterType;

  const ActivityState({required this.items, this.filterMember, this.filterType});

  List<ActivityItem> get filtered {
    var list = items;
    if (filterMember != null) list = list.where((i) => i.actorName == filterMember).toList();
    if (filterType != null) list = list.where((i) => i.type == filterType).toList();
    return list;
  }

  ActivityState copyWith({List<ActivityItem>? items, String? filterMember, ActivityType? filterType}) {
    return ActivityState(
      items: items ?? this.items,
      filterMember: filterMember,
      filterType: filterType,
    );
  }
}

final activityProvider = FutureProvider<ActivityState>((ref) async {
  final activeTrip = await ref.watch(activeTripProvider.future);
  final profile = ref.watch(profileProvider);
  if (activeTrip == null) return const ActivityState(items: []);

  try {
    final rows = await Supabase.instance.client
        .from('activity_log')
        .select()
        .eq('trip_id', activeTrip.id)
        .order('created_at', ascending: false);

    ActivityType toType(String raw) {
      switch (raw) {
        case 'expense_approved':
          return ActivityType.expenseApproved;
        case 'expense_logged':
          return ActivityType.expenseLogged;
        case 'trip_created':
          return ActivityType.tripCreated;
        default:
          return ActivityType.tripUpdated;
      }
    }

    final items = (rows as List).map((row) {
      final map = (row as Map).cast<String, dynamic>();
      return ActivityItem(
        id: '${map['id']}',
        type: toType('${map['action_type'] ?? ''}'),
        actorName: profile.displayName,
        actorInitials: profile.initials,
        actorColor: profile.avatarColor.toARGB32(),
        description: map['description']?.toString() ?? '',
        timestamp: DateTime.tryParse('${map['created_at']}') ?? DateTime.now(),
      );
    }).toList();
    return ActivityState(items: items);
  } catch (_) {
    return const ActivityState(items: []);
  }
});
