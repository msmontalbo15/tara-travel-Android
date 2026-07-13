import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trip_model.dart';
import '../services/database_service.dart';
import 'package:sembast/sembast.dart';

class TripRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DatabaseService _db = DatabaseService.instance;

  StoreRef<String, Map<String, dynamic>> get _tripStore =>
      _db.getStore(DatabaseService.tripStore);

  // ────────────────────────────────────────────────────────────────
  // READ
  // ────────────────────────────────────────────────────────────────

  /// Fetches trips from Supabase and updates local cache.
  /// Falls back to local cache if offline.
  Future<List<TripModel>> getTrips() async {
    final db = await _db.database;

    try {
      // Scope to trips the current user owns or is a member of
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return _loadLocalTrips(db);

      final response = await _supabase
          .from('trips')
          .select('*, trip_members!inner(*, users(*)), expenses(*)')
          .or('owner_id.eq.$userId,trip_members.user_id.eq.$userId')
          .order('start_date', ascending: true);

      final trips = (response as List)
          .map((json) => TripModel.fromMap((json as Map).cast<String, dynamic>()))
          .toList();

      // Update local cache
      await db.transaction((txn) async {
        for (final trip in trips) {
          await _tripStore.record(trip.id).put(txn, trip.toMap());
        }
      });

      return trips;
    } catch (e) {
      debugPrint('[TripRepository] getTrips error: $e');
      return _loadLocalTrips(db);
    }
  }

  Future<List<TripModel>> _loadLocalTrips(Database db) async {
    final snapshots = await _tripStore.find(
      db,
      finder: Finder(sortOrders: [SortOrder('start_date')]),
    );
    return snapshots.map((s) => TripModel.fromMap(s.value)).toList();
  }

  /// Fetches a single trip by ID (local cache first, Supabase fallback)
  Future<TripModel?> getTripById(String tripId) async {
    final db = await _db.database;

    // Try local first for instant response
    final local = await _tripStore.record(tripId).get(db);
    if (local != null) return TripModel.fromMap(local);

    try {
      final response = await _supabase
          .from('trips')
          .select('*, trip_members(*, users(*)), expenses(*)')
          .eq('id', tripId)
          .maybeSingle();

      if (response == null) return null;
      final trip = TripModel.fromMap((response as Map).cast<String, dynamic>());
      await _tripStore.record(trip.id).put(db, trip.toMap());
      return trip;
    } catch (e) {
      debugPrint('[TripRepository] getTripById error: $e');
      return null;
    }
  }

  /// Streams trips from the local database for real-time UI updates
  Stream<List<TripModel>> watchTrips() async* {
    final db = await _db.database;
    final query = _tripStore.query(
      finder: Finder(sortOrders: [SortOrder('start_date')]),
    );

    yield* query.onSnapshots(db).map((snapshots) {
      return snapshots.map((s) => TripModel.fromMap(s.value)).toList();
    });
  }

  // ────────────────────────────────────────────────────────────────
  // WRITE
  // ────────────────────────────────────────────────────────────────

  /// Creates a new trip — optimistic local write + Supabase sync.
  Future<void> createTrip(TripModel trip) async {
    final db = await _db.database;
    final ownerId = _supabase.auth.currentUser?.id;

    // Optimistic local write for instant UI feedback
    await _tripStore.record(trip.id).put(db, trip.toMap());

    if (ownerId != null) {
      try {
        await _supabase.from('trips').insert(trip.toSupabaseInsert(ownerId));
        // Also add the owner as an organizer member
        await _supabase.from('trip_members').insert({
          'trip_id': trip.id,
          'user_id': ownerId,
          'roles': ['organizer'],
        });
      } catch (e) {
        debugPrint('[TripRepository] createTrip sync error: $e');
        // Local write already done — no rethrow; will sync later
      }
    }
  }

  /// Updates an existing trip both locally and in Supabase.
  Future<void> updateTrip(TripModel trip) async {
    final db = await _db.database;
    await _tripStore.record(trip.id).put(db, trip.toMap());

    try {
      await _supabase.from('trips').update({
        'name': trip.name,
        'destination': trip.destination,
        'start_date': trip.fromDate.toIso8601String(),
        'end_date': trip.toDate.toIso8601String(),
        'budget': trip.totalBudget,
        'type': trip.tripType.toLowerCase(),
        'split_method': trip.splitEqually ? 'equal' : 'fixed',
      }).eq('id', trip.id);
    } catch (e) {
      debugPrint('[TripRepository] updateTrip sync error: $e');
    }
  }

  /// Marks a trip as archived (soft-delete).
  Future<void> archiveTrip(String tripId) async {
    final db = await _db.database;
    await _tripStore.record(tripId).update(db, {'is_archived': true});

    try {
      await _supabase
          .from('trips')
          .update({'status': 'archived'})
          .eq('id', tripId);
    } catch (e) {
      debugPrint('[TripRepository] archiveTrip sync error: $e');
    }
  }

  /// Permanently deletes a trip (local + Supabase cascade).
  Future<void> deleteTrip(String tripId) async {
    final db = await _db.database;
    await _tripStore.record(tripId).delete(db);

    try {
      await _supabase.from('trips').delete().eq('id', tripId);
    } catch (e) {
      debugPrint('[TripRepository] deleteTrip sync error: $e');
    }
  }

  /// Joins a trip using an invite code.
  Future<void> joinTripByCode(String code) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Must be logged in to join a trip.');
    }

    // 1. Find the trip by invite code
    final tripResponse = await _supabase
        .from('trips')
        .select('id')
        .eq('invite_code', code.trim().toUpperCase())
        .maybeSingle();

    if (tripResponse == null) {
      throw Exception('Invalid invite code or trip not found.');
    }

    final tripId = tripResponse['id'] as String;

    // 2. Insert into trip_members
    try {
      await _supabase.from('trip_members').insert({
        'trip_id': tripId,
        'user_id': userId,
        'roles': ['member'],
      });
    } on PostgrestException catch (e) {
      // 23505 is unique violation (already a member)
      if (e.code != '23505') {
        rethrow;
      }
    }

    // 3. Fetch the full trip and cache it locally
    await getTripById(tripId);
  }
}
