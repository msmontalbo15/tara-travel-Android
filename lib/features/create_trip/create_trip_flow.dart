import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/trip_model.dart';
import '../../core/models/member_model.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/providers/selected_trip_provider.dart';
import '../../core/providers/trip_provider.dart';
import 'models/new_trip_model.dart';
import 'steps/details_step.dart';
import 'steps/transport_step.dart';
import 'steps/budget_step.dart';
import 'steps/confirm_step.dart';

class CreateTripFlow extends ConsumerStatefulWidget {
  const CreateTripFlow({super.key});

  @override
  ConsumerState<CreateTripFlow> createState() => _CreateTripFlowState();
}

class _CreateTripFlowState extends ConsumerState<CreateTripFlow> {
  final PageController _controller = PageController();
  final NewTripModel _draft = NewTripModel();
  bool _saving = false;

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
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final tripId = const Uuid().v4();
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
        members: _draft.travelers
            .map((t) => MemberModel(
                  id: 'new_${t.name.hashCode}',
                  name: t.name,
                  initials: t.initials,
                  color: Color(t.color),
                ))
            .toList(),
      );

      // Save to repository (local + Supabase)
      final tripRepo = ref.read(tripRepositoryProvider);
      await tripRepo.createTrip(trip);

      // Seed default packing items for this trip
      try {
        final packingRepo = ref.read(packingRepositoryProvider);
        await packingRepo.seedDefaultItems(tripId);
      } catch (e) {
        debugPrint('[CreateTripFlow] packing seed error: $e');
      }

      // Set as the selected trip and refresh the trip list
      ref.read(selectedTripIdProvider.notifier).select(tripId);
      ref.invalidate(allTripsProvider);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/trip-detail');
      }
    } catch (e) {
      debugPrint('[CreateTripFlow] confirm error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not create trip: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _handleSaveDraft() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final tripId = const Uuid().v4();
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
      );

      await ref.read(tripRepositoryProvider).createTrip(trip);
      ref.invalidate(allTripsProvider);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      debugPrint('[CreateTripFlow] saveDraft error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
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
              onNext: (detail) => _goTo(2),
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
              onConfirm: _handleConfirm,
              onSaveDraft: _handleSaveDraft,
            ),
          ],
        ),

        // Saving overlay
        if (_saving)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFFD85A30)),
                  SizedBox(height: 16),
                  Text(
                    'Creating your trip…',
                    style: TextStyle(
                        fontFamily: 'DM Sans',
                        color: Colors.white,
                        fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
