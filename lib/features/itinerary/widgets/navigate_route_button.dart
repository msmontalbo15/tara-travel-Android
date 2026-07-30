import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/theme/app_colors.dart';

/// Builds and opens a Google Maps directions URL that routes from the
/// user's **current GPS position** through every [stops] waypoint in order,
/// ending at the last stop.
///
/// Only stops that have valid [ItineraryStop.lat] / [ItineraryStop.lng] are
/// included. If fewer than one stop has coordinates the button is disabled.
class NavigateRouteButton extends StatefulWidget {
  final List<ItineraryStop> stops;

  const NavigateRouteButton({super.key, required this.stops});

  @override
  State<NavigateRouteButton> createState() => _NavigateRouteButtonState();
}

class _NavigateRouteButtonState extends State<NavigateRouteButton> {
  bool _loading = false;

  List<ItineraryStop> get _stopsWithLocation =>
      widget.stops.where((s) => s.lat != null && s.lng != null).toList();

  /// Requests location permission if needed and returns the current position.
  /// Returns null and shows a snack if permission is denied.
  Future<Position?> _getCurrentPosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '📍 Location permission required to navigate.',
              style: TextStyle(fontFamily: 'DM Sans'),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  /// Builds the Google Maps directions deep-link URL.
  ///
  /// Format:
  ///   https://www.google.com/maps/dir/?api=1
  ///     &origin=<lat>,<lng>           ← current GPS
  ///     &destination=<lat>,<lng>      ← last stop
  ///     &waypoints=<lat>,<lng>|...    ← intermediate stops (up to 8)
  ///     &travelmode=driving
  String _buildMapsUrl(Position origin, List<ItineraryStop> stops) {
    final destination = stops.last;
    final waypoints = stops.length > 1 ? stops.sublist(0, stops.length - 1) : <ItineraryStop>[];

    final params = <String, String>{
      'api': '1',
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.lat},${destination.lng}',
      if (waypoints.isNotEmpty)
        'waypoints': waypoints.map((s) => '${s.lat},${s.lng}').join('|'),
      'travelmode': 'driving',
    };

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'https://www.google.com/maps/dir/?$query';
  }

  Future<void> _navigate() async {
    final stops = _stopsWithLocation;
    if (stops.isEmpty) return;

    setState(() => _loading = true);

    try {
      final position = await _getCurrentPosition();
      if (position == null) return;

      final url = _buildMapsUrl(position, stops);
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
    final stops = _stopsWithLocation;
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
              ? 'Getting location…'
              : canNavigate
                  ? 'Navigate Route in Google Maps  (${stops.length} stop${stops.length == 1 ? '' : 's'})'
                  : 'No stops with location',
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
