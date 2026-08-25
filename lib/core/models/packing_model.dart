import 'package:flutter/material.dart';

// ── Packing Item ─────────────────────────────────────────────────────────────

class PackingItem {
  final String id;
  String name;
  bool isChecked;
  bool isAiSuggested;
  bool isCritical;
  // Primary multi-member assignment list.
  List<String> assignedMemberIds;
  // Legacy display-only fields — mirror the first assigned member.
  String? assignedMemberId;
  String? assignedMemberName;
  String? assignedMemberInitials;
  int? assignedMemberColor;
  String? assignedMemberRole;

  PackingItem({
    required this.id,
    required this.name,
    this.isChecked = false,
    this.isAiSuggested = false,
    this.isCritical = false,
    List<String>? assignedMemberIds,
    this.assignedMemberId,
    this.assignedMemberName,
    this.assignedMemberInitials,
    this.assignedMemberColor,
    this.assignedMemberRole,
  }) : assignedMemberIds = assignedMemberIds ??
           (assignedMemberId != null && assignedMemberId.isNotEmpty
               ? [assignedMemberId]
               : []);

  bool get isAssigned => assignedMemberIds.isNotEmpty;

  PackingItem copyWith({
    String? id,
    String? name,
    bool? isChecked,
    bool? isAiSuggested,
    bool? isCritical,
    List<String>? assignedMemberIds,
    String? assignedMemberId,
    String? assignedMemberName,
    String? assignedMemberInitials,
    int? assignedMemberColor,
    String? assignedMemberRole,
    bool clearAssignment = false,
  }) {
    return PackingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      isChecked: isChecked ?? this.isChecked,
      isAiSuggested: isAiSuggested ?? this.isAiSuggested,
      isCritical: isCritical ?? this.isCritical,
      assignedMemberIds: clearAssignment ? [] : (assignedMemberIds ?? List<String>.from(this.assignedMemberIds)),
      assignedMemberId: clearAssignment ? null : (assignedMemberId ?? this.assignedMemberId),
      assignedMemberName: clearAssignment ? null : (assignedMemberName ?? this.assignedMemberName),
      assignedMemberInitials: clearAssignment ? null : (assignedMemberInitials ?? this.assignedMemberInitials),
      assignedMemberColor: clearAssignment ? null : (assignedMemberColor ?? this.assignedMemberColor),
      assignedMemberRole: clearAssignment ? null : (assignedMemberRole ?? this.assignedMemberRole),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'is_checked': isChecked,
      'is_ai_suggested': isAiSuggested,
      'is_critical': isCritical,
      'assigned_user_id': assignedMemberId,
      'assigned_user_name': assignedMemberName,
      'assigned_user_initials': assignedMemberInitials,
      'assigned_user_color': assignedMemberColor,
      'assigned_user_role': assignedMemberRole,
    };
  }

  factory PackingItem.fromMap(Map<String, dynamic> map) {
    return PackingItem(
      id: '${map['id']}',
      name: '${map['name'] ?? ''}',
      isChecked: map['is_checked'] == true,
      isAiSuggested: map['is_ai_suggested'] == true,
      isCritical: map['is_critical'] == true,
      assignedMemberId: map['assigned_user_id']?.toString(),
      assignedMemberName: map['assigned_user_name']?.toString(),
      assignedMemberInitials: map['assigned_user_initials']?.toString(),
      assignedMemberColor: map['assigned_user_color'] is int
          ? map['assigned_user_color'] as int
          : (map['assigned_user_color'] != null
              ? int.tryParse(map['assigned_user_color'].toString())
              : null),
      assignedMemberRole: map['assigned_user_role']?.toString(),
    );
  }
}

