import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_provider.dart';
import '../providers/selected_trip_provider.dart';

/// StreamProvider that listens to Supabase realtime changes for expenses of a specific trip.
final expenseRealtimeProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, tripId) {
  final supabase = Supabase.instance.client;
  final isOffline = ref.watch(offlineModeProvider);
  if (isOffline) return const Stream.empty();

  return supabase
      .from('expenses')
      .stream(primaryKey: ['id'])
      .eq('trip_id', tripId)
      .map((event) {
        // Trigger invalidation of local/cached providers when data changes
        ref.invalidate(selectedTripProvider);
        return event;
      });
});

/// StreamProvider that listens to Supabase realtime changes for itinerary stops of a specific trip.
final itineraryRealtimeProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, tripId) {
  final supabase = Supabase.instance.client;
  final isOffline = ref.watch(offlineModeProvider);
  if (isOffline) return const Stream.empty();

  return supabase
      .from('itinerary_stops')
      .stream(primaryKey: ['id'])
      .eq('trip_id', tripId)
      .map((event) {
        ref.invalidate(selectedTripProvider);
        return event;
      });
});

/// StreamProvider that listens to Supabase realtime changes for packing items of a specific trip.
final packingRealtimeProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, tripId) {
  final supabase = Supabase.instance.client;
  final isOffline = ref.watch(offlineModeProvider);
  if (isOffline) return const Stream.empty();

  return supabase
      .from('packing_items')
      .stream(primaryKey: ['id'])
      .eq('trip_id', tripId)
      .map((event) {
        return event;
      });
});

/// StreamProvider that listens to Supabase realtime changes for trip members.
final membersRealtimeProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, tripId) {
  final supabase = Supabase.instance.client;
  final isOffline = ref.watch(offlineModeProvider);
  if (isOffline) return const Stream.empty();

  return supabase
      .from('trip_members')
      .stream(primaryKey: ['id'])
      .eq('trip_id', tripId)
      .map((event) {
        ref.invalidate(allTripsProvider);
        ref.invalidate(selectedTripProvider);
        return event;
      });
});
