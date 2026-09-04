import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../core/models/expense_model.dart';
import '../../core/models/itinerary_model.dart';
import '../../core/models/member_model.dart';
import '../../core/providers/expense_provider.dart';
import '../../core/providers/itinerary_provider.dart';
import '../../core/providers/realtime_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/providers/trip_provider.dart';
import '../../core/providers/trip_weather_provider.dart';
import '../../core/services/location_tracking_service.dart';
import '../../core/services/module_view_tracker_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/buttons/app_back_button.dart';
import '../../core/widgets/feedback/app_dialog.dart';
import '../../core/widgets/feedback/app_feedback.dart';
import '../../core/widgets/feedback/feedback_type.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../budget/widgets/add_expense_form.dart';
import 'utils/transit_conflict_helper.dart';
import 'widgets/add_stop_form.dart';
import 'widgets/arrival_pill.dart';
import 'widgets/day_insights_header.dart';
import 'widgets/day_strip.dart';
import 'widgets/day_summary_card.dart';
import 'widgets/edit_stop_form.dart';
import 'widgets/inter_stop_transit_badge.dart';
import 'widgets/itinerary_action_sheet.dart';
import 'widgets/itinerary_bottom_dock.dart';
import 'widgets/smart_suggestion_chips.dart';
import 'widgets/stop_card.dart';
import 'widgets/stop_detail_sheet.dart';
import 'widgets/timeline_view.dart';

enum _StopViewMode { list, timeline }

/// Main Itinerary Screen for Tara Travel, refactored for IDEA-002
/// with progressive disclosure, consolidated action hubs, automated GPS arrival geofencing,
/// and a floating action dock.
class ItineraryScreen extends ConsumerStatefulWidget {
  final bool showHeader;
  final String? targetStopId;
  final int? targetDayNumber;

  const ItineraryScreen({
    super.key,
    this.showHeader = true,
    this.targetStopId,
    this.targetDayNumber,
  });

  @override
  ConsumerState<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends ConsumerState<ItineraryScreen> {
  _StopViewMode _viewMode = _StopViewMode.list;
  String? _editingStopId;
  String? _focusedStopId;
  int? _focusedDayNumber;
  bool _hasAttemptedScroll = false;
  final Map<String, GlobalKey> _stopKeys = {};

  // ── Arrival Detection & Geofence State ────────────────────────────────────
  ItineraryStop? _nearbyStop;
  bool _pillDismissed = false;
  final Set<String> _dismissedStopIds = <String>{};
  StreamSubscription<LocationSnapshot>? _gpsSub;

  @override
  void initState() {
    super.initState();
    _focusedStopId = widget.targetStopId;
    _focusedDayNumber = widget.targetDayNumber;
    _startGpsGeofencing();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final trip = ref.read(activeTripProvider).value;
      if (trip != null) {
        ModuleViewTrackerService.instance.markViewed('itinerary', trip.id);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_focusedStopId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _focusedStopId = args['targetStopId'] as String?;
        _focusedDayNumber = args['targetDayNumber'] as int?;
      }
    }
  }