// ── Packing Category ─────────────────────────────────────────────────────────

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
    this.isExpanded = false, // Default collapsed
    this.isCustom = false,
  });

  int get packedCount => items.where((i) => i.isChecked).length;
  int get totalCount => items.length;
  double get progress => totalCount == 0 ? 0 : packedCount / totalCount;
  bool get allPacked => totalCount > 0 && packedCount == totalCount;
  bool get isEmpty => items.isEmpty;

  PackingCategory copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    List<PackingItem>? items,
    bool? isExpanded,
    bool? isCustom,
  }) {
    return PackingCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      items: items ?? this.items,
      isExpanded: isExpanded ?? this.isExpanded,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}

// ── Smart Suggestion ─────────────────────────────────────────────────────────

class SmartSuggestion {
  final String text;
  final String categoryId;
  final String icon;
  final String? reason;
  final bool isWeatherAware;

  const SmartSuggestion({
    required this.text,
    required this.categoryId,
    required this.icon,
    this.reason,
    this.isWeatherAware = false,
  });
}

// ── Packing Template ─────────────────────────────────────────────────────────

class PackingTemplate {
  final String id;
  final String name;
  final String description;
  final String icon;
  final Map<String, List<String>> itemsByCategory;
  final bool isPrebuilt;
  final DateTime createdAt;

