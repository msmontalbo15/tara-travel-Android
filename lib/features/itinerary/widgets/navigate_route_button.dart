import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/theme/app_colors.dart';

/// Builds and opens a Google Maps directions URL that routes from the
/// user's **current GPS position** through every [stops] waypoint in order,
/// ending at the last stop.
///
/// Uses both location strings and titles (along with lat/lng coordinates when present)
/// to build precise multi-stop Google Maps navigation.
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

  /// Formats a stop target for Google Maps (combines Title + Location string).
  static String _formatStopTarget(ItineraryStop s) {
    if (s.lat != null && s.lng != null && s.lat != 0.0 && s.lng != 0.0) {
      return '${s.lat},${s.lng}';
    }
    if (s.location != null && s.location!.trim().isNotEmpty) {
      if (s.title.trim().isNotEmpty &&
          !s.location!.toLowerCase().contains(s.title.toLowerCase())) {
        return '${s.title}, ${s.location!}';
      }
      return s.location!;
    }
    return s.title;
  }

  /// Builds the Google Maps directions deep-link URL.
  /// No `origin` is set — Google Maps defaults to the user's live GPS.
  ///
  /// Format:
  ///   https://www.google.com/maps/dir/?api=1
  ///     &destination=<lat>,<lng> or <encoded name>  ← last stop
  ///     &waypoints=<lat>,<lng>|...                  ← intermediate stops
  ///     &travelmode=driving
  String _buildMapsUrl(List<ItineraryStop> stops) {
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

  /// Builds Google Maps URL including optional origin (current location).
  String _buildMapsUrlWithOrigin(List<ItineraryStop> stops, Position? origin) {
    final baseUrl = _buildMapsUrl(stops);
    if (origin == null) return baseUrl;
    final uri = Uri.parse(baseUrl);
    final queryParams = Map<String, String>.from(uri.queryParameters);
    queryParams['origin'] = '${origin.latitude},${origin.longitude}';
    return uri.replace(queryParameters: queryParams).toString();
  }

  Future<void> _navigate() async {
    final stops = _navigableStops;
    if (stops.isEmpty) return;

    setState(() => _loading = true);

    Position? currentPosition;
    try {
      // Request location permission if not granted
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      }
    } catch (_) {
      // Ignore location errors; continue without origin
    }

    try {
      final url = _buildMapsUrlWithOrigin(stops, currentPosition);
      final uri = Uri.parse(url);

      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '❌ Could not open Google Maps. Make sure it is installed.',
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              ? 'Getting location…'
              : canNavigate
                  ? 'Navigate Route in Google Maps (${stops.length} stop${stops.length == 1 ? '' : 's'})'
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

/// Opens Google Maps in **turn-by-turn navigation mode** from the user's
/// current GPS position to the stop's location.
///
/// Priority:
///   1. `google.navigation:q=lat,lng&mode=d`  — native Android nav intent (exact coords)
///   2. `google.navigation:q=Title, Location&mode=d` — native Android nav intent (address)
///   3. `https://www.google.com/maps/dir/...`  — universal web fallback
Future<void> openGoogleMapsForStop(
    BuildContext context, ItineraryStop stop) async {
  // Build the human-readable destination label (used both as label + text fallback)
  String destinationLabel;
  if (stop.location != null && stop.location!.trim().isNotEmpty) {
    if (stop.title.trim().isNotEmpty &&
        !stop.location!.toLowerCase().contains(stop.title.toLowerCase())) {
      destinationLabel = '${stop.title}, ${stop.location!}';
    } else {
      destinationLabel = stop.location!;
    }
  } else {
    destinationLabel = stop.title;
  }

  final bool hasCoords = stop.lat != null &&
      stop.lng != null &&
      stop.lat != 0.0 &&
      stop.lng != 0.0;

  // ── 1. Try native Android navigation intent (opens directly in nav mode) ──
  final String navIntentQuery = hasCoords
      ? '${stop.lat},${stop.lng}'
      : Uri.encodeComponent(destinationLabel);

  final Uri navIntent = Uri.parse('google.navigation:q=$navIntentQuery&mode=d');

  bool launched = false;
  try {
    if (await canLaunchUrl(navIntent)) {
      launched =
          await launchUrl(navIntent, mode: LaunchMode.externalApplication);
    }
  } catch (_) {
    launched = false;
  }

  if (launched) return;

  // ── 2. Fallback: Google Maps directions URL (no origin = uses current GPS) ──
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
          content: Text('📍 Could not open Google Maps.'),
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
