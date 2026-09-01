import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Lightweight, secure client-side storage for tracking module view timestamps.
///
/// Keys follow the format: `last_viewed:{module}:{tripId}`
/// Values are ISO-8601 UTC timestamp strings.
class ModuleViewTrackerService {
  ModuleViewTrackerService._();
  static final ModuleViewTrackerService instance = ModuleViewTrackerService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      keyCipherAlgorithm:
          KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // In-memory cache for ultra-fast $O(1)$ sync lookups during widget builds
  final Map<String, DateTime> _memoryCache = {};
  bool _isInitialized = false;

  /// Initializes in-memory cache from secure storage.
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final all = await _storage.readAll();
      for (final entry in all.entries) {
        if (entry.key.startsWith('last_viewed:')) {
          final parsed = DateTime.tryParse(entry.value);
          if (parsed != null) {
            _memoryCache[entry.key] = parsed;
          }
        }
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('[ModuleViewTrackerService] initialize warning: $e');
    }
  }

  String _buildKey(String module, String tripId) => 'last_viewed:${module.trim()}:$tripId';

  /// Returns the last viewed timestamp for a module in a trip.
  DateTime? getLastViewed(String module, String tripId) {
    final key = _buildKey(module, tripId);
    return _memoryCache[key];
  }

  /// Asynchronously fetches last viewed timestamp (refreshing from disk if not yet in cache).
  Future<DateTime?> getLastViewedAsync(String module, String tripId) async {
    final key = _buildKey(module, tripId);
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key];
    }
    try {
      final val = await _storage.read(key: key);
      if (val != null) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) {
          _memoryCache[key] = parsed;
          return parsed;
        }
      }
    } catch (e) {
      debugPrint('[ModuleViewTrackerService] read error: $e');
    }
    return null;
  }

  /// Marks a module as viewed right now.
  Future<void> markViewed(String module, String tripId, [DateTime? timestamp]) async {
    final key = _buildKey(module, tripId);
    final time = timestamp ?? DateTime.now().toUtc();
    _memoryCache[key] = time;
    try {
      await _storage.write(key: key, value: time.toIso8601String());
    } catch (e) {
      debugPrint('[ModuleViewTrackerService] write error: $e');
    }
  }

  /// Clears tracked timestamps for a specific trip.
  Future<void> clearTrip(String tripId) async {
    final keysToRemove = _memoryCache.keys
        .where((k) => k.endsWith(':$tripId'))
        .toList();
    for (final k in keysToRemove) {
      _memoryCache.remove(k);
      try {
        await _storage.delete(key: k);
      } catch (_) {}
    }
  }
}
