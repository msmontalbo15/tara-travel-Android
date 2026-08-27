import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/theme/app_colors.dart';

/// Builds and opens a turn-by-turn navigation route from the user's
/// **current GPS position** through every [stops] waypoint in order,
/// ending at the final destination.
///
/// Uses standard Geo intents and OpenStreetMap / universal navigation URLs.
class NavigateRouteButton extends StatefulWidget {
  final List<ItineraryStop> stops;

  const NavigateRouteButton({super.key, required this.stops});

  @override
  State<NavigateRouteButton> createState() => _NavigateRouteButtonState();
}

class _NavigateRouteButtonState extends State<NavigateRouteButton> {
  bool _loading = false;

  /// Returns stops that have location, title, or coordinates for navigation.
  List<ItineraryStop> get _navigableStops => widget.stops
      .where((s) =>
          (s.lat != null && s.lng != null && s.lat != 0.0 && s.lng != 0.0) ||
          (s.location != null && s.location!.trim().isNotEmpty) ||
          s.title.trim().isNotEmpty)
      .toList();

  /// Formats a stop target (uses Lat/Lng coordinates or Location string).
  static String _formatStopTarget(ItineraryStop s) {
    if (s.lat != null && s.lng != null && s.lat != 0.0 && s.lng != 0.0) {
      return '${s.lat},${s.lng}';
    }
    if (s.location != null && s.location!.trim().isNotEmpty) {
      return s.location!.trim();
    }
    return s.title.trim();
  }

  /// Builds a universal directions navigation URL.
  String _buildDirectionsUrl(List<ItineraryStop> stops) {
    final destination = stops.last;
    final waypoints = stops.length > 1
        ? stops.sublist(0, stops.length - 1)
        : <ItineraryStop>[];

    final destString = _formatStopTarget(destination);
    final waypointsString = waypoints.map(_formatStopTarget).join('|');

    final params = <String, String>{
      'api': '1',
      'destination': destString,
      if (waypointsString.isNotEmpty) 'waypoints': waypointsString,
      'travelmode': 'driving',
    };

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'https://www.google.com/maps/dir/?$query';
  }

  Future<void> _navigate() async {
    final stops = _navigableStops;
    if (stops.isEmpty) return;

    setState(() => _loading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
    } catch (_) {}

    try {
      final url = _buildDirectionsUrl(stops);
      final uri = Uri.parse(url);
      bool launched = false;
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        try {
          launched = await launchUrl(uri);
        } catch (_) {}
      }

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '📍 Could not launch map navigation application.',
              style: TextStyle(fontFamily: 'DM Sans'),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: const TextStyle(fontFamily: 'DM Sans')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stops = _navigableStops;
    final canNavigate = stops.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: canNavigate && !_loading ? _navigate : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.35),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.directions_rounded, size: 20),
        label: Text(
          _loading
              ? 'Opening live navigation…'
              : canNavigate
                  ? 'Start Route Navigation (${stops.length} stop${stops.length == 1 ? '' : 's'})'
                  : 'No stops to navigate',
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Opens turn-by-turn navigation mode for a specific single stop.
Future<void> openGoogleMapsForStop(
    BuildContext context, ItineraryStop stop) async {
  final String destinationLabel = (stop.location != null && stop.location!.trim().isNotEmpty)
      ? stop.location!.trim()
      : stop.title.trim();

  final bool hasCoords = stop.lat != null &&
      stop.lng != null &&
      stop.lat != 0.0 &&
      stop.lng != 0.0;

  bool launched = false;

  // 1. Try standard geo navigation intent
  if (hasCoords) {
    final geoUri = Uri.parse('geo:${stop.lat},${stop.lng}?q=${stop.lat},${stop.lng}(${Uri.encodeComponent(destinationLabel)})');
    try {
      if (await canLaunchUrl(geoUri)) {
        launched = await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  if (launched) return;

  // 2. Try native Android navigation intent
  final String navIntentQuery = hasCoords
      ? '${stop.lat},${stop.lng}'
      : Uri.encodeComponent(destinationLabel);

  final Uri navIntent = Uri.parse('google.navigation:q=$navIntentQuery&mode=d');
  try {
    if (await canLaunchUrl(navIntent)) {
      launched = await launchUrl(navIntent, mode: LaunchMode.externalApplication);
    }
  } catch (_) {}

  if (launched) return;

  // 3. Fallback: Universal directions web URL
  final String destination = hasCoords
      ? '${stop.lat},${stop.lng}'
      : Uri.encodeComponent(destinationLabel);

  final Uri webUrl = Uri.parse(
    'https://www.google.com/maps/dir/?api=1'
    '&destination=$destination'
    '&travelmode=driving',
  );

  try {
    launched = await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📍 Could not open map navigation application.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening maps: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
