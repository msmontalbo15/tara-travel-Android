/// destination_model.dart
/// Model representing curated travel destinations stored in Supabase `public.destinations`.
library;

class DestinationModel {
  final String id;
  final String name;
  final String country;
  final String distanceFromMetro;
  final String bestMode;
  final String avgCostRange;
  final String photoEmoji;
  final String tag;
  final String description;
  final bool isTrending;
  final bool isWeekendGetaway;
  final bool isRecommended;
  final String? recommendedReason;
  final String bestTimeToVisit;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final String tripType;

  const DestinationModel({
    required this.id,
    required this.name,
    this.country = 'Philippines',
    required this.distanceFromMetro,
    required this.bestMode,
    required this.avgCostRange,
    this.photoEmoji = '🌏',
    this.tag = 'General',
    required this.description,
    this.isTrending = false,
    this.isWeekendGetaway = false,
    this.isRecommended = false,
    this.recommendedReason,
    this.bestTimeToVisit = 'Year-round',
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.tripType = 'sightseeing_tours',
  });

  factory DestinationModel.fromMap(Map<String, dynamic> map) {
    return DestinationModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      country: map['country']?.toString() ?? 'Philippines',
      distanceFromMetro: map['distance_from_metro']?.toString() ?? '',
      bestMode: map['best_mode']?.toString() ?? '🚗 Car',
      avgCostRange: map['avg_cost_range']?.toString() ?? '₱2,000–₱5,000',
      photoEmoji: map['photo_emoji']?.toString() ?? '🌏',
      tag: map['tag']?.toString() ?? 'General',
      description: map['description']?.toString() ?? '',
      isTrending: map['is_trending'] == true,
      isWeekendGetaway: map['is_weekend_getaway'] == true,
      isRecommended: map['is_recommended'] == true,
      recommendedReason: map['recommended_reason']?.toString(),
      bestTimeToVisit: map['best_time_to_visit']?.toString() ?? 'Year-round',
      imageUrl: map['image_url']?.toString(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      tripType: map['trip_type']?.toString() ?? 'sightseeing_tours',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'distance_from_metro': distanceFromMetro,
      'best_mode': bestMode,
      'avg_cost_range': avgCostRange,
      'photo_emoji': photoEmoji,
      'tag': tag,
      'description': description,
      'is_trending': isTrending,
      'is_weekend_getaway': isWeekendGetaway,
      'is_recommended': isRecommended,
      'recommended_reason': recommendedReason,
      'best_time_to_visit': bestTimeToVisit,
      'image_url': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'trip_type': tripType,
    };
  }

  DestinationModel copyWith({
    String? id,
    String? name,
    String? country,
    String? distanceFromMetro,
    String? bestMode,
    String? avgCostRange,
    String? photoEmoji,
    String? tag,
    String? description,
    bool? isTrending,
    bool? isWeekendGetaway,
    bool? isRecommended,
    String? recommendedReason,
    String? bestTimeToVisit,
    String? imageUrl,
    double? latitude,
    double? longitude,
    String? tripType,
  }) {
    return DestinationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      distanceFromMetro: distanceFromMetro ?? this.distanceFromMetro,
      bestMode: bestMode ?? this.bestMode,
      avgCostRange: avgCostRange ?? this.avgCostRange,
      photoEmoji: photoEmoji ?? this.photoEmoji,
      tag: tag ?? this.tag,
      description: description ?? this.description,
      isTrending: isTrending ?? this.isTrending,
      isWeekendGetaway: isWeekendGetaway ?? this.isWeekendGetaway,
      isRecommended: isRecommended ?? this.isRecommended,
      recommendedReason: recommendedReason ?? this.recommendedReason,
      bestTimeToVisit: bestTimeToVisit ?? this.bestTimeToVisit,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      tripType: tripType ?? this.tripType,
    );
  }
}
