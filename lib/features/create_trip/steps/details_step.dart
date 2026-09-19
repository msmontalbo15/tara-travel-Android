import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/friend_model.dart';
import '../../../core/providers/friend_provider.dart';
import '../../../core/providers/friend_circle_provider.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/jit_guard.dart';
import '../../../core/utils/trip_conflict_helper.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/widgets/inputs/location_picker.dart';
import '../../../core/widgets/inputs/tara_date_range_picker.dart';

import '../../../shared/widgets/trip_type_carousel.dart';
import '../models/new_trip_model.dart';
import '../widgets/step_indicator.dart';

class DetailsStep extends ConsumerStatefulWidget {
  final NewTripModel trip;
  final VoidCallback onNext;
  final VoidCallback onCancel;

  const DetailsStep({
    super.key,
    required this.trip,
    required this.onNext,
    required this.onCancel,
  });

  @override
  ConsumerState<DetailsStep> createState() => _DetailsStepState();
}

class _DetailsStepState extends ConsumerState<DetailsStep> {
  late TextEditingController _nameController;
  late TextEditingController _destController;
  late TextEditingController _hubController;
  final _formKey = GlobalKey<FormState>();

  String? _nameError;
  String? _destError;
  String? _dateError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.trip.tripName);
    _destController = TextEditingController(text: widget.trip.destination);
    _hubController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _destController.dispose();
    _hubController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool ok = true;
    setState(() {
      _nameError = _nameController.text.trim().isEmpty
          ? 'Please enter a trip name'
          : null;
      _destError = null;
      _dateError = widget.trip.fromDate == null || widget.trip.toDate == null
          ? 'Please select travel dates'
          : (widget.trip.toDate!.isBefore(widget.trip.fromDate!)
              ? 'End date must be after start date'
              : null);
    });
    if (_nameError != null || _dateError != null) {
      ok = false;
    }
    return ok;
  }

  void _onContinue() {
    // Validate first — only commit to the draft if inputs are valid
    widget.trip.tripName = _nameController.text.trim();
    widget.trip.destination = _destController.text.trim();
    if (_validate()) widget.onNext();
  }



  Future<void> _selectDateRange() async {
    final existingTrips = ref.read(allTripsProvider).value ?? [];

    final picked = await TaraDateRangePickerSheet.show(
      context,
      initialStart: widget.trip.fromDate,
      initialEnd: widget.trip.toDate,
      existingTrips: existingTrips,
    );

    if (picked != null && mounted) {
      // Check for conflicts and ask for confirmation if overlapping
      final conflicts = TripConflictHelper.findConflictingTrips(
        trips: existingTrips,
        start: picked.start,
        end: picked.end,
      );

      if (conflicts.isNotEmpty) {
        final proceed = await JitGuard.checkDateOverlapGuard(
          context,
          conflictingTripNames: conflicts.map((t) => t.name).toList(),
        );
        if (!proceed || !mounted) return;
      }

      setState(() {
        widget.trip.fromDate = picked.start;
        widget.trip.toDate = picked.end;
        _dateError = null;
      });
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
              // ── Header ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onCancel,
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'New trip',
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

              // ── Step indicator ──────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: StepIndicator(
                  currentStep: 1,
                  totalSteps: 4,
                  label: 'Trip details',
                ),
              ),
              const SizedBox(height: 24),

              // ── Form ────────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Trip name
                      AppTextField(
                        label: 'Trip name',
                        controller: _nameController,
                        hint: 'e.g. Summer in Paris',
                        errorText: _nameError,
                        prefixIcon: Icons.luggage_rounded,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) {
                          if (_nameError != null) setState(() => _nameError = null);
                          widget.trip.tripName = _nameController.text;
                        },
                        semanticsLabel: 'Trip name field',
                      ),
                      const SizedBox(height: 18),

                      // Destination
                      LocationPicker(
                        label: 'Destination (Optional)',
                        hint: 'Search Philippine destination (optional)...',
                        initialValue: widget.trip.destination.isNotEmpty ? widget.trip.destination : null,
                        initialLat: widget.trip.destinationLat,
                        initialLon: widget.trip.destinationLng,
                        onLocationSelected: (loc) {
                          if (loc != null) {
                            _destController.text = loc.displayName;
                            widget.trip.destination = loc.displayName;
                            widget.trip.destinationLat = loc.lat;
                            widget.trip.destinationLng = loc.lon;
                            if (_destError != null) setState(() => _destError = null);
                          } else {
                            _destController.clear();
                            widget.trip.destination = '';
                            widget.trip.destinationLat = null;
                            widget.trip.destinationLng = null;
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

                      // Travel dates — Unified Date Range Picker
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
                        onTap: _selectDateRange,
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
                              const Icon(Icons.calendar_month_rounded, color: AppColors.textSecondary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  (widget.trip.fromDate != null && widget.trip.toDate != null)
                                      ? '${widget.trip.fromDate!.month}/${widget.trip.fromDate!.day}/${widget.trip.fromDate!.year} - ${widget.trip.toDate!.month}/${widget.trip.toDate!.day}/${widget.trip.toDate!.year}'
                                      : 'Select date range',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: (widget.trip.fromDate != null && widget.trip.toDate != null) 
                                        ? AppColors.textPrimary 
                                        : AppColors.muted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                      const SizedBox(height: 22),

                      // Trip type section
                      const Text(
                        'Trip type',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepEarth,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Trip type carousel
                      TripTypeCarousel(
                        selectedTripType: widget.trip.tripType,
                        onTypeSelected: (option) {
                          setState(() {
                            widget.trip.tripType = option.id;
                            // Smart default inference for journey mode based on tripType
                            final norm = option.id.toLowerCase();
                            if (norm.contains('hike') || norm.contains('camp') || norm.contains('adventure') || norm.contains('nature')) {
                              widget.trip.journeyMode = 'adventure';
                            } else if (norm.contains('roadtrip') || norm.contains('rides')) {
                              if (widget.trip.journeyMode == 'standard') {
                                widget.trip.journeyMode = 'multi_point';
                              }
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 22),

                      // ── Journey Style & Optional Map Settings ───────────
                      _buildJourneyStyleCard(),
                      const SizedBox(height: 22),

                      // Travelers
                      const Text(
                        'Travelers',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepEarth,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _travelersRow(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // ── CTA ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Continue — Budget setup',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
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

  Widget _buildJourneyStyleCard() {
    final mode = widget.trip.journeyMode;
    final isMapEnabled = widget.trip.isMapEnabled;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1,
        ),
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
                'Journey Style & Navigation Mode',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepEarth,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Select how your group navigates. Trips do not require fixed destination pins.',
            style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.3),
          ),
          const SizedBox(height: 14),

          // 3 Mode Selection Cards
          Row(
            children: [
              _journeyModeOption(
                modeKey: 'standard',
                title: 'Standard',
                icon: Icons.map_rounded,
                isSelected: mode == 'standard',
              ),
              const SizedBox(width: 8),
              _journeyModeOption(
                modeKey: 'adventure',
                title: 'Adventure',
                icon: Icons.explore_rounded,
                isSelected: mode == 'adventure',
              ),
              const SizedBox(width: 8),
              _journeyModeOption(
                modeKey: 'multi_point',
                title: 'Multi-Hub',
                icon: Icons.alt_route_rounded,
                isSelected: mode == 'multi_point',
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Informative Mode Description Banner
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
                  mode == 'adventure'
                      ? Icons.terrain_rounded
                      : mode == 'multi_point'
                          ? Icons.hub_rounded
                          : Icons.navigation_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    mode == 'adventure'
                        ? 'Off-Grid & Battery Saver: Compass bearings, waypoint checklists, zero mandatory map tiles.'
                        : mode == 'multi_point'
                            ? 'Multi-Destination: Sequential stops connecting multiple towns, islands or provinces.'
                            : 'Standard: Interactive road map, driving navigation and GPS pin snapping.',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.deepEarth, height: 1.3),
                  ),
                ),
              ],
            ),
          ),

          // Sequential Hubs Editor for Multi-Point
          if (mode == 'multi_point') ...[
            const SizedBox(height: 12),
            const Text(
              'Sequential Route Hubs (Optional)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.deepEarth,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...widget.trip.destinationHubs.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final hub = entry.value;
                  return Chip(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    side: const BorderSide(color: AppColors.primary, width: 0.8),
                    label: Text(
                      '${idx + 1}. $hub',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    onDeleted: () {
                      setState(() {
                        widget.trip.destinationHubs.removeAt(idx);
                      });
                    },
                    deleteIconColor: AppColors.primary,
                    visualDensity: VisualDensity.compact,
                  );
                }),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      controller: _hubController,
                      decoration: InputDecoration(
                        hintText: 'Add stop/town (e.g. Tagaytay)',
                        hintStyle: const TextStyle(fontSize: 12, color: AppColors.muted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
                        ),
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: () {
                    final text = _hubController.text.trim();
                    if (text.isNotEmpty) {
                      setState(() {
                        widget.trip.destinationHubs.add(text);
                        _hubController.clear();
                      });
                    }
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Add Hub', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],

          const Divider(height: 24, color: AppColors.cardBorder),

          // Map Tracking Toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: isMapEnabled,
            onChanged: (val) {
              setState(() {
                widget.trip.isMapEnabled = val;
              });
            },
            title: const Text(
              'Enable Map Tracking & Live Nav',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.deepEarth,
              ),
            ),
            subtitle: Text(
              isMapEnabled
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

  Widget _journeyModeOption({
    required String modeKey,
    required String title,
    required IconData icon,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            widget.trip.journeyMode = modeKey;
          });
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
              Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.deepEarth,
                size: 20,
              ),
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

  Widget _travelersRow() {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        ...widget.trip.travelers.map((t) => _avatar(t)),
        GestureDetector(
          onTap: _showSelectFriendsBottomSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              border: Border.all(color: AppColors.primary, width: 1.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_add_rounded, size: 16, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  'Add friends',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _avatar(TravelerModel traveler) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Color(traveler.color),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: traveler.profilePhotoUrl != null && traveler.profilePhotoUrl!.isNotEmpty
                ? Image.network(
                    traveler.profilePhotoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        traveler.initials,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      traveler.initials,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
        ),
        Positioned(
          right: -2,
          top: -2,
          child: GestureDetector(
            onTap: () {
              setState(() {
                widget.trip.travelers.removeWhere((t) =>
                    (t.id.isNotEmpty && t.id == traveler.id) || t.name == traveler.name);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSelectFriendsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(modalContext).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bottom sheet handle bar
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Friends',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Only existing friends can be added to your trip',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(modalContext).pop(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.cardBorder),

              // ── Travel Circles Quick-Add Carousel ─────────────────
              Consumer(
                builder: (context, ref, _) {
                  final circlesAsync = ref.watch(friendCirclesProvider);
                  return circlesAsync.maybeWhen(
                    data: (circles) {
                      if (circles.isEmpty) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        color: AppColors.surfaceLight.withValues(alpha: 0.5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.groups_rounded, size: 14, color: AppColors.primary),
                                SizedBox(width: 6),
                                Text(
                                  'TRAVEL CIRCLES (1-TAP SQUAD ADD)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: circles.map((circle) {
                                  final memberIds = circle.members.map((m) => m.userId).toSet();
                                  final selectedCount = widget.trip.travelers
                                      .where((t) => memberIds.contains(t.id))
                                      .length;
                                  final allSelected = selectedCount == circle.members.length && circle.members.isNotEmpty;

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ActionChip(
                                      avatar: Text(circle.emoji),
                                      label: Text(
                                        '${circle.name} ($selectedCount/${circle.members.length})',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: allSelected ? Colors.white : AppColors.deepEarth,
                                        ),
                                      ),
                                      backgroundColor: allSelected ? AppColors.primary : Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: allSelected ? AppColors.primary : AppColors.cardBorder,
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          if (allSelected) {
                                            // Remove circle members
                                            widget.trip.travelers.removeWhere((t) => memberIds.contains(t.id));
                                          } else {
                                            // Add missing circle members with deduplication
                                            for (final cm in circle.members) {
                                              if (!widget.trip.travelers.any((t) => t.id == cm.userId)) {
                                                widget.trip.travelers.add(
                                                  TravelerModel(
                                                    id: cm.userId,
                                                    name: cm.name,
                                                    initials: cm.initials,
                                                    color: AppColors.primary.toARGB32(),
                                                    profilePhotoUrl: cm.profilePhotoUrl,
                                                  ),
                                                );
                                              }
                                            }
                                          }
                                        });
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  );
                },
              ),

              // Friends list consumer
              Flexible(
                child: Consumer(
                  builder: (context, ref, child) {
                    final friendsAsync = ref.watch(friendsProvider);

                    return friendsAsync.when(
                      data: (friends) {
                        // Filter for accepted friends
                        final acceptedFriends = friends
                            .where((f) => f.status == FriendStatus.accepted)
                            .toList();

                        if (acceptedFriends.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    color: AppColors.surfaceLight,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.group_off_rounded,
                                    size: 40,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No Friends Found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'You do not have any accepted friends yet. Add friends from the Friends menu to invite them to trips.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return StatefulBuilder(
                          builder: (context, setModalState) {
                            return ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              itemCount: acceptedFriends.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.surfaceLight),
                              itemBuilder: (context, index) {
                                final friend = acceptedFriends[index];
                                final isSelected = widget.trip.travelers.any((t) =>
                                    (t.id.isNotEmpty && t.id == friend.id) || t.name == friend.name);

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                  leading: CircleAvatar(
                                    backgroundColor: friend.color,
                                    backgroundImage: (friend.profilePhotoUrl != null && friend.profilePhotoUrl!.isNotEmpty)
                                        ? NetworkImage(friend.profilePhotoUrl!)
                                        : null,
                                    child: (friend.profilePhotoUrl == null || friend.profilePhotoUrl!.isEmpty)
                                        ? Text(
                                            friend.initials,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                    friend.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  trailing: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primary : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? AppColors.primary : AppColors.muted,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                                        : null,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        widget.trip.travelers.removeWhere((t) =>
                                            (t.id.isNotEmpty && t.id == friend.id) || t.name == friend.name);
                                      } else {
                                        widget.trip.travelers.add(
                                          TravelerModel(
                                            id: friend.id,
                                            name: friend.name,
                                            initials: friend.initials,
                                            color: friend.color.toARGB32(),
                                            profilePhotoUrl: friend.profilePhotoUrl,
                                          ),
                                        );
                                      }
                                    });
                                    setModalState(() {});
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                      loading: () => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          children: List.generate(3, (index) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: 14,
                                        width: 120,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        height: 10,
                                        width: 70,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withValues(alpha: 0.05),
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ),
                      ),
                      error: (err, stack) => Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Could not load friends: $err',
                            style: const TextStyle(
                              color: AppColors.red,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom Done Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(modalContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Done (${widget.trip.travelers.length} selected)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }



}


