import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/philippine_geocoding_service.dart';
import '../../theme/app_colors.dart';
import 'location_picker.dart';

class MapPinPickerModal extends StatefulWidget {
  final LatLng? initialPosition;
  final String? initialAddress;

  const MapPinPickerModal({
    super.key,
    this.initialPosition,
    this.initialAddress,
  });

  static Future<LocationResult?> show(
    BuildContext context, {
    LatLng? initialPosition,
    String? initialAddress,
  }) {
    return showModalBottomSheet<LocationResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => MapPinPickerModal(
        initialPosition: initialPosition,
        initialAddress: initialAddress,
      ),
    );
  }

  @override
  State<MapPinPickerModal> createState() => _MapPinPickerModalState();
}

class _MapPinPickerModalState extends State<MapPinPickerModal> {
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Default position: Manila, Philippines if none provided
  static const LatLng _defaultLocation = LatLng(14.5995, 120.9842);

  late LatLng _currentCenter;
  String _placeName = 'Move map to select location';
  String _fullAddress = '';
  bool _isGeocoding = false;
  bool _isLocatingUser = false;
  Timer? _debounceTimer;
  CancelToken? _geocodingCancelToken;

  List<LocationResult> _searchSuggestions = [];
  bool _isSearching = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _currentCenter = widget.initialPosition ?? _defaultLocation;
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _placeName = widget.initialAddress!;
    } else {
      _reverseGeocode(_currentCenter);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    _geocodingCancelToken?.cancel('Modal disposed');
    super.dispose();
  }

  // Reverse geocode lat/lng to human readable address with debounce & request cancellation
  Future<void> _reverseGeocode(LatLng target) async {
    // Cancel any previous in-flight geocoding request to prevent network lag & race conditions
    _geocodingCancelToken?.cancel('New pin position selected');
    _geocodingCancelToken = CancelToken();

    if (mounted) {
      setState(() => _isGeocoding = true);
    }

    try {
      final result = await PhilippineGeocodingService.instance.reverseGeocode(
        target.latitude,
        target.longitude,
        cancelToken: _geocodingCancelToken,
      );

      if (result != null && mounted) {
        final parts = result.displayName.split(',');
        final title = parts.isNotEmpty ? parts.first.trim() : result.displayName;
        final subtitle = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';

        setState(() {
          _placeName = title;
          _fullAddress = subtitle.isNotEmpty ? subtitle : result.displayName;
          _isGeocoding = false;
        });
        return;
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        return; // Ignore cancelled requests cleanly
      }
    }

    if (mounted) {
      setState(() {
        _placeName = '${target.latitude.toStringAsFixed(4)}, ${target.longitude.toStringAsFixed(4)}';
        _fullAddress = 'Pinned location on map';
        _isGeocoding = false;
      });
    }
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    _currentCenter = camera.center;

    // Completely delay address picking & state updates until map finishes dragging and remains stationary
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        _reverseGeocode(_currentCenter);
      }
    });
  }

  Future<void> _goToMyLocation() async {
    setState(() => _isLocatingUser = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        final target = LatLng(pos.latitude, pos.longitude);
        _currentCenter = target;
        _mapController.move(target, 15);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLocatingUser = false);
  }

  Future<void> _searchPlace(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await PhilippineGeocodingService.instance.search(
        query,
        limit: 5,
      );

      if (mounted) {
        setState(() {
          _searchSuggestions = results
              .map((r) => LocationResult.fromGeocodingResult(r))
              .toList();
          _showSuggestions = true;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _selectSearchSuggestion(LocationResult result) async {
    _searchFocusNode.unfocus();
    setState(() {
      _showSuggestions = false;
      _searchCtrl.text = result.displayName;
    });

    LatLng target = LatLng(result.lat, result.lon);

    if (target.latitude != 0.0 || target.longitude != 0.0) {
      _currentCenter = target;
      _mapController.move(target, 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayTitle = _fullAddress.isNotEmpty ? '$_placeName, $_fullAddress' : _placeName;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // ── 1. Flutter Map View ──────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 14,
              onPositionChanged: _onMapPositionChanged,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'ph.taratravel.app',
                maxZoom: 19,
              ),
            ],
          ),

          // ── 2. Fixed Center Pin Indicator ───────────────────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.deepEarth,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6),
                      ],
                    ),
                    child: Text(
                      _isGeocoding ? 'Locating...' : 'Set Pin Here',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.location_on_rounded,
                    size: 44,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),

          // ── 3. Search Bar Overlay ───────────────────────────────────────
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          focusNode: _searchFocusNode,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Search Philippine places...',
                            hintStyle: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                            border: InputBorder.none,
                          ),
                          onChanged: (val) {
                            _debounceTimer?.cancel();
                            _debounceTimer = Timer(
                              const Duration(milliseconds: 350),
                              () => _searchPlace(val),
                            );
                          },
                        ),
                      ),
                      if (_isSearching)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                        )
                      else if (_searchCtrl.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _showSuggestions = false);
                          },
                        ),
                    ],
                  ),
                ),

                // Search Predictions List
                if (_showSuggestions && _searchSuggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 12),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _searchSuggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.cardBorder),
                      itemBuilder: (context, index) {
                        final item = _searchSuggestions[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.place_rounded, color: AppColors.primary, size: 18),
                          title: Text(
                            item.displayName,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectSearchSuggestion(item),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // ── 4. My Location Floating Action Button ───────────────────────
          Positioned(
            right: 16,
            bottom: 140,
            child: FloatingActionButton.small(
              heroTag: 'flutter_map_pin_my_loc',
              onPressed: _goToMyLocation,
              backgroundColor: Colors.white,
              elevation: 4,
              child: _isLocatingUser
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 20),
            ),
          ),

          // ── 5. Bottom Location Confirmation Panel ───────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _placeName,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_fullAddress.isNotEmpty && _fullAddress != _placeName)
                              Text(
                                _fullAddress,
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Confirm Pin Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        final result = LocationResult(
                          displayName: displayTitle,
                          lat: _currentCenter.latitude,
                          lon: _currentCenter.longitude,
                        );
                        Navigator.of(context).pop(result);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Confirm Pin Location',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
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
