import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/friend_model.dart';
import '../../../core/providers/friend_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/widgets/inputs/location_picker.dart';

import '../../../core/constants/trip_types.dart';
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
  final _formKey = GlobalKey<FormState>();

  String? _nameError;
  String? _destError;
  String? _dateError;



  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.trip.tripName);
    _destController = TextEditingController(text: widget.trip.destination);
    
    // Default cover color derived from trip type accent
    widget.trip.coverColor ??= AppTripTypes.getOption(widget.trip.tripType).accentColor.toARGB32();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _destController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool ok = true;
    setState(() {
      _nameError = _nameController.text.trim().isEmpty
          ? 'Please enter a trip name'
          : null;
      _destError = _destController.text.trim().isEmpty
          ? 'Please enter a destination'
          : null;
      _dateError = widget.trip.fromDate == null || widget.trip.toDate == null
          ? 'Please select travel dates'
          : (widget.trip.toDate!.isBefore(widget.trip.fromDate!)
              ? 'End date must be after start date'
              : null);
    });
    if (_nameError != null || _destError != null || _dateError != null) {
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
    final initialDateRange = (widget.trip.fromDate != null && widget.trip.toDate != null) 
      ? DateTimeRange(start: widget.trip.fromDate!, end: widget.trip.toDate!)
      : null;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      initialDateRange: initialDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.deepEarth,
            ),
          ),
          child: child!,
        );
      }
    );

    if (picked != null) {
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
                          fontFamily: 'DM Sans',
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
                            fontFamily: 'DM Sans',
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
                        label: 'Destination',
                        hint: 'Search Philippine destination...',
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
                              fontFamily: 'DM Sans',
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
                          fontFamily: 'DM Sans',
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
                                    fontFamily: 'DM Sans',
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
                              fontFamily: 'DM Sans',
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
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepEarth,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Trip type carousel (also sets cover color)
                      _TripTypeCarousel(
                        selectedTripType: widget.trip.tripType,
                        onTypeSelected: (option) {
                          setState(() {
                            widget.trip.tripType = option.label;
                            widget.trip.coverColor = option.accentColor.toARGB32();
                          });
                        },
                      ),
                      const SizedBox(height: 22),

                      // Travelers
                      const Text(
                        'Travelers',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
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
                        fontFamily: 'DM Sans',
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
                    fontFamily: 'DM Sans',
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
                          fontFamily: 'DM Sans',
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
                        fontFamily: 'DM Sans',
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
                              fontFamily: 'DM Sans',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Only existing friends can be added to your trip',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
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
                                    fontFamily: 'DM Sans',
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
                                    fontFamily: 'DM Sans',
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
                                              fontFamily: 'DM Sans',
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                    friend.name,
                                    style: const TextStyle(
                                      fontFamily: 'DM Sans',
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
                              fontFamily: 'DM Sans',
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
                        fontFamily: 'DM Sans',
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

// ─────────────────────────────────────────────────────────────────────────────
// Trip Type Carousel — same visual style as TripColorCarousel
// Selecting a type also auto-sets the cover color from its accentColor.
// ─────────────────────────────────────────────────────────────────────────────

class _TripTypeCarousel extends StatefulWidget {
  final String selectedTripType;
  final ValueChanged<TripTypeOption> onTypeSelected;

  const _TripTypeCarousel({
    required this.selectedTripType,
    required this.onTypeSelected,
  });

  @override
  State<_TripTypeCarousel> createState() => _TripTypeCarouselState();
}

class _TripTypeCarouselState extends State<_TripTypeCarousel> {
  static const int _kCenter = 1000;
  late PageController _pageController;
  int _currentRealIndex = 0;

  int get _count => AppTripTypes.all.length;

  @override
  void initState() {
    super.initState();
    final activeOpt = AppTripTypes.getOption(widget.selectedTripType);
    final idx = AppTripTypes.all.indexWhere((o) => o.id == activeOpt.id);
    _currentRealIndex = idx >= 0 ? idx : 0;
    _pageController = PageController(
      initialPage: (_kCenter * _count) + _currentRealIndex,
      viewportFraction: 0.76,
    );
  }

  @override
  void didUpdateWidget(_TripTypeCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTripType != widget.selectedTripType) {
      final activeOpt = AppTripTypes.getOption(widget.selectedTripType);
      final targetIdx = AppTripTypes.all.indexWhere((o) => o.id == activeOpt.id);
      if (targetIdx >= 0 &&
          targetIdx != _currentRealIndex &&
          _pageController.hasClients) {
        final curPage = _pageController.page?.round() ?? _pageController.initialPage;
        final curOffset = curPage % _count;
        final diff = targetIdx - curOffset;
        _currentRealIndex = targetIdx;
        _pageController.animateToPage(
          curPage + diff,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    final realIdx = index % _count;
    if (realIdx != _currentRealIndex) {
      setState(() => _currentRealIndex = realIdx);
      widget.onTypeSelected(AppTripTypes.all[realIdx]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 175,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final realIndex = index % _count;
              final option = AppTripTypes.all[realIndex];
              final isSelected = realIndex == _currentRealIndex;

              // Derive a lighter accent for the gradient end
              final accentLight = HSLColor.fromColor(option.accentColor)
                  .withLightness(
                    (HSLColor.fromColor(option.accentColor).lightness + 0.18)
                        .clamp(0.0, 1.0),
                  )
                  .toColor();

              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = (_pageController.page! - index).abs();
                    value = (1 - (value * 0.15)).clamp(0.85, 1.0);
                  } else {
                    value = isSelected ? 1.0 : 0.88;
                  }

                  return Transform.scale(
                    scale: value,
                    child: GestureDetector(
                      onTap: () {
                        if (_pageController.hasClients) {
                          final curPage =
                              _pageController.page?.round() ?? index;
                          if (curPage != index) {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOutCubic,
                            );
                          }
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: LinearGradient(
                            colors: [option.accentColor, accentLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: option.accentColor.withValues(
                                  alpha: isSelected ? 0.38 : 0.15),
                              blurRadius: isSelected ? 16 : 8,
                              spreadRadius: isSelected ? 2 : 0,
                              offset: Offset(0, isSelected ? 8 : 4),
                            ),
                          ],
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            width: isSelected ? 2.5 : 0,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Ambient shine blob
                            Positioned(
                              top: -20,
                              right: -20,
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                            ),
                            // Eye-catching large emoji watermark/accent in card corner
                            Positioned(
                              right: 12,
                              bottom: 6,
                              child: IgnorePointer(
                                child: Opacity(
                                  opacity: 0.28,
                                  child: Transform.rotate(
                                    angle: -0.12,
                                    child: Text(
                                      option.emoji,
                                      style: const TextStyle(
                                        fontSize: 64,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Eye-catching glassmorphic Icon / Category badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.25),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.35),
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.08),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.3),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                option.emoji,
                                                style: const TextStyle(fontSize: 18),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              option.category,
                                              style: const TextStyle(
                                                fontFamily: 'DM Sans',
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Check circle
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black
                                                  .withValues(alpha: 0.20),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.15),
                                                    blurRadius: 6,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: isSelected
                                            ? Icon(Icons.check_rounded,
                                                size: 20,
                                                color: option.accentColor)
                                            : null,
                                      ),
                                    ],
                                  ),
                                  // Label & subtitle
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option.label,
                                        style: const TextStyle(
                                          fontFamily: 'Playfair Display',
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          height: 1.1,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black26,
                                              offset: Offset(0, 1),
                                              blurRadius: 3,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        option.subtitle,
                                        style: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white
                                              .withValues(alpha: 0.90),
                                          letterSpacing: 0.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _count,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _currentRealIndex ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: i == _currentRealIndex
                    ? AppTripTypes.all[i].accentColor
                    : AppColors.cardBorder,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

