import 'package:flutter/material.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/itinerary_provider.dart';
import '../../core/providers/realtime_provider.dart';
import '../../core/providers/trip_provider.dart';
import '../../core/models/itinerary_model.dart';
import '../../core/models/member_model.dart';
import '../../core/providers/trip_weather_provider.dart';
import '../../core/widgets/share/share_trip_modal.dart';
import '../../core/widgets/shimmer_loading.dart';
import 'widgets/day_strip.dart';
import 'widgets/stop_card.dart';
import 'widgets/add_stop_form.dart';
import 'widgets/edit_stop_form.dart';
import 'widgets/transport_badge.dart';
import 'widgets/itinerary_map.dart';
import 'widgets/navigate_route_button.dart';
import 'widgets/timeline_view.dart';
import 'widgets/day_budget_bar.dart';
import 'widgets/day_summary_card.dart';
import 'widgets/smart_suggestion_chips.dart';
import 'widgets/arrival_pill.dart';
import 'widgets/itinerary_fulfillment_banner.dart';
import 'widgets/inter_stop_transit_badge.dart';
import 'widgets/roll_call_sheet.dart';
import 'widgets/day_actions_sheet.dart';
import 'utils/transit_conflict_helper.dart';
import '../budget/widgets/add_expense_form.dart';
import '../../core/models/expense_model.dart';
import '../../core/providers/expense_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/widgets/buttons/app_back_button.dart';

// ── View mode toggle ─────────────────────────────────────────────────────────
enum _StopViewMode { list, timeline }

class ItineraryScreen extends ConsumerStatefulWidget {
  final bool showHeader;
  const ItineraryScreen({super.key, this.showHeader = true});

