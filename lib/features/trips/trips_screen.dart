import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/trip_provider.dart';
import '../../core/providers/selected_trip_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/models/trip_model.dart';
import '../../core/utils/jit_guard.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/feedback/app_feedback.dart';
import '../../core/widgets/feedback/app_dialog.dart';
import '../trip_detail/widgets/edit_trip_sheet.dart';
import 'widgets/join_trip_modal.dart';

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
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.paddingOf(context).top + 16,
              24,
              22,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A0A04), AppColors.deepEarth],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('My Trips', style: AppTextStyles.headlineWhite),
                      const SizedBox(height: 2),
                      Text('All your journeys',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white54,
                          )),
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
                            // ── Icon container ─────────────────────────────
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: AppColors.sand,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.20),
                                  width: 2,
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  '✈️',
                                  style: TextStyle(fontSize: 36),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── Headline ─────────────────────────────────────
                            Text(
                              'No trips planned yet',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.headline2.copyWith(
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // ── Description ──────────────────────────────────
                            const Text(
                              'Your next adventure starts with a plan.\nCreate a new trip or join one with an invite code.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 14,
                                height: 1.55,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // ── Primary CTA ───────────────────────────────────
                            SizedBox(
                              width: double.infinity,
                              child: GestureDetector(
                                onTap: () async {
                                  final canProceed = await JitGuard.checkCreateTripGuard(context, ref);
                                  if (!canProceed || !context.mounted) return;
                                  Navigator.pushNamed(context, '/create-trip');
                                },
                                child: Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.35),
                                        blurRadius: 14,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_rounded,
                                          size: 20, color: Colors.white),
                                      SizedBox(width: 6),
                                      Text(
                                        'Create a Trip',
                                        style: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ── Secondary CTA ─────────────────────────────────
                            GestureDetector(
                              onTap: () => showJoinTripModal(context, ref),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.qr_code_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Have an invite code? Join Trip',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                        decoration: TextDecoration.underline,
                                        decorationColor:
                                            AppColors.primary.withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(allTripsProvider);
                      ref.invalidate(activeTripProvider);
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 140),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
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
                    ),
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
    showJoinTripModal(context, ref);
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
      AppFeedback.showSuccess(
        context,
        willArchive ? 'Trip moved to archive.' : 'Trip restored to your active list.',
        title: willArchive ? 'Trip Archived 📦' : 'Trip Restored ✨',
      );
    }
  }

  Future<void> _handleDelete() async {
    _close();
    final confirm = await AppDialog.showDestructive(
      context,
      title: 'Delete Trip',
      message: 'Are you sure you want to delete "${widget.trip.name}"? This action cannot be undone.',
      confirmLabel: 'Delete Trip',
    );

    if (confirm == true) {
      final repo = ref.read(tripRepositoryProvider);
      await repo.deleteTrip(widget.trip.id);
      ref.read(selectedTripIdProvider.notifier).clear();
      ref.invalidate(allTripsProvider);
      if (mounted) {
        AppFeedback.showInfo(
          context,
          'Trip "${widget.trip.name}" has been deleted.',
          title: 'Trip Deleted',
        );
      }
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
    final emoji = trip.coverEmoji;
    final typeOpt = trip.tripTypeOption;

    final themeColor = trip.coverColor;
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

