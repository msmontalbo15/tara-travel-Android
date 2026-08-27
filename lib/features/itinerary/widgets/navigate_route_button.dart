import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/theme/app_colors.dart';

/// Builds and opens a turn-by-turn navigation route from the user's
/// **current GPS position** through every waypoint in order,
/// ending at the final destination.
///
/// Supports multi-stop directions on Google Maps, remaining stops filtering,
/// automatic transport mode resolution, GPS coordinate origin pre-fill,
/// and an interactive route preview sheet.
class NavigateRouteButton extends StatefulWidget {
  final List<ItineraryStop> stops;
  final TransportDetail? transport;
  final int? dayNumber;

  const NavigateRouteButton({
    super.key,
    required this.stops,
    this.transport,
    this.dayNumber,
  });

  @override
  State<NavigateRouteButton> createState() => _NavigateRouteButtonState();
}

class _NavigateRouteButtonState extends State<NavigateRouteButton> {
  bool _loading = false;

  /// Returns stops that have location, title, or coordinates for navigation.
  static List<ItineraryStop> getNavigableStops(List<ItineraryStop> stops) =>
      stops
          .where((s) =>
              (s.lat != null && s.lng != null && s.lat != 0.0 && s.lng != 0.0) ||
              (s.location != null && s.location!.trim().isNotEmpty) ||
              s.title.trim().isNotEmpty)
          .toList();

  /// Returns uncompleted stops for remaining-route navigation.
  static List<ItineraryStop> getRemainingNavigableStops(
          List<ItineraryStop> stops) =>
      getNavigableStops(stops).where((s) => !s.isCompleted).toList();

  /// Formats a stop target (uses Lat/Lng coordinates or combined Title + Location).
  static String formatStopTarget(ItineraryStop s) {
    if (s.lat != null && s.lng != null && s.lat != 0.0 && s.lng != 0.0) {
      return '${s.lat},${s.lng}';
    }
    final loc = s.location?.trim() ?? '';
    final title = s.title.trim();
    if (title.isNotEmpty && loc.isNotEmpty) {
      if (loc.toLowerCase().contains(title.toLowerCase())) {
        return loc;
      }
      return '$title, $loc';
    }
    if (loc.isNotEmpty) return loc;
    return title;
  }

  /// Maps [TransportMode] to Google Maps `travelmode` parameter.
  static String mapTransportMode(TransportMode? mode) {
    if (mode == null) return 'driving';
    switch (mode) {
      case TransportMode.car:
      case TransportMode.vanHire:
      case TransportMode.other:
        return 'driving';
      case TransportMode.motorcycle:
      case TransportMode.tricycle:
        return 'two-wheeler';
      case TransportMode.bike:
        return 'bicycling';
      case TransportMode.commute:
      case TransportMode.bus:
      case TransportMode.jeepney:
      case TransportMode.ferry:
      case TransportMode.plane:
        return 'transit';
    }
  }

  /// Builds a universal Google Maps directions navigation URL with all waypoints in order.
  static String buildDirectionsUrl({
    required List<ItineraryStop> stops,
    String? origin,
    String travelMode = 'driving',
  }) {
    if (stops.isEmpty) return '';
    final destination = stops.last;
    final waypoints = stops.length > 1
        ? stops.sublist(0, stops.length - 1)
        : <ItineraryStop>[];

    final destString = formatStopTarget(destination);
    final waypointsString = waypoints.map(formatStopTarget).join('|');

    final params = <String, String>{
      'api': '1',
      'destination': destString,
      if (origin != null && origin.trim().isNotEmpty) 'origin': origin.trim(),
      if (waypointsString.isNotEmpty) 'waypoints': waypointsString,
      'travelmode': travelMode,
    };

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'https://www.google.com/maps/dir/?$query';
  }

