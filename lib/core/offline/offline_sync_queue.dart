/// offline_sync_queue.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// Persistent write queue for operations that fail while the device is offline.
///
/// Operations are stored in a dedicated Sembast store (`offline_queue`) and
/// processed in FIFO order by [SyncManager] when connectivity is restored.
///
/// Each operation has a [retryCount] — after [maxRetries] failed attempts
/// the operation is discarded and the user is notified via debug log.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'package:flutter/foundation.dart';
import 'package:sembast/sembast.dart';
import 'package:uuid/uuid.dart';

import '../services/database_service.dart';

// ── Operation Model ───────────────────────────────────────────────────────────

class SyncOperation {
  final String id;
  final String type;                // e.g. 'create_trip' | 'add_expense' | ...
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;

  const SyncOperation({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'payload': payload,
        'created_at': createdAt.toIso8601String(),
        'retry_count': retryCount,
      };

  factory SyncOperation.fromMap(Map<String, dynamic> map) => SyncOperation(
        id: map['id'] as String,
        type: map['type'] as String,
        payload: (map['payload'] as Map).cast<String, dynamic>(),
        createdAt: DateTime.parse(map['created_at'] as String),
        retryCount: (map['retry_count'] as int?) ?? 0,
      );

  SyncOperation copyWith({int? retryCount}) => SyncOperation(
        id: id,
        type: type,
        payload: payload,
        createdAt: createdAt,
        retryCount: retryCount ?? this.retryCount,
      );
}

// ── Queue ─────────────────────────────────────────────────────────────────────

class OfflineSyncQueue {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final OfflineSyncQueue instance = OfflineSyncQueue._();
  OfflineSyncQueue._();

  static const int maxRetries = 3;
  static const String _storeName = 'offline_queue';
  static const _uuid = Uuid();

  StoreRef<String, Map<String, dynamic>> get _store =>
      stringMapStoreFactory.store(_storeName);

  // ── Enqueue ────────────────────────────────────────────────────────────────

  /// Adds a pending operation to the queue.
  /// Call this when a repository write fails due to [OfflineException] or
  /// any network error, after completing the local Sembast write.
  Future<void> enqueue({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final op = SyncOperation(
        id: _uuid.v4(),
        type: type,
        payload: payload,
        createdAt: DateTime.now().toUtc(),
      );
      final db = await DatabaseService.instance.database;
      await _store.record(op.id).put(db, op.toMap());
      debugPrint('[OfflineSyncQueue] Enqueued: ${op.type} (${op.id})');
    } catch (e) {
      debugPrint('[OfflineSyncQueue] enqueue error: $e');
    }
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  /// Returns all pending operations in FIFO (creation time) order.
  Future<List<SyncOperation>> getPending() async {
    try {
      final db = await DatabaseService.instance.database;
      final snapshots = await _store.find(
        db,
        finder: Finder(sortOrders: [SortOrder('created_at')]),
      );
      return snapshots.map((s) => SyncOperation.fromMap(s.value)).toList();
    } catch (e) {
      debugPrint('[OfflineSyncQueue] getPending error: $e');
      return [];
    }
  }

  /// Returns the number of pending operations.
  Future<int> get pendingCount async {
    try {
      final db = await DatabaseService.instance.database;
      return await _store.count(db);
    } catch (_) {
      return 0;
    }
  }

  // ── Complete / Fail ────────────────────────────────────────────────────────

  /// Removes a successfully synced operation from the queue.
  Future<void> complete(String operationId) async {
    try {
      final db = await DatabaseService.instance.database;
      await _store.record(operationId).delete(db);
      debugPrint('[OfflineSyncQueue] Completed: $operationId');
    } catch (e) {
      debugPrint('[OfflineSyncQueue] complete error: $e');
    }
  }

  /// Increments the retry counter for a failed operation.
  /// Deletes the operation if it has exceeded [maxRetries].
  Future<void> fail(String operationId) async {
    try {
      final db = await DatabaseService.instance.database;
      final existing = await _store.record(operationId).get(db);
      if (existing == null) return;

      final op = SyncOperation.fromMap(existing);
      if (op.retryCount + 1 >= maxRetries) {
        await _store.record(operationId).delete(db);
        debugPrint('[OfflineSyncQueue] Discarded after $maxRetries retries: $operationId');
      } else {
        await _store
            .record(operationId)
            .put(db, op.copyWith(retryCount: op.retryCount + 1).toMap());
        debugPrint(
            '[OfflineSyncQueue] Retry ${op.retryCount + 1}/$maxRetries: $operationId');
      }
    } catch (e) {
      debugPrint('[OfflineSyncQueue] fail error: $e');
    }
  }

  // ── Clear ──────────────────────────────────────────────────────────────────

  /// Removes all pending operations (e.g. after sign-out).
  Future<void> clearAll() async {
    try {
      final db = await DatabaseService.instance.database;
      await _store.delete(db);
      debugPrint('[OfflineSyncQueue] All operations cleared.');
    } catch (e) {
      debugPrint('[OfflineSyncQueue] clearAll error: $e');
    }
  }
}
