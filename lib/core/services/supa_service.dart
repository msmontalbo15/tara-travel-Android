import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trip_model.dart';
import '../models/expense_model.dart';

/// Low-level Supabase operations service.
///
/// Responsibilities:
///   • Direct table CRUD (trips, expenses, settlements, member locations).
///   • Real-time location stream for active trips.
///   • Retry-capable batch write helpers.
///
/// Higher-level domain logic lives in the feature repositories
/// (TripRepository, ExpenseRepository, etc.).
class SupaService {
  SupaService._();
  static final SupaService instance = SupaService._();

  final SupabaseClient _client = Supabase.instance.client;

  // ── Trips ────────────────────────────────────────────────────────────────

  Future<List<TripModel>> getTrips() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('trips')
          .select()
          .or('owner_id.eq.$userId,trip_members.user_id.eq.$userId');
      return (response as List).map((e) => TripModel.fromMap(e)).toList();
    } catch (e) {
      debugPrint('[SupaService] getTrips error: $e');
      return [];
    }
  }

  Future<void> createTrip(TripModel trip) async {
    try {
      await _client.from('trips').insert(trip.toMap());
    } catch (e) {
      debugPrint('[SupaService] createTrip error: $e');
      rethrow;
    }
  }

  // ── Expenses ─────────────────────────────────────────────────────────────

  Future<void> addExpense(String tripId, ExpenseModel expense) async {
    try {
      await _client.from('expenses').insert({
        ...expense.toMap(),
        'trip_id': tripId,
      });
    } catch (e) {
      debugPrint('[SupaService] addExpense error: $e');
      rethrow;
    }
  }

  Future<void> updateExpenseStatus(
    String expenseId,
    ExpenseStatus status, {
    String? rejectionNote,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      final updateMap = <String, dynamic>{'status': status.name};
      if (status == ExpenseStatus.approved) {
        updateMap['approved_by'] = userId;
      } else if (status == ExpenseStatus.rejected) {
        updateMap['rejected_by'] = userId;
        if (rejectionNote != null) updateMap['rejection_note'] = rejectionNote;
      }
      await _client.from('expenses').update(updateMap).eq('id', expenseId);
    } catch (e) {
      debugPrint('[SupaService] updateExpenseStatus error: $e');
      rethrow;
    }
  }

  // ── Real-time Member Locations ────────────────────────────────────────────
  // Streams from trip_members (with last_lat / last_lng columns) for live GPS
  // tracking. Consumers should filter out rows where location_sharing = false.

  Stream<List<Map<String, dynamic>>> getMemberLocations(String tripId) {
    return _client
        .from('trip_members')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .map((rows) => rows.where((r) => r['location_sharing'] == true).toList());
  }

  /// Updates the current user's live coordinates in trip_members.
  /// Uses upsert on (trip_id, user_id) conflict resolution.
  Future<void> updateCurrentLocation(
    String tripId,
    double lat,
    double lng, {
    double? speed,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _client.from('trip_members').update({
        'last_lat':   lat,
        'last_lng':   lng,
        'last_speed': speed,
        'last_seen':  DateTime.now().toUtc().toIso8601String(),
      })
          .eq('trip_id', tripId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('[SupaService] updateCurrentLocation error: $e');
    }
  }

  // ── Online Presence ───────────────────────────────────────────────────────

  /// Call when the app enters foreground / user logs in.
  Future<void> setOnline() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client
          .from('users')
          .update({'is_online': true, 'last_seen': DateTime.now().toUtc().toIso8601String()})
          .eq('id', userId);
    } catch (e) {
      debugPrint('[SupaService] setOnline error: $e');
    }
  }

  /// Call on app pause / sign-out.
  Future<void> setOffline() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client
          .from('users')
          .update({'is_online': false, 'last_seen': DateTime.now().toUtc().toIso8601String()})
          .eq('id', userId);
    } catch (e) {
      debugPrint('[SupaService] setOffline error: $e');
    }
  }

  // ── User Settings ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getUserSettings() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      return await _client
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
    } catch (e) {
      debugPrint('[SupaService] getUserSettings error: $e');
      return null;
    }
  }

  Future<void> updateUserSettings(Map<String, dynamic> settings) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client.from('user_settings').upsert({
        ...settings,
        'user_id': userId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SupaService] updateUserSettings error: $e');
      rethrow;
    }
  }

  // ── FCM Device Token Registration ─────────────────────────────────────────

  Future<void> registerDeviceToken({
    required String fcmToken,
    required String deviceId,
    required String platform,
    String? deviceName,
    String? appVersion,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client.from('user_devices').upsert({
        'user_id':     userId,
        'fcm_token':   fcmToken,
        'device_id':   deviceId,
        'platform':    platform,
        'device_name': deviceName,
        'app_version': appVersion,
        'is_active':   true,
        'last_active': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SupaService] registerDeviceToken error: $e');
    }
  }
}
