import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../security/three_layer_encryption_service.dart';

/// Pure Supabase data source for user profiles.
/// Sensitive fields (phone, gcash_number, health_notes) are encrypted/decrypted
/// using ThreeLayerEncryptionService before writing to or reading from Supabase.
/// There is no local cache — all data comes directly from `public.users`.
class ProfileRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ThreeLayerEncryptionService _encryption =
      ThreeLayerEncryptionService.instance;

  // ── REMOTE STORAGE (SUPABASE WITH 3-LAYER ENCRYPTION) ──────────────────────

  /// Fetches a user's profile from Supabase, decrypting sensitive fields.
  Future<Map<String, dynamic>?> getRemoteProfile(String userId) async {
    try {
      final response =
          await _supabase.from('users').select().eq('id', userId).maybeSingle();
      if (response == null) return null;
      return _fromRemoteJson(response);
    } on PostgrestException catch (e) {
      debugPrint('[ProfileRepository] getRemoteProfile PostgrestException: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[ProfileRepository] getRemoteProfile error: $e');
      return null;
    }
  }

  /// Saves a user's profile to Supabase, encrypting sensitive fields.
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

      final remoteData =
          await _toRemoteJson({...data, 'displayName': displayName});
      remoteData['id'] = userId;
      remoteData['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('users').upsert(remoteData);
    } on PostgrestException catch (e) {
      debugPrint('[ProfileRepository] saveRemoteProfile PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ProfileRepository] saveRemoteProfile error: $e');
      rethrow;
    }
  }

  // ── SERIALISATION HELPERS ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> _toRemoteJson(Map<String, dynamic> data) async {
    final healthNotes = data['healthNotes'];
    final primaryHealthNote =
        healthNotes is List && healthNotes.isNotEmpty ? '${healthNotes.first}' : '';

    final rawPhone = data['contactNumber'] as String? ?? '';
    final rawGcashNumber = data['gcashNumber'] as String? ?? '';

    // Encrypt sensitive fields with 3-Layer encryption before writing at rest
    final encryptedPhone = rawPhone.isNotEmpty
        ? await _encryption.encryptData(rawPhone)
        : null;
    final encryptedGcash = rawGcashNumber.isNotEmpty
        ? await _encryption.encryptData(rawGcashNumber)
        : null;
    final encryptedHealth = primaryHealthNote.isNotEmpty
        ? await _encryption.encryptData(primaryHealthNote)
        : null;

    return {
      'email': data['accountEmail'] ?? _supabase.auth.currentUser?.email ?? '',
      'display_name': data['displayName'] ?? '',
      'avatar_url': data['profilePhotoUrl'],
      'gcash_qr_url': data['gcashQrUrl'],
      'gcash_number': encryptedGcash ?? rawGcashNumber,
      'health_notes': encryptedHealth ?? primaryHealthNote,
      'allergies': healthNotes is List ? healthNotes.cast<String>() : const <String>[],
      'home_city': data['homeCity'],
      'phone': encryptedPhone ?? rawPhone,
      'share_health_with_org': data['shareHealthWithOrganizer'] ?? false,
      'blood_type': data['bloodType'],
      'hide_surname': data['hideSurname'] ?? false,
      // Persist app-specific extras encoded into the `dietary` text-array column.
      'dietary': <String>[
        if (data['homeCountry'] != null) 'country:${data['homeCountry']}',
        if (data['homeRegion'] != null) 'region:${data['homeRegion']}',
        if (data['homeBarangay'] != null) 'barangay:${data['homeBarangay']}',
        if (data['preferredCurrency'] != null)
          'currency:${data['preferredCurrency']}',
        if (data['nickname'] != null &&
            (data['nickname'] as String).trim().isNotEmpty)
          'nickname:${(data['nickname'] as String).trim()}',
        if (data['dateOfBirth'] != null &&
            (data['dateOfBirth'] as String).trim().isNotEmpty)
          'dob:${(data['dateOfBirth'] as String).trim()}',
        if (data['hasCompletedOnboarding'] == true) 'onboarding:completed',
        if (data['hideSurname'] == true) 'privacy:hide_surname',
      ],
    };
  }

  Future<Map<String, dynamic>> _fromRemoteJson(Map<String, dynamic> row) async {
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

    final rawPhone = row['phone'] as String? ?? '';
    final rawGcash = row['gcash_number'] as String? ?? '';
    final rawHealth = row['health_notes'] as String? ?? '';

    // Decrypt sensitive fields with 3-Layer decryption upon fetch
    final decryptedPhone = rawPhone.isNotEmpty
        ? await _encryption.decryptData(rawPhone)
        : '';
    final decryptedGcash = rawGcash.isNotEmpty
        ? await _encryption.decryptData(rawGcash)
        : '';
    final decryptedHealth = rawHealth.isNotEmpty
        ? await _encryption.decryptData(rawHealth)
        : '';

    final allergies =
        (row['allergies'] as List<dynamic>? ?? const []).map((e) => '$e').toList();
    final healthNotes = {
      ...allergies,
      if (decryptedHealth.isNotEmpty) decryptedHealth,
    }.toList();

    return {
      'displayName': (row['display_name'] as String?)?.trim().isNotEmpty == true
          ? row['display_name'] as String
          : null,
      'firstName': _firstNameFromDisplayName(row['display_name'] as String?),
      'homeRegion': extractTag('region:') ?? '',
      'homeCity': row['home_city'] ?? '',
      'homeBarangay': extractTag('barangay:') ?? '',
      'homeCountry': extractTag('country:') ?? 'Philippines',
      'preferredCurrency': extractTag('currency:') ?? 'PHP',
      'nickname': extractTag('nickname:'),
      'dateOfBirth': extractTag('dob:'),
      'bloodType': row['blood_type'] as String?,
      'profilePhotoUrl': row['avatar_url'],
      'contactNumber': decryptedPhone,
      'gcashNumber': decryptedGcash,
      'gcashQrUrl': row['gcash_qr_url'],
      'healthNotes': healthNotes,
      'shareHealthWithOrganizer': row['share_health_with_org'] ?? false,
      'hideSurname': row['hide_surname'] == true ||
          dietary.contains('privacy:hide_surname'),
      'isCloudConnected': true,
      'accountEmail': row['email'],
      'hasCompletedOnboarding': dietary.contains('onboarding:completed'),
    };
  }

  String _firstNameFromDisplayName(String? displayName) {
    if (displayName == null || displayName.trim().isEmpty) return '';
    return displayName.trim().split(' ').first;
  }
}
