import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/itinerary_model.dart';

/// Pure Supabase data source for itinerary stops and collaborative voting.
/// All read/write operations go directly to Supabase.
/// RLS policies enforce row-level access per trip member.
class ItineraryRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ────────────────────────────────────────────────────────────────
  // READ
  // ────────────────────────────────────────────────────────────────

  /// Fetches all stops for a trip from Supabase, ordered by day then sort_order.
  Future<List<ItineraryStop>> getStops(String tripId) async {
    try {
      final response = await _supabase
          .from('itinerary_stops')
          .select()
          .eq('trip_id', tripId)
          .order('day_number', ascending: true)
          .order('sort_order', ascending: true);

      return (response as List).map((json) {
        final map = (json as Map).cast<String, dynamic>();
        return _stopFromSupabaseRow(map);
      }).toList();
    } on PostgrestException catch (e) {
      debugPrint('[ItineraryRepository] getStops PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ItineraryRepository] getStops error: $e');
      rethrow;
    }
  }

  /// Fetches grouped itinerary days for a trip, accurately mapped to the trip's date range.
  Future<List<ItineraryDay>> getItinerary(
    String tripId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final stops = await getStops(tripId);

    // Fetch remote day_number for each stop via Supabase query
    final rawRows = await _supabase
        .from('itinerary_stops')
        .select('id, day_number')
        .eq('trip_id', tripId);

    final dayNumberMap = <String, int>{};
    for (final row in (rawRows as List)) {
      final map = (row as Map).cast<String, dynamic>();
      final id = '${map['id']}';
      final dayNum = (map['day_number'] as num?)?.toInt() ?? 1;
      dayNumberMap[id] = dayNum;
    }

    final stopsByDay = <int, List<ItineraryStop>>{};
    for (final stop in stops) {
      final dayNum = dayNumberMap[stop.id] ?? 1;
      stopsByDay.putIfAbsent(dayNum, () => []).add(stop);
    }

    DateTime tripStart = startDate ?? DateTime.now();
    DateTime tripEnd = endDate ?? tripStart;

    // If dates weren't supplied, query trips table for start_date & end_date
    if (startDate == null || endDate == null) {
      try {
        final tripRow = await _supabase
            .from('trips')
            .select('start_date, end_date')
            .eq('id', tripId)
            .maybeSingle();
        if (tripRow != null) {
          if (startDate == null && tripRow['start_date'] != null) {
            tripStart = DateTime.parse('${tripRow['start_date']}');
          }
          if (endDate == null && tripRow['end_date'] != null) {
            tripEnd = DateTime.parse('${tripRow['end_date']}');
          }
        }
      } catch (e) {
        debugPrint('[ItineraryRepository] getItinerary trips date lookup error: $e');
      }
    }

    final startOnly = DateTime(tripStart.year, tripStart.month, tripStart.day);
    final endOnly = DateTime(tripEnd.year, tripEnd.month, tripEnd.day);
    final diffDays = endOnly.difference(startOnly).inDays + 1;
    final tripDaysCount = diffDays > 0 ? diffDays : 1;

    final maxStopDay = stopsByDay.keys.isEmpty
        ? 1
        : stopsByDay.keys.reduce((a, b) => a > b ? a : b);
    final totalDays = tripDaysCount > maxStopDay ? tripDaysCount : maxStopDay;

    final resultDays = <ItineraryDay>[];
    for (int dayNum = 1; dayNum <= totalDays; dayNum++) {
      resultDays.add(
        ItineraryDay(
          dayNumber: dayNum,
          date: DateTime(startOnly.year, startOnly.month, startOnly.day + (dayNum - 1)),
          stops: stopsByDay[dayNum] ?? const [],
        ),
      );
    }

    return resultDays;
  }

  // ────────────────────────────────────────────────────────────────
  // WRITE
  // ────────────────────────────────────────────────────────────────

  /// Updates a stop status in Supabase.
  Future<void> updateStopStatus(String stopId, StopStatus status) async {
    try {
      await _supabase
          .from('itinerary_stops')
          .update({
            'status': _toDbStatus(status),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', stopId);
    } on PostgrestException catch (e) {
      debugPrint('[ItineraryRepository] updateStopStatus PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ItineraryRepository] updateStopStatus error: $e');
      rethrow;
    }
  }

  /// Upserts a full day of itinerary stops to Supabase.
  Future<void> saveItineraryDay(String tripId, ItineraryDay day) async {
    try {
      final rows = day.stops.asMap().entries.map((entry) {
        final i = entry.key;
        final stop = entry.value;
        final stopId = _ensureUuid(stop.id);
        final assignedUserId = (stop.assignedMemberId != null && _isValidUuid(stop.assignedMemberId!))
            ? stop.assignedMemberId
            : null;

        // DB type check constraint: ('hotel', 'activity', 'food', 'transport', 'custom')
        final dbType = const {'hotel', 'activity', 'food', 'transport', 'custom'}
                .contains(stop.type.name)
            ? stop.type.name
            : 'activity';

        return {
          'id': stopId,
          'trip_id': tripId,
          'day_number': day.dayNumber,
          'sort_order': i,
          'title': stop.title,
          'notes': stop.notes,
          'type': dbType,
          'status': _toDbStatus(stop.status),
          'time_start': _encodeTime(stop.startTime),
          'time_end': _encodeTime(stop.endTime),
          'cost_estimate': stop.estimatedCost,
          'lat': stop.lat,
          'lng': stop.lng,
          'address': stop.location,
          'assigned_user_id': assignedUserId,
          'booking_ref': stop.confirmationNumber,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };
      }).toList();

      if (rows.isNotEmpty) {
        await _supabase.from('itinerary_stops').upsert(rows);
      }
    } on PostgrestException catch (e) {
      debugPrint('[ItineraryRepository] saveItineraryDay PostgrestException: ${e.message} code=${e.code} details=${e.details}');
      rethrow;
    } catch (e) {
      debugPrint('[ItineraryRepository] saveItineraryDay error: $e');
      rethrow;
    }
  }

  /// Deletes a single stop from Supabase.
  Future<void> deleteStop(String stopId) async {
    try {
      await _supabase.from('itinerary_stops').delete().eq('id', stopId);
    } on PostgrestException catch (e) {
      debugPrint('[ItineraryRepository] deleteStop PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ItineraryRepository] deleteStop error: $e');
      rethrow;
    }
  }

  /// Deletes multiple stops from Supabase in a single batch query.
  Future<void> deleteStops(List<String> stopIds) async {
    if (stopIds.isEmpty) return;
    try {
      await _supabase.from('itinerary_stops').delete().inFilter('id', stopIds);
    } on PostgrestException catch (e) {
      debugPrint('[ItineraryRepository] deleteStops PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ItineraryRepository] deleteStops error: $e');
      rethrow;
    }
  }

  /// Deletes any stops belonging to day numbers greater than [maxDayNumber] in Supabase.
  Future<void> deleteStopsBeyondDay(String tripId, int maxDayNumber) async {
    try {
      await _supabase
          .from('itinerary_stops')
          .delete()
          .eq('trip_id', tripId)
          .gt('day_number', maxDayNumber);
    } on PostgrestException catch (e) {
      debugPrint('[ItineraryRepository] deleteStopsBeyondDay PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ItineraryRepository] deleteStopsBeyondDay error: $e');
      rethrow;
    }
  }

  /// Records a collaborative vote (up/down) on a stop to Supabase stop_votes table.
  /// Uses upsert to allow toggle (user can only vote once per stop).
  Future<void> voteOnStop({
    required String tripId,
    required String stopId,
    required String memberId,
    required bool upvote,
  }) async {
    try {
      await _supabase.from('stop_votes').upsert(
        {
          'trip_id': tripId,
          'stop_id': stopId,
          'member_id': memberId,
          'upvote': upvote,
        },
        onConflict: 'stop_id,member_id',
      );
    } on PostgrestException catch (e) {
      debugPrint('[ItineraryRepository] voteOnStop PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ItineraryRepository] voteOnStop error: $e');
      rethrow;
    }
  }

  /// Removes a vote for the current user on a stop.
  Future<void> removeVote({required String stopId, required String memberId}) async {
    try {
      await _supabase
          .from('stop_votes')
          .delete()
          .eq('stop_id', stopId)
          .eq('member_id', memberId);
    } on PostgrestException catch (e) {
      debugPrint('[ItineraryRepository] removeVote PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ItineraryRepository] removeVote error: $e');
      rethrow;
    }
  }

  // ────────────────────────────────────────────────────────────────
  // HELPERS
  // ────────────────────────────────────────────────────────────────

  ItineraryStop _stopFromSupabaseRow(Map<String, dynamic> json) {
    return ItineraryStop(
      id: '${json['id']}',
      title: json['title']?.toString() ?? '',
      notes: json['notes']?.toString(),
      type: StopType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => StopType.custom,
      ),
      status: _fromDbStatus('${json['status'] ?? 'planned'}'),
      estimatedCost: json['cost_estimate'] != null
          ? double.tryParse(json['cost_estimate'].toString())
          : null,
      // Supabase stores location in 'address' column; map to model 'location' field
      location: json['address']?.toString() ?? json['location']?.toString(),
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lng: json['lng'] != null ? double.tryParse(json['lng'].toString()) : null,
      startTime: _decodeTime(json['time_start']?.toString()),
      endTime: _decodeTime(json['time_end']?.toString()),
      assignedMemberId: json['assigned_user_id']?.toString(),
      confirmationNumber: json['booking_ref']?.toString(),
    );
  }

  /// Maps Supabase DB status strings to local [StopStatus].
  StopStatus _fromDbStatus(String raw) {
    switch (raw) {
      case 'planned':
        return StopStatus.pending;
      case 'completed':
        return StopStatus.approved;
      case 'skipped':
        return StopStatus.rejected;
      case 'arrived':
        return StopStatus.arrived;
      default:
        return StopStatus.pending;
    }
  }

  /// Maps local [StopStatus] to DB status strings.
  String _toDbStatus(StopStatus status) {
    switch (status) {
      case StopStatus.pending:
        return 'planned';
      case StopStatus.approved:
        return 'completed';
      case StopStatus.rejected:
        return 'skipped';
      case StopStatus.arrived:
        return 'arrived';
    }
  }

  String? _encodeTime(TimeOfDay? t) {
    if (t == null) return null;
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  TimeOfDay? _decodeTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  bool _isValidUuid(String str) => _uuidRegex.hasMatch(str);

  String _ensureUuid(String id) {
    if (_isValidUuid(id)) return id;
    return const Uuid().v4();
  }
}
