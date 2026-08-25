import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/trip_model.dart';
import '../../core/models/member_model.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/providers/selected_trip_provider.dart';
import '../../core/providers/trip_provider.dart';
import '../../core/utils/invite_code_generator.dart';
import 'models/new_trip_model.dart';
import 'steps/details_step.dart';
import 'steps/transport_step.dart';
import 'steps/budget_step.dart';
import 'steps/confirm_step.dart';
import 'widgets/trip_creation_loading_overlay.dart';

class CreateTripFlow extends ConsumerStatefulWidget {
  const CreateTripFlow({super.key});

  @override
  ConsumerState<CreateTripFlow> createState() => _CreateTripFlowState();
}

class _CreateTripFlowState extends ConsumerState<CreateTripFlow> {
  final PageController _controller = PageController();
  final NewTripModel _draft = NewTripModel();

  bool _saving = false;
  TripCreationLoadingMode _loadingMode = TripCreationLoadingMode.create;
  double _loadingProgress = 0.0;
  bool _isCompleted = false;
  String? _errorMessage;
  // Guard so prefill from route args is applied only once
  bool _didApplyPrefill = false;

  /// Applies optional prefill data passed via route arguments.
  ///
  /// A [NewTripModel] may be supplied when navigating from the starter
  /// templates carousel. Relevant fields are copied into [_draft] so that
  /// [DetailsStep] opens with those values already populated.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didApplyPrefill) return;
    _didApplyPrefill = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is NewTripModel) {
      if (args.destination.isNotEmpty) _draft.destination = args.destination;
      if (args.destinationLat != null) _draft.destinationLat = args.destinationLat;
      if (args.destinationLng != null) _draft.destinationLng = args.destinationLng;
      if (args.tripType.isNotEmpty) _draft.tripType = args.tripType;
      if (args.fromDate != null) _draft.fromDate = args.fromDate;
      if (args.toDate != null) _draft.toDate = args.toDate;
      if (args.coverColor != null) _draft.coverColor = args.coverColor;
    }
  }

  void _goTo(int step) {
    _controller.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (_saving && _errorMessage == null) return;
    
    setState(() {
      _saving = true;
      _loadingMode = TripCreationLoadingMode.create;
      _loadingProgress = 0.2;
      _isCompleted = false;
      _errorMessage = null;
    });

    try {
      final tripId = const Uuid().v4();
      // Convert int ARGB color → '#AARRGGBB' hex string expected by TripModel
      final coverColorHex = _draft.coverColor != null
          ? '#${_draft.coverColor!.toRadixString(16).padLeft(8, '0').toUpperCase()}'
          : null;

      // Encode TransportDetail into transport_mode + transport_meta
      final td = _draft.transportDetail;
      final transportMode = td?.mode.name;
      final transportMeta = td == null ? null : {
        'mode': td.mode.name,
        if (td.vehicleCount != null) 'vehicle_count': td.vehicleCount,
        if (td.flightNumber != null) 'flight_number': td.flightNumber,
        if (td.operatorName != null) 'operator_name': td.operatorName,
        if (td.bookingReference != null) 'booking_reference': td.bookingReference,
        if (td.pierName != null) 'pier_name': td.pierName,
        if (td.estimatedDuration.isNotEmpty) 'estimated_duration': td.estimatedDuration,
        if (td.estimatedCost != null) 'estimated_cost': td.estimatedCost,
        'split_gas': td.splitGas,
        if (td.notes != null) 'notes': td.notes,
      };

      final trip = TripModel(
        id: tripId,
        name: _draft.tripName.isEmpty ? 'My Trip' : _draft.tripName,
        destination:
            _draft.destination.isEmpty ? 'TBD' : _draft.destination,
        fromDate:
            _draft.fromDate ?? DateTime.now().add(const Duration(days: 7)),
        toDate: _draft.toDate ??
            DateTime.now().add(const Duration(days: 10)),
        tripType: _draft.tripType.toLowerCase(),
        totalBudget: _draft.totalBudget ?? 0,
        splitEqually: _draft.splitEqually,
        inviteCode: InviteCodeGenerator.generate(),
        coverColor: coverColorHex,
        departurePoint: _draft.transportDetail?.departurePoint,
        departureLat: _draft.departureLat,
        departureLng: _draft.departureLng,
        transportMode: transportMode,
        transportMeta: transportMeta,
        isDraft: false,
        members: _draft.travelers
            .map((t) => MemberModel(
                  id: t.id.isNotEmpty ? t.id : 'new_${t.name.hashCode}',
                  name: t.name,
                  initials: t.initials,
                  color: Color(t.color),
                  profilePhotoUrl: t.profilePhotoUrl,
                ))
            .toList(),
      );

      // Save trip to repository (local + Supabase)
      final tripRepo = ref.read(tripRepositoryProvider);
      await tripRepo.createTrip(trip);

      if (mounted) setState(() => _loadingProgress = 0.65);

      // Seed default packing items for this trip
      try {
        final packingRepo = ref.read(packingRepositoryProvider);
        await packingRepo.seedDefaultItems(tripId);
      } catch (e) {
        debugPrint('[CreateTripFlow] packing seed error: $e');
      }

      // Set as selected trip and refresh providers
      ref.read(selectedTripIdProvider.notifier).select(tripId);
      ref.invalidate(allTripsProvider);

      if (mounted) {
        setState(() {
          _loadingProgress = 1.0;
          _isCompleted = true;
        });
      }

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/trip-detail');
      }
    } catch (e) {
      debugPrint('[CreateTripFlow] confirm error: $e');
      if (mounted) {
        setState(() {
          _saving = false;
          _errorMessage = 'Supabase error: $e';
        });
      }
    }
  }

  Future<void> _handleSaveDraft() async {
    if (_saving && _errorMessage == null) return;
    
    setState(() {
      _saving = true;
      _loadingMode = TripCreationLoadingMode.draft;
      _loadingProgress = 0.3;
      _isCompleted = false;
      _errorMessage = null;
    });

    try {
      final tripId = const Uuid().v4();
      final coverColorHex = _draft.coverColor != null
          ? '#${_draft.coverColor!.toRadixString(16).padLeft(8, '0').toUpperCase()}'
          : null;

      // Encode TransportDetail into transport_mode + transport_meta
      final td = _draft.transportDetail;
      final transportMode = td?.mode.name;
      final transportMeta = td == null ? null : {
        'mode': td.mode.name,
        if (td.vehicleCount != null) 'vehicle_count': td.vehicleCount,
        if (td.flightNumber != null) 'flight_number': td.flightNumber,
        if (td.operatorName != null) 'operator_name': td.operatorName,
        if (td.bookingReference != null) 'booking_reference': td.bookingReference,
        if (td.pierName != null) 'pier_name': td.pierName,
        if (td.estimatedDuration.isNotEmpty) 'estimated_duration': td.estimatedDuration,
        if (td.estimatedCost != null) 'estimated_cost': td.estimatedCost,
        'split_gas': td.splitGas,
        if (td.notes != null) 'notes': td.notes,
      };

      final trip = TripModel(
        id: tripId,
        name: _draft.tripName.isEmpty ? 'Draft Trip' : _draft.tripName,
        destination: _draft.destination,
        fromDate:
            _draft.fromDate ?? DateTime.now().add(const Duration(days: 7)),
        toDate: _draft.toDate ??
            DateTime.now().add(const Duration(days: 10)),
        tripType: _draft.tripType.toLowerCase(),
        totalBudget: _draft.totalBudget ?? 0,
        splitEqually: _draft.splitEqually,
        inviteCode: InviteCodeGenerator.generate(),
        coverColor: coverColorHex,
        departurePoint: _draft.transportDetail?.departurePoint,
        departureLat: _draft.departureLat,
        departureLng: _draft.departureLng,
        transportMode: transportMode,
        transportMeta: transportMeta,
        isDraft: true,
      );

      await ref.read(tripRepositoryProvider).createTrip(trip);
      ref.invalidate(allTripsProvider);

      if (mounted) {
        setState(() {
          _loadingProgress = 1.0;
          _isCompleted = true;
        });
      }

      await Future.delayed(const Duration(milliseconds: 250));

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      debugPrint('[CreateTripFlow] saveDraft error: $e');
      if (mounted) {
        setState(() {
          _saving = false;
          _errorMessage = 'Supabase error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView(
          controller: _controller,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // Step 1 — Details
            DetailsStep(
              trip: _draft,
              onNext: () => _goTo(1),
              onCancel: () => Navigator.of(context).pop(),
            ),

            // Step 2 — Transport
            TransportStep(
              trip: _draft,
              initial: _draft.transportDetail,
              onNext: (detail) {
                _draft.transportDetail = detail;
                _goTo(2);
              },
              onBack: () => _goTo(0),
            ),

            // Step 3 — Budget
            BudgetStep(
              trip: _draft,
              onNext: () => _goTo(3),
              onBack: () => _goTo(1),
            ),

            // Step 4 — Confirm
            ConfirmStep(
              trip: _draft,
              onBack: () => _goTo(2),
              onEditStep: (stepIndex) => _goTo(stepIndex),
              onConfirm: _handleConfirm,
              onSaveDraft: _handleSaveDraft,
            ),
          ],
        ),

        // Enhanced Glassmorphic Saving Overlay
        if (_saving)
          TripCreationLoadingOverlay(
            trip: _draft,
            mode: _loadingMode,
            progress: _loadingProgress,
            isCompleted: _isCompleted,
            errorMessage: _errorMessage,
            onRetry: _loadingMode == TripCreationLoadingMode.create
                ? _handleConfirm
                : _handleSaveDraft,
            onCancel: () {
              if (mounted) {
                setState(() {
                  _saving = false;
                  _errorMessage = null;
                });
              }
            },
          ),
      ],
    );
  }
}
