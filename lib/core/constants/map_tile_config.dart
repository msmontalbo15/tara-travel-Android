// map_tile_config.dart
// ─────────────────────────────────────────────────────────────────────────────
// Unified map tile provider supporting Mapbox, CartoDB Voyager, and OSM.
// Reads `MAPBOX_ACCESS_TOKEN` from `.env` with automatic fallback.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';

class MapTileConfig {
  MapTileConfig._();

  /// Mapbox access token loaded from environment variables
  static String get mapboxToken =>
      dotenv.env['MAPBOX_ACCESS_TOKEN']?.trim() ?? '';

  /// True if a valid Mapbox access token is configured
  static bool get hasMapbox =>
      mapboxToken.isNotEmpty && mapboxToken.startsWith('pk.');

  /// Generates the standard [TileLayer] for all map surfaces across Tara Travel.
  /// Uses Mapbox if [MAPBOX_ACCESS_TOKEN] is set, otherwise CartoDB Voyager.
  static TileLayer buildTileLayer({
    String style = 'mapbox/streets-v12', // streets-v12, outdoors-v12, navigation-day-v1, dark-v11
  }) {
    final token = mapboxToken;
    if (token.isNotEmpty && token.startsWith('pk.')) {
      return TileLayer(
        urlTemplate:
            'https://api.mapbox.com/styles/v1/$style/tiles/256/{z}/{x}/{y}@2x?access_token=$token',
        userAgentPackageName: 'ph.taratravel.app',
        maxZoom: 20,
        additionalOptions: {
          'accessToken': token,
        },
      );
    }

    // Default CartoDB Voyager / OpenStreetMap tile layer (no key required)
    return TileLayer(
      urlTemplate:
          'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
      subdomains: const ['a', 'b', 'c', 'd'],
      userAgentPackageName: 'ph.taratravel.app',
      maxZoom: 19,
    );
  }
}
