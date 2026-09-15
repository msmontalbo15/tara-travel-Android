/// destination_repository.dart
/// Remote Supabase repository for travel destinations with offline fallback resilience.
library;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/destination_model.dart';

class DestinationRepository {
  final SupabaseClient _supabase;

  DestinationRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Fetches destinations directly from Supabase `public.destinations`.
  /// Falls back to curated Philippine travel hubs if network is offline or table is empty.
  Future<List<DestinationModel>> getDestinations() async {
    try {
      final response = await _supabase
          .from('destinations')
          .select()
          .order('name', ascending: true);

      final rows = response as List;
      if (rows.isNotEmpty) {
        final destinations = rows
            .map((r) => DestinationModel.fromMap((r as Map).cast<String, dynamic>()))
            .toList();
        return destinations;
      }
    } catch (e) {
      debugPrint('[DestinationRepository] getDestinations remote error: $e. Falling back to built-in destinations.');
    }

    return defaultPhilippineDestinations;
  }

  /// Curated default Philippine destinations guaranteed to render even when completely offline
  static const List<DestinationModel> defaultPhilippineDestinations = [
    DestinationModel(
      id: 'dest-boracay',
      name: 'Boracay',
      country: 'Philippines',
      distanceFromMetro: '~315 km (1h flight from Manila)',
      bestMode: '✈️ Flight + Boat',
      avgCostRange: '₱8,000–₱16,000',
      photoEmoji: '🏖️',
      tag: 'Beach',
      description:
          'World-famous powdery white sand, breathtaking tropical sunsets, and vibrant watersport adventures along Station 1 to 3.',
      isTrending: true,
      isWeekendGetaway: false,
      isRecommended: true,
      recommendedReason: 'Top-rated beach in Southeast Asia with pristine shores and nightlife.',
      bestTimeToVisit: 'Nov–May',
      imageUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=1200&q=80',
      latitude: 11.9674,
      longitude: 121.9248,
      tripType: 'beach_coastal',
    ),
    DestinationModel(
      id: 'dest-elnido',
      name: 'El Nido',
      country: 'Philippines',
      distanceFromMetro: '~420 km (1.2h flight from Manila)',
      bestMode: '✈️ Flight + Van',
      avgCostRange: '₱12,000–₱24,000',
      photoEmoji: '🌴',
      tag: 'Nature',
      description:
          'Towering limestone karst cliffs, hidden lagoons, secret beaches, and crystalline turquoise snorkeling waters.',
      isTrending: true,
      isWeekendGetaway: false,
      isRecommended: true,
      recommendedReason: 'Must-visit UNESCO biosphere with breathtaking lagoons and island hopping.',
      bestTimeToVisit: 'Dec–May',
      imageUrl: 'https://images.unsplash.com/photo-1518509562904-e7ef99cdcc86?auto=format&fit=crop&w=1200&q=80',
      latitude: 11.1956,
      longitude: 119.4075,
      tripType: 'nature_outdoors',
    ),
    DestinationModel(
      id: 'dest-coron',
      name: 'Coron',
      country: 'Philippines',
      distanceFromMetro: '~300 km (1h flight from Manila)',
      bestMode: '✈️ Flight + Boat',
      avgCostRange: '₱10,000–₱20,000',
      photoEmoji: '🤿',
      tag: 'Adventure',
      description:
          'World-class WWII Japanese shipwrecks, Kayangan Lake cleanest inland water, and Twin Lagoon thermocline swims.',
      isTrending: true,
      isWeekendGetaway: false,
      isRecommended: true,
      recommendedReason: 'Renowned for crystal clear lakes and unforgettable wreck diving.',
      bestTimeToVisit: 'Dec–May',
      imageUrl: 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?auto=format&fit=crop&w=1200&q=80',
      latitude: 11.9986,
      longitude: 120.2043,
      tripType: 'nature_outdoors',
    ),
    DestinationModel(
      id: 'dest-siargao',
      name: 'Siargao',
      country: 'Philippines',
      distanceFromMetro: '~780 km (2h flight from Manila)',
      bestMode: '✈️ Flight + Motorbike',
      avgCostRange: '₱9,000–₱18,000',
      photoEmoji: '🏄',
      tag: 'Adventure',
      description:
          'The surfing capital of the Philippines. Legendary Cloud 9 breaks, endless coconut palm roads, and serene Sugba Lagoon.',
      isTrending: true,
      isWeekendGetaway: false,
      isRecommended: true,
      recommendedReason: 'Vibrant surf culture, cafes, and laid-back island vibes.',
      bestTimeToVisit: 'Jul–Nov (Surf) / Mar–Oct (Sun)',
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80',
      latitude: 9.8580,
      longitude: 126.0460,
      tripType: 'sports_active',
    ),
    DestinationModel(
      id: 'dest-baguio',
      name: 'Baguio City',
      country: 'Philippines',
      distanceFromMetro: '~245 km (~4-5h drive via TPLEX)',
      bestMode: '🚗 Car / Bus',
      avgCostRange: '₱3,500–₱8,000',
      photoEmoji: '🌲',
      tag: 'City',
      description:
          'The Summer Capital of the Philippines. Crisp pine air, strawberry farms, Burnham Park, and artistic heritage at Camp John Hay.',
      isTrending: false,
      isWeekendGetaway: true,
      isRecommended: true,
      recommendedReason: 'Refreshing cool weather escape just a scenic expressway drive away.',
      bestTimeToVisit: 'Nov–Feb',
      imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1200&q=80',
      latitude: 16.4023,
      longitude: 120.5960,
      tripType: 'staycation',
    ),
    DestinationModel(
      id: 'dest-tagaytay',
      name: 'Tagaytay',
      country: 'Philippines',
      distanceFromMetro: '~60 km (~1.5h drive via SLEX/CALAX)',
      bestMode: '🚗 Car',
      avgCostRange: '₱2,000–₱5,500',
      photoEmoji: '🌋',
      tag: 'Nature',
      description:
          'Cool highland breezes, panoramic views of Taal Volcano and Lake, roadside bulalo, and charming farm-to-table ridge bistros.',
      isTrending: false,
      isWeekendGetaway: true,
      isRecommended: true,
      recommendedReason: 'Quick and cozy road trip escape with magnificent lake ridge dining.',
      bestTimeToVisit: 'Year-round',
      imageUrl: 'https://images.unsplash.com/photo-1519046904884-53103b34b206?auto=format&fit=crop&w=1200&q=80',
      latitude: 14.1153,
      longitude: 120.9621,
      tripType: 'food_crawl',
    ),
    DestinationModel(
      id: 'dest-batanes',
      name: 'Batanes',
      country: 'Philippines',
      distanceFromMetro: '~680 km (1.5h flight from Manila)',
      bestMode: '✈️ Flight + Tricycle',
      avgCostRange: '₱18,000–₱35,000',
      photoEmoji: '⛰️',
      tag: 'Cultural',
      description:
          'Sweeping emerald rolling hills, Marlboro Hills sea vistas, historic Ivatan stone houses, and tranquil Pacific cliffs.',
      isTrending: true,
      isWeekendGetaway: false,
      isRecommended: true,
      recommendedReason: 'Unmatched dramatic cliffs, peaceful heritage, and pristine landscapes.',
      bestTimeToVisit: 'Dec–May',
      imageUrl: 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?auto=format&fit=crop&w=1200&q=80',
      latitude: 20.4485,
      longitude: 121.9708,
      tripType: 'sightseeing_tours',
    ),
    DestinationModel(
      id: 'dest-cebu',
      name: 'Cebu & Moalboal',
      country: 'Philippines',
      distanceFromMetro: '~570 km (1.2h flight from Manila)',
      bestMode: '✈️ Flight + Bus',
      avgCostRange: '₱7,500–₱15,000',
      photoEmoji: '🐟',
      tag: 'Adventure',
      description:
          'World-famous sardine run just meters off the beach, sea turtles, Kawasan Falls canyoneering, and Magellan’s Cross history.',
      isTrending: true,
      isWeekendGetaway: false,
      isRecommended: true,
      recommendedReason: 'Epic canyoneering waterfalls and rich colonial landmarks.',
      bestTimeToVisit: 'Dec–May',
      imageUrl: 'https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&w=1200&q=80',
      latitude: 10.3157,
      longitude: 123.8854,
      tripType: 'adventure_trekking',
    ),
    DestinationModel(
      id: 'dest-sagada',
      name: 'Sagada',
      country: 'Philippines',
      distanceFromMetro: '~390 km (~10-12h scenic drive/bus)',
      bestMode: '🚌 Bus / Van',
      avgCostRange: '₱4,500–₱9,000',
      photoEmoji: '☕',
      tag: 'Cultural',
      description:
          'Misty Kiltepan sunrise sea of clouds, mystical Sumaguing Cave spelunking, hanging coffins, and fresh mountain Arabica coffee.',
      isTrending: false,
      isWeekendGetaway: false,
      isRecommended: true,
      recommendedReason: 'Peaceful mountain sanctuary with rich Igorot culture and spelunking.',
      bestTimeToVisit: 'Nov–Feb',
      imageUrl: 'https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?auto=format&fit=crop&w=1200&q=80',
      latitude: 17.0833,
      longitude: 120.9000,
      tripType: 'backpacking',
    ),
    DestinationModel(
      id: 'dest-launion',
      name: 'La Union (San Juan)',
      country: 'Philippines',
      distanceFromMetro: '~270 km (~4h drive via TPLEX)',
      bestMode: '🚗 Car / Bus',
      avgCostRange: '₱3,500–₱7,500',
      photoEmoji: '🌊',
      tag: 'Beach',
      description:
          'Accessible surf destination on the Luzon west coast, bustling food park community, beach bars, and vibrant sunset nightlife.',
      isTrending: true,
      isWeekendGetaway: true,
      isRecommended: true,
      recommendedReason: 'Favorite weekend surf spot with creative food concepts and chill music.',
      bestTimeToVisit: 'Oct–Mar (Surf) / Apr–Jun (Calm)',
      imageUrl: 'https://images.unsplash.com/photo-1473116763249-2faaef81ccda?auto=format&fit=crop&w=1200&q=80',
      latitude: 16.6750,
      longitude: 120.3394,
      tripType: 'beach_coastal',
    ),
    DestinationModel(
      id: 'dest-bohol',
      name: 'Bohol & Panglao',
      country: 'Philippines',
      distanceFromMetro: '~630 km (1.3h flight from Manila)',
      bestMode: '✈️ Flight + Van',
      avgCostRange: '₱8,000–₱16,000',
      photoEmoji: '🐒',
      tag: 'Nature',
      description:
          'Iconic cone-shaped Chocolate Hills, tiny Philippine tarsiers, Loboc river cruise lunch, and Alona Beach dive trips.',
      isTrending: true,
      isWeekendGetaway: false,
      isRecommended: true,
      recommendedReason: 'Eclectic wonders from world-famous geodiversity hills to lively beach strips.',
      bestTimeToVisit: 'Dec–May',
      imageUrl: 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80',
      latitude: 9.8500,
      longitude: 124.1435,
      tripType: 'sightseeing_tours',
    ),
    DestinationModel(
      id: 'dest-camiguin',
      name: 'Camiguin Island',
      country: 'Philippines',
      distanceFromMetro: '~780 km (Flight / Ferry from Bohol/CDO)',
      bestMode: '✈️ Flight + Ferry',
      avgCostRange: '₱7,000–₱14,000',
      photoEmoji: '🌋',
      tag: 'Nature',
      description:
          'The "Island Born of Fire". White Island horseshoe sandbar, Katibawasan Falls, sunken cemetery cross, and sweet lanzones.',
      isTrending: false,
      isWeekendGetaway: false,
      isRecommended: true,
      recommendedReason: 'Untouched volcanic paradise with crystal springs and lush rainforests.',
      bestTimeToVisit: 'Mar–Oct',
      imageUrl: 'https://images.unsplash.com/photo-1433086966358-54859d0ed716?auto=format&fit=crop&w=1200&q=80',
      latitude: 9.1732,
      longitude: 124.7299,
      tripType: 'nature_outdoors',
    ),
    DestinationModel(
      id: 'dest-intramuros',
      name: 'Intramuros, Manila',
      country: 'Philippines',
      distanceFromMetro: 'Metro Manila',
      bestMode: '🚗 Car / LRT',
      avgCostRange: '₱800–₱2,500',
      photoEmoji: '🏛️',
      tag: 'Cultural',
      description:
          'The historic 16th-century Spanish walled enclave. Fort Santiago, San Agustin Church (UNESCO), cobblestone streets, and bamboo bike tours.',
      isTrending: false,
      isWeekendGetaway: true,
      isRecommended: false,
      recommendedReason: 'Rich colonial history, museums, and romantic rooftop dinners right in the city.',
      bestTimeToVisit: 'Year-round',
      imageUrl: 'https://images.unsplash.com/photo-1518684079-3c830dcef090?auto=format&fit=crop&w=1200&q=80',
      latitude: 14.5896,
      longitude: 120.9747,
      tripType: 'sightseeing_tours',
    ),
    DestinationModel(
      id: 'dest-iloilo',
      name: 'Iloilo & Guimaras',
      country: 'Philippines',
      distanceFromMetro: '~470 km (1h flight from Manila)',
      bestMode: '✈️ Flight + Ferry',
      avgCostRange: '₱6,000–₱12,000',
      photoEmoji: '🥣',
      tag: 'Cultural',
      description:
          'City of Love known for heritage churches, authentic La Paz Batchoy, Molo Mansion, and a 15-minute boat ride to world-famous sweet mangoes.',
      isTrending: false,
      isWeekendGetaway: false,
      isRecommended: true,
      recommendedReason: 'Culinary capital UNESCO Creative City of Gastronomy with gentle charm.',
      bestTimeToVisit: 'Nov–May',
      imageUrl: 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=1200&q=80',
      latitude: 10.7202,
      longitude: 122.5621,
      tripType: 'food_crawl',
    ),
  ];
}
