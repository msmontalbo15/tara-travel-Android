import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/trip_type_carousel.dart';
import '../../../core/models/trip_model.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/selected_trip_provider.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/providers/itinerary_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/jit_guard.dart';
import '../../../core/utils/trip_conflict_helper.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/widgets/inputs/location_picker.dart';
import '../../../core/widgets/inputs/tara_date_range_picker.dart';
import '../../../core/widgets/feedback/app_feedback.dart';

class EditTripSheet extends ConsumerStatefulWidget {
  final TripModel trip;

  const EditTripSheet({super.key, required this.trip});

  static Future<bool?> show(BuildContext context, TripModel trip) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => EditTripSheet(trip: trip),
      ),
    );
  }

  @override
  ConsumerState<EditTripSheet> createState() => _EditTripSheetState();
}

class _EditTripSheetState extends ConsumerState<EditTripSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _destController;
  late TextEditingController _budgetController;

  late DateTime _fromDate;
  late DateTime _toDate;
  late String _selectedTripType;
  late bool _isMapEnabled;
  late String _journeyMode;
  bool _isSaving = false;

  String? _nameError;
  String? _destError;
  String? _dateError;

  @override
  void initState() {
    super.initState();
    final t = widget.trip;
    _nameController = TextEditingController(text: t.name);
    _destController = TextEditingController(text: t.destination);
    _budgetController = TextEditingController(
      text: t.totalBudget > 0 ? t.totalBudget.toStringAsFixed(0) : '',
    );
    _fromDate = t.fromDate;
    _toDate = t.toDate;
    _selectedTripType = t.tripType.toLowerCase();
    _isMapEnabled = t.isMapEnabled;
    _journeyMode = t.journeyMode.name == 'multiPoint' ? 'multi_point' : t.journeyMode.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _destController.dispose();
    _budgetController.dispose();
    super.dispose();
  }



  Future<void> _pickDateRange() async {
    final existingTrips = ref.read(allTripsProvider).value ?? [];

    final picked = await TaraDateRangePickerSheet.show(
      context,
      initialStart: _fromDate,
      initialEnd: _toDate,
      existingTrips: existingTrips,
      excludeTripId: widget.trip.id,
    );

    if (picked != null && mounted) {
      final conflicts = TripConflictHelper.findConflictingTrips(
        trips: existingTrips,
        start: picked.start,
        end: picked.end,
        excludeTripId: widget.trip.id,
      );

      if (conflicts.isNotEmpty) {
        final proceed = await JitGuard.checkDateOverlapGuard(
          context,
          conflictingTripNames: conflicts.map((t) => t.name).toList(),
        );
        if (!proceed || !mounted) return;
      }

      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
        _dateError = null;
      });
    }
  }

  bool _validate() {
    bool ok = true;
    setState(() {
      _nameError = _nameController.text.trim().isEmpty ? 'Please enter a trip name' : null;
      _destError = _destController.text.trim().isEmpty ? 'Please enter a destination' : null;
      _dateError = _toDate.isBefore(_fromDate) ? 'End date must be after start date' : null;
    });
    if (_nameError != null || _destError != null || _dateError != null) {
      ok = false;
    }
    return ok;
  }

  Future<void> _saveChanges() async {
    if (!_validate() || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final budget = double.tryParse(_budgetController.text.trim()) ?? 0.0;

      // Merge journey mode settings into existing destinationDetails
      final existingDetails = Map<String, dynamic>.from(
        widget.trip.destinationDetails ?? <String, dynamic>{},
      );
      existingDetails['is_map_enabled'] = _isMapEnabled;
      existingDetails['journey_mode'] = _journeyMode;

      final updatedTrip = widget.trip.copyWith(
        name: _nameController.text.trim(),
        destination: _destController.text.trim(),
        fromDate: _fromDate,
        toDate: _toDate,
        tripType: _selectedTripType,
        totalBudget: budget,
        destinationDetails: existingDetails,
      );

      await ref.read(tripRepositoryProvider).updateTrip(updatedTrip);
      ref.invalidate(allTripsProvider);
      ref.invalidate(selectedTripProvider);
      ref.invalidate(itineraryProvider(widget.trip.id));

      if (mounted) {
        Navigator.pop(context, true);
        AppFeedback.showSuccess(
          context,
          'Trip details updated successfully! ✨',
          title: 'Trip Updated',
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
          context,
          'Failed to update trip: $e',
          title: 'Update Failed',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Header (Exact CreateTrip layout) ────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Edit trip',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 50),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Form Content ─────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Trip Name
                      AppTextField(
                        label: 'Trip name',
                        controller: _nameController,
                        hint: 'e.g. Summer in Paris',
                        errorText: _nameError,
                        prefixIcon: Icons.luggage_rounded,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) {
                          if (_nameError != null) setState(() => _nameError = null);
                        },
                      ),
                      const SizedBox(height: 18),

                      // 2. Destination
                      LocationPicker(
                        label: 'Destination',
                        hint: 'Search destination in the Philippines...',
                        initialValue: _destController.text.isNotEmpty ? _destController.text : null,
                        onLocationSelected: (loc) {
                          if (loc != null) {
                            _destController.text = loc.displayName;
                            if (_destError != null) setState(() => _destError = null);
                          } else {
                            _destController.clear();
                          }
                        },
                      ),
                      if (_destError != null) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            _destError!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.red,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),

                      // 3. Travel Dates Picker (Unified layout)
                      const Text(
                        'Travel dates',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepEarth,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickDateRange,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _dateError != null ? AppColors.red : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${DateFormat('MMM d, yyyy').format(_fromDate)} – ${DateFormat('MMM d, yyyy').format(_toDate)}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_toDate.difference(_fromDate).inDays} nights',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_dateError != null) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            _dateError!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.red,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),

                      // 4. Total Budget
                      const Text(
                        'Total budget',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepEarth,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _budgetController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: '0',
                          prefixText: '₱ ',
                          prefixStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          prefixIcon: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // 5. Trip Type & Style Carousel
                      const Text(
                        'Trip type',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepEarth,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TripTypeCarousel(
                        selectedTripType: _selectedTripType,
                        onTypeSelected: (option) {
                          setState(() {
                            _selectedTripType = option.id.toLowerCase();
                          });
                        },
                      ),
                      const SizedBox(height: 22),

                      // 6. Map & Navigation Mode Settings (Plan 10)
                      _buildMapNavigationCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // ── Bottom Sticky CTA Button (Matching CreateTripFlow) ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildMapNavigationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.explore_outlined, color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Map & Navigation Mode',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepEarth,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Journey Mode Chips
          Row(
            children: [
              _modeChip('standard', 'Standard', Icons.map_rounded),
              const SizedBox(width: 8),
              _modeChip('adventure', 'Adventure', Icons.explore_rounded),
              const SizedBox(width: 8),
              _modeChip('multi_point', 'Multi-Hub', Icons.alt_route_rounded),
            ],
          ),
          const SizedBox(height: 10),

          // Description Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.8)),
            ),
            child: Row(
              children: [
                Icon(
                  _journeyMode == 'adventure'
                      ? Icons.terrain_rounded
                      : _journeyMode == 'multi_point'
                          ? Icons.hub_rounded
                          : Icons.navigation_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _journeyMode == 'adventure'
                        ? 'Off-Grid & Battery Saver: Compass bearings, waypoint checklists, zero map tiles.'
                        : _journeyMode == 'multi_point'
                            ? 'Multi-Destination: Sequential stops connecting multiple towns or islands.'
                            : 'Standard: Interactive road map, driving navigation and GPS pin snapping.',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.deepEarth, height: 1.3),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 24, color: AppColors.cardBorder),

          // Map Tracking Toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _isMapEnabled,
            onChanged: (val) => setState(() => _isMapEnabled = val),
            title: const Text(
              'Enable Map Tracking & Live Nav',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.deepEarth,
              ),
            ),
            subtitle: Text(
              _isMapEnabled
                  ? 'Active map visualizer & road turn-by-turn routing.'
                  : 'Mapless / Off-grid mode: Saves mobile data and battery life.',
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _modeChip(String modeKey, String title, IconData icon) {
    final isSelected = _journeyMode == modeKey;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _journeyMode = modeKey);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? Colors.white : AppColors.deepEarth, size: 20),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.deepEarth,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
