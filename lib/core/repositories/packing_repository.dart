import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/packing_model.dart';

/// Default packing categories seeded for trips on first load.
const List<Map<String, dynamic>> _kDefaultCategories = [
  {'id': 'essentials', 'name': 'Essentials',    'icon': 0xe42d, 'color': 0xFFD85A30},
  {'id': 'clothing',   'name': 'Clothing',       'icon': 0xe90d, 'color': 0xFF8B5CF6},
  {'id': 'toiletries', 'name': 'Toiletries',     'icon': 0xe070, 'color': 0xFF0D9488},
  {'id': 'gadgets',    'name': 'Gadgets',        'icon': 0xe1b1, 'color': 0xFF3B82F6},
  {'id': 'documents',  'name': 'Documents',      'icon': 0xe873, 'color': 0xFFEF9F27},
  {'id': 'medicines',  'name': 'Medicines',      'icon': 0xe3f0, 'color': 0xFFEF4444},
  {'id': 'food',       'name': 'Food & Snacks',  'icon': 0xe532, 'color': 0xFF10B981},
  {'id': 'others',     'name': 'Others',         'icon': 0xe5d3, 'color': 0xFF6B7280},
];

const Map<String, List<String>> _kDefaultItems = {
  'essentials': ['Passport / Valid ID', 'Cash (PHP)', 'Travel Pillow', 'Sunscreen SPF 50+'],
  'clothing':   ['T-shirts (3x)', 'Underwear (4x)', 'Shorts', 'Light Jacket', 'Sandals'],
  'toiletries': ['Toothbrush & Paste', 'Shampoo & Body Wash', 'Deodorant', 'Wet Wipes'],
  'gadgets':    ['Phone Charger', 'Power Bank (20,000mAh)', 'Earphones', 'Camera'],
  'documents':  ['E-tickets / Boarding Pass', 'Hotel Booking Confirmation', 'Emergency Contacts'],
  'medicines':  ['Pain Reliever / Paracetamol', 'Anti-diarrhea (Loperamide)', 'Antihistamine', 'Band-Aids'],
  'food':       ['Drinking Water / Flask', 'Trail & Road Snacks', 'Instant 3-in-1 Coffee'],
  'others':     ['Reusable Shopping Bag', 'Ziploc Pouches'],
};

