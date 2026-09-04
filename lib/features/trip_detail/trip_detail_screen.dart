import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/selected_trip_provider.dart';
import '../../core/providers/trip_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/providers/expense_provider.dart';
import '../../core/providers/packing_provider.dart';
import '../../core/providers/itinerary_provider.dart';
import '../../core/models/trip_model.dart';
import '../../core/models/expense_model.dart';
import '../../core/models/itinerary_model.dart';
import '../../core/widgets/buttons/app_back_button.dart';
import '../../core/widgets/navigation/floating_nav_bar.dart';
import '../../core/widgets/share/share_trip_modal.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/feedback/app_feedback.dart';
import '../../core/widgets/feedback/app_dialog.dart';
import '../../core/widgets/member_avatar_circle.dart';
import 'widgets/edit_trip_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TripDetailScreen — Streamlined Dashboard (Zero-Redundancy Rich Hub)
// ─────────────────────────────────────────────────────────────────────────────

class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(selectedTripProvider);

    return tripAsync.when(
      data: (trip) {
        if (trip == null) {
          return const Scaffold(
            backgroundColor: AppColors.surfaceLight,
            body: Center(child: Text('Trip not found')),
          );
        }
        return _TripDashboard(trip: trip);
      },
      loading: () => const TripDetailSkeleton(),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.surfaceLight,
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TripDashboard extends ConsumerStatefulWidget {
  final TripModel trip;
  const _TripDashboard({required this.trip});

  @override
  ConsumerState<_TripDashboard> createState() => _TripDashboardState();
}

class _TripDashboardState extends ConsumerState<_TripDashboard> {
  bool _isPublishing = false;

  Future<void> _handlePublishTrip(TripModel trip) async {
    if (_isPublishing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publish Trip', style: AppTextStyles.titleLarge),
        content: Text(
          'Publishing this trip will make it active, allowing you to track schedules, manage members, and split expenses.',
          style: AppTextStyles.bodyMedium.copyWith(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Publish Now'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isPublishing = true);

    try {
      final updatedTrip = trip.copyWith(isDraft: false);
      await ref.read(tripRepositoryProvider).updateTrip(updatedTrip);

      // Seed default packing items if not present
      try {
        await ref.read(packingRepositoryProvider).seedDefaultItems(trip.id);
      } catch (e) {
        debugPrint('[TripDetail] Packing seed error on publish: $e');
      }

      ref.invalidate(allTripsProvider);
      ref.invalidate(selectedTripProvider);

      if (mounted) {
        AppFeedback.showSuccess(
          context,
          'Your trip "${trip.name}" is now live and ready for your travel group!',
          title: 'Trip Published! 🎉',
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
          context,
          'Failed to publish trip: $e',
          title: 'Publish Failed',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final coverColor = trip.coverColor;

    // ── Expenses ─────────────────────────────────────────────────
    final expensesAsync = ref.watch(expenseProvider(trip.id));
    final expenses = expensesAsync.asData?.value ?? trip.expenses;

    final totalSpent = expenses
        .where((e) => e.status == ExpenseStatus.approved)
        .fold<double>(0, (s, e) => s + e.amount);
    final totalPending = expenses
        .where((e) => e.status == ExpenseStatus.pending)
        .fold<double>(0, (s, e) => s + e.amount);
    final remaining = trip.totalBudget - totalSpent;
    final budgetPct =
        trip.totalBudget > 0 ? (totalSpent / trip.totalBudget).clamp(0.0, 1.0) : 0.0;

    // ── Packing ──────────────────────────────────────────────────
    final packingProviderInst = ref.watch(packingProvider(trip.id));
    final packingState = ref.watch(packingProviderInst);
    final packedCount = packingState.packedItems;
    final totalPacking = packingState.totalItems;

    // ── Itinerary ────────────────────────────────────────────────
    final itineraryProviderInst = ref.watch(itineraryProvider(trip.id));
    final itineraryAsync = ref.watch(itineraryProviderInst);
    final itineraryState = itineraryAsync.asData?.value;
    final itineraryDayCount = itineraryState?.days.length ?? 0;

    int totalStops = 0;
    int visitedStops = 0;
    ItineraryStop? nextStop;
    DateTime? nextStopDate;

    if (itineraryState != null) {
      for (final day in itineraryState.days) {
        totalStops += day.stops.length;
        for (final stop in day.stops) {
          if (stop.isCompleted) {
            visitedStops++;
          } else if (nextStop == null) {
            nextStop = stop;
            nextStopDate = day.date;
          }
        }
      }
    }

    final nights = trip.toDate.difference(trip.fromDate).inDays;
    final now = DateTime.now();
    final isActive = now.isAfter(trip.fromDate) && now.isBefore(trip.toDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F0),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── 1. Collapsible Sticky Hero Header ──────────────────
              _CollapsibleHeroHeader(
                trip: trip,
                coverColor: coverColor,
                nights: nights,
                isActive: isActive,
              ),

              // ── 2. Streamlined Interactive Dashboard ───────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // A. Draft Publish Banner (if draft)
                    if (trip.isDraft) ...[
                      _DraftPublishCard(
                        isLoading: _isPublishing,
                        onPublish: () => _handlePublishTrip(trip),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // B. Authoritative Itinerary / Next Stop Card (1-tap to /itinerary)
                    _ItineraryHubCard(
                      nextStop: nextStop,
                      nextStopDate: nextStopDate,
                      totalStops: totalStops,
                      visitedStops: visitedStops,
                      dayCount: itineraryDayCount,
                      onTap: () => Navigator.pushNamed(context, '/itinerary'),
                    ),
                    const SizedBox(height: 12),

                    // C. Logistics & Departure Card (if defined)
                    if ((trip.departurePoint != null && trip.departurePoint!.trim().isNotEmpty) ||
                        (trip.transportMode != null && trip.transportMode!.trim().isNotEmpty)) ...[
                      _LogisticsCard(trip: trip),
                      const SizedBox(height: 12),
                    ],

                    // D. Authoritative Budget Progress Card (1-tap to /budget)
                    _BudgetCard(
                      totalSpent: totalSpent,
                      totalPending: totalPending,
                      remaining: remaining,
                      budget: trip.totalBudget,
                      budgetPct: budgetPct,
                      splitEqually: trip.splitEqually,
                      onTap: () => Navigator.pushNamed(context, '/budget'),
                    ),
                    const SizedBox(height: 12),

                    // E. Authoritative Squad & Members Card (1-tap to /members)
                    _SquadPreviewCard(
                      trip: trip,
                      onTap: () => Navigator.pushNamed(context, '/members'),
                    ),
                    const SizedBox(height: 12),

                    // F. 2-Tile Utility Hub (Packing Checklist + Group Chat)
                    Row(
                      children: [
                        Expanded(
                          child: _QuickTile(
                            icon: Icons.luggage_rounded,
                            iconColor: const Color(0xFF854F0B),
                            title: 'Packing List',
                            subtitle: totalPacking > 0
                                ? '$packedCount of $totalPacking packed'
                                : 'Check items',
                            progress: totalPacking > 0 ? (packedCount / totalPacking).clamp(0.0, 1.0) : null,
                            onTap: () => Navigator.pushNamed(context, '/packing'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickTile(
                            icon: Icons.chat_bubble_rounded,
                            iconColor: const Color(0xFF4A2C7A),
                            title: 'Chat & Polls',
                            subtitle: 'Group discussions',
                            onTap: () => Navigator.pushNamed(context, '/chat'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // G. Live Navigation CTA (active trips only)
                    if (isActive) ...[
                      _NavButton(
                        onTap: () => Navigator.pushNamed(context, '/navigation'),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // H. Invite Code Card
                    if (trip.inviteCode.isNotEmpty)
                      _InviteCard(trip: trip),

                    // Bottom clearance for floating nav
                    const SizedBox(height: 120),
                  ]),
                ),
              ),
            ],
          ),

          // ── Bottom navigation bar ────────────────────────────────
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingNavBar(
              currentIndex: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Collapsible Sticky Hero Header (SliverAppBar with Pinned Frosted Glass Mini-Bar)
// ─────────────────────────────────────────────────────────────────────────────

class _CollapsibleHeroHeader extends ConsumerWidget {
  final TripModel trip;
  final Color coverColor;
  final int nights;
  final bool isActive;

  const _CollapsibleHeroHeader({
    required this.trip,
    required this.coverColor,
    required this.nights,
    required this.isActive,
  });

  Future<void> _confirmDeleteTrip(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Trip', style: AppTextStyles.titleLarge),
        content: Text('Are you sure you want to delete "${trip.name}"? This action cannot be undone.'),
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

    if (confirm == true && context.mounted) {
      final repo = ref.read(tripRepositoryProvider);
      await repo.deleteTrip(trip.id);
      ref.read(selectedTripIdProvider.notifier).clear();
      ref.invalidate(allTripsProvider);
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _toggleArchiveTrip(BuildContext context, WidgetRef ref) async {
    final willArchive = !trip.isArchived;
    final actionLabel = willArchive ? 'Archive' : 'Unarchive';

    final confirm = await AppDialog.showConfirmation(
      context,
      title: '$actionLabel Trip',
      message: willArchive
          ? 'Archiving "${trip.name}" will move it to Past Trips.'
          : 'Unarchiving "${trip.name}" will restore it to your active/upcoming trips.',
      confirmLabel: actionLabel,
      icon: willArchive ? Icons.archive_outlined : Icons.unarchive_outlined,
    );

    if (confirm == true && context.mounted) {
      final repo = ref.read(tripRepositoryProvider);
      final updated = trip.copyWith(isArchived: willArchive);
      await repo.updateTrip(updated);
      ref.invalidate(allTripsProvider);
      ref.invalidate(selectedTripProvider);

      if (context.mounted) {
        AppFeedback.showSuccess(
          context,
          willArchive ? 'Trip archived and closed.' : 'Trip unarchived and active.',
          title: willArchive ? 'Trip Archived 📦' : 'Trip Restored ✨',
        );

        if (willArchive) {
          ref.read(selectedTripIdProvider.notifier).clear();
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentLight = HSLColor.fromColor(coverColor)
        .withLightness((HSLColor.fromColor(coverColor).lightness + 0.18).clamp(0.0, 1.0))
        .toColor();

    final emoji = trip.coverEmoji;
    final imageUrl = trip.destinationDetails?['image'] ??
        trip.destinationDetails?['cover_image'] ??
        trip.destinationDetails?['image_url'];

    final statusDotColor = trip.isDraft
        ? AppColors.amberText
        : isActive
            ? AppColors.greenBright
            : trip.isArchived
                ? AppColors.warmMuted
                : AppColors.amber;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 270.0,
      elevation: 0,
      backgroundColor: coverColor,
      surfaceTintColor: Colors.transparent,
      leading: const Center(
        child: AppBackButton(
          variant: AppBackButtonVariant.glass,
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          color: const Color(0xFF2C2016),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: (value) {
            if (value == 'edit') EditTripSheet.show(context, trip);
            if (value == 'archive') _toggleArchiveTrip(context, ref);
            if (value == 'delete') _confirmDeleteTrip(context, ref);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18, color: Colors.white70),
                  SizedBox(width: 12),
                  Text('Edit Trip', style: TextStyle( color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'archive',
              child: Row(
                children: [
                  Icon(
                    trip.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                    size: 18,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    trip.isArchived ? 'Unarchive Trip' : 'Archive Trip',
                    style: const TextStyle( color: Colors.white),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                  SizedBox(width: 12),
                  Text('Delete Trip',
                      style: TextStyle( color: Colors.redAccent)),
                ],
              ),
            ),
          ],
        ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext ctx, BoxConstraints constraints) {
          final topPad = MediaQuery.of(ctx).padding.top;
          final currentHeight = constraints.biggest.height;
          final minHeight = kToolbarHeight + topPad;
          final delta = 270.0 - minHeight;
          final expandRatio = delta > 0 ? ((currentHeight - minHeight) / delta).clamp(0.0, 1.0) : 0.0;
          final isCollapsed = expandRatio < 0.28;

          return FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            titlePadding: EdgeInsets.zero,
            title: isCollapsed
                ? SafeArea(
                    bottom: false,
                    child: Container(
                      height: kToolbarHeight,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 60, right: 52),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: statusDotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              trip.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleMedium.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : null,
            background: Stack(
              children: [
                // Base background gradient
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          HSLColor.fromColor(coverColor)
                              .withLightness(
                                  (HSLColor.fromColor(coverColor).lightness - 0.12).clamp(0.0, 1.0))
                              .toColor(),
                          coverColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),

                // Background cover image watermark (if available)
                if (imageUrl != null && imageUrl.toString().isNotEmpty)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.14,
                        child: Image.network(
                          imageUrl.toString(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),

                // Large emoji watermark
                Positioned(
                  right: -20,
                  bottom: -30,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.12,
                      child: Transform.rotate(
                        angle: -0.10,
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 160, height: 1.0),
                        ),
                      ),
                    ),
                  ),
                ),

                // Ambient mesh blobs
                Positioned(
                  top: -40,
                  right: -30,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentLight.withValues(alpha: 0.22),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  left: -40,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                ),

                // Expanded content container
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, topPad + 56, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _StatusBadge(
                          isActive: isActive,
                          isArchived: trip.isArchived,
                          isDraft: trip.isDraft,
                        ),
                        const SizedBox(height: 10),

                        Text(
                          trip.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.headlineWhite,
                        ),
                        const SizedBox(height: 6),

                        Row(
                          children: [
                            Icon(Icons.place_rounded,
                                color: Colors.white.withValues(alpha: 0.75), size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                trip.destination,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        Text(
                          () {
                            final String dateStr;
                            if (trip.fromDate.year == trip.toDate.year) {
                              if (trip.fromDate.month == trip.toDate.month) {
                                dateStr =
                                    '${DateFormat('MMM d').format(trip.fromDate)}–${trip.toDate.day}, ${trip.toDate.year}';
                              } else {
                                dateStr =
                                    '${DateFormat('MMM d').format(trip.fromDate)} – ${DateFormat('MMM d').format(trip.toDate)}, ${trip.toDate.year}';
                              }
                            } else {
                              dateStr =
                                  '${DateFormat('MMM d, yyyy').format(trip.fromDate)} – ${DateFormat('MMM d, yyyy').format(trip.toDate)}';
                            }
                            return '$dateStr · $nights nights';
                          }(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Badge — frosted glass pill
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  final bool isArchived;
  final bool isDraft;
  const _StatusBadge({
    required this.isActive,
    required this.isArchived,
    this.isDraft = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = isDraft
        ? 'Draft'
        : isActive
            ? 'Active'
            : isArchived
                ? 'Completed'
                : 'Planning';
    final dot = isDraft
        ? AppColors.amberText
        : isActive
            ? AppColors.greenBright
            : isArchived
                ? AppColors.warmMuted
                : AppColors.amber;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
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
// Authoritative Itinerary / Next Stop Hub Card
// ─────────────────────────────────────────────────────────────────────────────

class _ItineraryHubCard extends StatelessWidget {
  final ItineraryStop? nextStop;
  final DateTime? nextStopDate;
  final int totalStops;
  final int visitedStops;
  final int dayCount;
  final VoidCallback onTap;

  const _ItineraryHubCard({
    this.nextStop,
    this.nextStopDate,
    required this.totalStops,
    required this.visitedStops,
    required this.dayCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (nextStop != null) {
      final dateStr = nextStopDate != null ? DateFormat('EEE, MMM d').format(nextStopDate!) : '';
      final timeStr = nextStop!.startTime != null
          ? nextStop!.startTime!.format(context)
          : 'Scheduled';

      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  nextStop!.type.icon,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.greenBright,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'NEXT UP · $timeStr${dateStr.isNotEmpty ? ' ($dateStr)' : ''}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nextStop!.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    if (nextStop!.location != null && nextStop!.location!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 12, color: Color(0xFF8E8E93)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              nextStop!.location!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF8E8E93)),
              ),
            ],
          ),
        ),
      );
    }

    // Fallback when all stops are completed or no stops are planned yet
    final isCompleted = totalStops > 0 && visitedStops >= totalStops;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF185FA5).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFF185FA5),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCompleted ? 'All Stops Completed 🎉' : 'Trip Itinerary',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    totalStops > 0
                        ? '$visitedStops of $totalStops stops visited · $dayCount days'
                        : 'Plan activities, food, hotels & stops',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF8E8E93)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logistics & Transport Departure Card
// ─────────────────────────────────────────────────────────────────────────────

class _LogisticsCard extends StatelessWidget {
  final TripModel trip;
  const _LogisticsCard({required this.trip});

  IconData _resolveTransportIcon(String? mode) {
    final m = mode?.toLowerCase() ?? '';
    if (m.contains('plane') || m.contains('flight') || m.contains('air')) {
      return Icons.flight_takeoff_rounded;
    }
    if (m.contains('ferry') || m.contains('boat') || m.contains('ship')) {
      return Icons.directions_boat_rounded;
    }
    if (m.contains('van') || m.contains('bus')) {
      return Icons.directions_bus_rounded;
    }
    if (m.contains('motor') || m.contains('bike')) {
      return Icons.two_wheeler_rounded;
    }
    return Icons.directions_car_rounded;
  }

  String _formatTransportLabel(String? mode) {
    if (mode == null || mode.isEmpty) return 'Land Transport';
    return mode[0].toUpperCase() + mode.substring(1);
  }

  void _copyDeparturePoint(BuildContext context) {
    if (trip.departurePoint != null && trip.departurePoint!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: trip.departurePoint!));
      AppFeedback.showSuccess(
        context,
        'Departure location copied: ${trip.departurePoint}',
        title: 'Location Copied 📋',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDeparture = trip.departurePoint != null && trip.departurePoint!.trim().isNotEmpty;
    final transportMode = trip.transportMode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
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
                  Icon(Icons.near_me_rounded, size: 16, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Logistics & Departure',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              if (transportMode != null && transportMode.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_resolveTransportIcon(transportMode), size: 13, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        _formatTransportLabel(transportMode),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (hasDeparture) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.place_rounded, size: 18, color: Color(0xFF185FA5)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MEETUP / DEPARTURE POINT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8E8E93),
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        trip.departurePoint!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF8E8E93)),
                  tooltip: 'Copy Departure Point',
                  onPressed: () => _copyDeparturePoint(context),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Authoritative Squad & Members Card
// ─────────────────────────────────────────────────────────────────────────────

class _SquadPreviewCard extends StatelessWidget {
  final TripModel trip;
  final VoidCallback onTap;

  const _SquadPreviewCard({
    required this.trip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final members = trip.members;
    const maxAvatars = 4;
    final displayMembers = members.take(maxAvatars).toList();
    final remainingCount = members.length > maxAvatars ? members.length - maxAvatars : 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Overlapping avatar cluster
            SizedBox(
              height: 38,
              width: (displayMembers.length * 26.0) + (remainingCount > 0 ? 32 : 12),
              child: Stack(
                children: [
                  for (int i = 0; i < displayMembers.length; i++)
                    Positioned(
                      left: i * 24.0,
                      child: MemberAvatarCircle(
                        photoUrl: displayMembers[i].profilePhotoUrl,
                        initials: displayMembers[i].initials,
                        color: displayMembers[i].color,
                        size: 36,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  if (remainingCount > 0)
                    Positioned(
                      left: displayMembers.length * 24.0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF2C1A14),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '+$remainingCount',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${members.length} Squad ${members.length == 1 ? 'Member' : 'Members'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Manage roles & split participants',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Manage',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF8E8E93)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Authoritative Budget & Expenses Card
// ─────────────────────────────────────────────────────────────────────────────

class _BudgetCard extends StatelessWidget {
  final double totalSpent;
  final double totalPending;
  final double remaining;
  final double budget;
  final double budgetPct;
  final bool splitEqually;
  final VoidCallback onTap;

  const _BudgetCard({
    required this.totalSpent,
    required this.totalPending,
    required this.remaining,
    required this.budget,
    required this.budgetPct,
    this.splitEqually = true,
    required this.onTap,
  });

  Color get _barColor {
    if (budgetPct >= 0.9) return const Color(0xFFA32D2D);
    if (budgetPct > 0.7) return const Color(0xFFE09A30);
    return AppColors.primary;
  }

  Color get _pctColor =>
      budgetPct > 0.9 ? const Color(0xFFA32D2D) : AppColors.primary;

  static String _fmt(double v) =>
      NumberFormat('#,##0', 'en_PH').format(v.toInt());

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _barColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.account_balance_wallet_rounded,
                          size: 18, color: _barColor),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trip Budget & Expenses',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          splitEqually ? 'Equal Split' : 'Custom Split',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (budget > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _pctColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(budgetPct * 100).round()}% used',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _pctColor,
                      ),
                    ),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'No Budget Set',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Progress bar
            if (budget > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: budgetPct),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, val, __) => LinearProgressIndicator(
                    value: val,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF2F2F7),
                    valueColor: AlwaysStoppedAnimation<Color>(_barColor),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Spent / Pending / Remaining
            Row(
              children: [
                Expanded(
                  child: _BudgetStat(
                    label: 'Spent',
                    value: '₱${_fmt(totalSpent)}',
                    valueColor: const Color(0xFF1A1A1A),
                  ),
                ),
                Expanded(
                  child: _BudgetStat(
                    label: 'Pending',
                    value: '₱${_fmt(totalPending)}',
                    valueColor: const Color(0xFF854F0B),
                    align: CrossAxisAlignment.center,
                  ),
                ),
                Expanded(
                  child: _BudgetStat(
                    label: budget > 0 ? 'Remaining' : 'Total Budget',
                    value: budget > 0
                        ? '₱${_fmt(remaining.abs())}${remaining < 0 ? ' over' : ''}'
                        : '₱${_fmt(budget)}',
                    valueColor: remaining < 0
                        ? const Color(0xFFA32D2D)
                        : const Color(0xFF3B6D11),
                    align: CrossAxisAlignment.end,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final CrossAxisAlignment align;

  const _BudgetStat({
    required this.label,
    required this.value,
    required this.valueColor,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF8E8E93))),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Utility Tile (Packing & Chat side-by-side grid)
// ─────────────────────────────────────────────────────────────────────────────

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final double? progress;
  final VoidCallback onTap;

  const _QuickTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const Icon(Icons.arrow_outward_rounded, size: 16, color: Color(0xFF8E8E93)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF8E8E93),
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: const Color(0xFFF2F2F7),
                  valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Navigation CTA
// ─────────────────────────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NavButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD85A30), Color(0xFFEF8A5E)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.40),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Start Navigation',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Invite Code Card — dark glass with ambient glow
// ─────────────────────────────────────────────────────────────────────────────

class _InviteCard extends ConsumerStatefulWidget {
  final TripModel trip;
  const _InviteCard({required this.trip});

  @override
  ConsumerState<_InviteCard> createState() => _InviteCardState();
}

class _InviteCardState extends ConsumerState<_InviteCard> {
  bool _copied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.trip.inviteCode));
    setState(() => _copied = true);
    AppFeedback.showSuccess(
      context,
      'Invite code copied: ${widget.trip.inviteCode}',
      title: 'Copied to Clipboard 📋',
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _share() {
    ShareTripModal.show(
      context,
      ref,
      widget.trip,
      initialScope: ShareScope.overview,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A0A04), Color(0xFF2C1A14)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.20),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INVITE CODE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.40),
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.trip.inviteCode,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Share with your squad to join this trip',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _InviteIconBtn(
                        icon: Icons.share_rounded,
                        onTap: _share,
                      ),
                      const SizedBox(height: 8),
                      _InviteIconBtn(
                        icon: _copied
                            ? Icons.check_circle_rounded
                            : Icons.copy_rounded,
                        activeColor: _copied ? AppColors.greenBright : null,
                        onTap: _copy,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? activeColor;
  const _InviteIconBtn({required this.icon, required this.onTap, this.activeColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(
          icon,
          size: 18,
          color: activeColor ?? Colors.white.withValues(alpha: 0.70),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Draft Publish Card — banner informing user and providing a Publish CTA
// ─────────────────────────────────────────────────────────────────────────────

class _DraftPublishCard extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPublish;

  const _DraftPublishCard({
    required this.isLoading,
    required this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.sand.withValues(alpha: 0.7),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.amber.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.amberBg,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.25)),
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: AppColors.amberText,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Draft Trip',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Publish this trip to activate live tracking, member sharing, and packing lists.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: isLoading ? null : onPublish,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Publish',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
