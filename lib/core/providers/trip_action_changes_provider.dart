import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/module_view_tracker_service.dart';
import '../models/trip_model.dart';
import '../../features/home/models/trip_card_badge_data.dart';
import 'auth_provider.dart';
import 'realtime_provider.dart';

final moduleViewTrackerProvider = Provider<ModuleViewTrackerService>((ref) {
  return ModuleViewTrackerService.instance;
});

/// Async provider computing unread / new modification change flags for trip modules.
/// Real-time streams automatically trigger recomputation for instant synchronization.
final tripQuickActionChangesProvider =
    FutureProvider.family<TripQuickActionChanges, TripModel>((ref, trip) async {
  final currentUserId = ref.watch(currentUserProvider)?.id;
  final tracker = ref.watch(moduleViewTrackerProvider);

  // Initialize tracker storage cache
  await tracker.initialize();

  // Watch real-time invalidation hooks
  ref.watch(itineraryRealtimeProvider(trip.id));
  ref.watch(packingRealtimeProvider(trip.id));
  ref.watch(expenseRealtimeProvider(trip.id));
  ref.watch(chatRealtimeProvider(trip.id));
  ref.watch(membersRealtimeProvider(trip.id));

  final supabase = Supabase.instance.client;

  // 1. Last viewed timestamps
  final lastViewedItinerary = tracker.getLastViewed('itinerary', trip.id);
  final lastViewedPacking = tracker.getLastViewed('packing', trip.id);
  final lastViewedMembers = tracker.getLastViewed('members', trip.id);
  final lastViewedExpenses = tracker.getLastViewed('expenses', trip.id);
  final lastViewedChat = tracker.getLastViewed('chat', trip.id);

  bool hasItineraryChanges = false;
  bool hasPackingChanges = false;
  bool hasMemberChanges = false;
  bool hasExpenseChanges = false;
  bool hasChatChanges = false;

  try {
    // ── Check Itinerary Stops Changes ──────────────────────────────
    var itQuery = supabase
        .from('itinerary_stops')
        .select('created_at, updated_at, assigned_user_id')
        .eq('trip_id', trip.id);

    if (lastViewedItinerary != null) {
      itQuery = itQuery.or(
        'created_at.gt.${lastViewedItinerary.toUtc().toIso8601String()},updated_at.gt.${lastViewedItinerary.toUtc().toIso8601String()}',
      );
    }
    final itRows = await itQuery.limit(5);
    if ((itRows as List).isNotEmpty) {
      // Exclude self updates if any
      final changes = itRows.where((r) {
        final assigned = r['assigned_user_id']?.toString();
        return currentUserId == null || assigned != currentUserId;
      });
      hasItineraryChanges = changes.isNotEmpty;
    }
  } catch (e) {
    debugPrint('[tripQuickActionChangesProvider] itinerary check error: $e');
  }

  try {
    // ── Check Packing Checklist Changes ────────────────────────────
    var packQuery = supabase
        .from('packing_items')
        .select('created_at, updated_at, assigned_user_id')
        .eq('trip_id', trip.id);

    if (lastViewedPacking != null) {
      packQuery = packQuery.or(
        'created_at.gt.${lastViewedPacking.toUtc().toIso8601String()},updated_at.gt.${lastViewedPacking.toUtc().toIso8601String()}',
      );
    }
    final packRows = await packQuery.limit(5);
    if ((packRows as List).isNotEmpty) {
      final changes = packRows.where((r) {
        final assigned = r['assigned_user_id']?.toString();
        return currentUserId == null || assigned != currentUserId;
      });
      hasPackingChanges = changes.isNotEmpty;
    }
  } catch (e) {
    debugPrint('[tripQuickActionChangesProvider] packing check error: $e');
  }

  try {
    // ── Check Members Changes ──────────────────────────────────────
    var memberQuery = supabase
        .from('trip_members')
        .select('joined_at, updated_at, user_id')
        .eq('trip_id', trip.id);

    if (lastViewedMembers != null) {
      memberQuery = memberQuery.or(
        'joined_at.gt.${lastViewedMembers.toUtc().toIso8601String()},updated_at.gt.${lastViewedMembers.toUtc().toIso8601String()}',
      );
    }
    final memberRows = await memberQuery.limit(5);
    if ((memberRows as List).isNotEmpty) {
      final changes = memberRows.where((r) {
        final memberUid = r['user_id']?.toString();
        return currentUserId == null || memberUid != currentUserId;
      });
      hasMemberChanges = changes.isNotEmpty;
    }
  } catch (e) {
    debugPrint('[tripQuickActionChangesProvider] members check error: $e');
  }

  try {
    // ── Check Expenses Changes ─────────────────────────────────────
    var expQuery = supabase
        .from('expenses')
        .select('created_at, updated_at, paid_by_user_id')
        .eq('trip_id', trip.id);

    if (lastViewedExpenses != null) {
      expQuery = expQuery.or(
        'created_at.gt.${lastViewedExpenses.toUtc().toIso8601String()},updated_at.gt.${lastViewedExpenses.toUtc().toIso8601String()}',
      );
    }
    final expRows = await expQuery.limit(5);
    if ((expRows as List).isNotEmpty) {
      final changes = expRows.where((r) {
        final paidBy = r['paid_by_user_id']?.toString();
        return currentUserId == null || paidBy != currentUserId;
      });
      hasExpenseChanges = changes.isNotEmpty;
    }
  } catch (e) {
    debugPrint('[tripQuickActionChangesProvider] expenses check error: $e');
  }

  try {
    // ── Check Unread Chat Messages ─────────────────────────────────
    var chatQuery = supabase
        .from('trip_messages')
        .select('created_at, user_id')
        .eq('trip_id', trip.id);

    if (lastViewedChat != null) {
      chatQuery = chatQuery.gt('created_at', lastViewedChat.toUtc().toIso8601String());
    }
    if (currentUserId != null) {
      chatQuery = chatQuery.neq('user_id', currentUserId);
    }
    final chatRows = await chatQuery.limit(10);
    hasChatChanges = (chatRows as List).isNotEmpty;
  } catch (e) {
    debugPrint('[tripQuickActionChangesProvider] chat check error: $e');
  }

  return TripQuickActionChanges(
    hasItineraryChanges: hasItineraryChanges,
    hasPackingChanges: hasPackingChanges,
    hasMemberChanges: hasMemberChanges,
    hasExpenseChanges: hasExpenseChanges,
    hasChatChanges: hasChatChanges,
  );
});