  const PackingTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.itemsByCategory,
    this.isPrebuilt = false,
    required this.createdAt,
  });

  int get totalItemCount =>
      itemsByCategory.values.fold(0, (sum, list) => sum + list.length);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'items_by_category': itemsByCategory,
      'is_prebuilt': isPrebuilt,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PackingTemplate.fromMap(Map<String, dynamic> map) {
    final rawCats = map['items_by_category'] as Map? ?? {};
    final parsedCats = <String, List<String>>{};
    for (final entry in rawCats.entries) {
      final key = entry.key.toString();
      final val = entry.value;
      if (val is List) {
        parsedCats[key] = val.map((e) => e.toString()).toList();
      }
    }

    return PackingTemplate(
      id: '${map['id']}',
      name: '${map['name'] ?? 'Custom Template'}',
      description: '${map['description'] ?? ''}',
      icon: '${map['icon'] ?? '🎒'}',
      itemsByCategory: parsedCats,
      isPrebuilt: map['is_prebuilt'] == true,
      createdAt: DateTime.tryParse('${map['created_at']}') ?? DateTime.now(),
    );
  }

  /// System prebuilt templates tailored for Filipino & Southeast Asian travel
  static List<PackingTemplate> get prebuiltTemplates => [
        PackingTemplate(
          id: 'template_beach',
          name: 'Beach & Island Trip',
          description: 'Reef-safe sunscreen, swimwear, dry bags, snorkel gear & island essentials',
          icon: '🏖️',
          isPrebuilt: true,
          createdAt: DateTime(2026, 1, 1),
          itemsByCategory: {
            'essentials': ['Passport / Valid ID', 'Pocket Cash (PHP)', 'Waterproof Dry Bag (10L)', 'Reef-safe Sunscreen SPF 50+', 'Aloe Vera Gel'],
            'clothing': ['Swimsuit / Rashguard (2x)', 'Quick-dry Shorts (2x)', 'Breathable Linen Shirts (3x)', 'Sandals / Aqua Shoes', 'Sun Hat / Cap', 'Sunglasses'],
            'toiletries': ['Biodegradable Shampoo', 'Body Wash', 'Toothbrush & Paste', 'Insect Repellent (DEET-free)'],
            'gadgets': ['Waterproof Phone Pouch', 'Power Bank (20,000mAh)', 'Action Camera / GoPro', 'Portable Speaker'],
            'food': ['Hydration Electrolytes', 'Trail Snacks / Dried Mangoes', 'Reusable Water Bottle (Insulated)'],
            'medicines': ['Dimenhydrinate (Motion sickness/Bonamine)', 'Pain Reliever', 'Band-aids & Antiseptic'],
            'others': ['Beach Towel (Microfiber)', 'Snorkel Mask', 'Ziploc Bags for Wet Clothes'],
          },
        ),
        PackingTemplate(
          id: 'template_mountain',
          name: 'Mountain & Cold Trek',
          description: 'Layered clothing, thermal wear, hiking shoes & trail survival kit for Sagada / Baguio / Pulag',
          icon: '⛰️',
          isPrebuilt: true,
          createdAt: DateTime(2026, 1, 1),
          itemsByCategory: {
            'essentials': ['Valid ID & Permits', 'Emergency Cash (PHP)', 'Trekking Poles', 'Thermal Flask / Water Bottle'],
            'clothing': ['Fleece / Puffer Jacket', 'Thermal Innerwear (Top & Bottom)', 'Moisture-wicking Shirts (3x)', 'Trekking Pants', 'Hiking Boots / Trail Shoes', 'Beanie & Gloves', 'Thick Wool Socks (3x)'],
            'toiletries': ['Lip Balm with SPF', 'Wet Wipes / Tissue', 'Toothbrush & Toothpaste', 'Moisturizer / Hand Cream'],
            'gadgets': ['Headlamp with Extra Batteries', 'High-capacity Power Bank', 'Camera with extra SD card'],
            'food': ['Energy Bars / Trail Mix', 'Instant Coffee / Ginger Tea', 'Cup Noodles & Trail Snacks'],
            'medicines': ['Paracetamol / Ibuprofen', 'Anti-altitude / Motion Sickness Meds', 'Muscle Rub (Salonpas / Omega)', 'First Aid Kit'],
            'others': ['Rain Poncho / Windbreaker', 'Backpack Rain Cover', 'Trash Bags (Leave No Trace)'],
          },
        ),
        PackingTemplate(
          id: 'template_city',
          name: 'City & Culture Weekend',
          description: 'Comfortable walking gear, power essentials, smart-casual outfits & urban kit',
          icon: '🏙️',
          isPrebuilt: true,
          createdAt: DateTime(2026, 1, 1),
          itemsByCategory: {
            'essentials': ['Govt ID / Student ID', 'Credit / Debit Cards', 'Beep Card / Transit Card', 'Foldable Tote Bag'],
            'clothing': ['Comfortable Walking Sneakers', 'Smart Casual Outfits (2x)', 'Light Cardigan / Blazer', 'Everyday T-shirts (3x)'],
            'toiletries': ['Travel Fragrance', 'Deodorant', 'Hand Sanitizer / Alcohol Spray', 'Pocket Mirror'],
            'gadgets': ['Wireless Earbuds', 'Fast Phone Charger & Cable', 'Compact Power Bank'],
            'food': ['Mints / Gum', 'Energy Granola Bar'],
            'medicines': ['Antacid (Kremil-S / Gaviscon)', 'Headache Relief Meds'],
            'others': ['Compact Umbrella', 'Foldable Shopping Bag'],
          },
        ),
        PackingTemplate(
          id: 'template_roadtrip',
          name: 'Road Trip & Camping',
          description: 'In-car entertainment, emergency roadside gear, coolers & camping essentials',
          icon: '🚗',
          isPrebuilt: true,
          createdAt: DateTime(2026, 1, 1),
          itemsByCategory: {
            'essentials': ["Driver's License & OR/CR", 'RFID Cards (Easytrip/Autosweep)', 'Car Emergency Kit', 'Flashlight'],
            'clothing': ['Casual Camp Outfits (2x)', 'Light Windbreaker', 'Slip-on Shoes / Slides'],
            'toiletries': ['Biodegradable Wet Wipes', 'Mosquito Repellent Lotion', 'Toothbrush kit'],
            'gadgets': ['Car Fast Charger (Dual USB-C)', 'Bluetooth Aux Adapter', 'Portable Bluetooth Speaker', 'Multi-plug Extension'],
            'food': ['Road Trip Chips & Snacks', 'Cooler with Cold Drinks', 'Bottled Water 5L', 'Ground Coffee & Dripper'],
            'medicines': ['Motion Sickness Pills', 'Antihistamines', 'Bandages & Antiseptic Cream'],
            'others': ['Camping Chair (Foldable)', 'Picnic Mat / Blanket', 'Multi-tool / Swiss Army Knife'],
          },
        ),
      ];
}

