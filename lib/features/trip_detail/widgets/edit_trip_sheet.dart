import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../core/constants/trip_types.dart';
import '../../../core/models/trip_model.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/selected_trip_provider.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/widgets/inputs/location_picker.dart';
import '../../../core/widgets/inputs/map_pin_picker_modal.dart';

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
  late String? _coverColor;
  bool _isSaving = false;

  String? _nameError;
  String? _destError;
  String? _dateError;

  List<LocationResult> _placePredictions = [];
  bool _isLoadingPlaces = false;
  Timer? _debounceTimer;

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
    _coverColor = t.coverColor;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nameController.dispose();
    _destController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  // Location search engine matching CreateTripFlow
  Future<void> _fetchPlaces(String query) async {
    _debounceTimer?.cancel();
    final cleanQuery = query.trim();

    if (cleanQuery.isEmpty) {
      if (mounted) setState(() => _placePredictions = []);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => _isLoadingPlaces = true);

      try {
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(cleanQuery)}&format=json&limit=6&addressdetails=1&countrycodes=ph',
        );
        final res = await http.get(
          uri,
          headers: {'User-Agent': 'TaraTravelApp/1.0 (MapLibre Search)'},
        );

        if (res.statusCode == 200) {
          final List data = json.decode(res.body);
          final predictions = data.map((e) => LocationResult.fromJson(e)).toList();

          if (mounted) {
            setState(() {
              _placePredictions = predictions;
              _isLoadingPlaces = false;
            });
          }
        } else {
          if (mounted) setState(() => _isLoadingPlaces = false);
        }
      } catch (_) {
        if (mounted) setState(() => _isLoadingPlaces = false);
      }
    });
  }

  Future<void> _openMapPinPicker([TextEditingController? textEditingController]) async {
    final result = await MapPinPickerModal.show(
      context,
      initialAddress: _destController.text,
    );

    if (result != null) {
      setState(() {
        _destController.text = result.displayName;
        if (textEditingController != null) {
          textEditingController.text = result.displayName;
        }
        _destError = null;
      });
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
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
      final updatedTrip = widget.trip.copyWith(
        name: _nameController.text.trim(),
        destination: _destController.text.trim(),
        fromDate: _fromDate,
        toDate: _toDate,
        tripType: _selectedTripType,
        totalBudget: budget,
        coverColor: _coverColor,
      );

      await ref.read(tripRepositoryProvider).updateTrip(updatedTrip);
      ref.invalidate(allTripsProvider);
      ref.invalidate(selectedTripProvider);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Trip details updated successfully! ✨'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update trip: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
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
                          fontFamily: 'DM Sans',
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

                      // 2. Destination with Pin on Map + MapLibre Suggestions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Destination',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.deepEarth,
                            ),
                          ),
                          InkWell(
                            onTap: () => _openMapPinPicker(_destController),
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Row(
                                children: [
                                  Icon(Icons.pin_drop_rounded, size: 14, color: Color(0xFFEA4335)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Pin on Map',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFEA4335),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Autocomplete<LocationResult>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<LocationResult>.empty();
                          }
                          return _placePredictions;
                        },
                        displayStringForOption: (LocationResult option) => option.displayName,
                        onSelected: (LocationResult selection) {
                          _destController.text = selection.displayName;
                          if (_destError != null) setState(() => _destError = null);
                        },
                        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                          if (textEditingController.text != _destController.text && !focusNode.hasFocus) {
                            textEditingController.text = _destController.text;
                          }

                          textEditingController.addListener(() {
                            if (focusNode.hasFocus) {
                              _destController.text = textEditingController.text;
                              if (_destError != null) setState(() => _destError = null);
                              _fetchPlaces(textEditingController.text);
                            }
                          });

                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search destination on MapLibre...',
                              hintStyle: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 15,
                                color: AppColors.muted,
                              ),
                              errorText: _destError,
                              prefixIcon: const Icon(
                                Icons.location_on_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isLoadingPlaces)
                                    Container(
                                      width: 18,
                                      height: 18,
                                      margin: const EdgeInsets.only(right: 10),
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                      ),
                                    ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.map_rounded,
                                      color: Color(0xFFEA4335),
                                      size: 20,
                                    ),
                                    tooltip: 'Pin location on Map',
                                    onPressed: () => _openMapPinPicker(textEditingController),
                                  ),
                                ],
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
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 6.0,
                              borderRadius: BorderRadius.circular(16),
                              shadowColor: Colors.black.withValues(alpha: 0.15),
                              child: Container(
                                width: MediaQuery.of(context).size.width - 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
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
                                          Icon(Icons.map_rounded, size: 14, color: AppColors.primary),
                                          SizedBox(width: 6),
                                          Text(
                                            'Place Suggestions',
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
                                    Flexible(
                                      child: ListView.separated(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: options.length,
                                        separatorBuilder: (_, __) =>
                                            const Divider(height: 1, color: AppColors.cardBorder),
                                        itemBuilder: (BuildContext context, int index) {
                                          final LocationResult option = options.elementAt(index);
                                          return ListTile(
                                            dense: true,
                                            leading: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.location_on_rounded,
                                                color: AppColors.primary,
                                                size: 16,
                                              ),
                                            ),
                                            title: Text(
                                              option.mainText ?? option.displayName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontFamily: 'DM Sans',
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            subtitle: option.secondaryText != null
                                                ? Text(
                                                    option.secondaryText!,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontFamily: 'DM Sans',
                                                      fontSize: 11,
                                                      color: AppColors.muted,
                                                    ),
                                                  )
                                                : null,
                                            onTap: () => onSelected(option),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),

                      // 3. Travel Dates Picker (Unified layout)
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
                                    fontFamily: 'DM Sans',
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
                                    fontFamily: 'DM Sans',
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
                              fontFamily: 'DM Sans',
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
                          fontFamily: 'DM Sans',
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
                          fontFamily: 'DM Sans',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: '0',
                          prefixText: '₱ ',
                          prefixStyle: const TextStyle(
                            fontFamily: 'DM Sans',
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
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepEarth,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _EditTripTypeCarousel(
                        selectedTripType: _selectedTripType,
                        onTypeSelected: (option) {
                          setState(() {
                            _selectedTripType = option.id.toLowerCase();
                            _coverColor = '#${option.accentColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
                          });
                        },
                      ),
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
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Trip Type Carousel Matching CreateTrip DetailsStep
// ─────────────────────────────────────────────────────────────────────────────

class _EditTripTypeCarousel extends StatefulWidget {
  final String selectedTripType;
  final ValueChanged<TripTypeOption> onTypeSelected;

  const _EditTripTypeCarousel({
    required this.selectedTripType,
    required this.onTypeSelected,
  });

  @override
  State<_EditTripTypeCarousel> createState() => _EditTripTypeCarouselState();
}

class _EditTripTypeCarouselState extends State<_EditTripTypeCarousel> {
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
  void didUpdateWidget(_EditTripTypeCarousel oldWidget) {
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
    return SizedBox(
      height: 155,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final realIndex = index % _count;
          final option = AppTripTypes.all[realIndex];
          final isSelected = realIndex == _currentRealIndex;

          final accentLight = HSLColor.fromColor(option.accentColor)
              .withLightness(
                (HSLColor.fromColor(option.accentColor).lightness + 0.18).clamp(0.0, 1.0),
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
                      final curPage = _pageController.page?.round() ?? index;
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
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        colors: [option.accentColor, accentLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: option.accentColor.withValues(alpha: isSelected ? 0.38 : 0.15),
                          blurRadius: isSelected ? 16 : 8,
                          spreadRadius: isSelected ? 2 : 0,
                          offset: Offset(0, isSelected ? 8 : 4),
                        ),
                      ],
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: isSelected ? 2.5 : 0,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                option.emoji,
                                style: const TextStyle(fontSize: 32),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check, size: 12, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text(
                                        'Selected',
                                        style: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.label,
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                option.subtitle,
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
