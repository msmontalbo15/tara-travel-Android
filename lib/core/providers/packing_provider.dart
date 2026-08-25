import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/member_model.dart';
import '../models/packing_model.dart';
import 'repository_providers.dart';

// ── Packing State ─────────────────────────────────────────────────────────────

class PackingState {
  final List<PackingCategory> categories;
  final List<SmartSuggestion> suggestions;
  final List<PackingTemplate> templates;
  final bool showSuggestions;
  final bool suggestionsExpanded; // collapsed by default to save space
  final bool isLoading;
  final String? tripId;
  final String selectedMemberFilter; // 'all', 'my', 'unassigned', or member.id
  final String? aiContextLabel;

  const PackingState({
    required this.categories,
    required this.suggestions,
    this.templates = const [],
    this.showSuggestions = true,
    this.suggestionsExpanded = false,
    this.isLoading = false,
    this.tripId,
    this.selectedMemberFilter = 'all',
    this.aiContextLabel,
  });

  PackingState copyWith({
    List<PackingCategory>? categories,
    List<SmartSuggestion>? suggestions,
    List<PackingTemplate>? templates,
    bool? showSuggestions,
    bool? suggestionsExpanded,
    bool? isLoading,
    String? tripId,
    String? selectedMemberFilter,
    String? aiContextLabel,
  }) {
    return PackingState(
      categories: categories ?? this.categories,
      suggestions: suggestions ?? this.suggestions,
      templates: templates ?? this.templates,
      showSuggestions: showSuggestions ?? this.showSuggestions,
      suggestionsExpanded: suggestionsExpanded ?? this.suggestionsExpanded,
      isLoading: isLoading ?? this.isLoading,
      tripId: tripId ?? this.tripId,
      selectedMemberFilter: selectedMemberFilter ?? this.selectedMemberFilter,
      aiContextLabel: aiContextLabel ?? this.aiContextLabel,
    );
  }

  int get totalItems => categories.fold(0, (s, c) => s + c.totalCount);
  int get packedItems => categories.fold(0, (s, c) => s + c.packedCount);
  double get overallProgress => totalItems == 0 ? 0 : packedItems / totalItems;
  bool get allPacked => totalItems > 0 && packedItems == totalItems;

  /// Returns categories with items filtered according to [selectedMemberFilter]
  List<PackingCategory> getFilteredCategories(String? currentUserId) {
    if (selectedMemberFilter == 'all') {
      return categories;
    }

    return categories.map((cat) {
      final filteredItems = cat.items.where((item) {
        if (selectedMemberFilter == 'my') {
          if (currentUserId == null || currentUserId.isEmpty) return true;
          return item.assignedMemberIds.contains(currentUserId);
        } else if (selectedMemberFilter == 'unassigned') {
          return !item.isAssigned;
        } else {
          return item.assignedMemberIds.contains(selectedMemberFilter);
        }
      }).toList();

      return cat.copyWith(items: filteredItems);
    }).toList();
  }

  /// Calculates packed and total items for a specific member
  (int packed, int total) getMemberStats(String memberId) {
    int packed = 0;
    int total = 0;
    for (final cat in categories) {
      for (final item in cat.items) {
        if (item.assignedMemberIds.contains(memberId)) {
          total++;
          if (item.isChecked) packed++;
        }
      }
    }
    return (packed, total);
  }

  /// Retrieves remaining unpacked items assigned to a member
  List<String> getMemberUnpackedItems(String memberId) {
    final list = <String>[];
    for (final cat in categories) {
      for (final item in cat.items) {
        if (item.assignedMemberIds.contains(memberId) && !item.isChecked) {
          list.add(item.name);
        }
      }
    }
    return list;
  }
}

// ── Packing Notifier ──────────────────────────────────────────────────────────

class PackingNotifier extends Notifier<PackingState> {
  late final String _tripId;

  @override
  PackingState build() {
    // Defer initial load so provider is fully mounted
    Future.microtask(() => _loadFromRepo(_tripId));
    return const PackingState(
      categories: [],
      suggestions: [],
      templates: [],
    );
  }

