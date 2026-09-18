import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/models/user_vehicle_model.dart';
import '../../../core/providers/user_vehicles_provider.dart';
import '../../../core/services/fuel_price_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_responsive.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/buttons/app_back_button.dart';
import '../../../core/widgets/inputs/location_picker.dart';
import '../../profile/widgets/user_vehicles_sheet.dart';
import '../models/new_trip_model.dart';

enum LandTransportType {
  private,
  commute,
  rental;

  String get label {
    switch (this) {
      case LandTransportType.private:
        return 'Private Vehicle';
      case LandTransportType.commute:
        return 'Public Commute';
      case LandTransportType.rental:
        return 'Van / Car Rental';
    }
  }

  String get subtitle {
    switch (this) {
      case LandTransportType.private:
        return 'Own car, motorcycle, or squad convoy';
      case LandTransportType.commute:
        return 'Bus, jeepney, tricycle, or UV Express';
      case LandTransportType.rental:
        return 'Van hire, rented car, or chartered coaster';
    }
  }

  String get emoji {
    switch (this) {
      case LandTransportType.private:
        return '🚗';
      case LandTransportType.commute:
        return '🚌';
      case LandTransportType.rental:
        return '🚐';
    }
  }

  IconData get icon {
    switch (this) {
      case LandTransportType.private:
        return Icons.directions_car_rounded;
      case LandTransportType.commute:
        return Icons.directions_bus_rounded;
      case LandTransportType.rental:
        return Icons.airport_shuttle_rounded;
    }
  }
}

class LandTransitHub {
  final String name;
  final String shortLabel;
  final double lat;
  final double lon;
  final String icon;

  const LandTransitHub({
    required this.name,
    required this.shortLabel,
    required this.lat,
    required this.lon,
    required this.icon,
  });
}

class TransportStep extends ConsumerStatefulWidget {
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
  ConsumerState<TransportStep> createState() => _TransportStepState();
}

class _TransportStepState extends ConsumerState<TransportStep> {
  LandTransportType _modeType = LandTransportType.private;

  // Mode A: Private Vehicle state
  UserVehicle? _selectedGarageVehicle;
  double _customKmPerLiter = 12.0;
  FuelType _selectedFuelType = FuelType.gasoline;
  bool _splitGas = true;
  bool _splitTolls = true;
  final _tollCostCtrl = TextEditingController();
  int _vehicleCount = 1;

  // Mode B: Commute state
  String _commuteType = 'bus';
  final _farePerPaxCtrl = TextEditingController();
  final _busLineCtrl = TextEditingController();

  // Mode C: Rental state
  String _rentalType = 'van_hire';
  final _dailyRateCtrl = TextEditingController(text: '3500');
  int _rentalDays = 1;
  bool _hasDriver = true;
  final _driverFeeCtrl = TextEditingController(text: '500');
  bool _rentalFuelIncluded = false;
  bool _rentalTollsIncluded = false;

  // Common fields
  final _departureCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  double? _departureLat;
  double? _departureLng;
  double? _calculatedDistanceKm;

