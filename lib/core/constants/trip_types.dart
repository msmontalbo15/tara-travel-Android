import 'package:flutter/material.dart';

class TripTypeOption {
  final String id;
  final String label;
  final String emoji;
  final String subtitle;
  final String category;
  final Color accentColor;

  const TripTypeOption({
    required this.id,
    required this.label,
    required this.emoji,
    required this.subtitle,
    required this.category,
    required this.accentColor,
  });
}

class AppTripTypes {
  static const String catPopular = 'Popular';
  static const String catOutdoors = 'Outdoors & Adventure';
  static const String catLifestyle = 'Lifestyle & Food';
  static const String catLeisure = 'Leisure & Travel';

  static const List<String> categories = [
    'All',
    catPopular,
    catOutdoors,
    catLifestyle,
    catLeisure,
  ];

  static const List<TripTypeOption> all = [
    // Popular
    TripTypeOption(
      id: 'beach',
      label: 'Beach',
      emoji: '🏖️',
      subtitle: 'Sun, sand & ocean breeze',
      category: catPopular,
      accentColor: Color(0xFF00B4DB),
    ),
    TripTypeOption(
      id: 'city',
      label: 'City',
      emoji: '🏙️',
      subtitle: 'Urban exploration & skylines',
      category: catPopular,
      accentColor: Color(0xFF5B61B9),
    ),
    TripTypeOption(
      id: 'road_trip',
      label: 'Road Trip',
      emoji: '🚗',
      subtitle: 'Scenic drives & open highways',
      category: catPopular,
      accentColor: Color(0xFFFF6B6B),
    ),
    TripTypeOption(
      id: 'foodie',
      label: 'Foodie',
      emoji: '🍕',
      subtitle: 'Culinary delights & local tastes',
      category: catPopular,
      accentColor: Color(0xFFFF8C42),
    ),

    // Outdoors & Adventure
    TripTypeOption(
      id: 'adventure',
      label: 'Adventure',
      emoji: '🏕️',
      subtitle: 'Hiking, camping & thrills',
      category: catOutdoors,
      accentColor: Color(0xFF2E7D32),
    ),
    TripTypeOption(
      id: 'nature',
      label: 'Nature',
      emoji: '🌿',
      subtitle: 'Forests, mountains & outdoors',
      category: catOutdoors,
      accentColor: Color(0xFF43A047),
    ),
    TripTypeOption(
      id: 'cruise',
      label: 'Cruise & Sailing',
      emoji: '🚢',
      subtitle: 'Ocean voyages & island hopping',
      category: catOutdoors,
      accentColor: Color(0xFF0288D1),
    ),
    TripTypeOption(
      id: 'backpacking',
      label: 'Backpacking',
      emoji: '🎒',
      subtitle: 'Budget travel & hostel life',
      category: catOutdoors,
      accentColor: Color(0xFF8D6E63),
    ),

    // Lifestyle & Food
    TripTypeOption(
      id: 'wellness',
      label: 'Wellness & Spa',
      emoji: '🧘‍♀️',
      subtitle: 'Mindful relaxation & retreat',
      category: catLifestyle,
      accentColor: Color(0xFF00897B),
    ),
    TripTypeOption(
      id: 'cultural',
      label: 'Cultural',
      emoji: '🏛️',
      subtitle: 'History, art & local heritage',
      category: catLifestyle,
      accentColor: Color(0xFF8E24AA),
    ),
    TripTypeOption(
      id: 'festival',
      label: 'Festival & Events',
      emoji: '🎟️',
      subtitle: 'Concerts, nightlife & events',
      category: catLifestyle,
      accentColor: Color(0xFFE91E63),
    ),
    TripTypeOption(
      id: 'solo',
      label: 'Solo Travel',
      emoji: '🧭',
      subtitle: 'Independent discovery & growth',
      category: catLifestyle,
      accentColor: Color(0xFF3F51B5),
    ),

    // Leisure & Travel
    TripTypeOption(
      id: 'family',
      label: 'Family Trip',
      emoji: '👨‍👩‍👧‍👦',
      subtitle: 'Kid-friendly fun & memories',
      category: catLeisure,
      accentColor: Color(0xFFFB8C00),
    ),
    TripTypeOption(
      id: 'romantic',
      label: 'Romantic',
      emoji: '💖',
      subtitle: 'Couples getaways & honeymoon',
      category: catLeisure,
      accentColor: Color(0xFFEC407A),
    ),
    TripTypeOption(
      id: 'business',
      label: 'Business',
      emoji: '💼',
      subtitle: 'Workcation & remote work',
      category: catLeisure,
      accentColor: Color(0xFF455A64),
    ),
    TripTypeOption(
      id: 'luxury',
      label: 'Luxury & Resort',
      emoji: '💎',
      subtitle: '5-star comfort & premium stays',
      category: catLeisure,
      accentColor: Color(0xFFD4AF37),
    ),
  ];

  static TripTypeOption getOption(String? typeStr) {
    if (typeStr == null || typeStr.isEmpty) return all.first;
    final normalized = typeStr.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    return all.firstWhere(
      (opt) =>
          opt.id == normalized ||
          opt.label.toLowerCase() == typeStr.trim().toLowerCase(),
      orElse: () => all.firstWhere(
        (opt) => typeStr.toLowerCase().contains(opt.id),
        orElse: () => TripTypeOption(
          id: normalized,
          label: typeStr,
          emoji: '🌏',
          subtitle: 'Custom trip experience',
          category: catPopular,
          accentColor: const Color(0xFF00B4DB),
        ),
      ),
    );
  }

  static String getEmoji(String? typeStr) {
    return getOption(typeStr).emoji;
  }

  static String getLabel(String? typeStr) {
    return getOption(typeStr).label;
  }

  static Color getColor(String? typeStr) {
    return getOption(typeStr).accentColor;
  }
}
