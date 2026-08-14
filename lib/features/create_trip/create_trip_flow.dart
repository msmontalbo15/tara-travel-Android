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
          _errorMessage = 'Could not create trip: ${e.toString().replaceAll('Exception: ', '')}';
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
          _errorMessage = 'Could not save draft: ${e.toString().replaceAll('Exception: ', '')}';
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
