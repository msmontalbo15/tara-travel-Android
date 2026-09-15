/// destination_repository.dart
/// Remote Supabase repository for travel destinations — fully dynamic, zero hardcoded data.
library;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/destination_model.dart';

class DestinationRepository {
  final SupabaseClient _supabase;

  DestinationRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Fetches all destinations from `public.destinations` ordered alphabetically.
  /// Returns an empty list on network failure so the UI can render an appropriate retry state.
  Future<List<DestinationModel>> getDestinations() async {
    try {
      final response = await _supabase
          .from('destinations')
          .select()
          .order('name', ascending: true);

      final rows = response as List;
      return rows
          .map((r) => DestinationModel.fromMap(
              (r as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      debugPrint(
          '[DestinationRepository] getDestinations error: $e');
      return [];
    }
  }
}
