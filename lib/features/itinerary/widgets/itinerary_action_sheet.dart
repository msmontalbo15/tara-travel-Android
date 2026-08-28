import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/models/trip_model.dart';
import '../../../core/providers/itinerary_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/feedback/app_dialog.dart';
import '../../../core/widgets/feedback/app_feedback.dart';
import '../../../core/widgets/share/share_trip_modal.dart';
import 'itinerary_map_sheet.dart';

/// Consolidated Action Hub ("⋯ More") bottom sheet for the itinerary screen.
/// Centralizes sharing, calendar export, day map preview, schedule shifting,
/// stop moving, and day lifecycle management.
class ItineraryActionSheet extends StatelessWidget {
  final TripModel trip;
  final ItineraryDay? day;
  final List<ItineraryDay> allDays;
  final int activeDayIndex;
  final bool canManageItinerary;
  final ItineraryNotifier notifier;
  final WidgetRef ref;
  final VoidCallback? onSimulateArrival;

  const ItineraryActionSheet({
    super.key,
    required this.trip,
    required this.day,
    required this.allDays,
    required this.activeDayIndex,
    required this.canManageItinerary,
    required this.notifier,
    required this.ref,
    this.onSimulateArrival,
  });

  static Future<void> show(
    BuildContext context, {
    required TripModel trip,
    required ItineraryDay? day,
    required List<ItineraryDay> allDays,
    required int activeDayIndex,
    required bool canManageItinerary,
    required ItineraryNotifier notifier,
    required WidgetRef ref,
    VoidCallback? onSimulateArrival,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ItineraryActionSheet(
        trip: trip,
        day: day,
        allDays: allDays,
        activeDayIndex: activeDayIndex,
        canManageItinerary: canManageItinerary,
        notifier: notifier,
        ref: ref,
        onSimulateArrival: onSimulateArrival,
      ),
    );
  }

  void _exportToCalendar(BuildContext context) {
    if (day == null || day!.stops.isEmpty) {
      AppFeedback.showInfo(context, 'No stops to export for this day.');
      return;
    }

    final currentDay = day!;
    for (final stop in currentDay.stops) {
      DateTime startTime = currentDay.date;
      DateTime endTime = currentDay.date.add(const Duration(hours: 1));

      if (stop.startTime != null) {
        startTime = DateTime(
          currentDay.date.year,
          currentDay.date.month,
          currentDay.date.day,
          stop.startTime!.hour,
          stop.startTime!.minute,
        );
        if (stop.endTime != null) {
          endTime = DateTime(
            currentDay.date.year,
            currentDay.date.month,
            currentDay.date.day,
            stop.endTime!.hour,
            stop.endTime!.minute,
          );
        } else {
          endTime = startTime.add(const Duration(hours: 1));
        }
      }

      final Event event = Event(
        title: stop.title,
        description: stop.notes ?? 'Trip stop from Tara Travel',
        location: stop.location ?? '',
        startDate: startTime,
        endDate: endTime,
        iosParams: const IOSParams(reminder: Duration(minutes: 30)),
      );

      Add2Calendar.addEvent2Cal(event);
    }

    final count = currentDay.stops.length;
    Navigator.pop(context);
    AppFeedback.showSuccess(
      context,
      '📅 $count stop${count == 1 ? '' : 's'} exported to Calendar!',
    );
  }