  // Major Philippine Land Transit Hubs (strictly land-based)
  static const List<LandTransitHub> _presetLandHubs = [
    LandTransitHub(
      name: 'Parañaque Integrated Terminal Exchange (PITX)',
      shortLabel: 'PITX Terminal',
      lat: 14.5103,
      lon: 120.9912,
      icon: '🚌',
    ),
    LandTransitHub(
      name: 'Araneta Center Bus Port, Cubao, Quezon City',
      shortLabel: 'Cubao Bus Port',
      lat: 14.6219,
      lon: 121.0544,
      icon: '🚌',
    ),
    LandTransitHub(
      name: 'Buendia / Gil Puyat Bus Terminal, Pasay',
      shortLabel: 'Buendia Terminal',
      lat: 14.5542,
      lon: 120.9995,
      icon: '🚌',
    ),
    LandTransitHub(
      name: 'Dau Central Bus Terminal, Mabalacat, Pampanga',
      shortLabel: 'Dau Bus Terminal',
      lat: 15.1764,
      lon: 120.5901,
      icon: '🚌',
    ),
    LandTransitHub(
      name: 'Baguio Grand Terminal, Gov. Pack Road, Baguio City',
      shortLabel: 'Baguio Grand Terminal',
      lat: 16.4087,
      lon: 120.5985,
      icon: '🚌',
    ),
    LandTransitHub(
      name: 'Cebu South Bus Terminal, N. Bacalso Ave, Cebu City',
      shortLabel: 'Cebu South Bus Terminal',
      lat: 10.3015,
      lon: 123.8932,
      icon: '🚌',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final tripDays = widget.trip.fromDate != null && widget.trip.toDate != null
        ? widget.trip.toDate!.difference(widget.trip.fromDate!).inDays + 1
        : 3;
    _rentalDays = tripDays > 0 ? tripDays : 1;

    if (widget.initial != null) {
      final init = widget.initial!;
      _departureCtrl.text = init.departurePoint ?? '';
      _departureLat = init.departureLat ?? widget.trip.departureLat;
      _departureLng = init.departureLng ?? widget.trip.departureLng;
      _durationCtrl.text = init.estimatedDuration;
      _notesCtrl.text = init.notes ?? '';
      _splitGas = init.splitGas;

      if (init.tripTransportMode == 'commute' || init.mode == TransportMode.commute || init.mode == TransportMode.bus) {
        _modeType = LandTransportType.commute;
        _commuteType = init.commuteType ?? 'bus';
        if (init.farePerPax != null && init.farePerPax! > 0) {
          _farePerPaxCtrl.text = init.farePerPax!.toStringAsFixed(0);
        }
        _busLineCtrl.text = init.operatorName ?? '';
      } else if (init.tripTransportMode == 'rental' || init.mode == TransportMode.vanHire) {
        _modeType = LandTransportType.rental;
        _rentalType = init.rentalType ?? 'van_hire';
        if (init.dailyRate != null && init.dailyRate! > 0) {
          _dailyRateCtrl.text = init.dailyRate!.toStringAsFixed(0);
        }
        _rentalDays = init.rentalDays ?? _rentalDays;
        _hasDriver = init.hasDriver;
        if (init.driverFeePerDay != null) {
          _driverFeeCtrl.text = init.driverFeePerDay!.toStringAsFixed(0);
        }
        _rentalFuelIncluded = init.fuelIncluded;
        _rentalTollsIncluded = init.tollsIncluded;
      } else {
        _modeType = LandTransportType.private;
        _customKmPerLiter = init.kmPerLiter ?? 14.0;
        _splitTolls = init.splitTolls;
        if (init.estimatedTollCost != null && init.estimatedTollCost! > 0) {
          _tollCostCtrl.text = init.estimatedTollCost!.toStringAsFixed(0);
        }
        _vehicleCount = init.vehicleCount ?? 1;
      }
    } else {
      _departureCtrl.text = widget.trip.departurePoint ?? '';
      _departureLat = widget.trip.departureLat;
      _departureLng = widget.trip.departureLng;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recalculateDistanceAndEstimate();
    });
  }

  @override
  void dispose() {
    _departureCtrl.dispose();
    _durationCtrl.dispose();
    _notesCtrl.dispose();
    _tollCostCtrl.dispose();
    _farePerPaxCtrl.dispose();
    _busLineCtrl.dispose();
    _dailyRateCtrl.dispose();
    _driverFeeCtrl.dispose();
    super.dispose();
  }

  void _recalculateDistanceAndEstimate() {
    final depLat = _departureLat;
    final depLng = _departureLng;
    final destLat = widget.trip.destinationLat;
    final destLng = widget.trip.destinationLng;

    if (depLat == null || depLng == null || destLat == null || destLng == null) {
      return;
    }

    final straightDistance = _calculateHaversineDistance(depLat, depLng, destLat, destLng);
    final estimatedRoadKm = straightDistance * 1.35; // typical winding road factor in PH
    final speedKmh = _modeType == LandTransportType.commute ? 40.0 : 55.0;
    final totalHours = estimatedRoadKm / speedKmh;

    final hours = totalHours.floor();
    final minutes = ((totalHours - hours) * 60).round();
    final formattedTime = hours > 0
        ? '~${hours}h ${minutes > 0 ? '${minutes}m' : ''}'
        : '~${math.max(15, minutes)}m';

    setState(() {
      _calculatedDistanceKm = estimatedRoadKm;
      if (_durationCtrl.text.isEmpty || _durationCtrl.text.startsWith('~')) {
        _durationCtrl.text = formattedTime;
      }
    });
  }

  double _calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  double _computeEstimatedFuelCost() {
    final distance = _calculatedDistanceKm ?? 100.0;
    final kml = _selectedGarageVehicle?.kmPerLiter ?? _customKmPerLiter;
    final fuelType = _selectedGarageVehicle?.fuelType ?? _selectedFuelType;
    return FuelPriceService.calculateFuelCost(
      distanceKm: distance,
      kmPerLiter: kml > 0 ? kml : 12.0,
      fuelType: fuelType,
    );
  }

