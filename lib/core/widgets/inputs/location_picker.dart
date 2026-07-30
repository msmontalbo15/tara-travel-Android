import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../theme/app_colors.dart';

class LocationResult {
  final String displayName;
  final double lat;
  final double lon;

  LocationResult({
    required this.displayName,
    required this.lat,
    required this.lon,
  });

  factory LocationResult.fromJson(Map<String, dynamic> json) {
    return LocationResult(
      displayName: json['display_name'] ?? '',
      lat: double.tryParse(json['lat'].toString()) ?? 0.0,
      lon: double.tryParse(json['lon'].toString()) ?? 0.0,
    );
  }
}

class LocationPicker extends StatefulWidget {
  final String label;
  final String? hint;
  final ValueChanged<LocationResult?> onLocationSelected;

  const LocationPicker({
    super.key,
    this.label = 'Location',
    this.hint = 'Search places...',
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
      setState(() {
        _results = [];
        _showDropdown = false;
      });
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchLocation(_searchCtrl.text);
    });
  }

  Future<void> _searchLocation(String query) async {
    setState(() {
      _isLoading = true;
      _showDropdown = true;
    });

    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 5,
        },
        options: Options(
          headers: {
            // Nominatim requires a User-Agent
            'User-Agent': 'TaraTravelApp/1.0',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List data = response.data;
        setState(() {
          _results = data.map((json) => LocationResult.fromJson(json)).toList();
        });
      }
    } catch (e) {
      debugPrint('Location search error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectLocation(LocationResult location) {
    setState(() {
      _selectedLocation = location;
      _searchCtrl.text = location.displayName;
      _showDropdown = false;
    });
    _focusNode.unfocus();
    widget.onLocationSelected(location);
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
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.warmMuted),
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
            
            // Dropdown results
            if (_showDropdown && (_results.isNotEmpty || _isLoading))
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: _isLoading && _results.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: Text('Searching...', style: TextStyle(fontFamily: 'DM Sans', color: AppColors.muted))),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final res = _results[index];
                              return ListTile(
                                leading: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                                title: Text(
                                  res.displayName,
                                  style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: AppColors.textPrimary),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => _selectLocation(res),
                              );
                            },
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
