/// session_cache_service.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// Lightweight TTL metadata service for Sembast store caches.
///
/// Writes a sentinel record `_cache_meta` into each Sembast store that
/// records the last successful remote fetch timestamp. No user data is stored
/// here — only ISO-8601 timestamps.
///
/// Usage:
///   await SessionCacheService.instance.stamp(DatabaseService.tripStore);
///   final fresh = await SessionCacheService.instance
///       .isFresh(DatabaseService.tripStore, ttl: Duration(hours: 4));
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'package:flutter/foundation.dart';
import 'package:sembast/sembast.dart';
import 'database_service.dart';

class SessionCacheService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final SessionCacheService _singleton = SessionCacheService._();
  static SessionCacheService get instance => _singleton;
  SessionCacheService._();

  // ── Internal sentinel key ──────────────────────────────────────────────────
  static const String _kMetaKey = '_cache_meta';
  static const String _kCachedAt = 'cachedAt';

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Stamps [storeName] with the current UTC timestamp.
  /// Call this immediately after a successful remote fetch.
  Future<void> stamp(String storeName) async {
    try {
      final db = await DatabaseService.instance.database;
      final store = stringMapStoreFactory.store(storeName);
      await store.record(_kMetaKey).put(db, {
        _kCachedAt: DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      // Non-fatal — cache metadata is informational only.
      debugPrint('[SessionCacheService] stamp error for $storeName: $e');
    }
  }

  /// Returns true when the last stamp for [storeName] is within [ttl].
  /// Returns false if never stamped or on any read error.
  Future<bool> isFresh(
    String storeName, {
    Duration ttl = const Duration(hours: 4),
  }) async {
    try {
      final db = await DatabaseService.instance.database;
      final store = stringMapStoreFactory.store(storeName);
      final meta = await store.record(_kMetaKey).get(db);
      if (meta == null) return false;
      final raw = meta[_kCachedAt] as String?;
      if (raw == null) return false;
      final cachedAt = DateTime.tryParse(raw);
      if (cachedAt == null) return false;
      return DateTime.now().toUtc().difference(cachedAt) < ttl;
    } catch (e) {
      debugPrint('[SessionCacheService] isFresh error for $storeName: $e');
      return false;
    }
  }

  /// Returns the last cached timestamp for [storeName], or null if never stamped.
  Future<DateTime?> lastCachedAt(String storeName) async {
    try {
      final db = await DatabaseService.instance.database;
      final store = stringMapStoreFactory.store(storeName);
      final meta = await store.record(_kMetaKey).get(db);
      if (meta == null) return null;
      final raw = meta[_kCachedAt] as String?;
      if (raw == null) return null;
      return DateTime.tryParse(raw);
    } catch (e) {
      debugPrint('[SessionCacheService] lastCachedAt error for $storeName: $e');
      return null;
    }
  }

  /// Clears the TTL stamp for [storeName].
  /// Use when you want to force a fresh fetch on next access.
  Future<void> invalidate(String storeName) async {
    try {
      final db = await DatabaseService.instance.database;
      final store = stringMapStoreFactory.store(storeName);
      await store.record(_kMetaKey).delete(db);
    } catch (e) {
      debugPrint('[SessionCacheService] invalidate error for $storeName: $e');
    }
  }

  /// Clears all TTL stamps (e.g. after sign-out).
  Future<void> invalidateAll() async {
    await Future.wait([
      invalidate(DatabaseService.tripStore),
      invalidate(DatabaseService.expenseStore),
      invalidate(DatabaseService.itineraryStore),
      invalidate(DatabaseService.packingStore),
      invalidate(DatabaseService.userStore),
      invalidate(DatabaseService.chatStore),
    ]);
  }
}
