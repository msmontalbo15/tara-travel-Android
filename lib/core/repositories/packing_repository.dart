import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/packing_model.dart';
import '../services/database_service.dart';
import 'package:sembast/sembast.dart';

/// Default packing categories seeded for every new trip.
const List<Map<String, dynamic>> _kDefaultCategories = [
  {'id': 'essentials', 'name': 'Essentials',    'icon': 0xe42d, 'color': 0xFFD85A30},
  {'id': 'clothing',   'name': 'Clothing',       'icon': 0xe90d, 'color': 0xFF8B5CF6},
  {'id': 'toiletries', 'name': 'Toiletries',     'icon': 0xe070, 'color': 0xFF0D9488},
  {'id': 'gadgets',    'name': 'Gadgets',        'icon': 0xe1b1, 'color': 0xFF3B82F6},
  {'id': 'documents',  'name': 'Documents',      'icon': 0xe873, 'color': 0xFFEF9F27},
  {'id': 'medicines',  'name': 'Medicines',      'icon': 0xe3f0, 'color': 0xFFEF4444},
];

const Map<String, List<String>> _kDefaultItems = {
  'essentials': ['Passport / ID', 'Cash (PHP)', 'Travel Pillow', 'Sunscreen SPF 50+'],
  'clothing':   ['T-shirts (3x)', 'Underwear (4x)', 'Shorts', 'Light Jacket', 'Sandals'],
  'toiletries': ['Toothbrush', 'Toothpaste', 'Shampoo', 'Body Wash', 'Deodorant'],
  'gadgets':    ['Phone Charger', 'Power Bank', 'Earphones', 'Camera'],
  'documents':  ['E-tickets', 'Hotel Booking', 'Emergency Contacts'],
  'medicines':  ['Pain Reliever', 'Anti-diarrhea', 'Antihistamine', 'Band-Aids'],
};

class PackingRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DatabaseService _db = DatabaseService.instance;

  StoreRef<String, Map<String, dynamic>> get _store =>
      _db.getStore(DatabaseService.packingStore);

  // ────────────────────────────────────────────────────────────────
  // READ
  // ────────────────────────────────────────────────────────────────

  /// Fetches packing categories/items for a trip.
  /// Supabase → local cache → default seed.
  Future<List<PackingCategory>> getCategories(String tripId) async {
    final db = await _db.database;

    try {
      final response = await _supabase
          .from('packing_items')
          .select()
          .eq('trip_id', tripId)
          .order('created_at', ascending: true);

      final rows = (response as List)
          .map((r) => (r as Map).cast<String, dynamic>())
          .toList();

      // Cache locally
      await db.transaction((txn) async {
        for (final row in rows) {
          await _store.record('${row['id']}').put(txn, {...row});
        }
      });

      return _buildCategories(rows, tripId);
    } catch (e) {
      debugPrint('[PackingRepository] getCategories error: $e');
      // Fall back to local cache
      final snapshots = await _store.find(
        db,
        finder: Finder(filter: Filter.equals('trip_id', tripId)),
      );
      if (snapshots.isEmpty) return _defaultCategories(tripId);
      return _buildCategories(
        snapshots.map((s) => s.value).toList(),
        tripId,
      );
    }
  }

  // ────────────────────────────────────────────────────────────────
  // WRITE
  // ────────────────────────────────────────────────────────────────

  /// Toggles an item's checked state — optimistic local + Supabase sync.
  Future<void> toggleItem(String itemId, bool checked) async {
    final db = await _db.database;
    await _store.record(itemId).update(db, {'is_checked': checked});

    try {
      await _supabase
          .from('packing_items')
          .update({'is_checked': checked})
          .eq('id', itemId);
    } catch (e) {
      debugPrint('[PackingRepository] toggleItem sync error: $e');
    }
  }

  /// Adds a new packing item to a category.
  Future<PackingItem> addItem({
    required String tripId,
    required String category,
    required String name,
    bool isAiSuggested = false,
  }) async {
    final id = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final row = {
      'id': id,
      'trip_id': tripId,
      'name': name,
      'category': category,
      'is_checked': false,
      'is_ai_suggested': isAiSuggested,
      'created_at': DateTime.now().toIso8601String(),
    };

    final db = await _db.database;
    await _store.record(id).put(db, row);

    String remoteId = id;
    try {
      final inserted = await _supabase
          .from('packing_items')
          .insert({
            'trip_id': tripId,
            'name': name,
            'category': category,
            'is_checked': false,
            'is_ai_suggested': isAiSuggested,
            'created_by': _supabase.auth.currentUser?.id,
          })
          .select()
          .single();
      remoteId = '${inserted['id']}';
      // Update local with real UUID
      if (remoteId != id) {
        await _store.record(id).delete(db);
        await _store.record(remoteId).put(db, {...row, 'id': remoteId});
      }
    } catch (e) {
      debugPrint('[PackingRepository] addItem sync error: $e');
    }

    return PackingItem(
      id: remoteId,
      name: name,
      isAiSuggested: isAiSuggested,
    );
  }

  /// Deletes a packing item.
  Future<void> deleteItem(String itemId) async {
    final db = await _db.database;
    await _store.record(itemId).delete(db);

    try {
      await _supabase.from('packing_items').delete().eq('id', itemId);
    } catch (e) {
      debugPrint('[PackingRepository] deleteItem sync error: $e');
    }
  }

  /// Seeds default packing categories/items for a brand-new trip.
  Future<void> seedDefaultItems(String tripId) async {
    for (final entry in _kDefaultItems.entries) {
      for (final itemName in entry.value) {
        await addItem(
          tripId: tripId,
          category: entry.key,
          name: itemName,
        );
      }
    }
  }

  // ────────────────────────────────────────────────────────────────
  // HELPERS
  // ────────────────────────────────────────────────────────────────

  List<PackingCategory> _buildCategories(
    List<Map<String, dynamic>> rows,
    String tripId,
  ) {
    // Group rows by category slug
    final grouped = <String, List<PackingItem>>{};
    for (final row in rows) {
      final catId = '${row['category'] ?? 'essentials'}';
      final item = PackingItem(
        id: '${row['id']}',
        name: '${row['name'] ?? ''}',
        isChecked: row['is_checked'] == true,
        isAiSuggested: row['is_ai_suggested'] == true,
        assignedMemberId: row['assigned_user_id']?.toString(),
      );
      grouped.putIfAbsent(catId, () => []).add(item);
    }

    return _kDefaultCategories.map((catDef) {
      final catId = catDef['id'] as String;
      return PackingCategory(
        id: catId,
        name: catDef['name'] as String,
        icon: IconData(catDef['icon'] as int, fontFamily: 'MaterialIcons'),
        color: Color(catDef['color'] as int),
        items: grouped[catId] ?? [],
        isExpanded: true,
      );
    }).toList();
  }

  List<PackingCategory> _defaultCategories(String tripId) {
    return _kDefaultCategories.map((catDef) {
      final catId = catDef['id'] as String;
      final defaultItemNames = _kDefaultItems[catId] ?? [];
      final items = defaultItemNames
          .map((name) => PackingItem(
                id: '${catId}_${name.hashCode}',
                name: name,
              ))
          .toList();

      return PackingCategory(
        id: catId,
        name: catDef['name'] as String,
        icon: IconData(catDef['icon'] as int, fontFamily: 'MaterialIcons'),
        color: Color(catDef['color'] as int),
        items: items,
        isExpanded: true,
      );
    }).toList();
  }
}
