import 'package:tara_travel/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/providers/itinerary_provider.dart';
import '../../../core/widgets/feedback/app_feedback.dart';
import '../../../core/widgets/feedback/app_dialog.dart';

/// Bottom sheet presenting quick day actions: schedule shifting, duplication, stop moving, and clearing.
class DayActionsSheet extends StatelessWidget {
  final int activeDayIndex;
  final ItineraryDay day;
  final List<ItineraryDay> allDays;
  final ItineraryNotifier notifier;

  const DayActionsSheet({
    super.key,
    required this.activeDayIndex,
    required this.day,
    required this.allDays,
    required this.notifier,
  });

  static Future<void> show(
    BuildContext context, {
    required int activeDayIndex,
    required ItineraryDay day,
    required List<ItineraryDay> allDays,
    required ItineraryNotifier notifier,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DayActionsSheet(
        activeDayIndex: activeDayIndex,
        day: day,
        allDays: allDays,
        notifier: notifier,
      ),
    );
  }

  void _showMoveStopPicker(BuildContext context) {
    if (day.stops.isEmpty) {
      AppFeedback.showInfo(context, 'No stops in this day to move.');
      return;
    }

    if (allDays.length <= 1) {
      AppFeedback.showInfo(context, 'Add another day first to move stops across days.');
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
                fontFamily: AppTextStyles.fontHeading,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.deepEarth,
              ),
            ),
            const SizedBox(height: 12),
            ...day.stops.map((stop) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      PopupMenuButton<int>(
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.primary),
                        tooltip: 'Move to day',
                        onSelected: (targetIndex) {
                          notifier.moveStopToDay(activeDayIndex, targetIndex, stop.id);
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                          AppFeedback.showSuccess(
                            context,
                            'Moved "${stop.title}" to Day ${targetIndex + 1}! 🚀',
                          );
                        },
                        itemBuilder: (_) => allDays.asMap().entries.where((e) => e.key != activeDayIndex).map((e) {
                          return PopupMenuItem(
                            value: e.key,
                            child: Text('Move to Day ${e.key + 1}', style: const TextStyle()),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
                  child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Day ${day.dayNumber} Quick Actions',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontHeading,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepEarth,
                      ),
                    ),
                    Text(
                      '${day.stops.length} stop${day.stops.length == 1 ? '' : 's'} scheduled',
                      style: const TextStyle(
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

          // ── 1. Shift Schedule Section ─────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Text(
              'SHIFT DAY SCHEDULE',
              style: TextStyle(
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

          const SizedBox(height: 14),
          const Divider(height: 1),

          // ── 2. Action list items ──────────────────────────────────
          _ActionTile(
            icon: Icons.add_circle_outline_rounded,
            color: AppColors.primary,
            title: 'Add New Day',
            subtitle: 'Append Day ${allDays.length + 1} to your trip itinerary',
            onTap: () async {
              final newDay = await notifier.addDay();
              if (context.mounted) {
                Navigator.pop(context);
                if (newDay != null) {
                  AppFeedback.showSuccess(
                    context,
                    'Added Day ${newDay.dayNumber} to your itinerary! 🗓️',
                  );
                }
              }
            },
          ),
          _ActionTile(
            icon: Icons.copy_rounded,
            color: const Color(0xFF3B82F6),
            title: 'Duplicate Day',
            subtitle: 'Clone this day and all stops into a new Day ${allDays.length + 1}',
            onTap: () {
              notifier.duplicateDay(activeDayIndex);
              Navigator.pop(context);
              AppFeedback.showSuccess(
                context,
                'Duplicated Day ${day.dayNumber} into Day ${allDays.length + 1}! ✨',
              );
            },
          ),
          _ActionTile(
            icon: Icons.drive_file_move_outline,
            color: const Color(0xFF10B981),
            title: 'Move Stop to Another Day',
            subtitle: 'Reassign individual stops across different itinerary days',
            onTap: () => _showMoveStopPicker(context),
          ),
          _ActionTile(
            icon: Icons.cleaning_services_rounded,
            color: const Color(0xFFEF9F27),
            title: 'Clear Day Stops',
            subtitle: 'Remove all ${day.stops.length} stops from this day',
            onTap: () {
              AppDialog.showDestructive(
                context,
                title: 'Clear All Stops?',
                message: 'Are you sure you want to remove all ${day.stops.length} stops from Day ${day.dayNumber}?',
                confirmLabel: 'Clear All',
                onConfirm: () {
                  notifier.clearDay(activeDayIndex);
                  Navigator.pop(context);
                },
              );
            },
          ),
          if (allDays.length > 1)
            _ActionTile(
              icon: Icons.delete_outline_rounded,
              color: const Color(0xFFEF4444),
              title: 'Delete Day ${day.dayNumber}',
              subtitle: 'Permanently remove this day and re-index remaining days',
              onTap: () {
                AppDialog.showDestructive(
                  context,
                  title: 'Delete Day ${day.dayNumber}?',
                  message: 'This will delete all stops in this day and adjust subsequent day numbers.',
                  confirmLabel: 'Delete Day',
                  onConfirm: () {
                    notifier.deleteDay(activeDayIndex);
                    Navigator.pop(context);
                  },
                );
              },
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _shiftBtn(BuildContext context, String label, int minutes) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          notifier.shiftDaySchedule(activeDayIndex, minutes);
          Navigator.pop(context);
          final dir = minutes > 0 ? 'advanced by +$minutes' : 'delayed by $minutes';
          AppFeedback.showSuccess(
            context,
            'Day ${day.dayNumber} schedule $dir mins! ⏱️',
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

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
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
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.deepEarth,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.muted,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
    );
  }
}
