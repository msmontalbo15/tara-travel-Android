import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/itinerary_model.dart';
import '../services/database_service.dart';
import 'package:sembast/sembast.dart';

class ItineraryRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DatabaseService _db = DatabaseService.instance;

  StoreRef<String, Map<String, dynamic>> get _itineraryStore =>
      _db.getStore(DatabaseService.itineraryStore);

  // ────────────────────────────────────────────────────────────────
  // READ
  // ────────────────────────────────────────────────────────────────

  /// Fetches all stops for a trip, caches them locally.
  Future<List<ItineraryStop>> getStops(String tripId) async {
    final db = await _db.database;

    try {
      final response = await _supabase
          .from('itinerary_stops')
          .select()
          .eq('trip_id', tripId)
          .order('day_number', ascending: true)
          .order('sort_order', ascending: true);

      final stops = (response as List).map((json) {
        final map = (json as Map).cast<String, dynamic>();
        return _stopFromSupabaseRow(map);
      }).toList();

      // Cache locally with day_number
      await db.transaction((txn) async {
        for (final raw in (response as List)) {
          final map = (raw as Map).cast<String, dynamic>();
          final stop = _stopFromSupabaseRow(map);
          await _itineraryStore.record(stop.id).put(txn, {
            'trip_id': tripId,
            'day_number': map['day_number'] ?? 1,
            'sort_order': map['sort_order'] ?? 0,
            'title': stop.title,
            'notes': stop.notes,
            'type': stop.type.name,
            'status': stop.status.name,
            'start_time': _encodeTime(stop.startTime),
            'end_time': _encodeTime(stop.endTime),
            'cost_estimate': stop.estimatedCost,
            'lat': stop.lat,
            'lng': stop.lng,
            'location': stop.location,
          });
        }
      });

      return stops;
    } catch (e) {
      debugPrint('[ItineraryRepository] getStops error: $e');
      final snapshots = await _itineraryStore.find(
        db,
        finder: Finder(
          filter: Filter.equals('trip_id', tripId),
          sortOrders: [
            SortOrder('day_number'),
            SortOrder('sort_order'),
          ],
        ),
      );
      return snapshots.map((s) => _stopFromLocalRow(s.key, s.value)).toList();
    }
  }

  /// Fetches grouped itinerary days for a trip.
  Future<List<ItineraryDay>> getItinerary(String tripId) async {
    final stops = await getStops(tripId);
    final db = await _db.database;

    // Group by day_number from local store
    final snapshots = await _itineraryStore.find(
      db,
      finder: Finder(filter: Filter.equals('trip_id', tripId)),
    );

    // Build a map of stop.id → day_number
    final dayNumberMap = <String, int>{};
    for (final snap in snapshots) {
      final dayNum = (snap.value['day_number'] as num?)?.toInt() ?? 1;
      dayNumberMap[snap.key] = dayNum;
    }

    final days = <int, List<ItineraryStop>>{};
    for (final stop in stops) {
      final dayNum = dayNumberMap[stop.id] ?? 1;
      days.putIfAbsent(dayNum, () => []).add(stop);
    }

    // Sort days by day number and create ItineraryDay objects
    final sortedKeys = days.keys.toList()..sort();
    return sortedKeys.map((dayNum) {
      return ItineraryDay(
        dayNumber: dayNum,
        date: DateTime.now().add(Duration(days: dayNum - 1)),
        stops: days[dayNum]!,
      );
    }).toList();
  }

  // ────────────────────────────────────────────────────────────────
  // WRITE
  // ────────────────────────────────────────────────────────────────

  /// Updates a stop status both locally and in Supabase.
  Future<void> updateStopStatus(String stopId, StopStatus status) async {
    final db = await _db.database;
    await _itineraryStore.record(stopId).update(db, {'status': status.name});

    try {
      await _supabase
          .from('itinerary_stops')
          .update({'status': _toDbStatus(status)})
          .eq('id', stopId);
    } catch (e) {
      debugPrint('[ItineraryRepository] updateStopStatus sync error: $e');
    }
  }

  /// Saves a full day of itinerary items to local + Supabase.
  Future<void> saveItineraryDay(String tripId, ItineraryDay day) async {
    final db = await _db.database;

    // Local transaction
    await db.transaction((txn) async {
      for (var i = 0; i < day.stops.length; i++) {
        final stop = day.stops[i];
        await _itineraryStore.record(stop.id).put(txn, {
          'trip_id': tripId,
          'day_number': day.dayNumber,
          'sort_order': i,
          'title': stop.title,
          'notes': stop.notes,
          'type': stop.type.name,
          'status': stop.status.name,
          'start_time': _encodeTime(stop.startTime),
          'end_time': _encodeTime(stop.endTime),
          'cost_estimate': stop.estimatedCost,
          'lat': stop.lat,
          'lng': stop.lng,
          'location': stop.location,
        });
      }
    });

    // Supabase upsert
    try {
      final rows = day.stops.asMap().entries.map((entry) {
        final i = entry.key;
        final stop = entry.value;
        return {
          'id': stop.id,
          'trip_id': tripId,
          'day_number': day.dayNumber,
          'sort_order': i,
          'title': stop.title,
          'notes': stop.notes,
          'type': stop.type.name,
          'status': _toDbStatus(stop.status),
          'time_start': _encodeTime(stop.startTime),
          'time_end': _encodeTime(stop.endTime),
          'cost_estimate': stop.estimatedCost,
          'lat': stop.lat,
          'lng': stop.lng,
        };
      }).toList();

      if (rows.isNotEmpty) {
        await _supabase.from('itinerary_stops').upsert(rows);
      }
    } catch (e) {
      debugPrint('[ItineraryRepository] saveItineraryDay sync error: $e');
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
      estimatedCost: json['cost_estimate'] != null ? double.tryParse(json['cost_estimate'].toString()) : null,
      location: json['location']?.toString(),
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lng: json['lng'] != null ? double.tryParse(json['lng'].toString()) : null,
      startTime: _decodeTime(json['time_start']?.toString()),
      endTime: _decodeTime(json['time_end']?.toString()),
    );
  }

  ItineraryStop _stopFromLocalRow(String id, Map<String, dynamic> val) {
    return ItineraryStop(
      id: id,
      title: val['title']?.toString() ?? '',
      notes: val['notes']?.toString(),
      type: StopType.values.firstWhere(
        (e) => e.name == val['type'],
        orElse: () => StopType.custom,
      ),
      status: StopStatus.values.firstWhere(
        (e) => e.name == val['status'],
        orElse: () => StopStatus.pending,
      ),
      estimatedCost: val['cost_estimate'] != null ? double.tryParse(val['cost_estimate'].toString()) : null,
      location: val['location']?.toString(),
      lat: val['lat'] != null ? double.tryParse(val['lat'].toString()) : null,
      lng: val['lng'] != null ? double.tryParse(val['lng'].toString()) : null,
      startTime: _decodeTime(val['start_time']?.toString()),
      endTime: _decodeTime(val['end_time']?.toString()),
    );
  }

  /// Maps Supabase DB status strings to local [StopStatus].
  StopStatus _fromDbStatus(String raw) {
    switch (raw) {
      case 'planned':   return StopStatus.pending;
      case 'completed': return StopStatus.approved;
      case 'skipped':   return StopStatus.rejected;
      case 'arrived':   return StopStatus.arrived;
      default:          return StopStatus.pending;
    }
  }

  /// Maps local [StopStatus] to DB status strings.
  String _toDbStatus(StopStatus status) {
    switch (status) {
      case StopStatus.pending:  return 'planned';
      case StopStatus.approved: return 'completed';
      case StopStatus.rejected: return 'skipped';
      case StopStatus.arrived:  return 'arrived';
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
}
