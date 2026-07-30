import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/models/itinerary_model.dart';

class ItineraryMap extends StatefulWidget {
  final ItineraryDay day;

  const ItineraryMap({super.key, required this.day});

  @override
  State<ItineraryMap> createState() => _ItineraryMapState();
}

class _ItineraryMapState extends State<ItineraryMap> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _buildMapData();
  }

  @override
  void didUpdateWidget(covariant ItineraryMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.day != oldWidget.day) {
      _buildMapData();
    }
  }

  void _buildMapData() {
    _markers.clear();
    _polylines.clear();

    final stopsWithLocation = widget.day.stops.where((s) => s.lat != null && s.lng != null).toList();
    if (stopsWithLocation.isEmpty) return;

    List<LatLng> routePoints = [];

    for (int i = 0; i < stopsWithLocation.length; i++) {
      final stop = stopsWithLocation[i];
      final pos = LatLng(stop.lat!, stop.lng!);
      routePoints.add(pos);

      _markers.add(
        Marker(
          markerId: MarkerId(stop.id),
          position: pos,
          infoWindow: InfoWindow(title: stop.title, snippet: stop.location),
          // We can't easily do custom widget markers in google_maps_flutter without a lot of bitmap generation,
          // so we use the default marker with different hues based on type.
          icon: BitmapDescriptor.defaultMarkerWithHue(_getHue(stop.type)),
        ),
      );
    }

    if (routePoints.length > 1) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: routePoints,
          color: Colors.blueAccent,
          width: 4,
          patterns: [PatternItem.dash(10), PatternItem.gap(10)],
        ),
      );
    }

    if (_mapController != null && routePoints.isNotEmpty) {
      _fitMapToPoints(routePoints);
    }
  }

  double _getHue(StopType type) {
    switch (type) {
      case StopType.transport:
        return BitmapDescriptor.hueAzure;
      case StopType.hotel:
        return BitmapDescriptor.hueViolet;
      case StopType.food:
        return BitmapDescriptor.hueOrange;
      case StopType.activity:
        return BitmapDescriptor.hueRose;
      case StopType.custom:
        return BitmapDescriptor.hueRed;
    }
  }

  void _fitMapToPoints(List<LatLng> points) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(points.first, 14));
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        40.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stopsWithLocation = widget.day.stops.where((s) => s.lat != null && s.lng != null).toList();

    if (stopsWithLocation.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_rounded, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            Text(
              '${widget.day.stops.length} stops for Day ${widget.day.dayNumber}',
              style: const TextStyle(fontFamily: 'Playfair Display', fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Route map loads when location data is available.\nEdit stops to add locations.',
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: Colors.white54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final initialPos = LatLng(stopsWithLocation.first.lat!, stopsWithLocation.first.lng!);

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialPos,
        zoom: 12,
      ),
      markers: _markers,
      polylines: _polylines,
      onMapCreated: (ctrl) {
        _mapController = ctrl;
        _fitMapToPoints(stopsWithLocation.map((s) => LatLng(s.lat!, s.lng!)).toList());
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
    );
  }
}
