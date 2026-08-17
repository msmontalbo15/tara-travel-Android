import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_brand_logo.dart';
import '../../core/providers/trip_provider.dart';
import '../../core/providers/selected_trip_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/models/trip_model.dart';
import '../../core/utils/jit_guard.dart';
import '../../core/constants/trip_types.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../trip_detail/widgets/edit_trip_sheet.dart';

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
                  onTap: () async {
                    final canProceed = await JitGuard.checkCreateTripGuard(context, ref);
                    if (!canProceed || !context.mounted) return;
                    Navigator.pushNamed(context, '/create-trip');
                  },
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
                  // Split into drafts, upcoming, and past trips
                  final drafts = trips.where((t) => t.isDraft && !t.isArchived).toList();
                  final upcoming = trips
                      .where((t) => !t.isDraft && !t.isArchived && !t.toDate.isBefore(now))
                      .toList();
                  final past = trips
                      .where((t) => !t.isDraft && (t.isArchived || t.toDate.isBefore(now)))
                      .toList();

                  if (trips.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const AppBrandLogo(size: 64),
                            const SizedBox(height: 18),
                            const Text('No trips yet',
                                style: TextStyle(
                                    fontFamily: 'Playfair Display',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 6),
                            const Text('Your journey begins here. Plan your first adventure with Tara Travel!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 14,
                                    height: 1.5,
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 24),
                            GestureDetector(
                              onTap: () async {
                                final canProceed = await JitGuard.checkCreateTripGuard(context, ref);
                                if (!canProceed || !context.mounted) return;
                                Navigator.pushNamed(context, '/create-trip');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 28, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
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
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 80),
                    children: [
                      if (drafts.isNotEmpty) ...[
                        _sectionHeader('DRAFTS'),
                        ...drafts.map((t) => _TripListCard(
                              trip: t,
                              onTap: () {
                                 ref
                                     .read(selectedTripIdProvider.notifier)
                                     .select(t.id);
                                 Navigator.pushNamed(context, '/trip-detail');
                               },
                            )),
                        const SizedBox(height: 8),
                      ],
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
                    const TripsListSkeleton(count: 3),
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
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter a 6-character invite code.');
      return;
    }

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
             behavior: SnackBarBehavior.floating,
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
            topLeft: Radius.circular(32), topRight: Radius.circular(32)),
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

// ── Trip List Card with Smooth Swipe-to-Reveal Actions ─────────────────────────

class _TripListCard extends ConsumerStatefulWidget {
  final TripModel trip;
  final bool isArchived;
  final VoidCallback onTap;

  const _TripListCard({
    required this.trip,
    this.isArchived = false,
    required this.onTap,
  });

  @override
  ConsumerState<_TripListCard> createState() => _TripListCardState();
}

class _TripListCardState extends ConsumerState<_TripListCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  static const double _actionWidth = 210.0;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _close() {
    _slideController.animateTo(0.0, curve: Curves.easeOutCubic);
  }

  void _open() {
    _slideController.animateTo(1.0, curve: Curves.easeOutCubic);
  }

  void _toggle() {
    if (_slideController.value > 0.5) {
      _close();
    } else {
      _open();
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    // Left drag (negative delta) increases value towards 1.0 (open)
    _slideController.value -= details.primaryDelta! / _actionWidth;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -300) {
      _open();
    } else if (velocity > 300) {
      _close();
    } else if (_slideController.value >= 0.4) {
      _open();
    } else {
      _close();
    }
  }

  Future<void> _handleArchive() async {
    _close();
    final willArchive = !widget.trip.isArchived;
    final repo = ref.read(tripRepositoryProvider);
    final updated = widget.trip.copyWith(isArchived: willArchive);
    await repo.updateTrip(updated);
    ref.invalidate(allTripsProvider);
    ref.invalidate(selectedTripProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(willArchive ? 'Trip archived 📦' : 'Trip restored ✨'),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _handleDelete() async {
    _close();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Trip',
            style: TextStyle(fontFamily: 'Playfair Display', fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete "${widget.trip.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final repo = ref.read(tripRepositoryProvider);
      await repo.deleteTrip(widget.trip.id);
      ref.read(selectedTripIdProvider.notifier).clear();
      ref.invalidate(allTripsProvider);
    }
  }

  Future<void> _handleEdit() async {
    _close();
    await EditTripSheet.show(context, widget.trip);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          // ── Background Action Buttons (Revealed on Swipe Left) ──
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1A17),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.centerRight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit Action
                    _SwipeActionBtn(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      color: const Color(0xFF2E86DE),
                      onTap: _handleEdit,
                    ),

                    // Archive / Restore Action
                    _SwipeActionBtn(
                      icon: widget.trip.isArchived
                          ? Icons.unarchive_outlined
                          : Icons.archive_outlined,
                      label: widget.trip.isArchived ? 'Restore' : 'Archive',
                      color: AppColors.amberText,
                      onTap: _handleArchive,
                    ),

                    // Delete Action
                    _SwipeActionBtn(
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete',
                      color: const Color(0xFFEB4D4B),
                      onTap: _handleDelete,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Foreground Card (Draggable / Slidable via AnimationController) ─
          AnimatedBuilder(
            animation: _slideController,
            builder: (context, child) {
              final offset = -(_slideController.value * _actionWidth);
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              onTap: () {
                if (_slideController.value > 0.05) {
                  _close();
                } else {
                  widget.onTap();
                }
              },
              child: _buildCardContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContent() {
    final trip = widget.trip;
    final daysLeft = trip.fromDate.difference(DateTime.now()).inDays;
    final emoji = trip.coverEmoji ?? AppTripTypes.getEmoji(trip.tripType);
    final typeOpt = AppTripTypes.getOption(trip.tripType);

    final themeColor = AppColors.parseTripColor(trip.coverColor);
    final hsl = HSLColor.fromColor(themeColor);
    final isMuted = widget.isArchived || trip.isIncomplete;
    final darkGrad = isMuted
        ? const Color(0xFF6E6A67)
        : hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0)).toColor();
    final lightGrad = isMuted
        ? const Color(0xFF9E9A96)
        : hsl.withLightness((hsl.lightness + 0.10).clamp(0.0, 1.0)).toColor();

    final imageUrl = trip.destinationDetails?['image'] ??
        trip.destinationDetails?['cover_image'] ??
        trip.destinationDetails?['image_url'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMuted ? AppColors.cardBorder : AppColors.cardBorder,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // ── Background Image Overlay ────
            if (imageUrl != null && imageUrl.toString().isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.08,
                    child: Image.network(
                      imageUrl.toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),

            // ── Background Large Emoji Watermark ───
            Positioned(
              right: -12,
              bottom: -22,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.08,
                  child: Transform.rotate(
                    angle: -0.15,
                    child: Text(
                      emoji,
                      style: const TextStyle(
                        fontSize: 110,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Foreground Content ───────────────────────────
            Row(
              children: [
                // Emoji panel with dynamic theme color gradient (grey if incomplete/archived)
                Container(
                  width: 72,
                  height: 86,
                  decoration: BoxDecoration(
                    gradient: isMuted
                        ? null
                        : LinearGradient(
                            colors: [darkGrad, lightGrad],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: isMuted ? const Color(0xFFE2DFDC) : null,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 30)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                trip.name,
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isMuted
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (trip.isDraft)
                              _badge('Draft', AppColors.surfaceLight, AppColors.warmMuted)
                            else if (widget.isArchived)
                              _badge('Past', AppColors.surfaceLight, AppColors.warmMuted)
                            else if (trip.isIncomplete)
                              _badge('Incomplete', AppColors.surfaceLight, AppColors.warmMuted)
                            else if (daysLeft == 0)
                              _badge('Today!', AppColors.greenBg, AppColors.green)
                            else if (daysLeft > 0)
                              _badge('$daysLeft days', AppColors.sand, AppColors.primary),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                trip.destination,
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: typeOpt.accentColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(typeOpt.emoji, style: const TextStyle(fontSize: 10)),
                                  const SizedBox(width: 3),
                                  Text(
                                    typeOpt.label,
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: typeOpt.accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${DateFormat('MMM d').format(trip.fromDate)} – ${DateFormat('MMM d, yyyy').format(trip.toDate)}',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 11,
                                color: AppColors.warmMuted,
                              ),
                            ),
                            GestureDetector(
                              onTap: _toggle,
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Actions',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.warmMuted.withValues(alpha: 0.7),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.chevron_left_rounded,
                                      size: 16,
                                      color: AppColors.warmMuted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _SwipeActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SwipeActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        height: 86,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