/// Pure Supabase data source for packing items.
/// All CRUD operations go directly to `packing_items` in Supabase.
/// RLS policies enforce per-trip member access.
class PackingRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ────────────────────────────────────────────────────────────────
  // READ
  // ────────────────────────────────────────────────────────────────

  /// Fetches packing categories and items for a trip from Supabase.
  /// If no items exist yet (first time), seeds defaults for the trip.
  Future<List<PackingCategory>> getCategories(String tripId) async {
    try {
      final response = await _supabase
          .from('packing_items')
          .select()
          .eq('trip_id', tripId)
          .order('created_at', ascending: true);

      final rows = (response as List)
          .map((r) => (r as Map).cast<String, dynamic>())
          .toList();

      if (rows.isEmpty) {
        // Auto-seed default items for brand-new trips
        await seedDefaultItems(tripId);
        return _defaultCategories(tripId);
      }

      return _buildCategories(rows, tripId);
    } on PostgrestException catch (e) {
      debugPrint('[PackingRepository] getCategories PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[PackingRepository] getCategories error: $e');
      rethrow;
    }
  }

  // ────────────────────────────────────────────────────────────────
  // WRITE
  // ────────────────────────────────────────────────────────────────

  /// Toggles an item's checked state in Supabase.
  Future<void> toggleItem(String itemId, bool checked) async {
    try {
      await _supabase
          .from('packing_items')
          .update({
            'is_checked': checked,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', itemId);
    } on PostgrestException catch (e) {
      debugPrint('[PackingRepository] toggleItem PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[PackingRepository] toggleItem error: $e');
      rethrow;
    }
  }

  /// Assigns or unassigns an item to a member in Supabase.
  Future<void> assignItem({
    required String itemId,
    required String? memberId,
    String? memberName,
    String? memberInitials,
    int? memberColor,
    String? memberRole,
  }) async {
    try {
      await _supabase
          .from('packing_items')
          .update({
            'assigned_user_id': memberId,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', itemId);
    } on PostgrestException catch (e) {
      debugPrint('[PackingRepository] assignItem PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[PackingRepository] assignItem error: $e');
      rethrow;
    }
  }

  /// Adds a new packing item to Supabase and returns the saved PackingItem.
  Future<PackingItem> addItem({
    required String tripId,
    required String category,
    required String name,
    bool isAiSuggested = false,
    bool isCritical = false,
    String? subCategory,
    String? assignedMemberId,
    String? assignedMemberName,
    String? assignedMemberInitials,
    int? assignedMemberColor,
    String? memberRole,
  }) async {
    try {
      final insertMap = <String, dynamic>{
        'trip_id': tripId,
        'name': name,
        'category': category,
        'is_checked': false,
        'is_ai_suggested': isAiSuggested,
        if (subCategory != null && subCategory.trim().isNotEmpty)
          'sub_category': subCategory.trim(),
        if (assignedMemberId != null) 'assigned_user_id': assignedMemberId,
      };

      Map<String, dynamic> inserted;
      try {
        final res = await _supabase
            .from('packing_items')
            .insert(insertMap)
            .select()
            .single();
        inserted = res;
      } on PostgrestException catch (e) {
        // Fallback if 'sub_category' column is not yet present on remote DB schema
        if (e.code == '42703' || e.message.toLowerCase().contains('sub_category')) {
          debugPrint('[PackingRepository] sub_category column missing in DB, falling back to standard insert');
          insertMap.remove('sub_category');
          final fallback = await _supabase
              .from('packing_items')
              .insert(insertMap)
              .select()
              .single();
          inserted = fallback;
        } else {
          rethrow;
        }
      }

      final remoteId = '${inserted['id']}';

      return PackingItem(
        id: remoteId,
        name: name,
        isAiSuggested: isAiSuggested,
        isCritical: isCritical,
        subCategory: subCategory?.trim(),
        assignedMemberId: assignedMemberId,
        assignedMemberName: assignedMemberName,
        assignedMemberInitials: assignedMemberInitials,
        assignedMemberColor: assignedMemberColor,
        assignedMemberRole: memberRole,
      );
    } on PostgrestException catch (e) {
      debugPrint('[PackingRepository] addItem PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[PackingRepository] addItem error: $e');
      rethrow;
    }
  }

  /// Updates an item's sub-category in Supabase.
  Future<void> updateItemSubCategory(String itemId, String? subCategory) async {
    try {
      await _supabase
          .from('packing_items')
          .update({
            'sub_category': subCategory?.trim().isNotEmpty == true ? subCategory!.trim() : null,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', itemId);
    } on PostgrestException catch (e) {
      debugPrint('[PackingRepository] updateItemSubCategory PostgrestException: ${e.message}');
      // Non-fatal if remote column is not yet migrated
      if (e.code == '42703' || e.message.toLowerCase().contains('sub_category')) {
        debugPrint('[PackingRepository] remote sub_category column missing, handled gracefully in memory');
        return;
      }
      rethrow;
    } catch (e) {
      debugPrint('[PackingRepository] updateItemSubCategory error: $e');
    }
  }

  /// Deletes a packing item from Supabase.
  Future<void> deleteItem(String itemId) async {
    try {
      await _supabase.from('packing_items').delete().eq('id', itemId);
    } on PostgrestException catch (e) {
      debugPrint('[PackingRepository] deleteItem PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[PackingRepository] deleteItem error: $e');
      rethrow;
    }
  }

  /// Deletes all packing items under a specific category for a trip.
  Future<void> deleteCategory(String tripId, String categoryId) async {
    try {
      await _supabase
          .from('packing_items')
          .delete()
          .eq('trip_id', tripId)
          .eq('category', categoryId);
    } on PostgrestException catch (e) {
      debugPrint('[PackingRepository] deleteCategory PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[PackingRepository] deleteCategory error: $e');
      rethrow;
    }
  }

  /// Seeds default packing items for a brand-new trip into Supabase.
  Future<void> seedDefaultItems(String tripId) async {
    try {
      final rows = <Map<String, dynamic>>[];
      for (final entry in _kDefaultItems.entries) {
        for (final itemName in entry.value) {
          rows.add({
            'trip_id': tripId,
            'name': itemName,
            'category': entry.key,
            'is_checked': false,
            'is_ai_suggested': false,
          });
        }
      }
      if (rows.isNotEmpty) {
        await _supabase.from('packing_items').insert(rows);
      }
    } catch (e) {
      debugPrint('[PackingRepository] seedDefaultItems error: $e');
    }
  }

  // ────────────────────────────────────────────────────────────────
  // TEMPLATES
  // ────────────────────────────────────────────────────────────────

  static final List<PackingTemplate> _customTemplates = [];

  /// Saves a packing list as a custom template in memory.
  Future<PackingTemplate> saveTemplate({
    required String name,
    required String description,
    required String icon,
    required Map<String, List<String>> itemsByCategory,
  }) async {
    final template = PackingTemplate(
      id: 'custom_tpl_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      icon: icon,
      itemsByCategory: itemsByCategory,
      isPrebuilt: false,
      createdAt: DateTime.now(),
    );
    _customTemplates.removeWhere((t) => t.id == template.id);
    _customTemplates.add(template);
    return template;
  }

  /// Deletes a custom template.
  Future<void> deleteTemplate(String templateId) async {
    _customTemplates.removeWhere((t) => t.id == templateId);
  }

  /// Returns all templates (prebuilt + custom in-memory).
  Future<List<PackingTemplate>> getTemplates() async {
    return [
      ...PackingTemplate.prebuiltTemplates,
      ..._customTemplates,
    ];
  }

  /// Applies a template by adding its items to the trip in Supabase.
  Future<void> applyTemplate({
    required String tripId,
    required PackingTemplate template,
  }) async {
    for (final entry in template.itemsByCategory.entries) {
      for (final itemName in entry.value) {
        await addItem(
          tripId: tripId,
          category: entry.key,
          name: itemName,
          isAiSuggested: template.isPrebuilt,
        );
      }
    }
  }

  // ────────────────────────────────────────────────────────────────
  // NOTIFICATIONS & REMINDERS
  // ────────────────────────────────────────────────────────────────

  /// Dispatches a packing reminder notification via Supabase `notifications` table.
  Future<void> sendPackingReminder({
    required String tripId,
    required String tripName,
    required String memberId,
    required String memberName,
    required List<String> unpackedItems,
  }) async {
    final previewItems = unpackedItems.take(3).join(', ');
    final remainingCount = unpackedItems.length;
    final countText = remainingCount > 3 ? ' (+$remainingCount more)' : '';
    final body = remainingCount == 0
        ? 'All assigned items are packed! Ready to go!'
        : 'You have $remainingCount items left to pack: $previewItems$countText';

    try {
      await _supabase.from('notifications').insert({
        'trip_id': tripId,
        'user_id': memberId,
        'type': 'packing',
        'title': '🎒 Packing Reminder for $tripName',
        'body': body,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[PackingRepository] sendPackingReminder error: $e');
    }
  }

  // ────────────────────────────────────────────────────────────────
  // HELPERS
  // ────────────────────────────────────────────────────────────────

  List<PackingCategory> _buildCategories(
    List<Map<String, dynamic>> rows,
    String tripId,
  ) {
    final grouped = <String, List<PackingItem>>{};
    final customCategoryIds = <String>{};

    for (final row in rows) {
      final catId = '${row['category'] ?? 'essentials'}';
      final item = PackingItem.fromMap(row);
      grouped.putIfAbsent(catId, () => []).add(item);

      if (!_kDefaultCategories.any((c) => c['id'] == catId)) {
        customCategoryIds.add(catId);
      }
    }

    final categories = _kDefaultCategories.map((catDef) {
      final catId = catDef['id'] as String;
      return PackingCategory(
        id: catId,
        name: catDef['name'] as String,
        icon: IconData(catDef['icon'] as int, fontFamily: 'MaterialIcons'),
        color: Color(catDef['color'] as int),
        items: grouped[catId] ?? [],
        isExpanded: false,
      );
    }).toList();

    for (final customId in customCategoryIds) {
      final name = customId.replaceAll('custom_', '').replaceAll('_', ' ').toUpperCase();
      categories.add(PackingCategory(
        id: customId,
        name: name.isNotEmpty ? name : 'Custom',
        icon: Icons.category_rounded,
        color: const Color(0xFF8B5CF6),
        items: grouped[customId] ?? [],
        isExpanded: false,
        isCustom: true,
      ));
    }

    return categories;
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
        isExpanded: false,
      );
    }).toList();
  }
}