// ── Smart AI Recommendation Engine ──────────────────────────────────────────

class AiPackingEngine {
  /// Generates dynamic contextual suggestions based on destination, weather, duration, transport
  static List<SmartSuggestion> generateSuggestions({
    required String destination,
    required String tripType,
    required int durationDays,
    String? weatherCondition, // e.g. "rain", "sunny", "cold", "cloudy"
    String? transportMode,    // e.g. "flight", "car", "ferry", "bus"
  }) {
    final suggestions = <SmartSuggestion>[];
    final destLower = destination.toLowerCase();
    final typeLower = tripType.toLowerCase();
    final weatherLower = (weatherCondition ?? '').toLowerCase();
    final transLower = (transportMode ?? '').toLowerCase();

    // ── 1. Weather-Aware Suggestions ────────────────────────────────────────
    if (weatherLower.contains('rain') || weatherLower.contains('storm') || weatherLower.contains('typhoon')) {
      suggestions.add(const SmartSuggestion(
        text: 'Compact Windproof Umbrella',
        categoryId: 'others',
        icon: '☔',
        reason: 'Rain forecast for trip dates',
        isWeatherAware: true,
      ));
      suggestions.add(const SmartSuggestion(
        text: 'Waterproof Rain Poncho / Jacket',
        categoryId: 'clothing',
        icon: '🧥',
        reason: 'Keep clothes dry during rain',
        isWeatherAware: true,
      ));
      suggestions.add(const SmartSuggestion(
        text: 'Waterproof Phone Dry Pouch',
        categoryId: 'gadgets',
        icon: '📱',
        reason: 'Protects electronics from rain',
        isWeatherAware: true,
      ));
    } else if (weatherLower.contains('sunny') || weatherLower.contains('hot') || weatherLower.contains('clear')) {
      suggestions.add(const SmartSuggestion(
        text: 'UV Protection Sunglasses',
        categoryId: 'clothing',
        icon: '🕶️',
        reason: 'Sunny & bright UV forecast',
        isWeatherAware: true,
      ));
      suggestions.add(const SmartSuggestion(
        text: 'Electrolyte Hydration Powders',
        categoryId: 'food',
        icon: '⚡',
        reason: 'Beat dehydration in hot weather',
        isWeatherAware: true,
      ));
    }

    // ── 2. Destination & Trip Type Analysis ──────────────────────────────────
    final isBeach = typeLower.contains('beach') ||
        destLower.contains('boracay') ||
        destLower.contains('siargao') ||
        destLower.contains('palawan') ||
        destLower.contains('el nido') ||
        destLower.contains('coron') ||
        destLower.contains('cebu') ||
        destLower.contains('panglao') ||
        destLower.contains('la union') ||
        destLower.contains('elyu') ||
        destLower.contains('puerto galera') ||
        destLower.contains('baler');

    final isMountain = typeLower.contains('mountain') ||
        typeLower.contains('hiking') ||
        typeLower.contains('camping') ||
        destLower.contains('baguio') ||
        destLower.contains('sagada') ||
        destLower.contains('pulag') ||
        destLower.contains('batanes') ||
        destLower.contains('tagaytay') ||
        destLower.contains('bukidnon') ||
        destLower.contains('mt.');

    if (isBeach) {
      suggestions.addAll([
        const SmartSuggestion(
          text: 'Reef-safe Sunscreen SPF 50+',
          categoryId: 'essentials',
          icon: '🧴',
          reason: 'Protects coral reefs and your skin',
        ),
        const SmartSuggestion(
          text: 'UV Long-sleeve Rashguard',
          categoryId: 'clothing',
          icon: '🏄',
          reason: 'Sun protection for water activities',
        ),
        const SmartSuggestion(
          text: 'Waterproof Dry Bag (10L)',
          categoryId: 'essentials',
          icon: '🎒',
          reason: 'Keep valuables dry during boat transfers',
        ),
        const SmartSuggestion(
          text: 'Aqua Shoes / Anti-slip Booties',
          categoryId: 'clothing',
          icon: '👟',
          reason: 'Protects feet from sharp corals/rocks',
        ),
        const SmartSuggestion(
          text: 'Aloe Vera After-sun Soothing Gel',
          categoryId: 'toiletries',
          icon: '🌿',
          reason: 'Instant sunburn relief',
        ),
      ]);
    } else if (isMountain) {
      suggestions.addAll([
        const SmartSuggestion(
          text: 'Thermal Base Layer (Top & Bottom)',
          categoryId: 'clothing',
          icon: '🧣',
          reason: 'Cold mountain elevation temperatures',
        ),
        const SmartSuggestion(
          text: 'Lightweight Packable Windbreaker',
          categoryId: 'clothing',
          icon: '🧥',
          reason: 'Shield against mountain gusts',
        ),
        const SmartSuggestion(
          text: 'Headlamp with Extra Batteries',
          categoryId: 'gadgets',
          icon: '🔦',
          reason: 'Essential for sunrise treks and trails',
        ),
        const SmartSuggestion(
          text: 'Muscle Pain Rub / Salonpas',
          categoryId: 'medicines',
          icon: '🩹',
          reason: 'Relieves fatigue after steep hikes',
        ),
        const SmartSuggestion(
          text: 'Instant Ginger Tea / 3-in-1 Coffee',
          categoryId: 'food',
          icon: '☕',
          reason: 'Warm up on chilly mountain mornings',
        ),
      ]);
    } else {
      // General / City / Sightseeing suggestions
      suggestions.addAll([
        const SmartSuggestion(
          text: 'High-Speed Power Bank (20,000mAh)',
          categoryId: 'gadgets',
          icon: '🔋',
          reason: 'Full day sightseeing battery backup',
        ),
        const SmartSuggestion(
          text: 'Anti-motion Sickness Meds (Bonamine)',
          categoryId: 'medicines',
          icon: '💊',
          reason: 'Travel relief during long rides',
        ),
        const SmartSuggestion(
          text: 'Hand Sanitizer Spray (70% Alcohol)',
          categoryId: 'toiletries',
          icon: '🧴',
          reason: 'Clean hands before street food stops',
        ),
        const SmartSuggestion(
          text: 'Travel Neck Pillow & Eye Mask',
          categoryId: 'essentials',
          icon: '😴',
          reason: 'Comfort during transit',
        ),
      ]);
    }

    // ── 3. Transport Mode Checks ───────────────────────────────────────────
    if (transLower.contains('flight') || transLower.contains('plane')) {
      suggestions.add(const SmartSuggestion(
        text: 'Liquids in <100ml Travel Bottles',
        categoryId: 'toiletries',
        icon: '✈️',
        reason: 'Airport TSA liquid restriction compliant',
      ));
      suggestions.add(const SmartSuggestion(
        text: 'Luggage Tag & TSA Lock',
        categoryId: 'essentials',
        icon: '🔒',
        reason: 'Secure check-in baggage',
      ));
    } else if (transLower.contains('car') || transLower.contains('drive') || transLower.contains('road')) {
      suggestions.add(const SmartSuggestion(
        text: 'Dual-Port USB Car Fast Charger',
        categoryId: 'gadgets',
        icon: '🚗',
        reason: 'Keep navigation phones charged in vehicle',
      ));
      suggestions.add(const SmartSuggestion(
        text: 'Tollway RFID Cards (Easytrip & Autosweep)',
        categoryId: 'essentials',
        icon: '💳',
        reason: 'Breeze through expressways',
      ));
    }

    // ── 4. Duration Multiplier Checks ───────────────────────────────────────
    if (durationDays >= 4) {
      suggestions.add(SmartSuggestion(
        text: 'Travel Laundry Detergent Sheets',
        categoryId: 'toiletries',
        icon: '🧼',
        reason: 'Quick wash for $durationDays-day trip',
      ));
    }

    return suggestions;
  }
}