  void _scrollToFocusedStop() {
    if (_focusedStopId == null || _hasAttemptedScroll) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        final key = _stopKeys[_focusedStopId];
        if (key?.currentContext != null) {
          Scrollable.ensureVisible(
            key!.currentContext!,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            alignment: 0.25,
          );
          if (mounted) {
            setState(() {
              _hasAttemptedScroll = true;
            });
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    super.dispose();
  }

  /// Listen to real-time location stream and check proximity to uncompleted stops
  void _startGpsGeofencing() {
    _gpsSub = LocationTrackingService.instance.snapshotStream.listen((snapshot) {
      if (!mounted) return;
      final trip = ref.read(activeTripProvider).value;
      if (trip == null) return;

      final itineraryState =
          ref.read(ref.read(itineraryProvider(trip.id))).value;
      if (itineraryState == null || itineraryState.days.isEmpty) return;

      final activeDayIndex = itineraryState.activeDay;
      if (activeDayIndex >= itineraryState.days.length) return;
      final currentDay = itineraryState.days[activeDayIndex];

      for (final stop in currentDay.stops) {
        if (stop.isCompleted || _dismissedStopIds.contains(stop.id)) continue;
        if (stop.lat != null &&
            stop.lng != null &&
            stop.lat != 0.0 &&
            stop.lng != 0.0) {
          final distance = Geolocator.distanceBetween(
            snapshot.lat,
            snapshot.lng,
            stop.lat!,
            stop.lng!,
          );

          // Within 150m arrival geofence
          if (distance <= 150.0) {
            if (_nearbyStop?.id != stop.id) {
              setState(() {
                _nearbyStop = stop;
                _pillDismissed = false;
              });
            }
            break;
          }
        }
      }
    });
  }

  void _showArrivalPill(ItineraryStop stop) {
    setState(() {
      _nearbyStop = stop;
      _pillDismissed = false;
    });
  }

  // ── Modal Forms ────────────────────────────────────────────────────────────

  void _openAddForm(
    BuildContext context,
    int dayIndex,
    List<MemberModel> members,
    ItineraryNotifier notifier, {
    StopType? initialType,
    String? initialTitle,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(12),
            child: AddStopForm(
              members: members,
              initialType: initialType,
              initialTitle: initialTitle,
              onAdd: (stop) {
                notifier.addStop(dayIndex, stop);
                Navigator.pop(ctx);
              },
            ),
          ),
        ),
      ),
    );
  }

  void _openEditForm(
    BuildContext context,
    int dayIndex,
    ItineraryStop stop,
    List<MemberModel> members,
    ItineraryNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(12),
            child: EditStopForm(
              stop: stop,
              members: members,
              onSave: (updated) {
                notifier.updateStop(dayIndex, updated);
                Navigator.pop(ctx);
              },
              onCancel: () => Navigator.pop(ctx),
            ),
          ),
        ),
      ),
    );
  }

  void _openLogExpenseForm(
    BuildContext context,
    ItineraryStop stop,
    List<MemberModel> members,
    String tripId,
    DateTime stopDate,
  ) {
    ExpenseCategory category;
    switch (stop.type) {
      case StopType.hotel:
        category = ExpenseCategory.hotel;
        break;
      case StopType.activity:
        category = ExpenseCategory.activities;
        break;
      case StopType.food:
        category = ExpenseCategory.food;
        break;
      case StopType.transport:
        category = ExpenseCategory.transport;
        break;
      case StopType.custom:
        category = ExpenseCategory.custom;
        break;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(12),
            child: AddExpenseForm(
              members: members,
              initialDescription: stop.title,
              initialAmount: stop.estimatedCost,
              initialCategory: category,
              initialDate: stopDate,
              onExpenseAdded: (expense) async {
                final repo = ref.read(expenseRepositoryProvider);
                await repo.addExpense(tripId, expense);
                ref.invalidate(expenseProvider(tripId));
                ref.invalidate(activeTripProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  AppFeedback.showSuccess(
                    context,
                    'Logged "${expense.description}" (₱${expense.amount.toStringAsFixed(0)}) as trip expense! 💰',
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showStopDetail(
    BuildContext context,
    ItineraryStop stop,
    List<MemberModel> members,
    int dayIndex,
    String tripId,
    DateTime stopDate, {
    String? currentUserId,
    bool canManage = false,
    ItineraryStop? previousStop,
  }) {
    final notifier = ref.read(ref.read(itineraryProvider(tripId)).notifier);
    final selfId = currentUserId ??
        (members.isNotEmpty ? members.first.id : 'me');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StopDetailSheet(
        stop: stop,
        members: members,
        previousStop: previousStop,
        currentUserId: selfId,
        canManage: canManage,
        onEdit: () {
          Navigator.pop(context);
          _openEditForm(
            context,
            dayIndex,
            stop,
            members,
            notifier,
          );
        },
        onLogExpense: () {
          Navigator.pop(context);
          _openLogExpenseForm(context, stop, members, tripId, stopDate);
        },
        onCheckIn: () {
          final isCurrentlyCompleted = stop.isCompleted;
          notifier.toggleStopVisited(dayIndex, stop.id, selfId);

          // If stop was marked as arrived, display floating confirmed banner with Undo action on the main screen
          if (!isCurrentlyCompleted && context.mounted) {
            AppFeedback.show(
              context,
              type: FeedbackType.success,
              title: '✓ Arrived at ${stop.title}',
              message: 'Arrival recorded in itinerary · Stop completed',
              customIcon: Icons.check_circle_rounded,
              actionLabel: 'Undo',
              duration: const Duration(seconds: 6),
              onAction: () {
                notifier.toggleStopVisited(dayIndex, stop.id, selfId);
              },
            );
          }
        },
        onMemberToggle: (memberId) {
          notifier.toggleStopVisited(dayIndex, stop.id, memberId);
        },
        onMarkAllArrived: () {
          notifier.updateCheckedInMembers(
            dayIndex,
            stop.id,
            members.map((m) => m.id).toList(),
          );
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(activeTripProvider);

    return tripAsync.when(
      data: (trip) {
        if (trip == null) {
          return const Scaffold(
            body: Center(child: Text('No active trip found.')),
          );
        }

        // Live Supabase stream listener
        ref.watch(itineraryRealtimeProvider(trip.id));

        final itineraryAsync = ref.watch(ref.watch(itineraryProvider(trip.id)));
        final weatherAsync = ref.watch(tripWeatherProvider(trip.id));
        final weatherList = weatherAsync.value;
        final currentMember = ref.watch(currentMemberProvider(trip));
        final canManageItinerary = currentMember?.canManageItinerary ?? false;

        return itineraryAsync.when(
          data: (itineraryState) {
            final days = itineraryState.days;
            final activeDay = itineraryState.activeDay;
            final notifier =
                ref.read(ref.read(itineraryProvider(trip.id)).notifier);

            // If target day number was provided and differs from activeDay, automatically switch to it
            if (_focusedDayNumber != null && days.isNotEmpty) {
              final targetIdx =
                  days.indexWhere((d) => d.dayNumber == _focusedDayNumber);
              if (targetIdx != -1 && targetIdx != activeDay) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  notifier.setActiveDay(targetIdx);
                });
              }
            }

            // Trigger scroll to focused winning stop
            if (_focusedStopId != null && !_hasAttemptedScroll) {
              _scrollToFocusedStop();
            }

            final currentDay = (days.isNotEmpty && activeDay < days.length)
                ? days[activeDay]
                : (days.isNotEmpty ? days.first : null);
            final currentWeather =
                (weatherList != null && activeDay < weatherList.length)
                    ? weatherList[activeDay]
                    : null;
            final dailyBudget = (trip.totalBudget > 0 && days.isNotEmpty)
                ? trip.totalBudget / days.length
                : 0.0;

            return Scaffold(
              backgroundColor: AppColors.deepEarth,
              body: Stack(
                children: [
                  Column(
                    children: [
                      // ── Header Section ──────────────────────────────────
                      Container(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          MediaQuery.paddingOf(context).top + 12,
                          20,
                          14,
                        ),
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
                            if (widget.showHeader) ...[
                              Row(
                                children: [
                                  if (Navigator.canPop(context))
                                    const Padding(
                                      padding: EdgeInsets.only(right: 12),
                                      child: AppBackButton(),
                                    ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          trip.name,
                                          style: const TextStyle(
                                            fontFamily: 'Playfair Display',
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          trip.destination,
                                          style: const TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 13,
                                            color: Colors.white54,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Live sync dot indicator
                                  _LiveDot(),
                                  const SizedBox(width: 8),

                                  // View mode toggle
                                  _ViewToggleButton(
                                    mode: _viewMode,
                                    onToggle: () {
                                      HapticFeedback.lightImpact();
                                      setState(() {
                                        _viewMode =
                                            _viewMode == _StopViewMode.list
                                                ? _StopViewMode.timeline
                                                : _StopViewMode.list;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),

                                  // Consolidated "⋯ More" Action Hub
                                  InkWell(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      ItineraryActionSheet.show(
                                        context,
                                        trip: trip,
                                        day: currentDay,
                                        allDays: days,
                                        activeDayIndex: activeDay,
                                        canManageItinerary: canManageItinerary,
                                        notifier: notifier,
                                        ref: ref,
                                        onSimulateArrival: () {
                                          final next = currentDay?.stops
                                              .where((s) => !s.isCompleted)
                                              .firstOrNull;
                                          if (next != null) {
                                            _showArrivalPill(next);
                                          }
                                        },
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.15),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.more_horiz_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Day strip
                            if (days.isNotEmpty)
                              DayStrip(
                                dayLabels: days
                                    .map((d) =>
                                        'Day ${d.dayNumber} · ${DateFormat('MMM d').format(d.date)}')
                                    .toList(),
                                activeIndex: activeDay,
                                weather: weatherList,
                                onTap: (i) => notifier.setActiveDay(i),
                                onAddDay: canManageItinerary
                                    ? () async {
                                        final newDay = await notifier.addDay();
                                        if (context.mounted && newDay != null) {
                                          AppFeedback.showSuccess(
                                            context,
                                            'Added Day ${newDay.dayNumber} (${DateFormat('MMM d').format(newDay.date)}) to itinerary! 🗓️',
                                          );
                                        }
                                      }
                                    : null,
                              ),
                          ],
                        ),
                      ),

                      // ── Body ────────────────────────────────────────────
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(28),
                              topRight: Radius.circular(28),
                            ),
                          ),
                          child: currentDay == null
                              ? const Center(
                                  child: Text(
                                    'No itinerary yet.',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      color: AppColors.muted,
                                    ),
                                  ),
                                )
                              : _viewMode == _StopViewMode.timeline
                                  ? TimelineView(
                                      day: currentDay,
                                      onStopTap: (s) {
                                        final stops = currentDay.stops;
                                        final idx = stops.indexWhere((st) => st.id == s.id);
                                        _showStopDetail(
                                          context,
                                          s,
                                          trip.members,
                                          activeDay,
                                          trip.id,
                                          currentDay.date,
                                          currentUserId: currentMember?.id,
                                          canManage: canManageItinerary,
                                          previousStop: idx > 0 ? stops[idx - 1] : null,
                                        );
                                      },
                                    )
                                  : _buildListContent(
                                      currentDay,
                                      activeDay,
                                      trip.members,
                                      trip.id,
                                      dailyBudget,
                                      currentWeather,
                                      canManageItinerary,
                                    ),
                        ),
                      ),
                    ],
                  ),

                  // ── Floating Action Dock (Navigate Route + Add Stop) ─────
                  ItineraryBottomDock(
                    currentDay: currentDay,
                    tripId: trip.id,
                    canManage: canManageItinerary,
                    onAddStop: () => _openAddForm(
                      context,
                      activeDay,
                      trip.members,
                      notifier,
                    ),
                  ),

                  // ── Floating Arrival Pill Overlay ────────────────────────
                  if (_nearbyStop != null && !_pillDismissed)
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 16,
                      left: 16,
                      right: 16,
                      child: SafeArea(
                        child: ArrivalPill(
                          stop: _nearbyStop!,
                          checkedInMembers: trip.members
                              .where((m) => _nearbyStop!.checkedInMemberIds
                                  .contains(m.id))
                              .toList(),
                          onCheckIn: () {
                            final currentMemberId = trip.members.isNotEmpty
                                ? trip.members.first.id
                                : 'me';
                            notifier.toggleStopVisited(
                              activeDay,
                              _nearbyStop!.id,
                              currentMemberId,
                            );
                            _dismissedStopIds.add(_nearbyStop!.id);
                            setState(() => _pillDismissed = true);
                          },
                          onDismiss: () {
                            _dismissedStopIds.add(_nearbyStop!.id);
                            setState(() => _pillDismissed = true);
                          },
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          loading: () => const ItineraryScreenSkeleton(),
          error: (e, _) => Scaffold(
            backgroundColor: AppColors.deepEarth,
            body: Center(
              child: Text(
                'Itinerary Error: $e',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
      },
      loading: () => const ItineraryScreenSkeleton(),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.deepEarth,
        body: Center(
          child: Text(
            'Trip Error: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ── List View Content with Progressive Disclosure ───────────────────────────

  Widget _buildListContent(
    ItineraryDay day,
    int dayIndex,
    List<MemberModel> members,
    String tripId,
    double dailyBudget,
    dynamic weather,
    bool canManage,
  ) {
    final notifier = ref.read(ref.read(itineraryProvider(tripId)).notifier);
    final currentMemberId = members.isNotEmpty ? members.first.id : 'me';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Collapsible Day Insights Accordion (Weather, Budget, Fulfillment)
          DayInsightsHeader(
            day: day,
            members: members,
            dailyBudget: dailyBudget,
            weather: weather,
          ),

          // 2. Stop count header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: Row(
              children: [
                Text(
                  '${day.stops.length} STOP${day.stops.length == 1 ? '' : 'S'} · DAY ${day.dayNumber}',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warmMuted,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                if (day.stops.isNotEmpty && canManage)
                  const Text(
                    'Hold & Drag to reorder',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 10,
                      color: AppColors.muted,
                    ),
                  ),
              ],
            ),
          ),

          // 3. Drag & drop reorderable stop list
          if (day.stops.isNotEmpty)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              buildDefaultDragHandles: false,
              onReorder: (oldIdx, newIdx) =>
                  notifier.reorderStop(dayIndex, oldIdx, newIdx),
              itemCount: day.stops.length,
              itemBuilder: (context, i) {
                final stop = day.stops[i];
                final isEditing = _editingStopId == stop.id;
                final prevStop = i > 0 ? day.stops[i - 1] : null;
                final transitInfo = prevStop != null
                    ? TransitConflictHelper.analyze(from: prevStop, to: stop)
                    : null;
                final stopKey =
                    _stopKeys.putIfAbsent(stop.id, () => GlobalKey());

                return KeyedSubtree(
                  key: ValueKey(stop.id),
                  child: Container(
                    key: stopKey,
                    child: Column(
                      key: ValueKey('col_${stop.id}'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Inter-Stop Transit & Conflict Badge
                        if (transitInfo != null &&
                            (transitInfo.distanceKm != null ||
                                transitInfo.hasWarning))
                          InterStopTransitBadge(info: transitInfo),

                        // Swipe-to-delete dismissible
                        Dismissible(
                          key: ValueKey('dis_${stop.id}'),
                          direction: canManage
                              ? DismissDirection.endToStart
                              : DismissDirection.none,
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.delete_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          confirmDismiss: (_) async {
                            bool confirmed = false;
                            await AppDialog.showDestructive(
                              context,
                              title: 'Delete Stop?',
                              message:
                                  'Remove "${stop.title}" from Day ${day.dayNumber}?',
                              confirmLabel: 'Delete',
                              onConfirm: () => confirmed = true,
                            );
                            return confirmed;
                          },
                          onDismissed: (_) =>
                              notifier.deleteStop(dayIndex, stop.id),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                // Drag handle
                                if (canManage)
                                  ReorderableDragStartListener(
                                    index: i,
                                    child: const Padding(
                                      padding: EdgeInsets.only(right: 6),
                                      child: Icon(
                                        Icons.drag_handle_rounded,
                                        size: 18,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: StopCard(
                                    stop: stop,
                                    members: members,
                                    isLast: i == day.stops.length - 1,
                                    isHighlighted: stop.id == _focusedStopId,
                                    onTap: () => _showStopDetail(
                                      context,
                                      stop,
                                      members,
                                      dayIndex,
                                      tripId,
                                      day.date,
                                      currentUserId: currentMemberId,
                                      canManage: canManage,
                                      previousStop:
                                          i > 0 ? day.stops[i - 1] : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Inline edit form
                      if (isEditing) ...[
                        const SizedBox(height: 8),
                        EditStopForm(
                          stop: stop,
                          members: members,
                          onSave: (updated) {
                            notifier.updateStop(dayIndex, updated);
                            setState(() => _editingStopId = null);
                          },
                          onCancel: () => setState(() => _editingStopId = null),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              );
              },
            ),

          // 4. Collapsible Smart suggestion chips
          if (canManage)
            SmartSuggestionChips(
              day: day,
              onSuggest: (type, title) {
                _openAddForm(
                  context,
                  dayIndex,
                  members,
                  notifier,
                  initialType: type,
                  initialTitle: title,
                );
              },
            ),

          // 5. Day summary card
          if (day.stops.isNotEmpty) ...[
            const SizedBox(height: 8),
            DaySummaryCard(day: day),
          ],
        ],
      ),
    );
  }
}

// ── Live indicator dot ───────────────────────────────────────────────────────
class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF10B981),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ── View toggle button (List vs Timeline) ───────────────────────────────────
class _ViewToggleButton extends StatelessWidget {
  final _StopViewMode mode;
  final VoidCallback onToggle;

  const _ViewToggleButton({required this.mode, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: mode == _StopViewMode.timeline
              ? AppColors.primary.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: mode == _StopViewMode.timeline
              ? Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4))
              : Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(
          mode == _StopViewMode.list
              ? Icons.timeline_rounded
              : Icons.view_list_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