  void _showMoveStopPicker(BuildContext context) {
    if (day == null || day!.stops.isEmpty) {
      AppFeedback.showInfo(context, 'No stops in this day to move.');
      return;
    }

    if (allDays.length <= 1) {
      AppFeedback.showInfo(
          context, 'Add another day first to move stops across days.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Move Stop to Another Day',
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.deepEarth,
              ),
            ),
            const SizedBox(height: 12),
            ...day!.stops.map(
              (stop) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.dividerLight),
                ),
                child: Row(
                  children: [
                    Icon(stop.type.icon, size: 16, color: stop.type.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stop.title,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<int>(
                      icon: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      tooltip: 'Move to day',
                      onSelected: (targetIndex) {
                        notifier.moveStopToDay(
                          activeDayIndex,
                          targetIndex,
                          stop.id,
                        );
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                        AppFeedback.showSuccess(
                          context,
                          'Moved "${stop.title}" to Day ${targetIndex + 1}! 🚀',
                        );
                      },
                      itemBuilder: (_) => allDays
                          .asMap()
                          .entries
                          .where((e) => e.key != activeDayIndex)
                          .map((e) {
                        return PopupMenuItem(
                          value: e.key,
                          child: Text(
                            'Move to Day ${e.key + 1}',
                            style: const TextStyle(fontFamily: 'DM Sans'),
                          ),
                        );
                      }).toList(),
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

  @override
  Widget build(BuildContext context) {
    final currentDay = day;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.dividerLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.more_horiz_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentDay != null
                            ? 'Day ${currentDay.dayNumber} · Hub Actions'
                            : 'Itinerary Actions',
                        style: const TextStyle(
                          fontFamily: 'Playfair Display',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepEarth,
                        ),
                      ),
                      Text(
                        trip.name,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── Primary Action Grid ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  // Share
                  _HubActionTile(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                      ShareTripModal.show(
                        context,
                        ref,
                        trip,
                        initialScope: allDays.isNotEmpty
                            ? ShareScope.currentDay
                            : ShareScope.itinerary,
                        activeDayIndex: activeDayIndex,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  // Calendar Export
                  _HubActionTile(
                    icon: Icons.calendar_month_outlined,
                    label: 'Calendar',
                    color: const Color(0xFF3B82F6),
                    onTap: () => _exportToCalendar(context),
                  ),
                  const SizedBox(width: 8),
                  // Map View
                  _HubActionTile(
                    icon: Icons.map_outlined,
                    label: 'Day Map',
                    color: const Color(0xFF10B981),
                    onTap: () {
                      Navigator.pop(context);
                      if (currentDay != null) {
                        ItineraryMapSheet.show(
                          context,
                          day: currentDay,
                          tripId: trip.id,
                        );
                      }
                    },
                  ),
                  if (onSimulateArrival != null) ...[
                    const SizedBox(width: 8),
                    // Proximity simulation
                    _HubActionTile(
                      icon: Icons.near_me_rounded,
                      label: 'Arrival Pin',
                      color: const Color(0xFF8B5CF6),
                      onTap: () {
                        Navigator.pop(context);
                        onSimulateArrival!();
                      },
                    ),
                  ],
                ],
              ),
            ),

            // ── Day Management Section ───────────────────────────────────────
            if (canManageItinerary && currentDay != null) ...[
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Text(
                  'SHIFT SCHEDULE',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.warmMuted,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _shiftBtn(context, '-1 Hour', -60),
                    const SizedBox(width: 8),
                    _shiftBtn(context, '-30 Min', -30),
                    const SizedBox(width: 8),
                    _shiftBtn(context, '+30 Min', 30),
                    const SizedBox(width: 8),
                    _shiftBtn(context, '+1 Hour', 60),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),

              // Action list items
              _ListActionItem(
                icon: Icons.add_circle_outline_rounded,
                color: AppColors.primary,
                title: 'Add New Day',
                subtitle:
                    'Append Day ${allDays.length + 1} to your trip itinerary',
                onTap: () async {
                  final newDay = await notifier.addDay();
                  if (context.mounted) {
                    Navigator.pop(context);
                    if (newDay != null) {
                      AppFeedback.showSuccess(
                        context,
                        'Added Day ${newDay.dayNumber} to itinerary! 🗓️',
                      );
                    }
                  }
                },
              ),
              _ListActionItem(
                icon: Icons.copy_rounded,
                color: const Color(0xFF3B82F6),
                title: 'Duplicate Day',
                subtitle:
                    'Clone this day and all stops into Day ${allDays.length + 1}',
                onTap: () {
                  notifier.duplicateDay(activeDayIndex);
                  Navigator.pop(context);
                  AppFeedback.showSuccess(
                    context,
                    'Duplicated Day ${currentDay.dayNumber}! ✨',
                  );
                },
              ),
              _ListActionItem(
                icon: Icons.drive_file_move_outline,
                color: const Color(0xFF10B981),
                title: 'Move Stop to Another Day',
                subtitle:
                    'Reassign individual stops across different itinerary days',
                onTap: () => _showMoveStopPicker(context),
              ),
              _ListActionItem(
                icon: Icons.cleaning_services_rounded,
                color: const Color(0xFFEF9F27),
                title: 'Clear Day Stops',
                subtitle:
                    'Remove all ${currentDay.stops.length} stops from this day',
                onTap: () {
                  AppDialog.showDestructive(
                    context,
                    title: 'Clear All Stops?',
                    message:
                        'Are you sure you want to remove all ${currentDay.stops.length} stops from Day ${currentDay.dayNumber}?',
                    confirmLabel: 'Clear All',
                    onConfirm: () {
                      notifier.clearDay(activeDayIndex);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
              if (allDays.length > 1)
                _ListActionItem(
                  icon: Icons.delete_outline_rounded,
                  color: const Color(0xFFEF4444),
                  title: 'Delete Day ${currentDay.dayNumber}',
                  subtitle:
                      'Permanently remove this day and re-index remaining days',
                  onTap: () {
                    AppDialog.showDestructive(
                      context,
                      title: 'Delete Day ${currentDay.dayNumber}?',
                      message:
                          'This will delete all stops in this day and adjust subsequent day numbers.',
                      confirmLabel: 'Delete Day',
                      onConfirm: () {
                        notifier.deleteDay(activeDayIndex);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _shiftBtn(BuildContext context, String label, int minutes) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          notifier.shiftDaySchedule(activeDayIndex, minutes);
          Navigator.pop(context);
          final dir =
              minutes > 0 ? 'advanced by +$minutes' : 'delayed by $minutes';
          AppFeedback.showSuccess(
            context,
            'Day ${day?.dayNumber ?? 1} schedule $dir mins! ⏱️',
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.dividerLight),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.deepEarth,
            ),
          ),
        ),
      ),
    );
  }
}

class _HubActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _HubActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.dividerLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepEarth,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListActionItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ListActionItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.deepEarth,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 11,
          color: AppColors.muted,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.muted,
        size: 18,
      ),
    );
  }
}
