import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/trip_provider.dart';
import '../../core/providers/selected_trip_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/models/trip_model.dart';

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTripsAsync = ref.watch(allTripsProvider);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.deepEarth,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A0A04), AppColors.deepEarth],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My Trips',
                          style: TextStyle(
                              fontFamily: 'Playfair Display',
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      SizedBox(height: 2),
                      Text('All your journeys',
                          style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13,
                              color: Colors.white54)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showJoinTripModal(context, ref),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.group_add_rounded, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/create-trip'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 4),
                        Text('New',
                            style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28)),
              ),
              child: allTripsAsync.when(
                data: (trips) {
                  // Split on real date, not just isArchived flag
                  final upcoming = trips
                      .where((t) => !t.isArchived && !t.toDate.isBefore(now))
                      .toList();
                  final past = trips
                      .where((t) => t.isArchived || t.toDate.isBefore(now))
                      .toList();

                  if (trips.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🌏',
                              style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 16),
                          const Text('No trips yet',
                              style: TextStyle(
                                  fontFamily: 'Playfair Display',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 6),
                          const Text('Start planning your first journey!',
                              style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 14,
                                  color: AppColors.muted)),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/create-trip'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text('Create a Trip',
                                  style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 80),
                    children: [
                      if (upcoming.isNotEmpty) ...[
                        _sectionHeader('UPCOMING'),
                        ...upcoming.map((t) => _TripListCard(
                              trip: t,
                              onTap: () {
                                 ref
                                     .read(selectedTripIdProvider.notifier)
                                     .select(t.id);
                                 Navigator.pushNamed(context, '/trip-detail');
                               },
                            )),
                      ],
                      if (past.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _sectionHeader('PAST TRIPS'),
                        ...past.map((t) => _TripListCard(
                              trip: t,
                              isArchived: true,
                              onTap: () {
                                 ref
                                     .read(selectedTripIdProvider.notifier)
                                     .select(t.id);
                                 Navigator.pushNamed(context, '/trip-detail');
                               },
                            )),
                      ],
                    ],
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          color: AppColors.warmMuted, size: 40),
                      const SizedBox(height: 12),
                      Text('Could not load trips\n$e',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: 'DM Sans',
                              color: AppColors.muted)),
                      const SizedBox(height: 16),
                      TextButton(
                          onPressed: () => ref.invalidate(allTripsProvider),
                          child: const Text('Retry')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.warmMuted,
              letterSpacing: 1.5)),
    );
  }

  void _showJoinTripModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _JoinTripSheet(ref: ref),
    );
  }
}

class _JoinTripSheet extends StatefulWidget {
  final WidgetRef ref;
  const _JoinTripSheet({required this.ref});

  @override
  State<_JoinTripSheet> createState() => _JoinTripSheetState();
}

class _JoinTripSheetState extends State<_JoinTripSheet> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = widget.ref.read(tripRepositoryProvider);
      await repo.joinTripByCode(code);
      
      // Refresh the trips list so the new trip shows up
      widget.ref.invalidate(allTripsProvider);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
             content: Text('Successfully joined trip!'),
             backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + keyboardSpace),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Join a Trip',
              style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Enter the 6-character invite code from your trip organizer.',
              style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            decoration: InputDecoration(
              hintText: 'e.g. TAR4BC',
              counterText: '',
              errorText: _error,
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
            onChanged: (v) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _join,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Join Trip',
                      style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Trip List Card ─────────────────────────────────────────────────────────────

class _TripListCard extends StatelessWidget {
  final TripModel trip;
  final bool isArchived;
  final VoidCallback onTap;

  const _TripListCard(
      {required this.trip, this.isArchived = false, required this.onTap});

  static const _typeEmoji = {
    'beach': '🏖️',
    'city': '🏙️',
    'adventure': '🏔️',
    'nature': '🌿',
    'cultural': '🏛️',
    // Capitalised keys for backwards compat
    'Beach': '🏖️',
    'City': '🏙️',
    'Adventure': '🏔️',
    'Nature': '🌿',
    'Cultural': '🏛️',
  };

  @override
  Widget build(BuildContext context) {
    final daysLeft = trip.fromDate.difference(DateTime.now()).inDays;
    final emoji = trip.coverEmoji ??
        _typeEmoji[trip.tripType.toLowerCase()] ??
        _typeEmoji[trip.tripType] ??
        '🌏';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder, width: 0.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            // Emoji panel
            Container(
              width: 72,
              height: 82,
              decoration: BoxDecoration(
                gradient: isArchived
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF1A0A04), AppColors.deepEarth],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: isArchived ? AppColors.surfaceLight : null,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20)),
              ),
              child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 30))),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(trip.name,
                              style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isArchived
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary)),
                        ),
                        if (isArchived)
                          _badge('Past', AppColors.surfaceLight,
                              AppColors.warmMuted)
                        else if (daysLeft == 0)
                          _badge(
                              'Today!', AppColors.greenBg, AppColors.green)
                        else if (daysLeft > 0)
                          _badge('$daysLeft days', AppColors.sand,
                              AppColors.primary),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(trip.destination,
                        style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('MMM d').format(trip.fromDate)} – ${DateFormat('MMM d, yyyy').format(trip.toDate)}',
                      style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          color: AppColors.warmMuted),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.chevron_right_rounded,
                    color: AppColors.warmMuted, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg)),
    );
  }
}