  Future<void> _loadFromRepo(String tripId) async {
    try {
      state = state.copyWith(isLoading: true, tripId: tripId);
    } catch (e) {
      debugPrint('[PackingNotifier] state not ready yet: $e');
      return;
    }
    try {
      final repo = ref.read(packingRepositoryProvider);
      final categories = await repo.getCategories(tripId);
      final templates = await repo.getTemplates();
      state = state.copyWith(
        categories: categories,
        templates: templates,
        isLoading: false,
        tripId: tripId,
      );
    } catch (e) {
      debugPrint('[PackingNotifier] load error: $e');
      try {
        state = state.copyWith(isLoading: false);
      } catch (_) {}
    }
  }

  // ── Filters & View Controls ───────────────────────────────────────

  void setMemberFilter(String filterId) {
    state = state.copyWith(selectedMemberFilter: filterId);
  }

  void toggleCategory(String categoryId) {
    final cats = state.categories.map((c) {
      if (c.id != categoryId) return c;
      return c.copyWith(isExpanded: !c.isExpanded);
    }).toList();
    state = state.copyWith(categories: cats);
  }

  void toggleCollapseAll(bool expand) {
    final cats = state.categories.map((c) {
      return c.copyWith(isExpanded: expand);
    }).toList();
    state = state.copyWith(categories: cats);
  }

  // ── Item Mutations ────────────────────────────────────────────────

  Future<void> toggleItem(String categoryId, String itemId) async {
    // Optimistic local update
    final cats = _mapCategories(categoryId, (items) {
      return items.map((i) {
        if (i.id != itemId) return i;
        return i.copyWith(isChecked: !i.isChecked);
      }).toList();
    });
    state = state.copyWith(categories: cats);

    // Persist
    final checked = _findItem(categoryId, itemId)?.isChecked ?? false;
    if (state.tripId != null) {
      await ref.read(packingRepositoryProvider).toggleItem(itemId, checked);
    }
  }

  Future<void> toggleItemCritical(String categoryId, String itemId) async {
    final cats = _mapCategories(categoryId, (items) {
      return items.map((i) {
        if (i.id != itemId) return i;
        return i.copyWith(isCritical: !i.isCritical);
      }).toList();
    });
    state = state.copyWith(categories: cats);
  }

  /// Assigns multiple members to a packing item. Pass an empty list to clear.
  Future<void> assignMembers(
    String categoryId,
    String itemId,
    List<MemberModel> members,
  ) async {
    final primary = members.isNotEmpty ? members.first : null;
    final cats = _mapCategories(categoryId, (items) {
      return items.map((i) {
        if (i.id != itemId) return i;
        if (members.isEmpty) {
          return i.copyWith(clearAssignment: true);
        }
        final roleLabel = primary!.roles.isNotEmpty
            ? primary.roles.first.displayName
            : 'Trip Member';
        return i.copyWith(
          assignedMemberIds: members.map((m) => m.id).toList(),
          assignedMemberId: primary.id,
          assignedMemberName: primary.name,
          assignedMemberInitials: primary.initials,
          assignedMemberColor: primary.color.toARGB32(),
          assignedMemberRole: roleLabel,
        );
      }).toList();
    });
    state = state.copyWith(categories: cats);

    if (state.tripId != null) {
      final roleLabel = primary?.roles.isNotEmpty == true
          ? primary!.roles.first.displayName
          : primary != null ? 'Trip Member' : null;
      await ref.read(packingRepositoryProvider).assignItem(
            itemId: itemId,
            memberId: primary?.id,
            memberName: primary?.name,
            memberInitials: primary?.initials,
            memberColor: primary?.color.toARGB32(),
            memberRole: roleLabel,
          );
    }
  }

  /// Legacy single-member assignment shim — delegates to [assignMembers].
  Future<void> assignMember(
    String categoryId,
    String itemId,
    MemberModel? member,
  ) async {
    await assignMembers(
      categoryId,
      itemId,
      member != null ? [member] : [],
    );
  }

