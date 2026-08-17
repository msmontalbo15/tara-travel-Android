import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_provider.dart';
import '../providers/selected_trip_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TARA TRAVEL · REALTIME PROVIDERS
// Supabase Realtime stream providers for live UI updates.
//
// All providers are:
//   • Family-keyed by tripId for per-trip subscriptions.
//   • Short-circuited in offline mode (empty stream).
//   • Side-effect: invalidate cached query providers on each emission so that
//     the UI rebuilds from fresh remote data.
// ─────────────────────────────────────────────────────────────────────────────

// ── Expenses ─────────────────────────────────────────────────────────────────

final expenseRealtimeProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, tripId) {
  final isOffline = ref.watch(offlineModeProvider);
  if (isOffline) return const Stream.empty();

  return Supabase.instance.client
      .from('expenses')
      .stream(primaryKey: ['id'])
      .eq('trip_id', tripId)
      .map((rows) {
        ref.invalidate(selectedTripProvider);
        ref.invalidate(allTripsProvider);
        ref.invalidate(activeTripProvider);
        return rows;
      });
});

// ── Itinerary Stops ───────────────────────────────────────────────────────────

final itineraryRealtimeProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, tripId) {
  final isOffline = ref.watch(offlineModeProvider);
  if (isOffline) return const Stream.empty();

  return Supabase.instance.client
      .from('itinerary_stops')
      .stream(primaryKey: ['id'])
      .eq('trip_id', tripId)
      .map((rows) {
        ref.invalidate(selectedTripProvider);
        ref.invalidate(allTripsProvider);
        ref.invalidate(activeTripProvider);
        return rows;
      });
});

// ── Packing Items ─────────────────────────────────────────────────────────────

final packingRealtimeProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, tripId) {
  final isOffline = ref.watch(offlineModeProvider);
  if (isOffline) return const Stream.empty();

  return Supabase.instance.client
      .from('packing_items')
      .stream(primaryKey: ['id'])
      .eq('trip_id', tripId)
      .map((rows) {
        ref.invalidate(selectedTripProvider);
        ref.invalidate(allTripsProvider);
        ref.invalidate(activeTripProvider);
        return rows;
      });
});

// ── Trip Members (presence + location) ───────────────────────────────────────

final membersRealtimeProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, tripId) {
  final isOffline = ref.watch(offlineModeProvider);
  if (isOffline) return const Stream.empty();

  return Supabase.instance.client
      .from('trip_members')
      .stream(primaryKey: ['id'])
      .eq('trip_id', tripId)
      .map((rows) {
        ref.invalidate(allTripsProvider);
        ref.invalidate(selectedTripProvider);
        ref.invalidate(activeTripProvider);
        return rows;
      });
});

// ── Member Locations (GPS-only, filtered stream) ──────────────────────────────
// Streams trip_members rows that have location_sharing enabled and have live
// coordinates — used by the map / buddy-tracker UI.

final memberLocationsRealtimeProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, tripId) {
  final isOffline = ref.watch(offlineModeProvider);
  if (isOffline) return const Stream.empty();

  return Supabase.instance.client
      .from('trip_members')
      .stream(primaryKey: ['id'])
      .eq('trip_id', tripId)
      .map((rows) => rows
          .where((r) =>
              r['location_sharing'] == true &&
              r['last_lat'] != null &&
              r['last_lng'] != null)
          .toList());
});

// ── Stop Votes ────────────────────────────────────────────────────────────────

final stopVotesRealtimeProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, tripId) {
  final isOffline = ref.watch(offlineModeProvider);
  if (isOffline) return const Stream.empty();

  return Supabase.instance.client
      .from('stop_votes')
      .stream(primaryKey: ['id'])
      .eq('trip_id', tripId);
});

// ── Settlements ───────────────────────────────────────────────────────────────

final settlementsRealtimeProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, tripId) {
  final isOffline = ref.watch(offlineModeProvider);
  if (isOffline) return const Stream.empty();

  return Supabase.instance.client
      .from('settlements')
      .stream(primaryKey: ['id'])
      .eq('trip_id', tripId);
});

// ── Trip Chat Messages ────────────────────────────────────────────────────────

final chatRealtimeProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, tripId) {
  final isOffline = ref.watch(offlineModeProvider);
  if (isOffline) return const Stream.empty();

  return Supabase.instance.client
      .from('trip_messages')
      .stream(primaryKey: ['id'])
      .eq('trip_id', tripId)
      .order('created_at', ascending: true);
});

// ── Notifications (current user) ──────────────────────────────────────────────

final notificationsRealtimeProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final isOffline = ref.watch(offlineModeProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (isOffline || userId == null) return const Stream.empty();

  return Supabase.instance.client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .limit(50);
});

// ── Activity Log ──────────────────────────────────────────────────────────────

final activityLogRealtimeProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, tripId) {
  final isOffline = ref.watch(offlineModeProvider);
  if (isOffline) return const Stream.empty();

  return Supabase.instance.client
      .from('activity_log')
      .stream(primaryKey: ['id'])
      .eq('trip_id', tripId)
      .order('created_at', ascending: false)
      .limit(100);
});
