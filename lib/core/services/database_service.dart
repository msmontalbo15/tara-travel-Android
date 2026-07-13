/// database_service.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// Singleton Sembast database service with per-user isolation and
/// corruption-resilient open logic.
///
/// Security posture:
/// • Each user's data is stored in a separate `.db` file — no cross-user
///   data leakage from the local store.
/// • All I/O is performed asynchronously — no main-thread blocking.
/// • On [DatabaseException] (corrupt file), the file is deleted and a fresh
///   database is opened automatically, preventing persistent crash loops.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

class DatabaseService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final DatabaseService _singleton = DatabaseService._();
  static DatabaseService get instance => _singleton;
  DatabaseService._();

  // ── State ──────────────────────────────────────────────────────────────────

  /// Cached Future prevents double-init race condition when multiple callers
  /// await [database] concurrently before the first init completes.
  Future<Database>? _initFuture;
  String _userId = 'default';
  Database? _dbInstance;

  // ── User Switching ─────────────────────────────────────────────────────────

  /// Closes the current database (if open) and prepares the service to open
  /// a new per-user database on the next [database] access.
  ///
  /// [userId] is sanitised to prevent path traversal: only alphanumeric
  /// characters and underscores are retained.
  Future<void> switchUser(String userId) async {
    final cleanId = userId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    if (_userId == cleanId) return;

    _userId = cleanId;
    if (_dbInstance != null) {
      await _dbInstance!.close();
      _dbInstance = null;
    }
    _initFuture = null;
  }

  // ── Database Accessor ──────────────────────────────────────────────────────

  /// Returns the open [Database], initialising it exactly once even under
  /// concurrent access. Uses a cached [Future] to avoid the
  /// "Future already completed" [StateError] from a raw [Completer].
  Future<Database> get database => _initFuture ??= _openDatabase();

  // ── Private Open Logic ─────────────────────────────────────────────────────

  /// Opens (or creates) the Sembast database for [_userId].
  ///
  /// Corruption resilience:
  /// If [databaseFactoryIo.openDatabase] throws a [DatabaseException], the
  /// corrupt file is deleted and the database is re-created empty. This
  /// prevents an unrecoverable crash loop at the cost of local data for that
  /// session (remote data from Supabase will be re-synced on next login).
  Future<Database> _openDatabase() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final dbPath = join(appDocDir.path, 'tara_travel_$_userId.db');

    try {
      final db = await databaseFactoryIo.openDatabase(dbPath);
      _dbInstance = db;
      return db;
    } on DatabaseException catch (e) {
      debugPrint(
        '[DatabaseService] Corrupt database detected at $dbPath — '
        'deleting and recreating. Error: $e',
      );
      // Delete the corrupt file.
      final file = File(dbPath);
      if (await file.exists()) {
        await file.delete();
      }
      // Re-open on a fresh file.
      final db = await databaseFactoryIo.openDatabase(dbPath);
      _dbInstance = db;
      return db;
    }
  }

  // ── Store Factory ──────────────────────────────────────────────────────────

  /// Returns a typed `String → Map<String, dynamic>` Sembast store by name.
  StoreRef<String, Map<String, dynamic>> getStore(String storeName) {
    return stringMapStoreFactory.store(storeName);
  }

  // ── Store Name Constants ───────────────────────────────────────────────────

  static const String tripStore      = 'trips';
  static const String memberStore    = 'members';
  static const String expenseStore   = 'expenses';
  static const String itineraryStore = 'itinerary';
  static const String packingStore   = 'packing_items';
  static const String userStore      = 'user_profile';
}
