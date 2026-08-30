/// trip_repository.dart
/// Pure Supabase data source for trips.
/// All read and write operations hit Supabase directly — there is no local
/// Sembast cache layer. This guarantees the UI always reflects the
/// authoritative remote state and eliminates count/deduplication drift.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trip_model.dart';
import '../models/member_model.dart';
import '../utils/invite_code_generator.dart';

class TripRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ────────────────────────────────────────────────────────────────
  // READ
  // ────────────────────────────────────────────────────────────────

  /// Fetches all trips the current user owns or is a member of, directly
  /// from Supabase. RLS policies enforce row-level isolation.
  Future<List<TripModel>> getTrips() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('[TripRepository] getTrips: no authenticated user.');
      return [];
    }

    try {
      final response = await _supabase
          .from('trips')
          .select('*, trip_members(*, users(*)), expenses(*)')
          .order('start_date', ascending: true);

      final rows = response as List;
      debugPrint('[TripRepository] getTrips fetched ${rows.length} rows from Supabase.');

      // Deduplicate by trip ID (defensive — RLS should already prevent duplicates)
      final Map<String, TripModel> seen = {};
      for (final json in rows) {
        try {
          final trip = TripModel.fromMap((json as Map).cast<String, dynamic>());
          seen[trip.id] = trip;
        } catch (parseErr) {
          debugPrint('[TripRepository] Failed to parse trip row: $parseErr\nRow: $json');
        }
      }

      final trips = seen.values.toList();
      debugPrint('[TripRepository] ${trips.length} unique trips: ${trips.map((t) => t.name).toList()}');
      return trips;
    } on PostgrestException catch (e) {
      debugPrint('[TripRepository] getTrips PostgrestException: code=${e.code} message=${e.message} details=${e.details}');
      rethrow;
    } catch (e, st) {
      debugPrint('[TripRepository] getTrips error: $e\n$st');
      rethrow;
    }
  }

  /// Fetches a single trip by ID — always fresh from Supabase.
  Future<TripModel?> getTripById(String tripId) async {
    try {
      final response = await _supabase
          .from('trips')
          .select('*, trip_members(*, users(*)), expenses(*)')
          .eq('id', tripId)
          .maybeSingle();

      if (response == null) return null;
      return TripModel.fromMap((response as Map).cast<String, dynamic>());
    } on PostgrestException catch (e) {
      debugPrint('[TripRepository] getTripById PostgrestException: code=${e.code} message=${e.message}');
      rethrow;
    } catch (e, st) {
      debugPrint('[TripRepository] getTripById error: $e\n$st');
      rethrow;
    }
  }

  // ────────────────────────────────────────────────────────────────
  // WRITE
  // ────────────────────────────────────────────────────────────────

  /// Creates a new trip in Supabase. Throws on any remote error so the
  /// calling UI can surface the failure immediately.
  Future<void> createTrip(TripModel trip) async {
    final ownerId = _supabase.auth.currentUser?.id;
    if (ownerId == null) {
      throw Exception('User is not authenticated with Supabase.');
    }

    // Ensure trip has a secure invite code
    if (trip.inviteCode.trim().isEmpty) {
      trip = trip.copyWith(inviteCode: InviteCodeGenerator.generate());
    }

    // 1. Upsert the public.users row to satisfy the FK constraint
    try {
      final existingUser = await _supabase
          .from('users')
          .select('id')
          .eq('id', ownerId)
          .maybeSingle();
      if (existingUser == null) {
        final email =
            _supabase.auth.currentUser?.email ?? '$ownerId@taratravel.app';
        final name =
            (_supabase.auth.currentUser?.userMetadata?['full_name'] as String?) ??
            (_supabase.auth.currentUser?.userMetadata?['name'] as String?) ??
            email.split('@').first;
        debugPrint('[TripRepository] Upserting public.users row for $ownerId');
        await _supabase.from('users').upsert({
          'id': ownerId,
          'email': email,
          'display_name': name,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (userErr) {
      debugPrint('[TripRepository] User upsert warning: $userErr');
    }

    // 2. Insert the trip row
    final payload = trip.toSupabaseInsert(ownerId);
    debugPrint('[TripRepository] Inserting payload: $payload');
    await _supabase.from('trips').insert(payload);
    debugPrint('[TripRepository] Trip ${trip.id} saved to Supabase.');

    // 3. Add owner as organizer in trip_members
    try {
      await _supabase.from('trip_members').insert({
        'trip_id': trip.id,
        'user_id': ownerId,
        'roles': ['organizer'],
        'status': 'approved',
      });
    } catch (memberErr) {
      // Unique-violation (already a member) is acceptable
      debugPrint('[TripRepository] trip_members insert note: $memberErr');
    }
  }

  /// Regenerates a fresh invite code for a trip (organizer action).
  Future<String> regenerateInviteCode(String tripId) async {
    final newCode = InviteCodeGenerator.generate();
    await _supabase
        .from('trips')
        .update({'invite_code': newCode}).eq('id', tripId);
    return newCode;
  }

  /// Updates an existing trip.
  Future<void> updateTrip(TripModel trip) async {
    final normalizedType =
        trip.tripType.toLowerCase().trim().replaceAll('-', '_').replaceAll(' ', '_');

    final payload = {
      'name': trip.name,
      'destination': trip.destination,
      'start_date': trip.fromDate.toIso8601String().split('T').first,
      'end_date': trip.toDate.toIso8601String().split('T').first,
      'budget': trip.totalBudget,
      'type': normalizedType.isEmpty ? 'beach' : normalizedType,
      'split_method': trip.splitEqually ? 'equal' : 'fixed',
      'invite_code': trip.inviteCode,
      'status': trip.isDraft ? 'draft' : (trip.isArchived ? 'archived' : 'planned'),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      if (trip.departurePoint != null) 'departure_point': trip.departurePoint,
      if (trip.departureLat != null) 'departure_lat': trip.departureLat,
      if (trip.departureLng != null) 'departure_lng': trip.departureLng,
      if (trip.transportMode != null) 'transport_mode': trip.transportMode,
      if (trip.transportMeta != null) 'transport_meta': trip.transportMeta,
    };

    try {
      debugPrint('[TripRepository] Updating trip ${trip.id} with payload: $payload');
      await _supabase.from('trips').update(payload).eq('id', trip.id);
      debugPrint('[TripRepository] Trip ${trip.id} successfully updated in Supabase.');
    } on PostgrestException catch (e) {
      debugPrint('[TripRepository] updateTrip PostgrestException: code=${e.code} message=${e.message} details=${e.details}');
      rethrow;
    } catch (e, st) {
      debugPrint('[TripRepository] updateTrip error: $e\n$st');
      rethrow;
    }
  }

  /// Marks a trip as archived (soft-delete).
  Future<void> archiveTrip(String tripId) async {
    try {
      debugPrint('[TripRepository] Archiving trip $tripId');
      await _supabase
          .from('trips')
          .update({
            'status': 'archived',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', tripId);
      debugPrint('[TripRepository] Trip $tripId successfully archived.');
    } on PostgrestException catch (e) {
      debugPrint('[TripRepository] archiveTrip PostgrestException: code=${e.code} message=${e.message}');
      rethrow;
    } catch (e, st) {
      debugPrint('[TripRepository] archiveTrip error: $e\n$st');
      rethrow;
    }
  }

  /// Restores an archived trip to active/planned status.
  Future<void> unarchiveTrip(String tripId) async {
    try {
      debugPrint('[TripRepository] Unarchiving trip $tripId');
      await _supabase
          .from('trips')
          .update({
            'status': 'planned',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', tripId);
      debugPrint('[TripRepository] Trip $tripId successfully unarchived.');
    } on PostgrestException catch (e) {
      debugPrint('[TripRepository] unarchiveTrip PostgrestException: code=${e.code} message=${e.message}');
      rethrow;
    } catch (e, st) {
      debugPrint('[TripRepository] unarchiveTrip error: $e\n$st');
      rethrow;
    }
  }

  /// Permanently deletes a trip.
  Future<void> deleteTrip(String tripId) async {
    try {
      debugPrint('[TripRepository] Deleting trip $tripId');
      await _supabase.from('trips').delete().eq('id', tripId);
      debugPrint('[TripRepository] Trip $tripId successfully deleted.');
    } on PostgrestException catch (e) {
      debugPrint('[TripRepository] deleteTrip PostgrestException: code=${e.code} message=${e.message}');
      rethrow;
    } catch (e, st) {
      debugPrint('[TripRepository] deleteTrip error: $e\n$st');
      rethrow;
    }
  }

  // ────────────────────────────────────────────────────────────────
  // MEMBER LIFECYCLE
  // ────────────────────────────────────────────────────────────────

  /// Joins a trip using a 6-character invite code.
  ///
  /// Returns a [JoinResult] indicating whether membership is now
  /// [JoinStatus.pending] (awaiting organizer approval) or
  /// [JoinStatus.approved] (instantly joined).
  Future<JoinResult> joinTripByCode(String code) async {
    final cleanCode = InviteCodeGenerator.sanitize(code);
    if (!InviteCodeGenerator.isValidFormat(cleanCode)) {
      throw Exception('Invalid invite code format. Please check the 6-character code.');
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Must be logged in to join a trip.');
    }

    // 1. Ensure user exists in public.users to satisfy foreign keys
    try {
      final existingUser = await _supabase
          .from('users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      if (existingUser == null) {
        final email = _supabase.auth.currentUser?.email ?? '$userId@taratravel.app';
        final name = (_supabase.auth.currentUser?.userMetadata?['full_name'] as String?) ??
            (_supabase.auth.currentUser?.userMetadata?['name'] as String?) ??
            email.split('@').first;
        debugPrint('[TripRepository] Upserting public.users row for $userId before join');
        await _supabase.from('users').upsert({
          'id': userId,
          'email': email,
          'display_name': name,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (userErr) {
      debugPrint('[TripRepository] User upsert pre-join warning: $userErr');
    }

    // 2. Execute RPC (SECURITY DEFINER transaction)
    try {
      final rawRes = await _supabase.rpc(
        'join_trip_by_code',
        params: {'p_invite_code': cleanCode},
      );

      Map<String, dynamic>? rpcMap;
      if (rawRes is Map) {
        rpcMap = Map<String, dynamic>.from(rawRes);
      } else if (rawRes is String) {
        try {
          final decoded = jsonDecode(rawRes);
          if (decoded is Map) {
            rpcMap = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}
      }

      if (rpcMap != null && rpcMap['trip_id'] != null) {
        final status = (rpcMap['status'] as String? ?? 'pending').toLowerCase();
        final tripName = rpcMap['trip_name'] as String? ?? '';
        final alreadyMember = rpcMap['already_member'] == true;
        final alreadyPending = rpcMap['already_pending'] == true;
        debugPrint('[TripRepository] Joined via RPC: ${rpcMap['trip_id']} — status=$status (alreadyMember=$alreadyMember, alreadyPending=$alreadyPending)');
        return JoinResult(
          status: status == 'approved' ? JoinStatus.approved : JoinStatus.pending,
          tripName: tripName,
          alreadyMember: alreadyMember,
          alreadyPending: alreadyPending,
        );
      }
    } on PostgrestException catch (e) {
      final msg = e.message.isNotEmpty ? e.message : 'Failed to join trip.';
      // If message is a clear business rule (e.g. organizer, invalid code), throw immediately
      if (msg.contains('organizer') || msg.contains('not found') || msg.contains('Invalid')) {
        throw Exception(msg);
      }
      debugPrint('[TripRepository] join_trip_by_code RPC error (${e.code}): ${e.message}. Attempting direct fallback.');
    } catch (e) {
      debugPrint('[TripRepository] join_trip_by_code unexpected exception: $e. Attempting direct fallback.');
    }

    // 3. Fallback: Direct table query & membership insertion
    try {
      final tripRow = await _supabase
          .from('trips')
          .select('id, name, owner_id')
          .ilike('invite_code', cleanCode)
          .maybeSingle();

      if (tripRow == null) {
        throw Exception('Trip not found. Please verify your invite code.');
      }

      final tripId = tripRow['id'] as String;
      final tripName = tripRow['name'] as String? ?? 'Trip';
      final ownerId = tripRow['owner_id'] as String?;

      if (ownerId == userId) {
        throw Exception('You are already the organizer of this trip.');
      }

      // Check existing membership
      final existingMember = await _supabase
          .from('trip_members')
          .select('status')
          .eq('trip_id', tripId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingMember != null) {
        final currentStatus = (existingMember['status'] as String? ?? 'pending').toLowerCase();
        if (currentStatus == 'approved') {
          return JoinResult(
            status: JoinStatus.approved,
            tripName: tripName,
            alreadyMember: true,
          );
        } else if (currentStatus == 'pending') {
          return JoinResult(
            status: JoinStatus.pending,
            tripName: tripName,
            alreadyPending: true,
          );
        } else {
          // Re-open rejected request
          await _supabase
              .from('trip_members')
              .update({'status': 'pending', 'updated_at': DateTime.now().toIso8601String()})
              .eq('trip_id', tripId)
              .eq('user_id', userId);
          return JoinResult(
            status: JoinStatus.pending,
            tripName: tripName,
          );
        }
      }

      // Insert new pending member
      await _supabase.from('trip_members').insert({
        'trip_id': tripId,
        'user_id': userId,
        'roles': ['member'],
        'status': 'pending',
      });

      // Best-effort activity logging
      try {
        await _supabase.from('activity_log').insert({
          'trip_id': tripId,
          'user_id': userId,
          'action_type': 'member_join_request',
          'description': 'Requested to join the trip.',
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

      return JoinResult(
        status: JoinStatus.pending,
        tripName: tripName,
      );
    } on PostgrestException catch (e) {
      final msg = e.message.isNotEmpty ? e.message : 'Failed to join trip.';
      throw Exception(msg);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error — could not join trip.');
    }
  }

  /// Updates roles for a member in a trip (organizer-only action).
  Future<void> updateMemberRoles(
    String tripId,
    String memberId,
    List<MemberRole> newRoles,
  ) async {
    final rolesToAssign = newRoles.isEmpty ? [MemberRole.member] : newRoles;
    final roleNames = rolesToAssign.map((r) => r.name).toList();

    try {
      debugPrint('[TripRepository] Calling update_member_roles RPC: trip=$tripId member=$memberId roles=$roleNames');
      final res = await _supabase.rpc(
        'update_member_roles',
        params: {
          'p_trip_id': tripId,
          'p_member_uid': memberId,
          'p_roles': roleNames,
        },
      );
      debugPrint('[TripRepository] update_member_roles RPC succeeded: $res');
      return;
    } on PostgrestException catch (rpcErr) {
      debugPrint('[TripRepository] update_member_roles RPC warning (${rpcErr.code}): ${rpcErr.message}. Attempting direct update fallback.');
      try {
        await _supabase
            .from('trip_members')
            .update({'roles': roleNames})
            .eq('trip_id', tripId)
            .or('user_id.eq.$memberId,id.eq.$memberId');

        final roleLabels = rolesToAssign.map((r) => r.displayName).join(', ');
        await _supabase.from('activity_log').insert({
          'trip_id': tripId,
          'user_id': _supabase.auth.currentUser?.id,
          'action_type': 'member_role_changed',
          'description': 'Updated member roles to: $roleLabels',
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (directErr) {
        debugPrint('[TripRepository] Direct update fallback failed: $directErr');
        throw Exception(rpcErr.message.isNotEmpty ? rpcErr.message : 'Failed to update member roles.');
      }
    } catch (e, st) {
      debugPrint('[TripRepository] updateMemberRoles unexpected error: $e\n$st');
      rethrow;
    }
  }

  /// Approves a pending trip member.
  ///
  /// Delegates to the [approve_member] RPC which also notifies the applicant
  /// and writes an activity log entry.
  Future<void> approveMember(String tripId, String memberId) async {
    try {
      debugPrint('[TripRepository] Approving member $memberId for trip $tripId');
      await _supabase.rpc('approve_member', params: {
        'p_trip_id':    tripId,
        'p_member_uid': memberId,
      });
      debugPrint('[TripRepository] Member $memberId approved.');
    } on PostgrestException catch (e) {
      debugPrint('[TripRepository] approveMember RPC error: ${e.message}');
      throw Exception(e.message.isNotEmpty ? e.message : 'Failed to approve member.');
    } catch (e, st) {
      debugPrint('[TripRepository] approveMember error: $e\n$st');
      rethrow;
    }
  }

  /// Rejects a pending trip member join request.
  ///
  /// Delegates to [reject_or_remove_member] RPC with reason='rejected',
  /// which deletes the row and sends a declined notification to the applicant.
  Future<void> rejectMember(String tripId, String memberId) async {
    try {
      debugPrint('[TripRepository] Rejecting member $memberId for trip $tripId');
      await _supabase.rpc('reject_or_remove_member', params: {
        'p_trip_id':    tripId,
        'p_member_uid': memberId,
        'p_reason':     'rejected',
      });
      debugPrint('[TripRepository] Member $memberId rejected.');
    } on PostgrestException catch (e) {
      debugPrint('[TripRepository] rejectMember RPC error: ${e.message}');
      throw Exception(e.message.isNotEmpty ? e.message : 'Failed to reject member.');
    } catch (e, st) {
      debugPrint('[TripRepository] rejectMember error: $e\n$st');
      rethrow;
    }
  }

  /// Removes an approved member from a trip (organizer-only).
  ///
  /// Delegates to [reject_or_remove_member] RPC with reason='removed',
  /// which sends a removal notification to the affected member.
  Future<void> removeMember(String tripId, String memberId) async {
    try {
      debugPrint('[TripRepository] Removing member $memberId from trip $tripId');
      await _supabase.rpc('reject_or_remove_member', params: {
        'p_trip_id':    tripId,
        'p_member_uid': memberId,
        'p_reason':     'removed',
      });
      debugPrint('[TripRepository] Member $memberId removed.');
    } on PostgrestException catch (e) {
      debugPrint('[TripRepository] removeMember RPC error: ${e.message}');
      throw Exception(e.message.isNotEmpty ? e.message : 'Failed to remove member.');
    } catch (e, st) {
      debugPrint('[TripRepository] removeMember error: $e\n$st');
      rethrow;
    }
  }

  /// Allows the current authenticated user to voluntarily leave a trip.
  ///
  /// Blocked by the RPC if the caller is the trip owner (must transfer first).
  /// Returns the trip name for use in a farewell snackbar.
  Future<String> leaveTrip(String tripId) async {
    try {
      debugPrint('[TripRepository] Leaving trip $tripId');
      final res = await _supabase.rpc('leave_trip', params: {'p_trip_id': tripId});
      final tripName = (res as Map?)?['trip_name'] as String? ?? 'the trip';
      debugPrint('[TripRepository] Left trip $tripId ($tripName).');
      return tripName;
    } on PostgrestException catch (e) {
      debugPrint('[TripRepository] leaveTrip RPC error: ${e.message}');
      throw Exception(e.message.isNotEmpty ? e.message : 'Failed to leave trip.');
    } catch (e, st) {
      debugPrint('[TripRepository] leaveTrip error: $e\n$st');
      rethrow;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Value types for join results
// ─────────────────────────────────────────────────────────────────────────────

enum JoinStatus { pending, approved }

class JoinResult {
  final JoinStatus status;
  final String tripName;
  final bool alreadyMember;
  final bool alreadyPending;

  const JoinResult({
    required this.status,
    required this.tripName,
    this.alreadyMember = false,
    this.alreadyPending = false,
  });

  bool get isPending => status == JoinStatus.pending;
  bool get isApproved => status == JoinStatus.approved;
}
