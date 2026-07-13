import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/packing_model.dart';
import 'repository_providers.dart';

// ── Packing State ─────────────────────────────────────────────────────────────

class PackingState {
  final List<PackingCategory> categories;
  final List<SmartSuggestion> suggestions;
  final bool showSuggestions;
  final bool isLoading;
  final String? tripId;

  const PackingState({
    required this.categories,
    required this.suggestions,
    this.showSuggestions = true,
    this.isLoading = false,
    this.tripId,
  });

  PackingState copyWith({
    List<PackingCategory>? categories,
    List<SmartSuggestion>? suggestions,
    bool? showSuggestions,
    bool? isLoading,
    String? tripId,
  }) {
    return PackingState(
      categories: categories ?? this.categories,
      suggestions: suggestions ?? this.suggestions,
      showSuggestions: showSuggestions ?? this.showSuggestions,
      isLoading: isLoading ?? this.isLoading,
      tripId: tripId ?? this.tripId,
    );
  }

  int get totalItems => categories.fold(0, (s, c) => s + c.totalCount);
  int get packedItems => categories.fold(0, (s, c) => s + c.packedCount);
  double get overallProgress => totalItems == 0 ? 0 : packedItems / totalItems;
  bool get allPacked => totalItems > 0 && packedItems == totalItems;
}

// ── Packing Notifier ──────────────────────────────────────────────────────────
// Riverpod v3: store tripId as late field, injected by the provider factory.

class PackingNotifier extends Notifier<PackingState> {
  late final String _tripId;

  @override
  PackingState build() {
    _loadFromRepo(_tripId);
    return const PackingState(categories: [], suggestions: []);
  }

  Future<void> _loadFromRepo(String tripId) async {
    state = state.copyWith(isLoading: true, tripId: tripId);
    try {
      final repo = ref.read(packingRepositoryProvider);
      final categories = await repo.getCategories(tripId);
      state = state.copyWith(
        categories: categories,
        isLoading: false,
        tripId: tripId,
      );
    } catch (e) {
      debugPrint('[PackingNotifier] load error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  // ── Mutations ─────────────────────────────────────────────────────

  Future<void> toggleItem(String categoryId, String itemId) async {
    // Optimistic local update
    final cats = _mapCategories(categoryId, (items) {
      return items.map((i) {
        if (i.id != itemId) return i;
        return PackingItem(
          id: i.id,
          name: i.name,
          isChecked: !i.isChecked,
          isAiSuggested: i.isAiSuggested,
          isCritical: i.isCritical,
          assignedMemberId: i.assignedMemberId,
        );
      }).toList();
    });
    state = state.copyWith(categories: cats);

    // Find the new checked state and persist
    final checked = _findItem(categoryId, itemId)?.isChecked ?? false;
    if (state.tripId != null) {
      await ref.read(packingRepositoryProvider).toggleItem(itemId, checked);
    }
  }

  Future<void> addItemToCategory(String categoryId, String itemName) async {
    final tripId = state.tripId;
    if (tripId == null) return;

    final repo = ref.read(packingRepositoryProvider);
    final newItem = await repo.addItem(
      tripId: tripId,
      category: categoryId,
      name: itemName,
    );

    final cats = _mapCategories(categoryId, (items) => [...items, newItem]);
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

  void toggleCategory(String categoryId) {
    final cats = state.categories.map((c) {
      if (c.id != categoryId) return c;
      return PackingCategory(
        id: c.id,
        name: c.name,
        icon: c.icon,
        color: c.color,
        items: c.items,
        isExpanded: !c.isExpanded,
        isCustom: c.isCustom,
      );
    }).toList();
    state = state.copyWith(categories: cats);
  }

  Future<void> addSuggestion(SmartSuggestion suggestion) async {
    final remaining =
        state.suggestions.where((s) => s.text != suggestion.text).toList();
    state = state.copyWith(suggestions: remaining);
    await addItemToCategory(suggestion.categoryId, suggestion.text);
  }

  void dismissSuggestions() =>
      state = state.copyWith(showSuggestions: false);

  Future<void> addCustomCategory(String name) async {
    final newCat = PackingCategory(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      icon: Icons.category_rounded,
      color: const Color(0xFF8B5CF6),
      items: [],
      isCustom: true,
    );
    state = state.copyWith(categories: [...state.categories, newCat]);
  }

  // ── Helpers ───────────────────────────────────────────────────────

  List<PackingCategory> _mapCategories(
    String categoryId,
    List<PackingItem> Function(List<PackingItem>) transform,
  ) {
    return state.categories.map((c) {
      if (c.id != categoryId) return c;
      return PackingCategory(
        id: c.id,
        name: c.name,
        icon: c.icon,
        color: c.color,
        items: transform(c.items),
        isExpanded: c.isExpanded,
        isCustom: c.isCustom,
      );
    }).toList();
  }

  PackingItem? _findItem(String categoryId, String itemId) {
    final cat = state.categories.where((c) => c.id == categoryId).firstOrNull;
    return cat?.items.where((i) => i.id == itemId).firstOrNull;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────
// Family of providers keyed by tripId. Each returns a fresh NotifierProvider
// with its own PackingNotifier._tripId injected.

final packingProvider = Provider.autoDispose
    .family<NotifierProvider<PackingNotifier, PackingState>, String>(
  (ref, tripId) {
    return NotifierProvider<PackingNotifier, PackingState>(() {
      return PackingNotifier().._tripId = tripId;
    });
  },
);
