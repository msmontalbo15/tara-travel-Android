import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sembast/sembast.dart';
import '../services/database_service.dart';

class ProfileRepository {
  final DatabaseService _dbService = DatabaseService.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Synchronous store reference — no need for async here.
  StoreRef<String, Map<String, dynamic>> get _store =>
      _dbService.getStore(DatabaseService.userStore);

  // ── LOCAL STORAGE ──────────────────────────────────────────────

  Future<Map<String, dynamic>?> getProfile() async {
    final db = await _dbService.database;
    return _store.record('current_user').get(db);
  }

  Future<void> saveProfile(Map<String, dynamic> data) async {
    final db = await _dbService.database;
    await _store.record('current_user').put(db, data);
  }

  Future<void> clearProfile() async {
    final db = await _dbService.database;
    await _store.record('current_user').delete(db);
  }

  // ── REMOTE STORAGE (SUPABASE) ──────────────────────────────────

  Future<Map<String, dynamic>?> getRemoteProfile(String userId) async {
    try {
      final response =
          await _supabase.from('users').select().eq('id', userId).maybeSingle();
      if (response == null) return null;
      return _fromRemoteJson(response);
    } catch (e) {
      debugPrint('[ProfileRepository] getRemoteProfile error: $e');
      return null;
    }
  }

  Future<void> saveRemoteProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Seed display_name from Supabase auth metadata if local profile
      // has no meaningful name (happens on first email/password registration).
      String displayName = data['displayName'] ?? '';
      if (displayName.isEmpty || displayName == 'User') {
        final metadata = _supabase.auth.currentUser?.userMetadata;
        final metaName = metadata?['full_name'] as String? ??
            metadata?['name'] as String?;
        if (metaName != null && metaName.isNotEmpty) {
          displayName = metaName;
        }
      }

      final remoteData = _toRemoteJson({...data, 'displayName': displayName})
        ..['id'] = userId
        ..['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('users').upsert(remoteData);
    } catch (e) {
      debugPrint('[ProfileRepository] saveRemoteProfile error: $e');
    }
  }

  Map<String, dynamic> _toRemoteJson(Map<String, dynamic> data) {
    final healthNotes = data['healthNotes'];
    final primaryHealthNote =
        healthNotes is List && healthNotes.isNotEmpty ? '${healthNotes.first}' : null;

    return {
      'email': data['accountEmail'] ?? _supabase.auth.currentUser?.email ?? '',
      'display_name': data['displayName'] ?? 'User',
      'avatar_url': data['profilePhotoUrl'],
      'gcash_qr_url': data['gcashQrUrl'],
      'gcash_number': data['gcashNumber'],
      'health_notes': primaryHealthNote,
      'allergies': healthNotes is List ? healthNotes.cast<String>() : const <String>[],
      'home_city': data['homeCity'],
      'phone': data['contactNumber'],
      'share_health_with_org': data['shareHealthWithOrganizer'] ?? false,
      // Persist app-specific extras in a compatible way.
      'dietary': <String>[
        if (data['homeCountry'] != null) 'country:${data['homeCountry']}',
        if (data['homeRegion'] != null) 'region:${data['homeRegion']}',
        if (data['homeBarangay'] != null) 'barangay:${data['homeBarangay']}',
        if (data['preferredCurrency'] != null)
          'currency:${data['preferredCurrency']}',
        if (data['hasCompletedOnboarding'] == true) 'onboarding:completed',
      ],
    };
  }

  Map<String, dynamic> _fromRemoteJson(Map<String, dynamic> row) {
    final dietary = (row['dietary'] as List<dynamic>? ?? const [])
        .map((e) => '$e')
        .toList();

    String? extractTag(String prefix) {
      for (final entry in dietary) {
        if (entry.startsWith(prefix)) {
          return entry.substring(prefix.length);
        }
      }
      return null;
    }

    final allergies =
        (row['allergies'] as List<dynamic>? ?? const []).map((e) => '$e').toList();
    final healthNotes = {
      ...allergies,
      if ((row['health_notes'] as String?)?.isNotEmpty == true)
        row['health_notes'] as String,
    }.toList();

    return {
      // Treat empty string the same as null so local name is not overwritten
      'displayName': (row['display_name'] as String?)?.trim().isNotEmpty == true
          ? row['display_name'] as String
          : null, // null → ProfileState.fromJson uses its own fallback logic
      'firstName': _firstNameFromDisplayName(row['display_name'] as String?),
      'homeRegion': extractTag('region:') ?? '',
      'homeCity': row['home_city'] ?? '',
      'homeBarangay': extractTag('barangay:') ?? '',
      'homeCountry': extractTag('country:') ?? 'Philippines',
      'preferredCurrency': extractTag('currency:') ?? 'PHP',
      'profilePhotoUrl': row['avatar_url'],
      'contactNumber': row['phone'],
      'gcashNumber': row['gcash_number'],
      'gcashQrUrl': row['gcash_qr_url'],
      'healthNotes': healthNotes,
      'shareHealthWithOrganizer': row['share_health_with_org'] ?? false,
      'isCloudConnected': true,
      'accountEmail': row['email'],
      'hasCompletedOnboarding': dietary.contains('onboarding:completed'),
    };
  }

  String _firstNameFromDisplayName(String? displayName) {
    if (displayName == null || displayName.trim().isEmpty) return 'User';
    return displayName.trim().split(' ').first;
  }
}
