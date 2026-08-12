/// sync_manager.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// Listens to [ConnectivityService.onlineStream] and drains the
/// [OfflineSyncQueue] in FIFO order whenever the device comes back online.
///
/// Sync order (dependency-safe):
///   1. create_trip       → must exist before expenses / itinerary
///   2. update_trip
///   3. add_expense
///   4. update_expense
///   5. update_itinerary
///   6. add_packing_item
///   7. update_packing_item
///   8. send_chat         → best-effort; notify user if failed
///
/// Conflict resolution: last-write-wins on Supabase `updated_at` field.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/connectivity_service.dart';
import 'offline_sync_queue.dart';

// ── Progress Model ────────────────────────────────────────────────────────────

class SyncProgress {
  final int total;
  final int completed;
  final int failed;
  final bool isDone;

  const SyncProgress({
    required this.total,
    required this.completed,
    required this.failed,
    this.isDone = false,
  });

  double get fraction => total == 0 ? 1.0 : completed / total;
}

// ── Sync Order ────────────────────────────────────────────────────────────────

const _kSyncOrder = [
  'create_trip',
  'update_trip',
  'archive_trip',
  'add_expense',
  'update_expense',
  'delete_expense',
  'update_itinerary',
  'add_packing_item',
  'update_packing_item',
  'delete_packing_item',
  'send_chat',
  'update_member_roles',
];

// ── Manager ───────────────────────────────────────────────────────────────────

class SyncManager {
  StreamSubscription<bool>? _connectivitySub;
  bool _isSyncing = false;

  final _progressController = StreamController<SyncProgress>.broadcast();

  /// Stream of sync progress — useful for showing a sync indicator in the UI.
  Stream<SyncProgress> get progressStream => _progressController.stream;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Starts listening to connectivity changes.
  /// Call this once from the app's root widget or a top-level provider.
  void start() {
    _connectivitySub ??=
        ConnectivityService.instance.onlineStream.listen((isOnline) {
      if (isOnline) {
        debugPrint('[SyncManager] Back online — starting sync.');
        processPendingSync();
      }
    });
  }

  /// Stops the connectivity listener and closes the progress stream.
  void dispose() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _progressController.close();
  }

  // ── Sync ───────────────────────────────────────────────────────────────────

  /// Drains [OfflineSyncQueue] in dependency-safe FIFO order.
  /// Safe to call multiple times — concurrent calls are de-duped.
  Future<void> processPendingSync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pending = await OfflineSyncQueue.instance.getPending();
      if (pending.isEmpty) {
        _isSyncing = false;
        return;
      }

      // Sort by sync order priority, then by creation time within same type
      pending.sort((a, b) {
        final aIndex = _kSyncOrder.indexOf(a.type);
        final bIndex = _kSyncOrder.indexOf(b.type);
        final orderDiff =
            (aIndex == -1 ? 999 : aIndex) - (bIndex == -1 ? 999 : bIndex);
        if (orderDiff != 0) return orderDiff;
        return a.createdAt.compareTo(b.createdAt);
      });

      int completed = 0;
      int failed = 0;

      for (final op in pending) {
        _progressController.add(SyncProgress(
          total: pending.length,
          completed: completed,
          failed: failed,
        ));

        final success = await _executeOperation(op);
        if (success) {
          await OfflineSyncQueue.instance.complete(op.id);
          completed++;
        } else {
          await OfflineSyncQueue.instance.fail(op.id);
          failed++;
        }
      }

      _progressController.add(SyncProgress(
        total: pending.length,
        completed: completed,
        failed: failed,
        isDone: true,
      ));

      debugPrint(
          '[SyncManager] Sync complete: $completed succeeded, $failed failed.');
    } catch (e) {
      debugPrint('[SyncManager] processPendingSync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // ── Operation Executor ────────────────────────────────────────────────────

  Future<bool> _executeOperation(SyncOperation op) async {
    final supabase = Supabase.instance.client;
    final payload = op.payload;

    try {
      switch (op.type) {
        case 'create_trip':
          await supabase.from('trips').upsert(payload,
              onConflict: 'id', ignoreDuplicates: true);
          break;

        case 'update_trip':
          final id = payload['id'] as String?;
          if (id == null) return false;
          await supabase.from('trips').update(payload).eq('id', id);
          break;

        case 'archive_trip':
          final id = payload['id'] as String?;
          if (id == null) return false;
          await supabase
              .from('trips')
              .update({'status': 'archived'}).eq('id', id);
          break;

        case 'add_expense':
          await supabase.from('expenses').upsert(payload,
              onConflict: 'id', ignoreDuplicates: true);
          break;

        case 'update_expense':
          final id = payload['id'] as String?;
          if (id == null) return false;
          await supabase.from('expenses').update(payload).eq('id', id);
          break;

        case 'delete_expense':
          final id = payload['id'] as String?;
          if (id == null) return false;
          await supabase.from('expenses').delete().eq('id', id);
          break;

        case 'update_itinerary':
          final id = payload['id'] as String?;
          if (id == null) return false;
          await supabase.from('itinerary_stops').update(payload).eq('id', id);
          break;

        case 'add_packing_item':
          await supabase.from('packing_items').upsert(payload,
              onConflict: 'id', ignoreDuplicates: true);
          break;

        case 'update_packing_item':
          final id = payload['id'] as String?;
          if (id == null) return false;
          await supabase.from('packing_items').update(payload).eq('id', id);
          break;

        case 'delete_packing_item':
          final id = payload['id'] as String?;
          if (id == null) return false;
          await supabase.from('packing_items').delete().eq('id', id);
          break;

        case 'send_chat':
          await supabase.from('chat_messages').upsert(payload,
              onConflict: 'id', ignoreDuplicates: true);
          break;

        case 'update_member_roles':
          final tripId = payload['trip_id'] as String?;
          final userId = payload['user_id'] as String?;
          if (tripId == null || userId == null) return false;
          await supabase
              .from('trip_members')
              .update({'roles': payload['roles']})
              .eq('trip_id', tripId)
              .eq('user_id', userId);
          break;

        default:
          debugPrint('[SyncManager] Unknown operation type: ${op.type}');
          return true; // Treat unknown types as completed to avoid infinite retry
      }

      debugPrint('[SyncManager] ✓ ${op.type} (${op.id})');
      return true;
    } catch (e) {
      debugPrint('[SyncManager] ✗ ${op.type} (${op.id}): $e');
      return false;
    }
  }
}

// ── Riverpod Provider ──────────────────────────────────────────────────────────

// Note: SyncManager is started from AuthGate after sign-in.
// It is intentionally not a Riverpod provider to avoid re-creation on
// provider invalidation — it holds a long-lived stream subscription.
final syncManagerInstance = SyncManager();
