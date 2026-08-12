import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
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
  MapLibreMapController? _mapController;
  final Dio _dio = Dio();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Default position: Manila, Philippines if none provided
  static const LatLng _defaultLocation = LatLng(14.5995, 120.9842);

  // High quality open vector tile styles (OpenFreeMap / MapLibre)
  static const String _mapStyle = 'https://tiles.openfreemap.org/styles/liberty';

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

    final apiKey = dotenv.env['EXPO_PUBLIC_GOOGLE_MAPS_API_KEY'] ??
        dotenv.env['GOOGLE_MAPS_API_KEY'];

    try {
      if (apiKey != null && apiKey.isNotEmpty) {
        final url =
            'https://maps.googleapis.com/maps/api/geocode/json?latlng=${target.latitude},${target.longitude}&key=$apiKey';
        final response = await _dio.get(url, cancelToken: _geocodingCancelToken);
        if (response.statusCode == 200 && response.data['status'] == 'OK') {
          final results = response.data['results'] as List;
          if (results.isNotEmpty) {
            final first = results.first;
            final formatted = first['formatted_address'] as String? ?? '';
            final parts = formatted.split(',');
            final title = parts.isNotEmpty ? parts.first.trim() : formatted;
            final subtitle = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';

            if (mounted) {
              setState(() {
                _placeName = title;
                _fullAddress = subtitle.isNotEmpty ? subtitle : formatted;
                _isGeocoding = false;
              });
            }
            return;
          }
        }
      }

      // Fallback: Nominatim OpenStreetMap reverse geocoding
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': target.latitude,
          'lon': target.longitude,
          'format': 'json',
        },
        options: Options(headers: {'User-Agent': 'TaraTravelApp/1.0'}),
        cancelToken: _geocodingCancelToken,
      );

      if (response.statusCode == 200) {
        final displayName = response.data['display_name'] as String? ?? '';
        final parts = displayName.split(',');
        final title = parts.isNotEmpty ? parts.first.trim() : 'Selected Location';
        final subtitle = parts.length > 1 ? parts.sublist(1).join(',').trim() : displayName;

        if (mounted) {
          setState(() {
            _placeName = title;
            _fullAddress = subtitle;
            _isGeocoding = false;
          });
        }
      }
    } catch (e) {
      if (DioException.connectionError == e || (e is DioException && CancelToken.isCancel(e))) {
        return; // Ignore cancelled requests cleanly
      }
      if (mounted) {
        setState(() {
          _placeName = '${target.latitude.toStringAsFixed(4)}, ${target.longitude.toStringAsFixed(4)}';
          _fullAddress = 'Pinned location on map';
          _isGeocoding = false;
        });
      }
    }
  }

  void _onCameraIdle() {
    final target = _mapController?.cameraPosition?.target;
    if (target != null) {
      _currentCenter = target;
    }
    
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
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 15));
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
    final apiKey = dotenv.env['EXPO_PUBLIC_GOOGLE_MAPS_API_KEY'] ??
        dotenv.env['GOOGLE_MAPS_API_KEY'];

    try {
      if (apiKey != null && apiKey.isNotEmpty) {
        final url =
            'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(query)}&components=country:ph&key=$apiKey';
        final response = await _dio.get(url);
        if (response.statusCode == 200 && response.data['status'] == 'OK') {
          final predictions = (response.data['predictions'] as List)
              .take(5)
              .map((p) => LocationResult.fromJson(p))
              .toList();

          if (mounted) {
            setState(() {
              _searchSuggestions = predictions;
              _showSuggestions = true;
              _isSearching = false;
            });
          }
          return;
        }
      }

      // Nominatim search fallback (Philippines restricted)
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 5,
          'countrycodes': 'ph',
        },
        options: Options(headers: {'User-Agent': 'TaraTravelApp/1.0'}),
      );

      if (response.statusCode == 200) {
        final list = (response.data as List)
            .map((item) => LocationResult.fromJson(item))
            .toList();
        if (mounted) {
          setState(() {
            _searchSuggestions = list;
            _showSuggestions = true;
            _isSearching = false;
          });
        }
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

    if (result.lat == 0.0 && result.lon == 0.0 && result.placeId != null) {
      final apiKey = dotenv.env['EXPO_PUBLIC_GOOGLE_MAPS_API_KEY'] ??
          dotenv.env['GOOGLE_MAPS_API_KEY'];
      if (apiKey != null && apiKey.isNotEmpty) {
        try {
          final url =
              'https://maps.googleapis.com/maps/api/place/details/json?place_id=${result.placeId}&fields=geometry&key=$apiKey';
          final res = await _dio.get(url);
          if (res.statusCode == 200 && res.data['status'] == 'OK') {
            final loc = res.data['result']['geometry']['location'];
            target = LatLng(
              (loc['lat'] as num).toDouble(),
              (loc['lng'] as num).toDouble(),
            );
          }
        } catch (_) {}
      }
    }

    if (target.latitude != 0.0 || target.longitude != 0.0) {
      _currentCenter = target;
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 15));
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
          // ── 1. MapLibre Map View ─────────────────────────────────────────
          MapLibreMap(
            initialCameraPosition: CameraPosition(
              target: _currentCenter,
              zoom: 14,
            ),
            styleString: _mapStyle,
            onMapCreated: (controller) => _mapController = controller,
            onCameraIdle: _onCameraIdle,
            trackCameraPosition: true,
            myLocationEnabled: true,
            myLocationRenderMode: MyLocationRenderMode.normal,
            compassEnabled: true,
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
                            hintText: 'Search place or city on MapLibre map...',
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
              heroTag: 'maplibre_pin_my_loc',
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
