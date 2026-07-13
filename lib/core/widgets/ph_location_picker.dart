import 'package:flutter/material.dart';
import '../data/ph_location_data.dart';
import '../theme/app_colors.dart';

/// A cascading dropdown picker: Region → City/Municipality → Barangay
/// for Philippine addresses.
///
/// All three values are optional – the widget calls [onChanged] whenever any
/// selection changes so the parent can persist partial state.
class PhLocationPicker extends StatefulWidget {
  final String? initialRegion;
  final String? initialCity;
  final String? initialBarangay;

  /// Called when any of the three fields change.
  final void Function(String? region, String? city, String? barangay)
      onChanged;

  /// If true, shows a more compact card-style layout (for onboarding).
  final bool compact;

  const PhLocationPicker({
    super.key,
    this.initialRegion,
    this.initialCity,
    this.initialBarangay,
    required this.onChanged,
    this.compact = false,
  });

  @override
  State<PhLocationPicker> createState() => _PhLocationPickerState();
}

class _PhLocationPickerState extends State<PhLocationPicker> {
  String? _region;
  String? _city;
  String? _barangay;

  // Filtered lists
  List<String> _cities = [];
  List<String> _barangays = [];

  @override
  void initState() {
    super.initState();
    _region = widget.initialRegion;
    if (_region != null) {
      _cities = cityNames(_region!);
      _city = (_cities.contains(widget.initialCity)) ? widget.initialCity : null;
    }
    if (_city != null && _region != null) {
      _barangays = barangayNames(_region!, _city!);
      _barangay = (_barangays.contains(widget.initialBarangay))
          ? widget.initialBarangay
          : null;
    }
  }

  void _onRegionChanged(String? v) {
    setState(() {
      _region = v;
      _cities = v != null ? cityNames(v) : [];
      _city = _cities.isNotEmpty ? _cities.first : null;
      _barangays = (_city != null && v != null)
          ? barangayNames(v, _city!)
          : [];
      _barangay = _barangays.isNotEmpty ? _barangays.first : null;
    });
    widget.onChanged(_region, _city, _barangay);
  }

  void _onCityChanged(String? v) {
    setState(() {
      _city = v;
      _barangays =
          (v != null && _region != null) ? barangayNames(_region!, v) : [];
      _barangay = _barangays.isNotEmpty ? _barangays.first : null;
    });
    widget.onChanged(_region, _city, _barangay);
  }

  void _onBarangayChanged(String? v) {
    setState(() => _barangay = v);
    widget.onChanged(_region, _city, _barangay);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Country (read-only)
        _label('Country'),
        const SizedBox(height: 8),
        _readOnlyField('🇵🇭  Philippines', Icons.public_rounded),
        const SizedBox(height: 20),

        // Region
        _label('Region'),
        const SizedBox(height: 8),
        _dropdown<String>(
          value: _region,
          hint: 'Select region',
          items: regionNames(),
          onChanged: _onRegionChanged,
          icon: Icons.map_outlined,
        ),
        const SizedBox(height: 20),

        // City / Municipality
        _label('City / Municipality'),
        const SizedBox(height: 8),
        _dropdown<String>(
          value: _city,
          hint: _region == null ? 'Select region first' : 'Select city',
          items: _cities,
          onChanged: _region == null ? null : _onCityChanged,
          icon: Icons.location_city_rounded,
        ),
        const SizedBox(height: 20),

        // Barangay
        _label('Barangay'),
        const SizedBox(height: 8),
        _dropdown<String>(
          value: _barangay,
          hint: _city == null ? 'Select city first' : 'Select barangay',
          items: _barangays,
          onChanged: _city == null ? null : _onBarangayChanged,
          icon: Icons.place_outlined,
        ),
      ],
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      );

  Widget _readOnlyField(String text, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.warmMuted),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.sand,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Fixed',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _dropdown<T>({
    required T? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
    required IconData icon,
  }) {
    final bool enabled = onChanged != null && items.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enabled ? AppColors.cardBorder : AppColors.dividerLight,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: enabled ? AppColors.warmMuted : AppColors.dividerLight),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value as String?,
                hint: Text(
                  hint,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    color: enabled ? AppColors.warmMuted : AppColors.dividerLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                isExpanded: true,
                icon: Icon(
                  Icons.expand_more_rounded,
                  color: enabled ? AppColors.warmMuted : AppColors.dividerLight,
                  size: 20,
                ),
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                items: items.map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: enabled ? onChanged : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
