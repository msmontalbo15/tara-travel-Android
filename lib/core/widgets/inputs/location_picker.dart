import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../services/philippine_geocoding_service.dart';
import '../../theme/app_colors.dart';
import 'map_pin_picker_modal.dart';

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

  /// Parse from Nominatim JSON.
  factory LocationResult.fromJson(Map<String, dynamic> json) {
    String name = json['display_name'] ?? '';

    final parts = name.split(',');
    String? main = parts.isNotEmpty ? parts.first.trim() : name;
    String? secondary =
        parts.length > 1 ? parts.sublist(1).join(',').trim() : null;

    double parsedLat = 0.0;
    double parsedLon = 0.0;

    if (json['lat'] != null && json['lon'] != null) {
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

  /// Construct from a [GeocodingResult].
  factory LocationResult.fromGeocodingResult(GeocodingResult r) {
    return LocationResult(
      displayName: r.displayName,
      mainText: r.mainText,
      secondaryText: r.secondaryText,
      lat: r.lat,
      lon: r.lon,
    );
  }
}

class LocationPicker extends StatefulWidget {
  final String label;
  final String? hint;
  final String? initialValue;
  final double? initialLat;
  final double? initialLon;
  final bool enableMapPin;
  final ValueChanged<LocationResult?> onLocationSelected;

  const LocationPicker({
    super.key,
    this.label = 'Location',
    this.hint = 'Search Philippine places...',
    this.initialValue,
    this.initialLat,
    this.initialLon,
    this.enableMapPin = true,
    required this.onLocationSelected,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  CancelToken? _cancelToken;

  List<LocationResult> _results = [];
  bool _isLoading = false;
  bool _showDropdown = false;
  LocationResult? _selectedLocation;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      _searchCtrl.text = widget.initialValue!;
      if (widget.initialLat != null && widget.initialLon != null) {
        _selectedLocation = LocationResult(
          displayName: widget.initialValue!,
          lat: widget.initialLat!,
          lon: widget.initialLon!,
        );
      }
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
    _cancelToken?.cancel('Widget disposed');
    super.dispose();
  }

  void _onSearchChanged() {
    if (_selectedLocation != null &&
        _searchCtrl.text == _selectedLocation!.displayName) {
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

    // Cancel previous in-flight request
    _cancelToken?.cancel('New query');
    _cancelToken = CancelToken();

    try {
      final geocodingResults = await PhilippineGeocodingService.instance.search(
        query,
        limit: 6,
        cancelToken: _cancelToken,
      );

      if (mounted) {
        setState(() {
          _results = geocodingResults
              .map((r) => LocationResult.fromGeocodingResult(r))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('[LocationPicker] Search error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectLocation(LocationResult location) async {
    setState(() {
      _selectedLocation = location;
      _searchCtrl.text = location.displayName;
      _showDropdown = false;
    });
    _focusNode.unfocus();
    widget.onLocationSelected(location);
  }

  Future<void> _openMapPinPicker() async {
    _focusNode.unfocus();
    setState(() => _showDropdown = false);

    LatLng? initialPos;
    if (_selectedLocation != null &&
        _selectedLocation!.lat != 0.0 &&
        _selectedLocation!.lon != 0.0) {
      initialPos = LatLng(_selectedLocation!.lat, _selectedLocation!.lon);
    } else if (widget.initialLat != null && widget.initialLon != null) {
      initialPos = LatLng(widget.initialLat!, widget.initialLon!);
    }

    final result = await MapPinPickerModal.show(
      context,
      initialPosition: initialPos,
      initialAddress: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null,
    );

    if (result != null && mounted) {
      _selectLocation(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            const Spacer(),
            if (widget.enableMapPin)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _openMapPinPicker,
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pin_drop_rounded,
                          size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Pin on Map',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
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
                prefixIcon: const Icon(Icons.place_outlined,
                    size: 20, color: AppColors.primary),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary),
                        ),
                      )
                    else if (_searchCtrl.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            size: 18, color: AppColors.muted),
                        onPressed: () {
                          _searchCtrl.clear();
                          _selectedLocation = null;
                          widget.onLocationSelected(null);
                        },
                      ),
                    if (widget.enableMapPin)
                      IconButton(
                        tooltip: 'Choose pin on map',
                        icon: const Icon(Icons.map_outlined,
                            size: 20, color: AppColors.primary),
                        onPressed: _openMapPinPicker,
                      ),
                  ],
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.cardBorder, width: 0.8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),

            // Philippines Search Dropdown
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
                    constraints: const BoxConstraints(maxHeight: 290),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // OpenStreetMap Header Banner
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.public_rounded,
                                  size: 14, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text(
                                'Philippine Places (OpenStreetMap)',
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

                        // Pin on Map Quick Action
                        if (widget.enableMapPin) ...[
                          InkWell(
                            onTap: _openMapPinPicker,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              color: const Color(0xFFFDF7F5),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.pin_drop_rounded,
                                      color: AppColors.primary,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Set pin directly on map',
                                          style: TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        Text(
                                          'Drag pin and pinpoint exact location',
                                          style: TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 11,
                                            color: AppColors.darkAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded,
                                      size: 12, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                          const Divider(
                              height: 1, color: AppColors.cardBorder),
                        ],

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
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'Searching Philippine places...',
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
                                  separatorBuilder: (_, __) => const Divider(
                                      height: 1, color: AppColors.cardBorder),
                                  itemBuilder: (context, index) {
                                    final res = _results[index];
                                    final mainTitle =
                                        res.mainText ?? res.displayName;
                                    final subTitle = res.secondaryText;

                                    return ListTile(
                                      dense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 4),
                                      leading: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.location_on_rounded,
                                          color: AppColors.primary,
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
                                      subtitle: subTitle != null &&
                                              subTitle.isNotEmpty
                                          ? Text(
                                              subTitle,
                                              style: TextStyle(
                                                fontFamily: 'DM Sans',
                                                fontSize: 11,
                                                color: AppColors.warmMuted
                                                    .withValues(alpha: 0.9),
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
