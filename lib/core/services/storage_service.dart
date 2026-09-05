import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service responsible for client-side image optimization, uploading to Supabase Storage,
/// and returning public CDN URLs with cache-busting timestamping.
class StorageService {
  static final StorageService instance = StorageService._();
  StorageService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Uploads user profile avatar to Supabase Storage bucket `avatars`.
  /// Standardized path: `avatars/{userId}/avatar.{ext}`.
  /// Upserts file and returns the public CDN URL with a timestamp query param for fresh display.
  Future<String?> uploadAvatar({
    required String userId,
    required String localFilePath,
  }) async {
    try {
      final file = File(localFilePath);
      if (!file.existsSync()) {
        debugPrint('[StorageService] uploadAvatar: file not found at $localFilePath');
        return null;
      }

      final ext = localFilePath.split('.').last.toLowerCase();
      // Use standard naming convention within user directory
      final storagePath = '$userId/avatar.$ext';

      // Upload with upsert so subsequent changes replace the old image
      await _supabase.storage.from('avatars').upload(
        storagePath,
        file,
        fileOptions: const FileOptions(
          upsert: true,
          contentType: 'image/webp',
        ),
      );

      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(storagePath);
      final cacheBustedUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('[StorageService] uploadAvatar successful: $cacheBustedUrl');
      return cacheBustedUrl;
    } on StorageException catch (e) {
      debugPrint('[StorageService] uploadAvatar StorageException: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[StorageService] uploadAvatar error: $e');
      return null;
    }
  }

  /// Deletes the avatar file for the given user from the `avatars` bucket.
  Future<bool> deleteAvatar(String userId) async {
    try {
      final files = await _supabase.storage.from('avatars').list(path: userId);
      if (files.isNotEmpty) {
        final paths = files.map((f) => '$userId/${f.name}').toList();
        await _supabase.storage.from('avatars').remove(paths);
      }
      return true;
    } catch (e) {
      debugPrint('[StorageService] deleteAvatar error: $e');
      return false;
    }
  }
}
