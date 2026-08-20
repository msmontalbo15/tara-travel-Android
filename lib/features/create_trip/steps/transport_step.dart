import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/widgets/inputs/map_pin_picker_modal.dart';
import '../../../core/utils/currency_utils.dart';
import '../models/new_trip_model.dart';

class TransportPresetHub {
  final String name;
  final String shortLabel;
  final double lat;
  final double lon;
  final TransportCategory category;
  final String icon;

  const TransportPresetHub({
    required this.name,
    required this.shortLabel,
    required this.lat,
    required this.lon,
    required this.category,
    required this.icon,
  });
}

class TransportStep extends StatefulWidget {
  final NewTripModel trip;
  final TransportDetail? initial;
  final void Function(TransportDetail detail) onNext;
  final VoidCallback onBack;

  const TransportStep({
    super.key,
    required this.trip,
    this.initial,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<TransportStep> createState() => _TransportStepState();
}

class _TransportStepState extends State<TransportStep> with SingleTickerProviderStateMixin {
  TransportMode _selected = TransportMode.car;
  TransportCategory? _selectedCategoryFilter; // null = All
  int _vehicleCount = 1;
  final _departureCtrl = TextEditingController();
  final _flightCtrl = TextEditingController();
  final _operatorCtrl = TextEditingController(); // Airline, Shipping Line, Bus Co, etc.
  final _bookingRefCtrl = TextEditingController(); // PNR / Ticket / Confirmation
  final _pierCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _costCtrl = TextEditingController();

  double? _departureLat;
  double? _departureLng;
  bool _splitGas = true;
  bool _showAdvancedFields = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // Infinite Carousel controller & state
  late PageController _pageController;
  double _currentPage = 5000.0;
  static const int _virtualItemCount = 10000;

  // Common Philippine transportation modes (excluding 'other' for main selection)
  static const _allModes = [
    TransportMode.car,
    TransportMode.motorcycle,
    TransportMode.commute,
    TransportMode.jeepney,
    TransportMode.tricycle,
    TransportMode.bus,
    TransportMode.vanHire,
    TransportMode.ferry,
    TransportMode.plane,
    TransportMode.bike,
  ];

  // Popular Philippine Transportation Departure Hubs
  static const List<TransportPresetHub> _presetHubs = [
    TransportPresetHub(
      name: 'Ninoy Aquino International Airport (NAIA), Pasay',
      shortLabel: 'NAIA (MNL)',
      lat: 14.5086,
      lon: 121.0194,
      category: TransportCategory.air,
      icon: '✈️',
    ),
    TransportPresetHub(
      name: 'Clark International Airport (CRK), Pampanga',
      shortLabel: 'Clark (CRK)',
      lat: 15.1859,
      lon: 120.5596,
      category: TransportCategory.air,
      icon: '✈️',
    ),
    TransportPresetHub(
      name: 'Mactan-Cebu International Airport (MCIA), Cebu',
      shortLabel: 'Cebu (CEB)',
      lat: 10.3075,
      lon: 123.9794,
      category: TransportCategory.air,
      icon: '✈️',
    ),
    TransportPresetHub(
      name: 'Parañaque Integrated Terminal Exchange (PITX)',
      shortLabel: 'PITX Terminal',
      lat: 14.5103,
      lon: 120.9912,
      category: TransportCategory.land,
      icon: '🚌',
    ),
    TransportPresetHub(
      name: 'Araneta Center Bus Port, Cubao, Quezon City',
      shortLabel: 'Cubao Bus Port',
      lat: 14.6219,
      lon: 121.0544,
      category: TransportCategory.land,
      icon: '🚌',
    ),
    TransportPresetHub(
      name: 'Batangas Port Passenger Terminal, Batangas',
      shortLabel: 'Batangas Port',
      lat: 13.7565,
      lon: 121.0435,
      category: TransportCategory.sea,
      icon: '⛴️',
    ),
    TransportPresetHub(
      name: 'North Harbor Passenger Terminal, Manila',
      shortLabel: 'Manila North Harbor',
      lat: 14.6072,
      lon: 120.9572,
      category: TransportCategory.sea,
      icon: '⛴️',
    ),
    TransportPresetHub(
      name: 'Cebu City Pier 1 Terminal, Cebu',
      shortLabel: 'Cebu Pier 1',
      lat: 10.2936,
      lon: 123.9073,
      category: TransportCategory.sea,
      icon: '⛴️',
    ),
  ];

  List<TransportMode> get _filteredModes {
    if (_selectedCategoryFilter == null) return _allModes;
    return _allModes.where((m) => m.category == _selectedCategoryFilter).toList();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _selected = widget.initial!.mode;
      _vehicleCount = widget.initial!.vehicleCount ?? 1;
      _departureCtrl.text = widget.initial!.departurePoint ?? '';
      _departureLat = widget.initial!.departureLat ?? widget.trip.departureLat;
      _departureLng = widget.initial!.departureLng ?? widget.trip.departureLng;
      _flightCtrl.text = widget.initial!.flightNumber ?? '';
      _operatorCtrl.text = widget.initial!.operatorName ?? '';
      _bookingRefCtrl.text = widget.initial!.bookingReference ?? '';
      _pierCtrl.text = widget.initial!.pierName ?? '';
      _durationCtrl.text = widget.initial!.estimatedDuration;
      _splitGas = widget.initial!.splitGas;
      _notesCtrl.text = widget.initial!.notes ?? '';
      if (widget.initial!.estimatedCost != null && widget.initial!.estimatedCost! > 0) {
        _costCtrl.text = CurrencyUtils.formatAmount(widget.initial!.estimatedCost!);
      }
    } else {
      _departureCtrl.text = widget.trip.departurePoint ?? '';
      _departureLat = widget.trip.departureLat;
      _departureLng = widget.trip.departureLng;
    }

    _initCarouselController();

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();

    // Auto-calculate estimate if departure & destination are present
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recalculateSmartEstimate(autoSetDuration: _durationCtrl.text.isEmpty);
    });
  }

  void _initCarouselController() {
    final modes = _filteredModes;
    int initialIndex = modes.indexOf(_selected);
    if (initialIndex < 0) {
      initialIndex = 0;
      if (modes.isNotEmpty) {
        _selected = modes.first;
      }
    }

    final initialVirtualIndex = (_virtualItemCount ~/ 2) - ((_virtualItemCount ~/ 2) % (modes.isEmpty ? 1 : modes.length)) + initialIndex;
    _currentPage = initialVirtualIndex.toDouble();
    _pageController = PageController(
      initialPage: initialVirtualIndex,
      viewportFraction: 0.52,
    );

    _pageController.addListener(() {
      if (_pageController.hasClients) {
        setState(() {
          _currentPage = _pageController.page ?? _currentPage;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeCtrl.dispose();
    _departureCtrl.dispose();
    _flightCtrl.dispose();
    _operatorCtrl.dispose();
    _bookingRefCtrl.dispose();
    _pierCtrl.dispose();
    _durationCtrl.dispose();
    _notesCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  void _onSelectMode(TransportMode m) {
    setState(() {
      _selected = m;
    });
    _fadeCtrl.reset();
    _fadeCtrl.forward();
    _recalculateSmartEstimate(autoSetDuration: true);
  }

  void _onCategoryFilterChanged(TransportCategory? cat) {
    setState(() {
      _selectedCategoryFilter = cat;
    });
    _initCarouselController();
    _fadeCtrl.reset();
    _fadeCtrl.forward();
  }

  Future<void> _pickDepartureOnMap() async {
    final result = await MapPinPickerModal.show(
      context,
      initialAddress: _departureCtrl.text.trim(),
    );

    if (result != null) {
      setState(() {
        _departureCtrl.text = result.displayName;
        _departureLat = result.lat;
        _departureLng = result.lon;
        widget.trip.departurePoint = result.displayName;
        widget.trip.departureLat = result.lat;
        widget.trip.departureLng = result.lon;
      });
      _recalculateSmartEstimate(autoSetDuration: true);
    }
  }

  void _selectPresetHub(TransportPresetHub hub) {
    setState(() {
      _departureCtrl.text = hub.name;
      _departureLat = hub.lat;
      _departureLng = hub.lon;
      widget.trip.departurePoint = hub.name;
      widget.trip.departureLat = hub.lat;
      widget.trip.departureLng = hub.lon;

      // Auto-switch mode if compatible
      if (hub.category == TransportCategory.air && _selected.category != TransportCategory.air) {
        _selected = TransportMode.plane;
      } else if (hub.category == TransportCategory.sea && _selected.category != TransportCategory.sea) {
        _selected = TransportMode.ferry;
      }
    });
    _recalculateSmartEstimate(autoSetDuration: true);
  }

  // ── Smart Distance & Duration Calculation ──────────────────────────────────
  double? _calculatedDistanceKm;
  String? _calculatedEstimatedTime;

  void _recalculateSmartEstimate({bool autoSetDuration = false}) {
    if (_departureLat == null ||
        _departureLng == null ||
        widget.trip.destinationLat == null ||
        widget.trip.destinationLng == null) {
      setState(() {
        _calculatedDistanceKm = null;
      });
      return;
    }

    final straightDistance = _calculateHaversineDistance(
      _departureLat!,
      _departureLng!,
      widget.trip.destinationLat!,
      widget.trip.destinationLng!,
    );

    // Apply typical road/winding path factor (1.35x for land, 1.15x for air/sea)
    double roadFactor = 1.35;
    if (_selected == TransportMode.plane) {
      roadFactor = 1.05;
    } else if (_selected == TransportMode.ferry) {
      roadFactor = 1.20;
    }

    final estimatedDistance = straightDistance * roadFactor;
    final speed = _selected.averageSpeedKmh;
    final totalHours = estimatedDistance / speed;

    final hours = totalHours.floor();
    final minutes = ((totalHours - hours) * 60).round();

    String formattedTime;
    if (hours > 0) {
      formattedTime = '~${hours}h ${minutes > 0 ? '${minutes}m' : ''}';
    } else {
      formattedTime = '~${math.max(15, minutes)}m';
    }

    setState(() {
      _calculatedDistanceKm = estimatedDistance;
      _calculatedEstimatedTime = formattedTime;
    });

    if (autoSetDuration && (_durationCtrl.text.isEmpty || _durationCtrl.text.startsWith('~'))) {
      _durationCtrl.text = formattedTime;
    }
  }

  double _calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R * asin... Earth diameter = 12742 km
  }

  void _syncCostToBudget(double cost) {
    // Find Transportation category in draft budget and pre-fill if 0
    for (final cat in widget.trip.budgetBreakdown) {
      if (cat.name.toLowerCase().contains('transport') || cat.name.toLowerCase().contains('flight')) {
        if (cat.amount == 0 || cat.amount < cost) {
          cat.amount = cost;
        }
        break;
      }
    }
  }

  void _submit() {
    final cleanCost = _costCtrl.text.replaceAll(',', '').trim();
    final parsedCost = double.tryParse(cleanCost);

    if (parsedCost != null && parsedCost > 0) {
      _syncCostToBudget(parsedCost);
    }

    widget.trip.departurePoint = _departureCtrl.text.trim().isEmpty ? null : _departureCtrl.text.trim();
    widget.trip.departureLat = _departureLat;
    widget.trip.departureLng = _departureLng;

    widget.onNext(TransportDetail(
      mode: _selected,
      vehicleCount: _vehicleCount,
      departurePoint: _departureCtrl.text.trim().isEmpty ? null : _departureCtrl.text.trim(),
      departureLat: _departureLat,
      departureLng: _departureLng,
      flightNumber: _flightCtrl.text.trim().isEmpty ? null : _flightCtrl.text.trim(),
      operatorName: _operatorCtrl.text.trim().isEmpty ? null : _operatorCtrl.text.trim(),
      bookingReference: _bookingRefCtrl.text.trim().isEmpty ? null : _bookingRefCtrl.text.trim(),
      pierName: _pierCtrl.text.trim().isEmpty ? null : _pierCtrl.text.trim(),
      estimatedDuration: _durationCtrl.text.trim(),
      estimatedCost: parsedCost,
      splitGas: _splitGas,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepEarth,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A0A04), AppColors.deepEarth],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onBack,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Step 2 of 4', style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: Colors.white54)),
                          Text('Transport Mode', style: TextStyle(fontFamily: 'Playfair Display', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                        ],
                      ),
                    ),
                    // Progress bar
                    Container(
                      width: 60,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.5,
                        child: Container(
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + MediaQuery.of(context).padding.bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Filter Pills
                    _buildCategoryFilterRow(),
                    const SizedBox(height: 14),

                    // Infinite Loop Animated Carousel Card
                    _buildInfiniteCarousel(),

                    const SizedBox(height: 20),

                    // Route Summary & Distance Preview Card
                    _buildRoutePreviewCard(),

                    const SizedBox(height: 20),

                    // Dynamic Sub-fields & Form
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: _buildSubFields(),
                    ),

                    const SizedBox(height: 32),

                    // Next Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue to Budget',
                              style: TextStyle(fontFamily: 'DM Sans', fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterRow() {
    final categories = [
      (null, '✨ All Modes'),
      (TransportCategory.land, '🚗 Land'),
      (TransportCategory.air, '✈️ Flights'),
      (TransportCategory.sea, '⛴️ Sea Ferry'),
      (TransportCategory.eco, '🚲 Eco / Bike'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategoryFilter == cat.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                cat.$2,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.deepEarth,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => _onCategoryFilterChanged(cat.$1),
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              elevation: isSelected ? 2 : 0,
              pressElevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.cardBorder,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfiniteCarousel() {
    final modes = _filteredModes;
    if (modes.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(
          child: Text('No transportation modes found in this category',
              style: TextStyle(fontFamily: 'DM Sans', color: AppColors.muted)),
        ),
      );
    }

    return SizedBox(
      height: 155,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _virtualItemCount,
        onPageChanged: (index) {
          final m = modes[index % modes.length];
          if (_selected != m) {
            _onSelectMode(m);
          }
        },
        itemBuilder: (context, index) {
          final m = modes[index % modes.length];
          final isSelected = _selected == m;

          double pageDelta = (index - _currentPage).abs();
          double scale = (1.0 - (pageDelta * 0.15)).clamp(0.85, 1.0);
          double opacity = (1.0 - (pageDelta * 0.35)).clamp(0.6, 1.0);

          return Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  );
                  _onSelectMode(m);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.chipBackground : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.dividerLight,
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                            )
                          ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        m.emoji,
                        style: TextStyle(fontSize: isSelected ? 38 : 30),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        m.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: isSelected ? 13 : 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.deepEarth,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '~${m.averageSpeedKmh.round()} km/h',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppColors.primary : AppColors.warmMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoutePreviewCard() {
    final destination = widget.trip.destination.isNotEmpty ? widget.trip.destination : 'Destination';
    final departure = _departureCtrl.text.isNotEmpty ? _departureCtrl.text : 'Select departure point';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E100A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.route_rounded, size: 16, color: Color(0xFFD85A30)),
                  SizedBox(width: 6),
                  Text(
                    'ROUTE & ESTIMATE',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD85A30),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              if (_calculatedDistanceKm != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD85A30).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_calculatedDistanceKm!.toStringAsFixed(0)} km est.',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Route Visual Timeline
          Row(
            children: [
              // Left Icons Column
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 28,
                    color: Colors.white24,
                  ),
                  const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFEA4335)),
                ],
              ),
              const SizedBox(width: 12),

              // Labels Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      departure,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _departureCtrl.text.isNotEmpty ? Colors.white : Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      destination,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (_calculatedEstimatedTime != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFF331B13)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: Colors.white60),
                    const SizedBox(width: 6),
                    Text(
                      'Smart travel estimate via ${_selected.label}:',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                Text(
                  _calculatedEstimatedTime!,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEF9F27),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubFields() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(_selected.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    '${_selected.label} Details',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepEarth,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _selected.category.name.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Departure Hub / Point
          _buildDepartureField('Departure Point', 'Tap pin on map or enter location…', _departureCtrl),

          // Preset Quick Hubs Chips (Commuters only)
          if (_selected == TransportMode.commute) ...[
            const SizedBox(height: 10),
            _buildPresetHubsList(),
          ],

          const SizedBox(height: 14),

          // Mode-Specific Fields
          if (_selected == TransportMode.plane) ...[
            _buildTextField(
              label: 'Airline / Operator',
              hint: 'e.g. Philippine Airlines, Cebu Pacific, AirAsia',
              ctrl: _operatorCtrl,
              prefixIcon: Icons.flight_takeoff_rounded,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Flight Number',
                    hint: 'e.g. PR 2814, 5J 561',
                    ctrl: _flightCtrl,
                    prefixIcon: Icons.tag_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    label: 'Terminal / Gate',
                    hint: 'e.g. NAIA T2',
                    ctrl: _pierCtrl,
                    prefixIcon: Icons.meeting_room_rounded,
                  ),
                ),
              ],
            ),
          ],

          if (_selected == TransportMode.ferry) ...[
            _buildTextField(
              label: 'Shipping Line / Fastcraft',
              hint: 'e.g. 2GO Travel, OceanJet, Montenegro Lines',
              ctrl: _operatorCtrl,
              prefixIcon: Icons.directions_boat_rounded,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Port / Pier Name',
              hint: 'e.g. Batangas Port Pier 1, Caticlan Jetty Port',
              ctrl: _pierCtrl,
              prefixIcon: Icons.anchor_rounded,
            ),
          ],

          if (_selected == TransportMode.bus) ...[
            _buildTextField(
              label: 'Bus Line / Company',
              hint: 'e.g. Victory Liner, Genesis, DLTB, JoyBus',
              ctrl: _operatorCtrl,
              prefixIcon: Icons.directions_bus_rounded,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Terminal / Station',
              hint: 'e.g. Cubao Terminal, PITX Gate 3',
              ctrl: _pierCtrl,
              prefixIcon: Icons.storefront_rounded,
            ),
          ],

          if (_selected == TransportMode.car ||
              _selected == TransportMode.vanHire ||
              _selected == TransportMode.motorcycle) ...[
            _buildVehicleCountStepper(),
            const SizedBox(height: 12),
            _buildGasSplitToggle(),
          ],

          const SizedBox(height: 12),

          // Duration & Transport Cost Rows
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Travel Duration',
                  hint: 'e.g. ~4h 30m',
                  ctrl: _durationCtrl,
                  prefixIcon: Icons.schedule_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCostField(
                  label: _selected == TransportMode.plane || _selected == TransportMode.bus || _selected == TransportMode.ferry
                      ? 'Fare / Ticket'
                      : 'Est. Fuel / Fare',
                  ctrl: _costCtrl,
                ),
              ),
            ],
          ),

          // Advanced optional toggle
          const SizedBox(height: 14),
          InkWell(
            onTap: () => setState(() => _showAdvancedFields = !_showAdvancedFields),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    _showAdvancedFields ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _showAdvancedFields ? 'Hide additional info' : 'Add booking reference & notes',
                    style: const TextStyle(
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

          if (_showAdvancedFields) ...[
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Booking Ref / PNR / Plate Number',
              hint: 'e.g. PNR: 7Q89KM, Plate: NBD 1234',
              ctrl: _bookingRefCtrl,
              prefixIcon: Icons.confirmation_number_outlined,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Transport Notes',
              hint: 'e.g. Baggage allowance 20kg, Meetup at 5:00 AM',
              ctrl: _notesCtrl,
              prefixIcon: Icons.edit_note_rounded,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPresetHubsList() {
    final relevantHubs = _presetHubs.where((h) {
      if (_selected.category == TransportCategory.air) return h.category == TransportCategory.air;
      if (_selected.category == TransportCategory.sea) return h.category == TransportCategory.sea;
      return h.category == TransportCategory.land;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Philippine Hubs',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.warmMuted,
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: relevantHubs.map((hub) {
              final isPicked = _departureCtrl.text == hub.name;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ActionChip(
                  label: Text('${hub.icon} ${hub.shortLabel}'),
                  labelStyle: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    fontWeight: isPicked ? FontWeight.w700 : FontWeight.w500,
                    color: isPicked ? AppColors.primary : AppColors.deepEarth,
                  ),
                  backgroundColor: isPicked ? AppColors.sand : const Color(0xFFF9FAFB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isPicked ? AppColors.primary : const Color(0xFFE5E7EB),
                    ),
                  ),
                  onPressed: () => _selectPresetHub(hub),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDepartureField(String label, String hint, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.deepEarth),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: AppColors.muted),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            prefixIcon: const Icon(Icons.pin_drop_rounded, color: Color(0xFFEA4335), size: 20),
            suffixIcon: IconButton(
              icon: const Icon(Icons.map_rounded, color: AppColors.primary, size: 22),
              tooltip: 'Select on MapLibre Map',
              onPressed: _pickDepartureOnMap,
            ),
          ),
          onTap: () {
            if (ctrl.text.trim().isEmpty) {
              _pickDepartureOnMap();
            }
          },
          onChanged: (val) {
            _departureLat = null;
            _departureLng = null;
            _recalculateSmartEstimate();
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController ctrl,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.deepEarth),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: AppColors.muted),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.primary, size: 18) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCostField({
    required String label,
    required TextEditingController ctrl,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.deepEarth),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: AppColors.muted),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 12, right: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: 1.0,
                child: Text(
                  '₱',
                  style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
            ),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleCountStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Number of Vehicles',
                  style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.deepEarth),
                ),
                Text(
                  'Carpooling / Convoy fleet',
                  style: TextStyle(fontFamily: 'DM Sans', fontSize: 10, color: AppColors.warmMuted),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _stepperBtn(Icons.remove_rounded, () {
                if (_vehicleCount > 1) setState(() => _vehicleCount--);
              }),
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                child: Text(
                  '$_vehicleCount',
                  style: const TextStyle(fontFamily: 'DM Sans', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepEarth),
                ),
              ),
              _stepperBtn(Icons.add_rounded, () => setState(() => _vehicleCount++)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepperBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }

  Widget _buildGasSplitToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Split Gas & Tolls',
                  style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.deepEarth),
                ),
                Text(
                  'Include in group expense split',
                  style: TextStyle(fontFamily: 'DM Sans', fontSize: 10, color: AppColors.warmMuted),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _splitGas,
            onChanged: (v) => setState(() => _splitGas = v),
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}