  Future<void> addItemToCategory(
    String categoryId,
    String itemName, {
    bool isAiSuggested = false,
    bool isCritical = false,
    MemberModel? assignedMember,
  }) async {
    final tripId = state.tripId;
    if (tripId == null) return;

    // ── Duplicate guard: skip if item with same name already exists in category ──
    final normalizedNew = itemName.trim().toLowerCase();
    final existingCat = state.categories.where((c) => c.id == categoryId).firstOrNull;
    final isDuplicate = existingCat?.items.any(
          (i) => i.name.trim().toLowerCase() == normalizedNew,
        ) ?? false;
    if (isDuplicate) return;

    final repo = ref.read(packingRepositoryProvider);
    final roleLabel = assignedMember?.roles.isNotEmpty == true
        ? assignedMember!.roles.first.displayName
        : assignedMember != null ? 'Trip Member' : null;

    final newItem = await repo.addItem(
      tripId: tripId,
      category: categoryId,
      name: itemName,
      isAiSuggested: isAiSuggested,
      isCritical: isCritical,
      assignedMemberId: assignedMember?.id,
      assignedMemberName: assignedMember?.name,
      assignedMemberInitials: assignedMember?.initials,
      assignedMemberColor: assignedMember?.color.toARGB32(),
      memberRole: roleLabel,
    );

    // Auto-expand category when adding an item
    final cats = state.categories.map((c) {
      if (c.id != categoryId) return c;
      return c.copyWith(
        items: [...c.items, newItem],
        isExpanded: true,
      );
    }).toList();

    state = state.copyWith(categories: cats);
  }

  Future<void> removeItem(String categoryId, String itemId) async {
    final cats = _mapCategories(categoryId, (items) {
      return items.where((i) => i.id != itemId).toList();
    });
    state = state.copyWith(categories: cats);

    if (state.tripId != null) {
      await ref.read(packingRepositoryProvider).deleteItem(itemId);
    }
  }

  Future<void> removeCategory(String categoryId) async {
    final tripId = state.tripId;
    final cats = state.categories.where((c) => c.id != categoryId).toList();
    state = state.copyWith(categories: cats);

    if (tripId != null) {
      await ref.read(packingRepositoryProvider).deleteCategory(tripId, categoryId);
    }
  }

  Future<void> addCustomCategory(
    String name, {
    IconData icon = Icons.category_rounded,
    Color color = const Color(0xFF8B5CF6),
  }) async {
    final newCat = PackingCategory(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      icon: icon,
      color: color,
      items: [],
      isCustom: true,
      isExpanded: true,
    );
    state = state.copyWith(categories: [...state.categories, newCat]);
  }

  // ── AI Suggestions ────────────────────────────────────────────────

  void generateAiSuggestions({
    required String destination,
    required String tripType,
    required int durationDays,
    String? weatherCondition,
    String? transportMode,
  }) {
    final suggestions = AiPackingEngine.generateSuggestions(
      destination: destination,
      tripType: tripType,
      durationDays: durationDays,
      weatherCondition: weatherCondition,
      transportMode: transportMode,
    );

    final contextParts = <String>[];
    if (destination.isNotEmpty) contextParts.add(destination);
    if (weatherCondition != null && weatherCondition.isNotEmpty) {
      contextParts.add(weatherCondition);
    }
    if (transportMode != null && transportMode.isNotEmpty) {
      contextParts.add(transportMode);
    }

    // Filter out suggestions for items already in the list
    final existingNames = state.categories
        .expand((c) => c.items)
        .map((i) => i.name.trim().toLowerCase())
        .toSet();
    final filtered = suggestions
        .where((s) => !existingNames.contains(s.text.trim().toLowerCase()))
        .toList();

    state = state.copyWith(
      suggestions: filtered,
      showSuggestions: true,
      suggestionsExpanded: false, // always start collapsed
      aiContextLabel: contextParts.isNotEmpty
          ? 'Tailored for ${contextParts.join(' • ')}'
          : null,
    );
  }