  @override
  ConsumerState<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends ConsumerState<ItineraryScreen> {
  _StopViewMode _viewMode = _StopViewMode.list;
  String? _editingStopId;

  // ── Arrival Pill state ─────────────────────────────────────────
  ItineraryStop? _nearbyStop;
  bool _pillDismissed = false;

  void _showArrivalPill(ItineraryStop stop) {
    setState(() {
      _nearbyStop = stop;
      _pillDismissed = false;
    });
  }

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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logged "${expense.description}" (₱${expense.amount.toStringAsFixed(0)}) as trip expense! 💰'),
                      backgroundColor: AppColors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  void _openRollCallSheet(
    BuildContext context,
    int dayIndex,
    ItineraryStop stop,
    List<MemberModel> members,
    ItineraryNotifier notifier,
  ) {
    RollCallSheet.show(
      context,
      stop: stop,
      members: members,
      onSave: (ids) {
        notifier.updateCheckedInMembers(dayIndex, stop.id, ids);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(activeTripProvider);

    return tripAsync.when(
      data: (trip) {
        if (trip == null) {
          return const Scaffold(body: Center(child: Text('No active trip found.')));
        }

        // Feature 8 — listen to live realtime stream for itinerary
        ref.watch(itineraryRealtimeProvider(trip.id));

        final itineraryAsync = ref.watch(ref.watch(itineraryProvider(trip.id)));
        final weatherAsync = ref.watch(tripWeatherProvider(trip.id));
        final weatherList = weatherAsync.value;
        final currentMember = ref.watch(currentMemberProvider(trip));
        final canManageItinerary = currentMember?.canManageItinerary ?? true;

        return itineraryAsync.when(
          data: (itineraryState) {
            final days = itineraryState.days;
            final activeDay = itineraryState.activeDay;
            final currentDay = (days.isNotEmpty && activeDay < days.length)
                ? days[activeDay]
                : (days.isNotEmpty ? days.first : null);

            return Scaffold(
              backgroundColor: AppColors.deepEarth,
              body: Column(
                children: [
                  // ── Header Section ──────────────────────────────────────────
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      MediaQuery.paddingOf(context).top + 12,
                      20,
                      16,
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
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if (Navigator.canPop(context))
                                  const Padding(
                                    padding: EdgeInsets.only(right: 12),
                                    child: AppBackButton(),
                                  ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(trip.name, style: const TextStyle(fontFamily: 'Playfair Display', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                                    Text(trip.destination, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: Colors.white54)),
                                  ],
                                ),
                                // Feature 8 — Live indicator dot
                                _LiveDot(),
                                const SizedBox(width: 10),
                                // Feature 5 — View mode toggle
                                _ViewToggleButton(
                                  mode: _viewMode,
                                  onToggle: () => setState(() {
                                    _viewMode = _viewMode == _StopViewMode.list
                                        ? _StopViewMode.timeline
                                        : _StopViewMode.list;
                                  }),
                                ),
                                const SizedBox(width: 10),
                                // Calendar export btn
                                GestureDetector(
                                  onTap: () => _showCalendarSnack(context, currentDay),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.calendar_month_outlined, color: Colors.white, size: 20),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Map view btn
                                GestureDetector(
                                  onTap: () => _showMapView(context, currentDay),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.map_outlined, color: Colors.white, size: 20),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Share itinerary button
                                GestureDetector(
                                  onTap: () => ShareTripModal.show(
                                    context,
                                    ref,
                                    trip,
                                    initialScope: days.isNotEmpty ? ShareScope.currentDay : ShareScope.itinerary,
                                    activeDayIndex: activeDay,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.share_rounded, color: Colors.white, size: 14),
                                        SizedBox(width: 4),
                                        Text('Share', style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ),
                                if (canManageItinerary && currentDay != null) ...[
                                  const SizedBox(width: 10),
                                  // Day Actions button
                                  GestureDetector(
                                    onTap: () => DayActionsSheet.show(
                                      context,
                                      activeDayIndex: activeDay,
                                      day: currentDay,
                                      allDays: days,
                                      notifier: ref.read(ref.read(itineraryProvider(trip.id)).notifier),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.tune_rounded, color: Colors.white, size: 14),
                                          SizedBox(width: 4),
                                          Text('Actions', style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 10),
                                // Arrival demo trigger (simulates GPS proximity)
                                GestureDetector(
                                  onTap: () {
                                    final next = currentDay?.stops.where((s) => !s.isCompleted).firstOrNull;
                                    if (next != null) _showArrivalPill(next);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.greenBright.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.greenBright.withValues(alpha: 0.4)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.location_on_rounded, color: AppColors.greenBright, size: 14),
                                        SizedBox(width: 4),
                                        Text('Arrive', style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.greenBright)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        // Day strip — always visible
                        if (days.isNotEmpty)
                          DayStrip(
                            dayLabels: days.map((d) => 'Day ${d.dayNumber} · ${DateFormat('MMM d').format(d.date)}').toList(),
                            activeIndex: activeDay,
                            weather: weatherList,
                            onTap: (i) => ref.read(ref.read(itineraryProvider(trip.id)).notifier).setActiveDay(i),
                            onAddDay: canManageItinerary ? () => ref.read(ref.read(itineraryProvider(trip.id)).notifier).addDay() : null,
                          ),
                      ],
                    ),
                  ),

                  // ── Body ──────────────────────────────────────────────────
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                      ),
                      child: currentDay == null
                          ? const Center(child: Text('No itinerary yet.', style: TextStyle(fontFamily: 'DM Sans', color: AppColors.muted)))
                          : _viewMode == _StopViewMode.timeline
                              ? TimelineView(
                                  day: currentDay,
                                  onStopTap: (s) => _showStopDetail(context, s, trip.members, activeDay, trip.id, currentDay.date),
                                )
                              : _buildListContent(currentDay, activeDay, trip.members, trip.id, trip.totalBudget, days.length),
                    ),
                  ),
                ],
              ),

              floatingActionButton: (currentDay == null || !canManageItinerary) ? null : FloatingActionButton.extended(
                onPressed: () {
                  final notifier = ref.read(ref.read(itineraryProvider(trip.id)).notifier);
                  _openAddForm(context, activeDay, trip.members, notifier);
                },
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Stop', style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w600)),
              ),

              // ── Arrival Pill Overlay ─────────────────────────────
              floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
            );
          },
          loading: () => const ItineraryScreenSkeleton(),
          error: (e, _) => Scaffold(backgroundColor: AppColors.deepEarth, body: Center(child: Text('Itinerary Error: $e', style: const TextStyle(color: Colors.white)))),
        );
      },
      loading: () => const ItineraryScreenSkeleton(),
      error: (e, _) => Scaffold(backgroundColor: AppColors.deepEarth, body: Center(child: Text('Trip Error: $e', style: const TextStyle(color: Colors.white)))),
    );
  }

  // ── Feature 1+2+3+10 — List content with drag-reorder ───────────────────
  Widget _buildListContent(ItineraryDay day, int dayIndex, List<MemberModel> members, String tripId, double tripBudget, int totalDaysCount) {
    final notifier = ref.read(ref.read(itineraryProvider(tripId)).notifier);
    final dailyBudget = (tripBudget > 0 && totalDaysCount > 0) ? tripBudget / totalDaysCount : 0.0;
    // Current user member (first for demo; in production use auth)
    final currentMemberId = members.isNotEmpty ? members.first.id : 'me';

    return Stack(
      children: [
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fulfillment Banner
              const SizedBox(height: 14),
              ItineraryFulfillmentBanner(day: day, allMembers: members),
              // Feature 3 — Budget bar
              if (day.totalDayCost > 0 || dailyBudget > 0) ...[
            const SizedBox(height: 12),
            DayBudgetBar(spent: day.totalDayCost, dailyBudget: dailyBudget),
              ],

              // Transport badge
              if (day.transport != null) ...[
            const SizedBox(height: 8),
            TransportBadge(transport: day.transport!),
              ],

              // Google Maps Directions bar for the entire day itinerary
              if (day.stops.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: NavigateRouteButton(stops: day.stops),
            ),
              ],

              // Stop count header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  '${day.stops.length} stop${day.stops.length == 1 ? '' : 's'} · Day ${day.dayNumber}',
                  style: const TextStyle(fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.warmMuted, letterSpacing: 1.5),
                ),
              ),

              // Feature 1 — Drag & drop reorderable stop list
              if (day.stops.isNotEmpty)
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  buildDefaultDragHandles: false,
                  onReorder: (oldIdx, newIdx) => notifier.reorderStop(dayIndex, oldIdx, newIdx),
                  itemCount: day.stops.length,
                  itemBuilder: (context, i) {
                    final stop = day.stops[i];
                    final isEditing = _editingStopId == stop.id;
                    final prevStop = i > 0 ? day.stops[i - 1] : null;
                    final transitInfo = prevStop != null
                        ? TransitConflictHelper.analyze(from: prevStop, to: stop)
                        : null;

                    return KeyedSubtree(
                      key: ValueKey(stop.id),
                      child: Column(
                        key: ValueKey('col_${stop.id}'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Inter-Stop Transit & Conflict Badge
                          if (transitInfo != null && (transitInfo.distanceKm != null || transitInfo.hasWarning))
                            InterStopTransitBadge(info: transitInfo),

                          // Feature 2 — Dismissible for swipe-to-delete
                          Dismissible(
                            key: ValueKey('dis_${stop.id}'),
                            direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_rounded, color: Colors.white, size: 22),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete stop?', style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w700)),
                              content: Text('Remove "${stop.title}" from Day ${day.dayNumber}?', style: const TextStyle(fontFamily: 'DM Sans')),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
                                  child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ) ?? false;
                        },
                        onDismissed: (_) => notifier.deleteStop(dayIndex, stop.id),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              // Feature 1 — Drag handle
                              ReorderableDragStartListener(
                                index: i,
                                child: const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(Icons.drag_handle_rounded, size: 18, color: AppColors.muted),
                                ),
                              ),
                              Expanded(
                                child: StopCard(
                                  stop: stop,
                                  members: members,
                                  isLast: i == day.stops.length - 1,
                                  onTap: () => _showStopDetail(context, stop, members, dayIndex, tripId, day.date),
                                  onStatusChange: (s) => notifier.updateStopStatus(dayIndex, stop.id, s),
                                  // Feature 2 — edit button
                                  onEdit: () => setState(() => _editingStopId = isEditing ? null : stop.id),
                                  onCheckIn: () => notifier.toggleStopVisited(dayIndex, stop.id, currentMemberId),
                                  onLogExpense: () => _openLogExpenseForm(context, stop, members, tripId, day.date),
                                  onRollCall: () => _openRollCallSheet(context, dayIndex, stop, members, notifier),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Feature 2 — Inline edit form
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
                );
              },
            ),

              // Feature 10 — Smart suggestion chips (Quick Add Templates)
              SmartSuggestionChips(
                day: day,
                onSuggest: (type, title) {
                  _openAddForm(context, dayIndex, members, notifier, initialType: type, initialTitle: title);
                },
              ),

              // Feature 10 — Day summary card
              if (day.stops.isNotEmpty) ...[  
                const SizedBox(height: 16),
                DaySummaryCard(day: day),
              ],
            ],
          ),
        ),

        // ── Arrival Pill Overlay ───────────────────────────────────
        if (_nearbyStop != null && !_pillDismissed)
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: SafeArea(
              child: ArrivalPill(
                stop: _nearbyStop!,
                checkedInMembers: members
                    .where((m) => _nearbyStop!.checkedInMemberIds.contains(m.id))
                    .toList(),
                onCheckIn: () {
                  notifier.toggleStopVisited(
                    dayIndex,
                    _nearbyStop!.id,
                    currentMemberId,
                  );
                  setState(() => _pillDismissed = true);
                },
                onDismiss: () => setState(() => _pillDismissed = true),
              ),
            ),
          ),
      ],
    );
  }

  void _showStopDetail(BuildContext context, ItineraryStop stop, List<MemberModel> members, int dayIndex, String tripId, DateTime stopDate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StopDetailSheet(
        stop: stop,
        members: members,
        onStatusChange: (s) => ref.read(ref.read(itineraryProvider(tripId)).notifier).updateStopStatus(dayIndex, stop.id, s),
        onVote: (memberId, upvote) => ref.read(ref.read(itineraryProvider(tripId)).notifier).voteOnStop(dayIndex, stop.id, memberId, upvote),
        onEdit: () {
          Navigator.pop(context);
          _openEditForm(context, dayIndex, stop, members, ref.read(ref.read(itineraryProvider(tripId)).notifier));
        },
        onLogExpense: () {
          Navigator.pop(context);
          _openLogExpenseForm(context, stop, members, tripId, stopDate);
        },
        onRollCall: () {
          Navigator.pop(context);
          _openRollCallSheet(context, dayIndex, stop, members, ref.read(ref.read(itineraryProvider(tripId)).notifier));
        },
      ),
    );
  }

  void _showMapView(BuildContext context, ItineraryDay? day) {
    if (day == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MapViewSheet(day: day),
    );
  }

  // Feature 9 — Calendar export
  void _showCalendarSnack(BuildContext context, ItineraryDay? day) {
    if (day == null || day.stops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No stops to export for this day', style: TextStyle(fontFamily: 'DM Sans'))),
      );
      return;
    }
    
    for (final stop in day.stops) {
      DateTime startTime = day.date;
      DateTime endTime = day.date.add(const Duration(hours: 1));
      
      if (stop.startTime != null) {
        startTime = DateTime(day.date.year, day.date.month, day.date.day, stop.startTime!.hour, stop.startTime!.minute);
        if (stop.endTime != null) {
          endTime = DateTime(day.date.year, day.date.month, day.date.day, stop.endTime!.hour, stop.endTime!.minute);
        } else {
          endTime = startTime.add(const Duration(hours: 1));
        }
      }

      final Event event = Event(
        title: stop.title,
        description: stop.notes ?? 'Trip stop from TaraTravel',
        location: stop.location ?? '',
        startDate: startTime,
        endDate: endTime,
        iosParams: const IOSParams(reminder: Duration(minutes: 30)),
      );

      Add2Calendar.addEvent2Cal(event);
    }
    
    final count = day.stops.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📅 $count stop${count == 1 ? '' : 's'} exported to Calendar!', style: const TextStyle(fontFamily: 'DM Sans')),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── Live indicator dot (Feature 8) ──────────────────────────────────────────
