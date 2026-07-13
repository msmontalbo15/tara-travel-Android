import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trip_model.dart';
import '../models/expense_model.dart';

class SupaService {
  final SupabaseClient _client = Supabase.instance.client;

  // Trips
  Future<List<TripModel>> getTrips() async {
    // In a real app, we'd fetch from 'trips' table
    // For now, returning mock data seeded into the model format
    return [];
  }

  Future<void> createTrip(TripModel trip) async {
    await _client.from('trips').insert(trip.toMap());
  }

  // Expenses
  Future<void> addExpense(String tripId, ExpenseModel expense) async {
    await _client.from('expenses').insert({
      ...expense.toMap(),
      'trip_id': tripId,
    });
  }

  Future<void> updateExpenseStatus(String expenseId, ExpenseStatus status) async {
    await _client.from('expenses').update({
      'status': status.name,
    }).eq('id', expenseId);
  }

  // Real-time location
  Stream<List<Map<String, dynamic>>> getMemberLocations(String tripId) {
    return _client
        .from('member_locations')
        .stream(primaryKey: ['member_id'])
        .eq('trip_id', tripId);
  }

  Future<void> updateCurrentLocation(String tripId, String memberId, double lat, double lng) async {
    await _client.from('member_locations').upsert({
      'trip_id': tripId,
      'member_id': memberId,
      'latitude': lat,
      'longitude': lng,
      'last_updated': DateTime.now().toIso8601String(),
    });
  }
}