  Future<void> addSuggestion(SmartSuggestion suggestion) async {
    // Check if item already exists across ALL categories before adding
    final normalizedText = suggestion.text.trim().toLowerCase();
    final alreadyExists = state.categories.any(
      (c) => c.items.any((i) => i.name.trim().toLowerCase() == normalizedText),
    );
    // Remove suggestion chip regardless (it's been acted upon)
    final remaining =
        state.suggestions.where((s) => s.text != suggestion.text).toList();
    state = state.copyWith(suggestions: remaining);
    if (alreadyExists) return; // Skip adding but still dismiss the chip
    await addItemToCategory(
      suggestion.categoryId,
      suggestion.text,
      isAiSuggested: true,
    );
  }

  void dismissSuggestions() =>
      state = state.copyWith(showSuggestions: false);

  void toggleSuggestionsExpanded() =>
      state = state.copyWith(suggestionsExpanded: !state.suggestionsExpanded);

  // ── Templates ─────────────────────────────────────────────────────

  Future<void> loadTemplates() async {
    final repo = ref.read(packingRepositoryProvider);
    final templates = await repo.getTemplates();
    state = state.copyWith(templates: templates);
  }

  Future<PackingTemplate> saveCurrentAsTemplate(
    String name, {
    String icon = '🎒',
    String description = '',
  }) async {
    final repo = ref.read(packingRepositoryProvider);
    final itemsByCategory = <String, List<String>>{};
    for (final cat in state.categories) {
      if (cat.items.isNotEmpty) {
        itemsByCategory[cat.id] = cat.items.map((i) => i.name).toList();
      }
    }

    final saved = await repo.saveTemplate(
      name: name,
      description: description.isNotEmpty
          ? description
          : 'Includes ${state.totalItems} items across ${itemsByCategory.length} categories',
      icon: icon,
      itemsByCategory: itemsByCategory,
    );

    final templates = await repo.getTemplates();
    state = state.copyWith(templates: templates);
    return saved;
  }

  Future<void> applyTemplate(PackingTemplate template) async {
    final tripId = state.tripId;
    if (tripId == null) return;

    state = state.copyWith(isLoading: true);
    final repo = ref.read(packingRepositoryProvider);
    await repo.applyTemplate(tripId: tripId, template: template);
    await _loadFromRepo(tripId);
  }

  Future<void> deleteTemplate(String templateId) async {
    final repo = ref.read(packingRepositoryProvider);
    await repo.deleteTemplate(templateId);
    final templates = await repo.getTemplates();
    state = state.copyWith(templates: templates);
  }

  // ── Reminders & Notifications ─────────────────────────────────────

  Future<void> sendMemberReminder(MemberModel member, String tripName) async {
    final tripId = state.tripId;
    if (tripId == null) return;

    final unpacked = state.getMemberUnpackedItems(member.id);
    final repo = ref.read(packingRepositoryProvider);
    await repo.sendPackingReminder(
      tripId: tripId,
      tripName: tripName,
      memberId: member.id,
      memberName: member.name,
      unpackedItems: unpacked,
    );
  }

  Future<void> sendGroupReminder(List<MemberModel> members, String tripName) async {
    for (final m in members) {
      await sendMemberReminder(m, tripName);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────

  List<PackingCategory> _mapCategories(
    String categoryId,
    List<PackingItem> Function(List<PackingItem>) transform,
  ) {
    return state.categories.map((c) {
      if (c.id != categoryId) return c;
      return c.copyWith(items: transform(c.items));
    }).toList();
  }

  PackingItem? _findItem(String categoryId, String itemId) {
    final cat = state.categories.where((c) => c.id == categoryId).firstOrNull;
    return cat?.items.where((i) => i.id == itemId).firstOrNull;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final packingProvider = Provider.autoDispose
    .family<NotifierProvider<PackingNotifier, PackingState>, String>(
  (ref, tripId) {
    return NotifierProvider<PackingNotifier, PackingState>(() {
      return PackingNotifier().._tripId = tripId;
    });
  },
);

