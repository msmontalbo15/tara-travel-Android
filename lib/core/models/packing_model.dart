import 'package:flutter/material.dart';

class PackingItem {
  final String id;
  String name;
  bool isChecked;
  bool isAiSuggested;
  bool isCritical;
  String? assignedMemberId;

  PackingItem({
    required this.id,
    required this.name,
    this.isChecked = false,
    this.isAiSuggested = false,
    this.isCritical = false,
    this.assignedMemberId,
  });
}

class PackingCategory {
  final String id;
  String name;
  IconData icon;
  Color color;
  List<PackingItem> items;
  bool isExpanded;
  bool isCustom;

  PackingCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.items = const [],
    this.isExpanded = true,
    this.isCustom = false,
  });

  int get packedCount => items.where((i) => i.isChecked).length;
  int get totalCount => items.length;
  double get progress => totalCount == 0 ? 0 : packedCount / totalCount;
  bool get allPacked => totalCount > 0 && packedCount == totalCount;
}

class SmartSuggestion {
  final String text;
  final String categoryId;
  final String icon;

  const SmartSuggestion({
    required this.text,
    required this.categoryId,
    required this.icon,
  });
}
