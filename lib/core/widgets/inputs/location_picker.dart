import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import '../../theme/app_colors.dart';

class LocationResult {
  final String displayName;
  final String? placeId;
  final String? mainText;
  final String? secondaryText;
  final double lat;
  final double lon;

  LocationResult({
    required this.displayName,
    this.placeId,
    this.mainText,
    this.secondaryText,
    required this.lat,
    required this.lon,
  });

  factory LocationResult.fromJson(Map<String, dynamic> json) {
    String name = json['display_name'] ?? json['description'] ?? json['formatted_address'] ?? '';
    String? main = json['structured_formatting']?['main_text'] as String?;
    String? secondary = json['structured_formatting']?['secondary_text'] as String?;

    if (main == null && name.isNotEmpty) {
      final parts = name.split(',');
      main = parts.first.trim();
      if (parts.length > 1) {
        secondary = parts.sublist(1).join(',').trim();
      }
    }

    double parsedLat = 0.0;
    double parsedLon = 0.0;

    if (json['geometry']?['location'] != null) {
      parsedLat = (json['geometry']['location']['lat'] as num?)?.toDouble() ?? 0.0;
      parsedLon = (json['geometry']['location']['lng'] as num?)?.toDouble() ?? 0.0;
    } else if (json['lat'] != null && json['lon'] != null) {
      parsedLat = double.tryParse(json['lat'].toString()) ?? 0.0;
      parsedLon = double.tryParse(json['lon'].toString()) ?? 0.0;
    }

    return LocationResult(
      displayName: name,
      placeId: json['place_id']?.toString(),
      mainText: main,
      secondaryText: secondary,
      lat: parsedLat,
      lon: parsedLon,
    );
  }
}

class LocationPicker extends StatefulWidget {
  final String label;
  final String? hint;
  final String? initialValue;
  final ValueChanged<LocationResult?> onLocationSelected;

