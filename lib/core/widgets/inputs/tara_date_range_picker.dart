import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/trip_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/trip_conflict_helper.dart';

/// Interactive modal bottom sheet for picking date ranges with booked schedule highlights (Option A).
class TaraDateRangePickerSheet extends StatefulWidget {
  final DateTime? initialStart;
  final DateTime? initialEnd;
  final DateTime firstDate;
  final DateTime lastDate;
  final List<TripModel> existingTrips;
  final String? excludeTripId;

  const TaraDateRangePickerSheet({
    super.key,
    this.initialStart,
    this.initialEnd,
    required this.firstDate,
    required this.lastDate,
    this.existingTrips = const [],
    this.excludeTripId,
  });

  static Future<DateTimeRange?> show(
    BuildContext context, {
    DateTime? initialStart,
    DateTime? initialEnd,
    DateTime? firstDate,
    DateTime? lastDate,
    List<TripModel> existingTrips = const [],
    String? excludeTripId,
  }) {
    final now = DateTime.now();
    return showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaraDateRangePickerSheet(
        initialStart: initialStart,
        initialEnd: initialEnd,
        firstDate: firstDate ?? DateTime(now.year, now.month, now.day),
        lastDate: lastDate ?? DateTime(now.year + 5, 12, 31),
        existingTrips: existingTrips,
        excludeTripId: excludeTripId,
      ),
    );
  }

  @override
  State<TaraDateRangePickerSheet> createState() => _TaraDateRangePickerSheetState();
}

class _TaraDateRangePickerSheetState extends State<TaraDateRangePickerSheet> {
  DateTime? _start;
  DateTime? _end;
  late DateTime _displayedMonth;
  late final Map<DateTime, List<TripModel>> _bookedDaysMap;

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
    final baseMonth = _start ?? widget.firstDate;
    _displayedMonth = DateTime(baseMonth.year, baseMonth.month, 1);
    _bookedDaysMap = TripConflictHelper.buildDayTripMap(
      widget.existingTrips,
      excludeTripId: widget.excludeTripId,
    );
  }

  void _onDayTapped(DateTime day) {
    setState(() {
      if (_start == null || (_start != null && _end != null)) {
        _start = day;
        _end = null;
      } else if (_start != null && _end == null) {
        if (day.isBefore(_start!)) {
          _start = day;
        } else {
          _end = day;
        }
      }
    });
  }

  void _previousMonth() {
    final prev = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    if (!prev.isBefore(DateTime(widget.firstDate.year, widget.firstDate.month, 1))) {
      setState(() => _displayedMonth = prev);
    }
  }

  void _nextMonth() {
    final next = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    if (!next.isAfter(DateTime(widget.lastDate.year, widget.lastDate.month, 1))) {
      setState(() => _displayedMonth = next);
    }
  }

  List<TripModel> _getConflicts() {
    if (_start == null) return [];
    final effectiveEnd = _end ?? _start!;
    return TripConflictHelper.findConflictingTrips(
      trips: widget.existingTrips,
      start: _start!,
      end: effectiveEnd,
      excludeTripId: widget.excludeTripId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final conflicts = _getConflicts();
    final mediaQuery = MediaQuery.of(context);

    int totalDays = 0;
    if (_start != null) {
      final effectiveEnd = _end ?? _start!;
      totalDays = effectiveEnd.difference(_start!).inDays + 1;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Trip Dates',
                        style: TextStyle(
                          fontFamily: 'Playfair Display',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepEarth,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _start == null
                            ? 'Tap start & end dates'
                            : _end == null
                                ? 'Select end date (1 day selected)'
                                : '$totalDays ${totalDays == 1 ? 'day' : 'days'} (${DateFormat('MMM d').format(_start!)} – ${DateFormat('MMM d, yyyy').format(_end!)})',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          color: _start != null ? AppColors.primary : AppColors.warmMuted,
                          fontWeight: _start != null ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  if (_start != null)
                    TextButton(
                      onPressed: () => setState(() {
                        _start = null;
                        _end = null;
                      }),
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warmMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.cardBorder),

            // Calendar Navigation Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: AppColors.deepEarth),
                    onPressed: _previousMonth,
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_displayedMonth),
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepEarth,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: AppColors.deepEarth),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ),

            // Weekday Headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warmMuted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 6),

            // Month Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildMonthGrid(_displayedMonth),
            ),

            // Conflict Warning Banner (if overlapping with scheduled trips)
            if (conflicts.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.amber.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.amber, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dates overlap with existing trip:',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.amber,
                            ),
                          ),
                          Text(
                            conflicts.map((t) => '${t.name} (${DateFormat('MMM d').format(t.fromDate)}–${DateFormat('MMM d').format(t.toDate)})').join(', '),
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.deepEarth,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Legend
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Scheduled Trip',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          color: AppColors.warmMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Selection',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          color: AppColors.warmMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Confirm Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _start == null
                      ? null
                      : () {
                          final selectedStart = _start!;
                          final selectedEnd = _end ?? _start!;
                          Navigator.pop(
                            context,
                            DateTimeRange(start: selectedStart, end: selectedEnd),
                          );
                        },
                  child: Text(
                    _start == null ? 'Select Dates' : 'Apply Dates',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthGrid(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    final totalSlots = ((startWeekday + daysInMonth) / 7).ceil() * 7;
    final nowNormalized = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 0,
        childAspectRatio: 1.15,
      ),
      itemCount: totalSlots,
      itemBuilder: (context, index) {
        if (index < startWeekday || index >= startWeekday + daysInMonth) {
          return const SizedBox.shrink();
        }

        final dayNumber = index - startWeekday + 1;
        final date = DateTime(month.year, month.month, dayNumber);
        final isPast = date.isBefore(widget.firstDate);
        final isToday = date.isAtSameMomentAs(nowNormalized);

        // Schedule check
        final hasExistingTrip = _bookedDaysMap.containsKey(date);

        // Range check
        bool isRangeStart = _start != null && date.isAtSameMomentAs(_start!);
        bool isRangeEnd = _end != null && date.isAtSameMomentAs(_end!);
        bool isInsideRange = _start != null &&
            _end != null &&
            date.isAfter(_start!) &&
            date.isBefore(_end!);

        Color? bgColor;
        Color textColor = AppColors.deepEarth;
        BorderRadius? borderRadius;

        if (isRangeStart && isRangeEnd) {
          bgColor = AppColors.primary;
          textColor = Colors.white;
          borderRadius = BorderRadius.circular(12);
        } else if (isRangeStart) {
          bgColor = AppColors.primary;
          textColor = Colors.white;
          borderRadius = const BorderRadius.horizontal(left: Radius.circular(12));
        } else if (isRangeEnd) {
          bgColor = AppColors.primary;
          textColor = Colors.white;
          borderRadius = const BorderRadius.horizontal(right: Radius.circular(12));
        } else if (isInsideRange) {
          bgColor = AppColors.sand;
          textColor = AppColors.primary;
        } else if (isPast) {
          textColor = Colors.grey.shade300;
        }

        return GestureDetector(
          onTap: isPast ? null : () => _onDayTapped(date),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: borderRadius,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        fontWeight: (isRangeStart || isRangeEnd || isToday)
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    if (hasExistingTrip && !isRangeStart && !isRangeEnd) ...[
                      const SizedBox(height: 2),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isInsideRange ? AppColors.primary : AppColors.amber,
                        ),
                      ),
                    ],
                  ],
                ),
                if (isToday && !isRangeStart && !isRangeEnd && !isInsideRange)
                  Positioned(
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