class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
          decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
        ),
      ),
    );
  }
}

// ── View toggle button (Feature 5) ──────────────────────────────────────────
class _ViewToggleButton extends StatelessWidget {
  final _StopViewMode mode;
  final VoidCallback onToggle;

  const _ViewToggleButton({required this.mode, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
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
              : null,
        ),
        child: Icon(
          mode == _StopViewMode.list ? Icons.timeline_rounded : Icons.view_list_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

// ── Stop Detail Sheet (Feature 6 — voting added) ────────────────────────────
class _StopDetailSheet extends StatelessWidget {
  final ItineraryStop stop;
  final List<MemberModel> members;
  final void Function(StopStatus) onStatusChange;
  final void Function(String memberId, bool upvote) onVote;
  final VoidCallback onEdit;
  final VoidCallback? onLogExpense;
  final VoidCallback? onRollCall;

  const _StopDetailSheet({
    required this.stop,
    required this.members,
    required this.onStatusChange,
    required this.onVote,
    required this.onEdit,
    this.onLogExpense,
    this.onRollCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.zero,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 16, bottom: 16),
              width: 36, 
              height: 4, 
              decoration: BoxDecoration(color: AppColors.dividerLight, borderRadius: BorderRadius.circular(2))
            ),
          ),
          
          // Feature 11 — Photo Gallery
          if (stop.photoUrls.isNotEmpty)
            SizedBox(
              height: 200,
              child: PageView.builder(
                itemCount: stop.photoUrls.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: NetworkImage(stop.photoUrls[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          
          if (stop.photoUrls.isNotEmpty) const SizedBox(height: 16),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: stop.type.color.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(stop.type.icon, color: stop.type.color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(stop.title, style: const TextStyle(fontFamily: 'Playfair Display', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.deepEarth))),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (stop.location != null) _infoRow(Icons.place_outlined, stop.location!),
          if (stop.estimatedCost != null) _infoRow(Icons.attach_money_rounded, '₱${stop.estimatedCost!.toInt()} estimated'),
          if (stop.confirmationNumber != null) _infoRow(Icons.confirmation_number_outlined, 'Ref: ${stop.confirmationNumber}'),

          // 1-Tap Google Maps Navigation Button
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => openGoogleMapsForStop(context, stop),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.directions_rounded, size: 18),
                    label: const Text(
                      'Navigate Maps',
                      style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              if (onLogExpense != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: onLogExpense,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.amberText,
                        side: const BorderSide(color: AppColors.amber),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.receipt_long_rounded, size: 16),
                      label: const Text(
                        'Expense',
                        style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
              if (onRollCall != null && members.length > 1) ...[
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: onRollCall,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.greenBright,
                      side: const BorderSide(color: AppColors.greenBright),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.people_alt_rounded, size: 16),
                    label: Text(
                      'Roll Call (${stop.checkedInMemberIds.length}/${members.length})',
                      style: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (stop.notes != null && stop.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Notes', style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
            const SizedBox(height: 4),
            Text(stop.notes!, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: AppColors.textSecondary)),
          ],

          // Feature 7 — Attachments
          if (stop.attachmentUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Attachments', style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: stop.attachmentUrls.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.dividerLight),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text('Attachment ${index + 1}', style: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],

          // Feature 6 — Collaborative voting
          const SizedBox(height: 16),
          const Text('Group Vote', style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
          const SizedBox(height: 8),
          Row(
            children: [
              _VoteButton(
                icon: Icons.thumb_up_rounded,
                count: stop.votes.values.where((v) => v).length,
                color: const Color(0xFF10B981),
                onTap: () {
                  if (members.isNotEmpty) onVote(members.first.id, true);
                },
              ),
              const SizedBox(width: 12),
              _VoteButton(
                icon: Icons.thumb_down_rounded,
                count: stop.votes.values.where((v) => !v).length,
                color: const Color(0xFFEF4444),
                onTap: () {
                  if (members.isNotEmpty) onVote(members.first.id, false);
                },
              ),
              const Spacer(),
              if (stop.voteScore != 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: stop.voteScore > 0 ? const Color(0xFF10B981).withValues(alpha: 0.1) : const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${stop.voteScore > 0 ? '+' : ''}${stop.voteScore} score',
                    style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w700, color: stop.voteScore > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                  ),
                ),
            ],
          ),

          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () { onStatusChange(StopStatus.approved); Navigator.pop(context); },
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                  label: const Text('Approve', style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.green, side: const BorderSide(color: AppColors.green)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () { onStatusChange(StopStatus.arrived); Navigator.pop(context); },
                  icon: const Icon(Icons.location_on_rounded, size: 16),
                  label: const Text('Arrived', style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0),
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
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: AppColors.textSecondary))),
        ],
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _VoteButton({required this.icon, required this.count, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Text('$count', style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Map View Sheet ───────────────────────────────────────────────────────────
class _MapViewSheet extends StatelessWidget {
  final ItineraryDay day;

  const _MapViewSheet({required this.day});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.deepEarth,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Row(
              children: [
                const Text('Day Map View', style: TextStyle(fontFamily: 'Playfair Display', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                const Spacer(),
                GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close_rounded, color: Colors.white54)),
              ],
            ),
          ),
          // Google Map
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: const Color(0xFF1E3A2B), borderRadius: BorderRadius.circular(20)),
              child: ItineraryMap(day: day),
            ),
          ),
          const SizedBox(height: 16),
          // Stop list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: day.stops.length,
              itemBuilder: (_, i) {
                final s = day.stops[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(color: s.type.color, shape: BoxShape.circle),
                        child: Center(child: Text('${i + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.title, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: Colors.white)),
                            if (s.location != null)
                              Text(s.location!, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Navigate button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: NavigateRouteButton(stops: day.stops),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