  double _computeTotalRentalCost() {
    final daily = double.tryParse(_dailyRateCtrl.text.replaceAll(',', '')) ?? 3500.0;
    final driverDaily = _hasDriver
        ? (double.tryParse(_driverFeeCtrl.text.replaceAll(',', '')) ?? 500.0)
        : 0.0;
    final baseRental = (daily * _rentalDays) + (driverDaily * _rentalDays);
    final fuelAddition = !_rentalFuelIncluded ? _computeEstimatedFuelCost() : 0.0;
    return baseRental + fuelAddition;
  }

  void _submit() {
    TransportDetail detail;

    if (_modeType == LandTransportType.private) {
      final kml = _selectedGarageVehicle?.kmPerLiter ?? _customKmPerLiter;
      final fuelType = _selectedGarageVehicle?.fuelType ?? _selectedFuelType;
      final fuelCost = _computeEstimatedFuelCost();
      final tolls = double.tryParse(_tollCostCtrl.text.replaceAll(',', '')) ?? 0.0;
      final totalPrivateCost = (fuelCost + tolls) * _vehicleCount;

      detail = TransportDetail(
        mode: TransportMode.car,
        tripTransportMode: 'private',
        vehicleCount: _vehicleCount,
        departurePoint: _departureCtrl.text.trim().isEmpty ? null : _departureCtrl.text.trim(),
        departureLat: _departureLat,
        departureLng: _departureLng,
        vehicleId: _selectedGarageVehicle?.id,
        vehicleName: _selectedGarageVehicle?.name ?? 'Personal Vehicle',
        vehicleType: _selectedGarageVehicle?.type.name ?? 'sedan',
        fuelType: fuelType.name,
        kmPerLiter: kml,
        splitGas: _splitGas,
        splitTolls: _splitTolls,
        estimatedTollCost: tolls,
        estimatedCost: totalPrivateCost > 0 ? totalPrivateCost : null,
        estimatedDuration: _durationCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
    } else if (_modeType == LandTransportType.commute) {
      final farePerPax = double.tryParse(_farePerPaxCtrl.text.replaceAll(',', ''));
      final passengerCount = widget.trip.travelers.isNotEmpty ? widget.trip.travelers.length : 1;
      final totalFare = farePerPax != null ? farePerPax * passengerCount : null;

      detail = TransportDetail(
        mode: TransportMode.commute,
        tripTransportMode: 'commute',
        commuteType: _commuteType,
        transitHubName: _departureCtrl.text.trim().isEmpty ? null : _departureCtrl.text.trim(),
        operatorName: _busLineCtrl.text.trim().isEmpty ? null : _busLineCtrl.text.trim(),
        departurePoint: _departureCtrl.text.trim().isEmpty ? null : _departureCtrl.text.trim(),
        departureLat: _departureLat,
        departureLng: _departureLng,
        farePerPax: farePerPax,
        estimatedCost: totalFare,
        estimatedDuration: _durationCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
    } else {
      final totalRental = _computeTotalRentalCost();
      final daily = double.tryParse(_dailyRateCtrl.text.replaceAll(',', '')) ?? 3500.0;
      final driverDaily = _hasDriver
          ? (double.tryParse(_driverFeeCtrl.text.replaceAll(',', '')) ?? 500.0)
          : 0.0;

      detail = TransportDetail(
        mode: TransportMode.vanHire,
        tripTransportMode: 'rental',
        rentalType: _rentalType,
        dailyRate: daily,
        rentalDays: _rentalDays,
        hasDriver: _hasDriver,
        driverFeePerDay: driverDaily,
        fuelIncluded: _rentalFuelIncluded,
        tollsIncluded: _rentalTollsIncluded,
        totalRentalCost: totalRental,
        departurePoint: _departureCtrl.text.trim().isEmpty ? null : _departureCtrl.text.trim(),
        departureLat: _departureLat,
        departureLng: _departureLng,
        estimatedCost: totalRental,
        estimatedDuration: _durationCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
    }

    widget.trip.departurePoint = detail.departurePoint;
    widget.trip.departureLat = detail.departureLat;
    widget.trip.departureLng = detail.departureLng;
    widget.trip.transportDetail = detail;

    widget.onNext(detail);
  }

  @override
  Widget build(BuildContext context) {
    final defaultGarageVehicle = ref.watch(defaultUserVehicleProvider);
    if (_selectedGarageVehicle == null && defaultGarageVehicle != null) {
      _selectedGarageVehicle = defaultGarageVehicle;
    }

    return Scaffold(
      backgroundColor: AppColors.deepEarth,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A0A04), AppColors.deepEarth],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                AppBackButton(
                  variant: AppBackButtonVariant.glass,
                  onPressed: widget.onBack,
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Step 2 of 4', style: TextStyle(fontSize: 12, color: Colors.white54)),
                      Text(
                        'Land Transportation',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontHeading,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    '🇵🇭 PH Routes',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable Body ─────────────────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 20, 20, context.safeBottomPadding(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tri-Modal Hero Selector
                    const Text(
                      'Choose Land Travel Mode',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTriModalSelector(),

                    const SizedBox(height: 18),

                    // Route Distance & Travel Time Header
                    _buildRouteEstimateBar(),

                    const SizedBox(height: 18),

                    // Mode-Specific Forms
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _buildSelectedModeSubform(),
                    ),

                    const SizedBox(height: 24),

                    // Next Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue to Budget & Expenses',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 1. Tri-Modal Hero Card Selector ────────────────────────────────────────
  Widget _buildTriModalSelector() {
    return Column(
      children: LandTransportType.values.map((type) {
        final isSelected = _modeType == type;
        return GestureDetector(
          onTap: () {
            setState(() {
              _modeType = type;
              _recalculateDistanceAndEstimate();
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.sand : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.cardBorder,
                width: isSelected ? 1.8 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isSelected ? 0.06 : 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      type.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        type.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.black26,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── 2. Route & Distance Estimate Bar ───────────────────────────────────────
  Widget _buildRouteEstimateBar() {
    final dist = _calculatedDistanceKm;
    final dur = _durationCtrl.text;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C1A14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.alt_route_rounded, size: 18, color: AppColors.primaryLight),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ESTIMATED HIGHWAY ROUTE',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white54, letterSpacing: 0.5),
                  ),
                  Text(
                    dist != null ? '${dist.toStringAsFixed(0)} km highway drive' : 'Distance calculating...',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
          if (dur.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                dur,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  // ── 3. Adaptive Sub-Forms ──────────────────────────────────────────────────
  Widget _buildSelectedModeSubform() {
    switch (_modeType) {
      case LandTransportType.private:
        return _buildPrivateModeForm();
      case LandTransportType.commute:
        return _buildCommuteModeForm();
      case LandTransportType.rental:
        return _buildRentalModeForm();
    }
  }

  // ── Mode A: Private Vehicle Sub-form ───────────────────────────────────────
  Widget _buildPrivateModeForm() {
    final vehiclesAsync = ref.watch(userVehiclesProvider);
    final fuelCost = _computeEstimatedFuelCost();

    return Container(
      key: const ValueKey('private_form'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Vehicle & Fuel Spec',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              TextButton.icon(
                onPressed: () => UserVehiclesSheet.show(context),
                icon: const Icon(Icons.garage_rounded, size: 16),
                label: const Text('Manage Garage', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Garage quick-select dropdown
          vehiclesAsync.maybeWhen(
            data: (vehicles) {
              if (vehicles.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'No vehicles in garage. Using standard 14 km/L gasoline benchmark.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                      TextButton(
                        onPressed: () => UserVehiclesSheet.show(context),
                        child: const Text('Add Vehicle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                );
              }

              return DropdownButtonFormField<UserVehicle>(
                initialValue: _selectedGarageVehicle ?? vehicles.first,
                items: vehicles.map((v) {
                  return DropdownMenuItem(
                    value: v,
                    child: Text('${v.type.emoji} ${v.name} (${v.kmPerLiter} km/L)'),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _selectedGarageVehicle = v;
                      _customKmPerLiter = v.kmPerLiter;
                      _selectedFuelType = v.fuelType;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Select Garage Vehicle',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),

          const SizedBox(height: 14),

          // Live Fuel Intelligence Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.sand,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text('⛽', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weekly DOE Fuel Intelligence',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                      Text(
                        'Est. Fuel Needed: ~${fuelCost > 0 ? CurrencyUtils.formatAmount(fuelCost) : '₱0.00'} (${_calculatedDistanceKm != null ? FuelPriceService.calculateLitersNeeded(_calculatedDistanceKm!, _selectedGarageVehicle?.kmPerLiter ?? _customKmPerLiter).toStringAsFixed(1) : '0'} L)',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.deepEarth),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Departure Point Picker
          _buildDepartureField('Meet-up / Departure Point'),

          const SizedBox(height: 14),

          // Convoy vehicle count
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Convoy Vehicles', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _vehicleCount > 1
                              ? () => setState(() => _vehicleCount--)
                              : null,
                        ),
                        Text('$_vehicleCount ${_vehicleCount == 1 ? 'vehicle' : 'vehicles'}',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => setState(() => _vehicleCount++),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _tollCostCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Est. Tollways (RFID)',
                    prefixText: '₱ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Split Gas Switch
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Split Gas & Tolls with Travelers', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: const Text('Generates itemized proposal in group expenses tab', style: TextStyle(fontSize: 12)),
            value: _splitGas,
            onChanged: (v) => setState(() => _splitGas = v),
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  // ── Mode B: Commute Sub-form ───────────────────────────────────────────────
  Widget _buildCommuteModeForm() {
    final fare = double.tryParse(_farePerPaxCtrl.text.replaceAll(',', '')) ?? 0.0;
    final pax = widget.trip.travelers.isNotEmpty ? widget.trip.travelers.length : 1;
    final totalFare = fare * pax;

    return Container(
      key: const ValueKey('commute_form'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Public Transit Details',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),

          // Land Transit Hub Presets
          const Text(
            'Philippine Land Transit Hubs (Tap to set departure):',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _presetLandHubs.map((hub) {
              return ActionChip(
                label: Text(hub.shortLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                avatar: Text(hub.icon),
                backgroundColor: AppColors.surfaceLight,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onPressed: () {
                  setState(() {
                    _departureCtrl.text = hub.name;
                    _departureLat = hub.lat;
                    _departureLng = hub.lon;
                    _recalculateDistanceAndEstimate();
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Departure Field
          _buildDepartureField('Bus Terminal / Departure Point'),

          const SizedBox(height: 14),

          // Bus Line / Operator
          TextField(
            controller: _busLineCtrl,
            decoration: InputDecoration(
              labelText: 'Bus Line / Operator (Optional)',
              hintText: 'e.g. Victory Liner, Genesis JoyBus, UV Express',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),

          const SizedBox(height: 14),

          // Fare Per Pax
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _farePerPaxCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Fare / Ticket Per Pax',
                    prefixText: '₱ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('GROUP COMMITMENT ($pax pax)', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      Text(
                        CurrencyUtils.formatAmount(totalFare),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepEarth),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Mode C: Rental Sub-form ────────────────────────────────────────────────
  Widget _buildRentalModeForm() {
    final totalRental = _computeTotalRentalCost();
    final memberCount = widget.trip.travelers.isNotEmpty ? widget.trip.travelers.length : 1;
    final perMemberShare = totalRental / memberCount;

    return Container(
      key: const ValueKey('rental_form'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chartered Van / Car Rental Pricing',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),

          // Daily Rate & Days Counter
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _dailyRateCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Daily Rental Rate',
                    prefixText: '₱ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rental Duration', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _rentalDays > 1 ? () => setState(() => _rentalDays--) : null,
                        ),
                        Text('$_rentalDays ${_rentalDays == 1 ? 'day' : 'days'}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => setState(() => _rentalDays++),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Driver Inclusion Switch
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Driver Included in Charter', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: const Text('Includes driver daily meal & per diem', style: TextStyle(fontSize: 12)),
            value: _hasDriver,
            onChanged: (v) => setState(() => _hasDriver = v),
            activeThumbColor: AppColors.primary,
          ),

          if (_hasDriver) ...[
            TextField(
              controller: _driverFeeCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Driver Daily Allowance / Meals',
                prefixText: '₱ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
          ],

          // Fuel Policy Toggle
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Fuel Included in Rental Package', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text(
              _rentalFuelIncluded
                  ? 'Rental agency covers gas'
                  : 'Group splits pump fuel (~${CurrencyUtils.formatAmount(_computeEstimatedFuelCost())})',
              style: const TextStyle(fontSize: 12),
            ),
            value: _rentalFuelIncluded,
            onChanged: (v) => setState(() => _rentalFuelIncluded = v),
            activeThumbColor: AppColors.primary,
          ),

          const SizedBox(height: 10),

          // Total Rental Shared Pool Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.sand,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL RENTAL COMMITMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    Text(
                      CurrencyUtils.formatAmount(totalRental),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.deepEarth),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('PER MEMBER ($memberCount)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    Text(
                      CurrencyUtils.formatAmount(perMemberShare),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Departure Field Input ──────────────────────────────────────────────────
  Widget _buildDepartureField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        LocationPicker(
          label: label,
          hint: 'Tap pin or type meet-up location...',
          initialValue: _departureCtrl.text,
          initialLat: _departureLat,
          initialLon: _departureLng,
          onLocationSelected: (result) {
            if (result != null) {
              setState(() {
                _departureCtrl.text = result.displayName;
                _departureLat = result.lat;
                _departureLng = result.lon;
                _recalculateDistanceAndEstimate();
              });
            }
          },
        ),
      ],
    );
  }
}