  const LocationPicker({
    super.key,
    this.label = 'Location',
    this.hint = 'Search Google Maps places...',
    this.initialValue,
    required this.onLocationSelected,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Dio _dio = Dio();
  Timer? _debounce;
  
  List<LocationResult> _results = [];
  bool _isLoading = false;
  bool _showDropdown = false;
  LocationResult? _selectedLocation;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      _searchCtrl.text = widget.initialValue!;
    }
    _searchCtrl.addListener(_onSearchChanged);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Delay hiding dropdown so tap on list item registers
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _showDropdown = false);
        });
      } else {
        if (_searchCtrl.text.isNotEmpty) {
          setState(() => _showDropdown = true);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_selectedLocation != null && _searchCtrl.text == _selectedLocation!.displayName) {
      return;
    }
    
    if (_searchCtrl.text.isEmpty) {
      _selectedLocation = null;
      widget.onLocationSelected(null);
      setState(() {
        _results = [];
        _showDropdown = false;
      });
      return;
    }

    // Provide custom typed text fallback
    widget.onLocationSelected(LocationResult(
      displayName: _searchCtrl.text.trim(),
      lat: _selectedLocation?.lat ?? 0.0,
      lon: _selectedLocation?.lon ?? 0.0,
    ));

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchLocation(_searchCtrl.text);
    });
  }

  Future<void> _searchLocation(String query) async {
    setState(() {
      _isLoading = true;
      _showDropdown = true;
    });

    final apiKey = dotenv.env['EXPO_PUBLIC_GOOGLE_MAPS_API_KEY'] ??
        dotenv.env['GOOGLE_MAPS_API_KEY'];

    try {
      if (apiKey != null && apiKey.isNotEmpty) {
        // ── 1. Official Google Places Autocomplete API (Philippines restricted) ────────────────────
        final url =
            'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(query)}&components=country:ph&key=$apiKey';
        final response = await _dio.get(url);
        if (response.statusCode == 200 && response.data['status'] == 'OK') {
          final List predictions = response.data['predictions'] ?? [];
          final results = <LocationResult>[];

          for (final p in predictions.take(5)) {
            results.add(LocationResult.fromJson(p));
          }

          if (mounted) {
            setState(() {
              _results = results;
            });
          }
          return;
        }
      }

      // ── 2. Fallback Nominatim Search (Philippines restricted) ───────
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 6,
          'addressdetails': 1,
          'countrycodes': 'ph',
        },
        options: Options(
          headers: {
            'User-Agent': 'TaraTravelApp/1.0',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List data = response.data;
        if (mounted) {
          setState(() {
            _results = data.map((json) => LocationResult.fromJson(json)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('[LocationPicker] Google Maps search error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectLocation(LocationResult location) async {
    final apiKey = dotenv.env['EXPO_PUBLIC_GOOGLE_MAPS_API_KEY'] ??
        dotenv.env['GOOGLE_MAPS_API_KEY'];

    LocationResult finalLoc = location;

    // Fetch exact lat/lng via Google Place Details if place_id exists and coordinates are zero
    if (apiKey != null &&
        apiKey.isNotEmpty &&
        location.placeId != null &&
        (location.lat == 0.0 || location.lon == 0.0)) {
      try {
        final detailsUrl =
            'https://maps.googleapis.com/maps/api/place/details/json?place_id=${location.placeId}&fields=geometry,name,formatted_address&key=$apiKey';
        final res = await _dio.get(detailsUrl);
        if (res.statusCode == 200 && res.data['status'] == 'OK') {
          final result = res.data['result'];
          finalLoc = LocationResult.fromJson(result);
        }
      } catch (e) {
        debugPrint('[LocationPicker] Place details error: $e');
      }
    }

    setState(() {
      _selectedLocation = finalLoc;
      _searchCtrl.text = finalLoc.displayName;
      _showDropdown = false;
    });
    _focusNode.unfocus();
    widget.onLocationSelected(finalLoc);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.deepEarth,
          ),
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            TextFormField(
              controller: _searchCtrl,
              focusNode: _focusNode,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(
                  color: AppColors.warmMuted.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.place_outlined, size: 20, color: Color(0xFFEA4335)),
                suffixIcon: _isLoading 
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                      )
                    : (_searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20, color: AppColors.muted),
                            onPressed: () {
                              _searchCtrl.clear();
                              _selectedLocation = null;
                              widget.onLocationSelected(null);
                            },
                          )
                        : null),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cardBorder, width: 0.8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            
            // Google Maps Recommended Places Dropdown
            if (_showDropdown && (_results.isNotEmpty || _isLoading))
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(16),
                  shadowColor: Colors.black.withValues(alpha: 0.15),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 260),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Google Maps Header Banner
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.map_rounded, size: 14, color: Color(0xFFEA4335)),
                              SizedBox(width: 6),
                              Text(
                                'Recommended by Google Maps',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF5F6368),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.cardBorder),

                        // Results List
                        Flexible(
                          child: _isLoading && _results.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFFEA4335),
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'Searching Google Maps...',
                                          style: TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 13,
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: _results.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.cardBorder),
                                  itemBuilder: (context, index) {
                                    final res = _results[index];
                                    final mainTitle = res.mainText ?? res.displayName;
                                    final subTitle = res.secondaryText;

                                    return ListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                      leading: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEA4335).withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.location_on_rounded,
                                          color: Color(0xFFEA4335),
                                          size: 16,
                                        ),
                                      ),
                                      title: Text(
                                        mainTitle,
                                        style: const TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: subTitle != null && subTitle.isNotEmpty
                                          ? Text(
                                              subTitle,
                                              style: TextStyle(
                                                fontFamily: 'DM Sans',
                                                fontSize: 11,
                                                color: AppColors.warmMuted.withValues(alpha: 0.9),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            )
                                          : null,
                                      onTap: () => _selectLocation(res),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