  /// Obtains current GPS coordinates if allowed, with a fast 2-second timeout.
  static Future<String?> _resolveCurrentLocationOrigin() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 2),
          ),
        );
        return '${pos.latitude},${pos.longitude}';
      }
    } catch (_) {}
    return null;
  }

  /// Launches the multi-stop route directions URL.
  static Future<bool> launchDirectionsUrl({
    required BuildContext context,
    required List<ItineraryStop> stops,
    String? origin,
    String travelMode = 'driving',
  }) async {
    if (stops.isEmpty) return false;
    final url = buildDirectionsUrl(
      stops: stops,
      origin: origin,
      travelMode: travelMode,
    );
    final uri = Uri.parse(url);
    bool launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        launched = await launchUrl(uri);
      } catch (_) {}
    }

    if (!launched && context.mounted) {
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
    return launched;
  }

  Future<void> _quickNavigate() async {
    final allNavigable = getNavigableStops(widget.stops);
    if (allNavigable.isEmpty) return;

    // Prefer remaining uncompleted stops if some are completed
    final remaining = getRemainingNavigableStops(widget.stops);
    final targetStops = remaining.isNotEmpty ? remaining : allNavigable;

    setState(() => _loading = true);

    try {
      final origin = await _resolveCurrentLocationOrigin();
      final mode = mapTransportMode(widget.transport?.mode);

      if (mounted) {
        await launchDirectionsUrl(
          context: context,
          stops: targetStops,
          origin: origin,
          travelMode: mode,
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

  void _openRouteOptionsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RouteOptionsSheet(
        stops: widget.stops,
        transport: widget.transport,
        dayNumber: widget.dayNumber,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allNavigable = getNavigableStops(widget.stops);
    final remaining = getRemainingNavigableStops(widget.stops);
    final canNavigate = allNavigable.isNotEmpty;

    final int displayCount = remaining.isNotEmpty ? remaining.length : allNavigable.length;
    final bool hasFilteredRemaining =
        remaining.isNotEmpty && remaining.length < allNavigable.length;

    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: canNavigate && !_loading ? _quickNavigate : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.directions_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _loading
                            ? 'Opening live navigation…'
                            : canNavigate
                                ? 'Start Route Navigation ($displayCount stop${displayCount == 1 ? '' : 's'})'
                                : 'No stops to navigate',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (canNavigate && !_loading)
                        Text(
                          hasFilteredRemaining
                              ? 'Next $displayCount remaining stops · Tap to launch'
                              : 'All $displayCount stops · Full day route',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 10.5,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (canNavigate && !_loading) ...[
                  Container(
                    height: 24,
                    width: 1,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 19),
                    tooltip: 'Route options & preview',
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    splashRadius: 18,
                    onPressed: _openRouteOptionsSheet,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Interactive modal sheet to preview waypoints, customize travel mode,
/// and launch or copy the multi-stop Google Maps navigation route.
class _RouteOptionsSheet extends StatefulWidget {
  final List<ItineraryStop> stops;
  final TransportDetail? transport;
  final int? dayNumber;

  const _RouteOptionsSheet({
    required this.stops,
    this.transport,
    this.dayNumber,
  });

  @override
  State<_RouteOptionsSheet> createState() => _RouteOptionsSheetState();
}

class _RouteOptionsSheetState extends State<_RouteOptionsSheet> {
  late bool _remainingOnly;
  late String _travelMode;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final remaining = _NavigateRouteButtonState.getRemainingNavigableStops(widget.stops);
    final all = _NavigateRouteButtonState.getNavigableStops(widget.stops);
    _remainingOnly = remaining.isNotEmpty && remaining.length < all.length;
    _travelMode = _NavigateRouteButtonState.mapTransportMode(widget.transport?.mode);
  }

  List<ItineraryStop> get _activeStops {
    final all = _NavigateRouteButtonState.getNavigableStops(widget.stops);
    if (!_remainingOnly) return all;
    final remaining = _NavigateRouteButtonState.getRemainingNavigableStops(widget.stops);
    return remaining.isNotEmpty ? remaining : all;
  }

  Future<void> _launch() async {
    final stops = _activeStops;
    if (stops.isEmpty) return;

    setState(() => _loading = true);
    try {
      final origin = await _NavigateRouteButtonState._resolveCurrentLocationOrigin();
      if (mounted) {
        Navigator.pop(context);
        await _NavigateRouteButtonState.launchDirectionsUrl(
          context: context,
          stops: stops,
          origin: origin,
          travelMode: _travelMode,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _copyLink() {
    final stops = _activeStops;
    if (stops.isEmpty) return;
    final url = _NavigateRouteButtonState.buildDirectionsUrl(
      stops: stops,
      travelMode: _travelMode,
    );
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Route link copied to clipboard!', style: TextStyle(fontFamily: 'DM Sans')),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeStops = _activeStops;
    final allNavigable = _NavigateRouteButtonState.getNavigableStops(widget.stops);
    final remainingNavigable = _NavigateRouteButtonState.getRemainingNavigableStops(widget.stops);
    final hasCompleted = remainingNavigable.length < allNavigable.length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.warmMuted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.route_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.dayNumber != null
                              ? 'Day ${widget.dayNumber} Route Navigation'
                              : 'Multi-Stop Route Navigation',
                          style: const TextStyle(
                            fontFamily: 'Playfair Display',
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: AppColors.deepEarth,
                          ),
                        ),
                        Text(
                          '${activeStops.length} stops in sequence · Turn-by-turn',
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.dividerLight),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                children: [
                  // Scope selector (Remaining vs All)
                  if (hasCompleted) ...[
                    const Text(
                      'ROUTE SCOPE',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.warmMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _ScopeChoiceChip(
                            label: 'Remaining (${remainingNavigable.length})',
                            isSelected: _remainingOnly,
                            onTap: () => setState(() => _remainingOnly = true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ScopeChoiceChip(
                            label: 'All Stops (${allNavigable.length})',
                            isSelected: !_remainingOnly,
                            onTap: () => setState(() => _remainingOnly = false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Travel mode selector
                  const Text(
                    'TRAVEL MODE',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.warmMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _TravelModeChip(
                          label: 'Driving',
                          icon: Icons.directions_car_rounded,
                          modeKey: 'driving',
                          selectedKey: _travelMode,
                          onSelected: (m) => setState(() => _travelMode = m),
                        ),
                        const SizedBox(width: 8),
                        _TravelModeChip(
                          label: 'Motorcycle',
                          icon: Icons.two_wheeler_rounded,
                          modeKey: 'two-wheeler',
                          selectedKey: _travelMode,
                          onSelected: (m) => setState(() => _travelMode = m),
                        ),
                        const SizedBox(width: 8),
                        _TravelModeChip(
                          label: 'Walking',
                          icon: Icons.directions_walk_rounded,
                          modeKey: 'walking',
                          selectedKey: _travelMode,
                          onSelected: (m) => setState(() => _travelMode = m),
                        ),
                        const SizedBox(width: 8),
                        _TravelModeChip(
                          label: 'Transit',
                          icon: Icons.directions_bus_rounded,
                          modeKey: 'transit',
                          selectedKey: _travelMode,
                          onSelected: (m) => setState(() => _travelMode = m),
                        ),
                        const SizedBox(width: 8),
                        _TravelModeChip(
                          label: 'Cycling',
                          icon: Icons.directions_bike_rounded,
                          modeKey: 'bicycling',
                          selectedKey: _travelMode,
                          onSelected: (m) => setState(() => _travelMode = m),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Waypoints Timeline Preview
                  const Text(
                    'WAYPOINTS ORDER',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.warmMuted,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Origin node
                  const _TimelineNode(
                    icon: Icons.my_location_rounded,
                    iconColor: AppColors.greenBright,
                    title: 'Current Location',
                    subtitle: 'Device GPS origin',
                    isFirst: true,
                    isLast: false,
                  ),

                  // Stops nodes
                  for (int i = 0; i < activeStops.length; i++) ...[
                    _TimelineNode(
                      icon: i == activeStops.length - 1
                          ? Icons.flag_rounded
                          : Icons.place_rounded,
                      iconColor: i == activeStops.length - 1
                          ? AppColors.primary
                          : AppColors.amber,
                      badgeText: i == activeStops.length - 1 ? 'Destination' : 'Stop ${i + 1}',
                      title: activeStops[i].title,
                      subtitle: activeStops[i].location ?? 'Exact GPS destination',
                      isFirst: false,
                      isLast: i == activeStops.length - 1,
                    ),
                  ],
                ],
              ),
            ),

            // Bottom action buttons
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _copyLink,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.deepEarth,
                      side: const BorderSide(color: AppColors.cardBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text(
                      'Copy Link',
                      style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: activeStops.isNotEmpty && !_loading ? _launch : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.map_rounded, size: 20),
                      label: Text(
                        _loading ? 'Opening Maps…' : 'Open in Google Maps',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScopeChoiceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScopeChoiceChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.deepEarth : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.deepEarth : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _TravelModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String modeKey;
  final String selectedKey;
  final ValueChanged<String> onSelected;

  const _TravelModeChip({
    required this.label,
    required this.icon,
    required this.modeKey,
    required this.selectedKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = modeKey == selectedKey;
    return GestureDetector(
      onTap: () => onSelected(modeKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.sand : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.darkAccent : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineNode extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badgeText;
  final bool isFirst;
  final bool isLast;

  const _TimelineNode({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badgeText,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: iconColor, width: 1.5),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: AppColors.cardBorder,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badgeText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isLast
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : AppColors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText!,
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isLast ? AppColors.primary : AppColors.amberText,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens turn-by-turn navigation mode for a specific single stop.
Future<void> openGoogleMapsForStop(
    BuildContext context, ItineraryStop stop) async {
  final String destination = _NavigateRouteButtonState.formatStopTarget(stop);

  // 1. Universal Google Maps directions URL
  final Uri webUrl = Uri.parse(
    'https://www.google.com/maps/dir/?api=1'
    '&destination=${Uri.encodeComponent(destination)}'
    '&travelmode=driving',
  );

  bool launched = false;
  try {
    launched = await launchUrl(webUrl, mode: LaunchMode.externalApplication);
  } catch (_) {
    try {
      launched = await launchUrl(webUrl);
    } catch (_) {}
  }

  // 2. Native Android navigation intent fallback if coordinates exist
  if (!launched && stop.lat != null && stop.lng != null && stop.lat != 0.0) {
    final Uri navIntent = Uri.parse('google.navigation:q=${stop.lat},${stop.lng}&mode=d');
    try {
      if (await canLaunchUrl(navIntent)) {
        launched = await launchUrl(navIntent, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '📍 Could not open map navigation application.',
          style: TextStyle(fontFamily: 'DM Sans'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
