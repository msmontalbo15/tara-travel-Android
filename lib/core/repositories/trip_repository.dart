import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trip_model.dart';
import '../models/member_model.dart';
import '../services/database_service.dart';
import '../services/session_cache_service.dart';
import '../utils/invite_code_generator.dart';
import 'package:sembast/sembast.dart';

class TripRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DatabaseService _db = DatabaseService.instance;
  final SessionCacheService _cache = SessionCacheService.instance;

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
      await _cache.stamp(DatabaseService.tripStore);

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

  /// Fetches a single trip by ID — always fetches fresh from Supabase so
  /// expense totals and member data are up-to-date after realtime invalidation.
  /// Falls back to local Sembast cache only when offline or on network error.
  Future<TripModel?> getTripById(String tripId) async {
    final db = await _db.database;

    try {
      final response = await _supabase
          .from('trips')
          .select('*, trip_members(*, users(*)), expenses(*)')
          .eq('id', tripId)
          .maybeSingle();

      if (response == null) return null;
      final trip = TripModel.fromMap((response as Map).cast<String, dynamic>());
      // Update local cache with the fresh data
      await _tripStore.record(trip.id).put(db, trip.toMap());
      return trip;
    } catch (e) {
      debugPrint('[TripRepository] getTripById error (falling back to cache): $e');
      // Offline or network error — serve stale local data
      final local = await _tripStore.record(tripId).get(db);
      if (local != null) return TripModel.fromMap(local);
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

    // Ensure trip has a secure invite code
    if (trip.inviteCode.trim().isEmpty) {
      trip = trip.copyWith(inviteCode: InviteCodeGenerator.generate());
    }

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

  /// Regenerates a fresh invite code for a trip (organizer action).
  Future<String> regenerateInviteCode(String tripId) async {
    final newCode = InviteCodeGenerator.generate();
    final db = await _db.database;

    // Update local cache
    final localRecord = await _tripStore.record(tripId).get(db);
    if (localRecord != null) {
      final updatedMap = Map<String, dynamic>.from(localRecord);
      updatedMap['invite_code'] = newCode;
      await _tripStore.record(tripId).put(db, updatedMap);
    }

    // Update Supabase
    try {
      await _supabase
          .from('trips')
          .update({'invite_code': newCode})
          .eq('id', tripId);
    } catch (e) {
      debugPrint('[TripRepository] regenerateInviteCode remote error: $e');
    }

    return newCode;
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
        'invite_code': trip.inviteCode,
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
    final cleanCode = InviteCodeGenerator.sanitize(code);
    if (!InviteCodeGenerator.isValidFormat(cleanCode)) {
      throw Exception('Invalid invite code format. Please check the 6-character code.');
    }

    final userId = _supabase.auth.currentUser?.id;

    // 1. Try Supabase RPC `join_trip_by_code` (handles RLS security)
    try {
      final rpcRes = await _supabase.rpc(
        'join_trip_by_code',
        params: {'p_invite_code': cleanCode},
      );
      if (rpcRes != null && rpcRes['trip_id'] != null) {
        final tripId = rpcRes['trip_id'].toString();
        await _fetchAndCacheRemoteTrip(tripId);
        return;
      }
    } catch (e) {
      debugPrint('[TripRepository] RPC join_trip_by_code notice: $e');
    }

    // 2. Fallback direct Supabase query
    if (userId == null) {
      throw Exception('Must be logged in to join a trip.');
    }

    String? tripId;
    final tripResponse = await _supabase
        .from('trips')
        .select('id')
        .eq('invite_code', cleanCode)
        .maybeSingle();

    if (tripResponse != null) {
      tripId = tripResponse['id'] as String;
    } else {
      // 3. Fallback check local database for offline or local-only trips
      final db = await _db.database;
      final localTrips = await _tripStore.find(db);
      for (final snap in localTrips) {
        final codeInLocal = snap.value['invite_code']?.toString().toUpperCase();
        if (codeInLocal == cleanCode) {
          tripId = snap.key;
          break;
        }
      }
    }

    if (tripId == null) {
      throw Exception('Invalid invite code or trip not found.');
    }

    // Insert into trip_members
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
    } catch (e) {
      debugPrint('[TripRepository] joinTripByCode member insert error: $e');
    }

    // Fetch the full trip from remote/local and refresh cache
    await _fetchAndCacheRemoteTrip(tripId);
  }

  /// Updates roles for a member in a trip.
  /// Persists locally to Sembast and remotely to Supabase.
  Future<void> updateMemberRoles(
    String tripId,
    String memberId,
    List<MemberRole> newRoles,
  ) async {
    final db = await _db.database;

    // Ensure member has at least one role (default to member if empty)
    final rolesToAssign = newRoles.isEmpty ? [MemberRole.member] : newRoles;
    final roleNames = rolesToAssign.map((r) => r.name).toList();

    // 1. Update local cache
    final localRecord = await _tripStore.record(tripId).get(db);
    if (localRecord != null) {
      final tripMap = Map<String, dynamic>.from(localRecord);
      final membersList = (tripMap['members'] as List?)
              ?.map((m) => Map<String, dynamic>.from(m as Map))
              .toList() ??
          [];
      final memberIndex = membersList.indexWhere(
        (m) => m['id'] == memberId || m['user_id'] == memberId,
      );
      if (memberIndex != -1) {
        membersList[memberIndex]['roles'] = roleNames;
        tripMap['members'] = membersList;
        await _tripStore.record(tripId).put(db, tripMap);
      }
    }

    // 2. Sync to Supabase
    try {
      await _supabase
          .from('trip_members')
          .update({'roles': roleNames})
          .eq('trip_id', tripId)
          .or('user_id.eq.$memberId,id.eq.$memberId');

      // 3. Add activity log entry
      final roleLabels = rolesToAssign.map((r) => r.displayName).join(', ');
      await _supabase.from('activity_log').insert({
        'trip_id': tripId,
        'user_id': _supabase.auth.currentUser?.id,
        'action_type': 'member_role_changed',
        'description': 'Updated member roles to: $roleLabels',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[TripRepository] updateMemberRoles sync error: $e');
    }
  }

  /// Approves a pending trip member
  Future<void> approveMember(String tripId, String memberId) async {
    final db = await _db.database;
    final localRecord = await _tripStore.record(tripId).get(db);
    if (localRecord != null) {
      final tripMap = Map<String, dynamic>.from(localRecord);
      final membersList = (tripMap['members'] as List?)
              ?.map((m) => Map<String, dynamic>.from(m as Map))
              .toList() ??
          [];
      final memberIndex = membersList.indexWhere(
        (m) => m['id'] == memberId || m['user_id'] == memberId,
      );
      if (memberIndex != -1) {
        membersList[memberIndex]['status'] = 'approved';
        tripMap['members'] = membersList;
        await _tripStore.record(tripId).put(db, tripMap);
      }
    }

    try {
      await _supabase
          .from('trip_members')
          .update({'status': 'approved'})
          .eq('trip_id', tripId)
          .or('user_id.eq.$memberId,id.eq.$memberId');
    } catch (e) {
      debugPrint('[TripRepository] approveMember sync error: $e');
    }
  }

  /// Rejects a pending trip member
  Future<void> rejectMember(String tripId, String memberId) async {
    final db = await _db.database;
    final localRecord = await _tripStore.record(tripId).get(db);
    if (localRecord != null) {
      final tripMap = Map<String, dynamic>.from(localRecord);
      final membersList = (tripMap['members'] as List?)
              ?.map((m) => Map<String, dynamic>.from(m as Map))
              .toList() ??
          [];
      membersList.removeWhere(
        (m) => m['id'] == memberId || m['user_id'] == memberId,
      );
      tripMap['members'] = membersList;
      await _tripStore.record(tripId).put(db, tripMap);
    }

    try {
      await _supabase
          .from('trip_members')
          .delete()
          .eq('trip_id', tripId)
          .or('user_id.eq.$memberId,id.eq.$memberId');
    } catch (e) {
      debugPrint('[TripRepository] rejectMember sync error: $e');
    }
  }

  Future<TripModel?> _fetchAndCacheRemoteTrip(String tripId) async {
    final db = await _db.database;
    try {
      final response = await _supabase
          .from('trips')
          .select('*, trip_members(*, users(*)), expenses(*)')
          .eq('id', tripId)
          .maybeSingle();

      if (response != null) {
        final trip = TripModel.fromMap((response as Map).cast<String, dynamic>());
        await _tripStore.record(trip.id).put(db, trip.toMap());
        return trip;
      }
    } catch (e) {
      debugPrint('[TripRepository] _fetchAndCacheRemoteTrip error: $e');
    }
    return getTripById(tripId);
  }
}
