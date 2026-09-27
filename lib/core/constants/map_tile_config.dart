import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import '../theme/app_colors.dart';

/// Disk-persistent tile provider using [CachedNetworkImageProvider].
///
/// Tiles fetched from Mapbox or CartoDB are automatically cached to disk,
/// allowing Day Map and Live Map navigation surfaces to render previously
/// viewed regions even when offline or in low-connectivity rural zones.
class CachedTileProvider extends TileProvider {
  CachedTileProvider({super.headers});

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    return CachedNetworkImageProvider(
      url,
      headers: headers,
    );
  }
}

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
  /// Disk-backed tile caching is enabled by default via [CachedTileProvider].
  static TileLayer buildTileLayer({
    String style = 'mapbox/streets-v12', // streets-v12, outdoors-v12, navigation-day-v1, dark-v11
    bool enableCache = true,
  }) {
    final token = mapboxToken;
    final tileProvider = enableCache ? CachedTileProvider() : null;

    if (token.isNotEmpty && token.startsWith('pk.')) {
      return TileLayer(
        urlTemplate:
            'https://api.mapbox.com/styles/v1/$style/tiles/256/{z}/{x}/{y}@2x?access_token=$token',
        userAgentPackageName: 'ph.taratravel.app',
        maxZoom: 20,
        tileProvider: tileProvider,
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
      tileProvider: tileProvider,
    );
  }

  /// Compact offline tile cache status badge for overlaying on map surfaces.
  static Widget buildOfflineCacheBadge({
    required bool isOffline,
    String? lastCachedLabel,
  }) {
    if (!isOffline) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xE61E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 13,
            color: Color(0xFFFBBF24),
          ),
          const SizedBox(width: 6),
          Text(
            lastCachedLabel != null
                ? 'Offline Map • $lastCachedLabel'
                : 'Offline Map • Cached',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
