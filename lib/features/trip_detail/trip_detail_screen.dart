import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_responsive.dart';
import '../../core/providers/selected_trip_provider.dart';
import '../../core/providers/trip_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/providers/expense_provider.dart';
import '../../core/providers/itinerary_provider.dart';
import '../../core/models/trip_model.dart';
import '../../core/models/itinerary_model.dart';
import '../../core/models/member_model.dart';
import '../../core/widgets/buttons/app_back_button.dart';
import '../../core/widgets/share/share_trip_modal.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/feedback/app_feedback.dart';
import '../../core/widgets/feedback/app_dialog.dart';
import '../../core/widgets/member_avatar_circle.dart';
import '../../core/widgets/privacy_invite_code_widget.dart';
import '../../core/widgets/offline_read_only_banner.dart';
import '../../core/providers/connectivity_provider.dart';
import '../../core/providers/auth_provider.dart';
import 'widgets/edit_trip_sheet.dart';
import 'widgets/destination_weather_widget.dart';
import 'widgets/ongoing_trip_hud.dart';
import 'widgets/planning_recommendations_card.dart';
import 'widgets/smart_departure_advisory_card.dart';

import 'widgets/trip_detail_bottom_bar.dart';
import '../../core/services/departure_advisory_service.dart';
import '../itinerary/widgets/stop_detail_sheet.dart';
import '../itinerary/widgets/edit_stop_form.dart';

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
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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

    // ── Expenses Summary (Memoized) ──────────────────────────────
    final expenseSummary = ref.watch(expenseSummaryProvider(trip.id));
    final totalSpent = expenseSummary.totalSpent;
    final totalPending = expenseSummary.totalPending;
    final remaining = trip.totalBudget - totalSpent;
    final budgetPct = trip.totalBudget > 0
        ? (totalSpent / trip.totalBudget).clamp(0.0, 1.0)
        : 0.0;

    // ── Itinerary Summary (Memoized) ─────────────────────────────
    final itinerarySummary = ref.watch(itinerarySummaryProvider(trip.id));
    final totalStops = itinerarySummary.totalStops;
    final visitedStops = itinerarySummary.visitedStops;
    final nextStop = itinerarySummary.nextStop;
    final nextStopDate = itinerarySummary.nextStopDate;
    final itineraryDayCount = itinerarySummary.dayCount;

    final nights = trip.toDate.difference(trip.fromDate).inDays;
    final isActive = trip.isOngoing;
    final isOnline = ref.watch(isOnlineProvider).value ?? true;

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
                    // 0. Offline Read-Only Banner (when disconnected)
                    if (!isOnline) ...[
                      const OfflineReadOnlyBanner(
                        padding: EdgeInsets.only(bottom: 12),
                      ),
                    ],

                    // A. Draft Publish Banner (if draft)
                    if (trip.isDraft) ...[
                      _DraftPublishCard(
                        isLoading: _isPublishing,
                        onPublish: () => _handlePublishTrip(trip),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 1. Real-Time Destination Weather Forecast (Top Content Card)
                    DestinationWeatherWidget(
                      tripId: trip.id,
                      destinationName: trip.destination,
                      nextStopTitle: nextStop?.title,
                      stopLocation: nextStop?.location,
                    ),
                    const SizedBox(height: 12),

                    // 2. Next Up: Ongoing Cockpit (Active Trips) OR Meet-up Assembly (Pre-departure) OR Standard Next Stop Hub Card
                    if (isActive) ...[
                      OngoingTripHud(
                        tripId: trip.id,
                        activeStop: nextStop,
                        nextStop: nextStop,
                        totalStops: totalStops,
                        visitedStops: visitedStops,
                        onOpenItinerary: () =>
                            Navigator.pushNamed(context, '/itinerary'),
                      ),
                      const SizedBox(height: 12),
                    ] else if ((trip.departurePoint != null &&
                            trip.departurePoint!.trim().isNotEmpty) ||
                        (nextStop != null &&
                            (nextStop.title.toLowerCase().contains('meet-up') ||
                             nextStop.title.toLowerCase().contains('departure') ||
                             nextStop.title.toLowerCase().contains('assembly')))) ...[
                      SmartDepartureAdvisoryCard(
                        trip: trip,
                        nextStop: nextStop,
                        nextStopDate: nextStopDate,
                        onOpenItinerary: () =>
                            Navigator.pushNamed(context, '/itinerary'),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      _ItineraryHubCard(
                        trip: trip,
                        nextStop: nextStop,
                        nextStopDate: nextStopDate,
                        totalStops: totalStops,
                        visitedStops: visitedStops,
                        dayCount: itineraryDayCount,
                        onTap: () => Navigator.pushNamed(context, '/itinerary'),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Logistics fallback when no meet-up advisory is present but transport mode is configured
                    if (!isActive &&
                        (trip.departurePoint == null || trip.departurePoint!.trim().isEmpty) &&
                        (nextStop == null ||
                            (!nextStop.title.toLowerCase().contains('meet-up') &&
                             !nextStop.title.toLowerCase().contains('departure') &&
                             !nextStop.title.toLowerCase().contains('assembly'))) &&
                        trip.transportMode != null &&
                        trip.transportMode!.trim().isNotEmpty) ...[
                      _LogisticsCard(trip: trip),
                      const SizedBox(height: 12),
                    ],

                    // 4. Authoritative Budget Progress Card (1-tap to /budget)
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

                    // 5. Smart Planning Recommendations (planning trips only)
                    PlanningRecommendationsCard(
                      trip: trip,
                      totalStops: totalStops,
                    ),
                    if (trip.status == TripStatus.planning)
                      const SizedBox(height: 12),

                    // 6. Authoritative Squad & Members Card (1-tap to /members)
                    _SquadPreviewCard(
                      trip: trip,
                      onTap: () => Navigator.pushNamed(context, '/members'),
                    ),
                    const SizedBox(height: 12),

                    // 7. Protected Invite Code Card
                    if (trip.inviteCode.isNotEmpty) ...[
                      _InviteCard(trip: trip),
                      const SizedBox(height: 14),
                    ],

                    // Bottom clearance for persistent bottom bar
                    const SizedBox(height: 140),
                  ]),
                ),
              ),
            ],
          ),

          // ── Floating Quick Action Dock ─────────────────────────────
          TripDetailBottomBar(
            isOngoing: isActive,
            onNavigationTap: () => Navigator.pushNamed(context, '/navigation'),
            onItineraryTap: () => Navigator.pushNamed(context, '/itinerary'),
            onPackingTap: () => Navigator.pushNamed(context, '/packing'),
            onMembersTap: () => Navigator.pushNamed(context, '/members'),
            onExpensesTap: () => Navigator.pushNamed(context, '/budget'),
            onChatTap: () => Navigator.pushNamed(context, '/chat'),
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
        content: Text(
            'Are you sure you want to delete "${trip.name}"? This action cannot be undone.'),
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

  Future<void> _confirmLeaveTrip(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Trip', style: AppTextStyles.titleLarge),
        content: Text(
          'Are you sure you want to leave "${trip.name}"? You will need an invite code to rejoin.',
          style: AppTextStyles.bodyMedium.copyWith(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Leave Trip'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        final repo = ref.read(tripRepositoryProvider);
        final leftName = await repo.leaveTrip(trip.id);
        ref.read(selectedTripIdProvider.notifier).clear();
        ref.invalidate(allTripsProvider);
        ref.invalidate(selectedTripProvider);

        if (context.mounted) {
          AppFeedback.showSuccess(
            context,
            'You left "$leftName".',
            title: 'Left Trip',
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          AppFeedback.showError(context, 'Failed to leave trip: $e');
        }
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
          willArchive
              ? 'Trip archived and closed.'
              : 'Trip unarchived and active.',
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
        Consumer(
          builder: (context, ref, _) {
            final currentUserId = ref.watch(currentUserProvider)?.id;
            final isOwner =
                currentUserId != null && trip.ownerId == currentUserId;
            final currentMember = ref.watch(currentMemberProvider(trip));
            final canEditTrip = isOwner || (currentMember?.canManageTripSettings ?? false);

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                        width: 1.0,
                      ),
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      color: const Color(0xFF2C2016),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      onSelected: (value) {
                        if (value == 'edit') EditTripSheet.show(context, trip);
                        if (value == 'archive') _toggleArchiveTrip(context, ref);
                        if (value == 'delete') _confirmDeleteTrip(context, ref);
                        if (value == 'leave') _confirmLeaveTrip(context, ref);
                      },
                      itemBuilder: (_) => [
                        if (canEditTrip)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined,
                                    size: 18, color: Colors.white70),
                                SizedBox(width: 12),
                                Text('Edit Trip', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                        if (isOwner)
                          PopupMenuItem(
                            value: 'archive',
                            child: Row(
                              children: [
                                Icon(
                                  trip.isArchived
                                      ? Icons.unarchive_outlined
                                      : Icons.archive_outlined,
                                  size: 18,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  trip.isArchived ? 'Unarchive Trip' : 'Archive Trip',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        const PopupMenuDivider(),
                        if (isOwner)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded,
                                    size: 18, color: Colors.redAccent),
                                SizedBox(width: 12),
                                Text('Delete Trip',
                                    style: TextStyle(color: Colors.redAccent)),
                              ],
                            ),
                          )
                        else
                          const PopupMenuItem(
                            value: 'leave',
                            child: Row(
                              children: [
                                Icon(Icons.logout_rounded,
                                    size: 18, color: Colors.redAccent),
                                SizedBox(width: 12),
                                Text('Leave Trip',
                                    style: TextStyle(color: Colors.redAccent)),
                              ],
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
      ],
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext ctx, BoxConstraints constraints) {
          final topPad = ctx.topInset;
          final currentHeight = constraints.biggest.height;
          final minHeight = kToolbarHeight + topPad;
          final delta = 270.0 - minHeight;
          final expandRatio = delta > 0
              ? ((currentHeight - minHeight) / delta).clamp(0.0, 1.0)
              : 0.0;
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
                      padding: const EdgeInsets.only(left: 64, right: 60),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: statusDotColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: statusDotColor.withValues(alpha: 0.6),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trip.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  trip.destination,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.70),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
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
                                  (HSLColor.fromColor(coverColor).lightness -
                                          0.12)
                                      .clamp(0.0, 1.0))
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
                        opacity: 0.10,
                        child: Image.network(
                          imageUrl.toString(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),

                // Subtle emoji accent
                Positioned(
                  right: -10,
                  bottom: -20,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.10,
                      child: Transform.rotate(
                        angle: -0.08,
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 120, height: 1.0),
                        ),
                      ),
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
                                color: Colors.white.withValues(alpha: 0.75),
                                size: 14),
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

                        // ── Journey Mode Pill (Adventure / Off-Grid indicator) ──
                        if (trip.isAdventureMode || !trip.isMapEnabled) ...[
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: trip.isAdventureMode
                                      ? const Color(0xFFEF6C00).withValues(alpha: 0.25)
                                      : Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: trip.isAdventureMode
                                        ? const Color(0xFFEF6C00).withValues(alpha: 0.5)
                                        : Colors.white.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      trip.isAdventureMode
                                          ? Icons.explore_rounded
                                          : Icons.layers_clear_rounded,
                                      size: 11,
                                      color: trip.isAdventureMode
                                          ? const Color(0xFFFFB74D)
                                          : Colors.white70,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      trip.isAdventureMode
                                          ? 'Off-Grid Adventure'
                                          : 'Mapless Mode',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: trip.isAdventureMode
                                            ? const Color(0xFFFFB74D)
                                            : Colors.white70,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],

                        // ── Multi-Hub Route Strip ───────────────────────────
                        if (trip.isMultiPointMode && trip.destinationHubs.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: trip.destinationHubs.asMap().entries.map((e) {
                                final isLast = e.key == trip.destinationHubs.length - 1;
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.primary.withValues(alpha: 0.35),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        e.value,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryLight,
                                        ),
                                      ),
                                    ),
                                    if (!isLast) ...[
                                      const SizedBox(width: 3),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 10,
                                        color: Colors.white.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(width: 3),
                                    ],
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],

                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                color: Colors.white.withValues(alpha: 0.75),
                                size: 12),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
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
                                  return dateStr;
                                }(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.80),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.20),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                '$nights ${nights == 1 ? 'night' : 'nights'}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
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
            ? 'Ongoing'
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

class _ItineraryHubCard extends ConsumerWidget {
  final TripModel trip;
  final ItineraryStop? nextStop;
  final DateTime? nextStopDate;
  final int totalStops;
  final int visitedStops;
  final int dayCount;
  final VoidCallback onTap;

  const _ItineraryHubCard({
    required this.trip,
    this.nextStop,
    this.nextStopDate,
    required this.totalStops,
    required this.visitedStops,
    required this.dayCount,
    required this.onTap,
  });

  bool get _isMeetUpStop {
    if (nextStop == null) return false;
    final t = nextStop!.title.toLowerCase();
    return t.contains('meet-up') || t.contains('departure') || t.contains('assembly') || nextStop!.type == StopType.transport;
  }

  void _openStopDetail(BuildContext context, WidgetRef ref, ItineraryStop targetStop) {
    final currentUserId = ref.read(currentUserProvider)?.id ?? '';
    final canManage = trip.ownerId == currentUserId ||
        trip.members.any((m) => m.id == currentUserId && m.isOrganizer);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StopDetailSheet(
        stop: targetStop,
        members: trip.members,
        currentUserId: currentUserId,
        canManage: canManage,
        onEdit: () {
          Navigator.pop(ctx);
          final subProvider = ref.read(itineraryProvider(trip.id));
          final itineraryState = ref.read(subProvider).asData?.value;
          int dayIndex = itineraryState?.days
                  .indexWhere((d) => d.stops.any((s) => s.id == targetStop.id)) ??
              0;
          if (dayIndex < 0) dayIndex = 0;

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (editCtx) => Padding(
              padding: EdgeInsets.only(
                bottom: editCtx.keyboardHeight,
              ),
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  child: EditStopForm(
                    stop: targetStop,
                    members: trip.members,
                    onSave: (updated) async {
                      await ref
                          .read(subProvider.notifier)
                          .updateStop(dayIndex, updated);
                      ref.invalidate(itineraryStopsProvider(trip.id));
                      if (editCtx.mounted) Navigator.pop(editCtx);
                    },
                    onCancel: () => Navigator.pop(editCtx),
                  ),
                ),
              ),
            ),
          );
        },
        onCheckIn: () async {
          try {
            final subProvider = ref.read(itineraryProvider(trip.id));
            final itineraryState = ref.read(subProvider).asData?.value;
            if (itineraryState != null) {
              await ref.read(subProvider.notifier).toggleStopVisited(
                itineraryState.activeDay,
                targetStop.id,
                currentUserId,
              );
              ref.invalidate(itineraryStopsProvider(trip.id));
            }
          } catch (e) {
            debugPrint('[_ItineraryHubCard] check-in error: $e');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (nextStop != null) {
      final dateStr = nextStopDate != null
          ? DateFormat('EEE, MMM d').format(nextStopDate!)
          : '';
      final timeStr = nextStop!.startTime != null
          ? nextStop!.startTime!.format(context)
          : 'Scheduled';

      final isAssembly = _isMeetUpStop;
      final departurePoint = trip.departurePoint ?? nextStop!.location;

      // Compute departure advisory state if this is an assembly stop or departurePoint exists
      final advisory = isAssembly
          ? DepartureAdvisoryService.instance.computeState(trip: trip, meetUpStop: nextStop)
          : null;

      Color badgeDotColor = AppColors.greenBright;
      String nextBadgeLabel = 'NEXT UP · $timeStr${dateStr.isNotEmpty ? ' ($dateStr)' : ''}';

      if (advisory != null) {
        switch (advisory.status) {
          case DepartureAdvisoryStatus.onTime:
            badgeDotColor = const Color(0xFF10B981);
            nextBadgeLabel = 'NEXT UP · ASSEMBLY (ON TIME)';
            break;
          case DepartureAdvisoryStatus.approachingGracePeriod:
            badgeDotColor = AppColors.primary;
            nextBadgeLabel = 'NEXT UP · ASSEMBLY SOON';
            break;
          case DepartureAdvisoryStatus.withinGracePeriod:
            badgeDotColor = const Color(0xFFEF9F27);
            nextBadgeLabel = 'NEXT UP · GRACE PERIOD';
            break;
          case DepartureAdvisoryStatus.delayed:
            badgeDotColor = const Color(0xFFDC2626);
            nextBadgeLabel = 'NEXT UP · ROLLING OUT';
            break;
          case DepartureAdvisoryStatus.departed:
            badgeDotColor = const Color(0xFF6366F1);
            nextBadgeLabel = 'NEXT UP · DEPARTED';
            break;
        }
      }

      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _openStopDetail(context, ref, nextStop!);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: isAssembly ? AppColors.primary.withValues(alpha: 0.35) : const Color(0xFFEBE8E3),
                width: isAssembly ? 1.2 : 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      nextStop!.type.icon,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: badgeDotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                nextBadgeLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          nextStop!.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        if (departurePoint != null && departurePoint.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.place_outlined,
                                  size: 11, color: Color(0xFF8E8E93)),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  departurePoint,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
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
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded,
                      size: 20, color: Color(0xFFB0B0B8)),
                ],
              ),

              // Embedded Meet-up Assembly details
              if (advisory != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.sand.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Buffer: ${advisory.gracePeriodMinutes}m',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.deepEarth),
                      ),
                      const Spacer(),
                      const Icon(Icons.groups_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${advisory.arrivedCount}/${advisory.totalCount} Arrived',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.deepEarth),
                      ),
                    ],
                  ),
                ),
              ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF185FA5).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Color(0xFF185FA5),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              isCompleted ? 'All Stops Completed 🎉' : 'Trip Itinerary',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (dayCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF185FA5).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$dayCount ${dayCount == 1 ? 'Day' : 'Days'}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF185FA5),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        totalStops > 0
                            ? '$visitedStops of $totalStops stops visited'
                            : 'Plan activities, food, hotels & stops',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    size: 20, color: Color(0xFFB0B0B8)),
              ],
            ),
            if (totalStops > 0 && !isCompleted) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (visitedStops / totalStops).clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: const Color(0xFFF2F2F7),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF185FA5)),
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
    final hasDeparture =
        trip.departurePoint != null && trip.departurePoint!.trim().isNotEmpty;
    final transportMode = trip.transportMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              const Row(
                children: [
                  Icon(Icons.near_me_rounded,
                      size: 15, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Logistics & Departure',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              if (transportMode != null && transportMode.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_resolveTransportIcon(transportMode),
                          size: 12, color: AppColors.primary),
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
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F8F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEFECE6), width: 0.8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.sand,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.place_rounded,
                        size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
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
                            letterSpacing: 0.5,
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
                    icon: const Icon(Icons.copy_rounded,
                        size: 16, color: Color(0xFF8E8E93)),
                    tooltip: 'Copy Departure Point',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _copyDeparturePoint(context),
                  ),
                ],
              ),
            ),
          ],
          if (trip.transportMeta != null && trip.transportMeta!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F8F6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEFECE6), width: 0.8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_car_filled_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      () {
                        final meta = trip.transportMeta!;
                        final mode = meta['mode']?.toString() ?? '';
                        if (mode == 'rental') {
                          final days = meta['rental_days'] ?? 1;
                          final driver = meta['has_driver'] == true ? 'with driver' : 'self-drive';
                          return 'Charter: $days-day van rental ($driver)';
                        }
                        if (mode == 'commute') {
                          final fare = meta['fare_per_pax'];
                          final hub = meta['transit_hub_name'] ?? 'Transit';
                          return fare != null ? 'Commute: ₱$fare/pax via $hub' : 'Commute: $hub';
                        }
                        final vName = meta['vehicle_name'] ?? 'Personal Vehicle';
                        final kml = meta['kml'];
                        return kml != null ? 'Vehicle: $vName ($kml km/L)' : 'Vehicle: $vName';
                      }(),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
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
    final remainingCount =
        members.length > maxAvatars ? members.length - maxAvatars : 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Overlapping avatar cluster
            SizedBox(
              height: 36,
              width: (displayMembers.length * 24.0) +
                  (remainingCount > 0 ? 32 : 12),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  for (int i = 0; i < displayMembers.length; i++)
                    Positioned(
                      left: i * 22.0,
                      child: MemberAvatarCircle(
                        photoUrl: displayMembers[i].profilePhotoUrl,
                        initials: displayMembers[i].initials,
                        color: displayMembers[i].color,
                        size: 34,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  if (remainingCount > 0)
                    Positioned(
                      left: displayMembers.length * 22.0,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.deepEarth,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '+$remainingCount',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${members.length} Squad ${members.length == 1 ? 'Member' : 'Members'}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.sand,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${members.where((m) => m.isOrganizer).length} Host',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkAccent,
                          ),
                        ),
                      ),
                    ],
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
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: Color(0xFFB0B0B8)),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
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
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _barColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(Icons.account_balance_wallet_rounded,
                          size: 16, color: _barColor),
                    ),
                    const SizedBox(width: 9),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trip Budget & Expenses',
                          style: TextStyle(
                            fontSize: 14,
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
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _pctColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${(budgetPct * 100).round()}% used',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _pctColor,
                      ),
                    ),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'No Budget Set',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            if (budget > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: budgetPct),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, val, __) => LinearProgressIndicator(
                    value: val,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFF2F2F7),
                    valueColor: AlwaysStoppedAnimation<Color>(_barColor),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Spent / Pending / Remaining
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F8F6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEFECE6), width: 0.8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _BudgetStat(
                      label: 'Spent',
                      value: '₱${_fmt(totalSpent)}',
                      valueColor: const Color(0xFF1A1A1A),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: const Color(0xFFE5E2DC),
                  ),
                  Expanded(
                    child: _BudgetStat(
                      label: 'Pending',
                      value: '₱${_fmt(totalPending)}',
                      valueColor: const Color(0xFF854F0B),
                      align: CrossAxisAlignment.center,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: const Color(0xFFE5E2DC),
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
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF8E8E93),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _InviteCard extends StatelessWidget {
  final TripModel trip;
  const _InviteCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => PrivacyInviteCodeWidget(
        code: trip.inviteCode,
        onShare: () {
          ShareTripModal.show(
            context,
            ref,
            trip,
            initialScope: ShareScope.overview,
          );
        },
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
        border: Border.all(
            color: AppColors.amber.withValues(alpha: 0.35), width: 1.2),
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
              border:
                  Border.all(color: AppColors.amber.withValues(alpha: 0.25)),
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
