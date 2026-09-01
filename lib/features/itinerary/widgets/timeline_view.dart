import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/theme/app_colors.dart';

/// A horizontal 24-hour Gantt/timeline view for an [ItineraryDay].
/// Each stop block is rendered at its [ItineraryStop.startTime]–[ItineraryStop.endTime].
/// Stops without a time are shown in a "no time" row at the top.
class TimelineView extends StatefulWidget {
  final ItineraryDay day;
  final void Function(ItineraryStop stop) onStopTap;

  const TimelineView({super.key, required this.day, required this.onStopTap});

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  static const double _hourWidth = 80.0;
  static const double _rowHeight = 56.0;
  static const double _headerHeight = 28.0;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToInitialPosition();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToInitialPosition() {
    if (!_scrollController.hasClients) return;
    
    final timedStops = widget.day.stops.where((s) => s.startTime != null && s.endTime != null).toList();
    
    double targetOffset = 0;
    
    if (timedStops.isNotEmpty) {
      timedStops.sort((a, b) {
        final aTime = a.startTime!.hour * 60 + a.startTime!.minute;
        final bTime = b.startTime!.hour * 60 + b.startTime!.minute;
        return aTime.compareTo(bTime);
      });
      final earliest = timedStops.first.startTime!;
      targetOffset = (earliest.hour + earliest.minute / 60.0) * _hourWidth;
    } else {
      final now = TimeOfDay.now();
      targetOffset = (now.hour + now.minute / 60.0) * _hourWidth;
    }
    
    // Offset slightly so it's not glued to the left edge
    targetOffset -= 40;
    if (targetOffset < 0) targetOffset = 0;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (targetOffset > maxScroll) targetOffset = maxScroll;
    
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final timedStops = widget.day.stops.where((s) => s.startTime != null && s.endTime != null).toList();
    final untimedStops = widget.day.stops.where((s) => s.startTime == null || s.endTime == null).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (untimedStops.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'NO TIME ASSIGNED',
                style: TextStyle(fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: AppColors.warmMuted),
              ),
            ),
            ...untimedStops.map((s) => _UntimedStopRow(stop: s, onTap: () => widget.onStopTap(s))),
            const Divider(height: 24, indent: 20, endIndent: 20),
          ],
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Text(
              'DAILY TIMELINE',
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: AppColors.warmMuted),
            ),
          ),
          if (timedStops.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Add start & end times to stops\nto see them in the timeline.',
                  style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: AppColors.muted),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
              child: _buildTimeline(timedStops),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<ItineraryStop> stops) {
    const totalHours = 24;
    const totalWidth = totalHours * _hourWidth;

    return SizedBox(
      width: totalWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hour header
          SizedBox(
            height: _headerHeight,
            child: Row(
              children: List.generate(totalHours, (h) {
                return SizedBox(
                  width: _hourWidth,
                  child: Text(
                    h == 0 ? '12am' : h < 12 ? '${h}am' : h == 12 ? '12pm' : '${h - 12}pm',
                    style: const TextStyle(fontFamily: 'DM Sans', fontSize: 10, color: AppColors.muted),
                  ),
                );
              }),
            ),
          ),

          // Timeline track
          SizedBox(
            height: _rowHeight,
            child: Stack(
              children: [
                // Hour grid lines
                Row(
                  children: List.generate(
                    totalHours,
                    (h) => Container(
                      width: _hourWidth,
                      decoration: const BoxDecoration(
                        border: Border(left: BorderSide(color: AppColors.dividerLight, width: 0.5)),
                      ),
                    ),
                  ),
                ),
                // Stop blocks
                ...stops.map((s) => _buildBlock(s)),
                // Current time indicator
                const _CurrentTimeIndicator(totalWidth: totalWidth, rowHeight: _rowHeight),
              ],
            ),
          ),

          // Legend
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: StopType.values.map((t) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: t.color, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 4),
                Text(t.label, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 10, color: AppColors.muted)),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBlock(ItineraryStop stop) {
    final start = stop.startTime!;
    final end = stop.endTime!;
    final startMin = start.hour * 60 + start.minute;
    int endMin = end.hour * 60 + end.minute;
    
    if (endMin < startMin) {
      endMin += 24 * 60; // Handle midnight crossing
    }
    
    final durMin = (endMin - startMin).clamp(15, 24 * 60).toDouble();

    final left = (startMin / 60.0) * _hourWidth;
    final width = (durMin / 60.0) * _hourWidth;

    return Positioned(
      left: left,
      top: 4,
      width: width,
      height: _rowHeight - 8,
      child: GestureDetector(
        onTap: () => widget.onStopTap(stop),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: stop.type.color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: stop.type.color.withValues(alpha: 0.35), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                stop.title,
                style: const TextStyle(fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (width > 60)
                Text(
                  stop.duration,
                  style: TextStyle(fontFamily: 'DM Sans', fontSize: 9, color: Colors.white.withValues(alpha: 0.8)),
                  maxLines: 1,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UntimedStopRow extends StatelessWidget {
  final ItineraryStop stop;
  final VoidCallback onTap;

  const _UntimedStopRow({required this.stop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: stop.type.color.withValues(alpha: 0.35), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(stop.type.icon, size: 18, color: stop.type.color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(stop.title, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.deepEarth)),
            ),
            const Icon(Icons.schedule_rounded, size: 15, color: AppColors.muted),
            const SizedBox(width: 4),
            const Text('No time', style: TextStyle(fontFamily: 'DM Sans', fontSize: 11.5, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

/// Animated vertical line marking the current time of day.
class _CurrentTimeIndicator extends StatefulWidget {
  final double totalWidth;
  final double rowHeight;

  const _CurrentTimeIndicator({required this.totalWidth, required this.rowHeight});

  @override
  State<_CurrentTimeIndicator> createState() => _CurrentTimeIndicatorState();
}

class _CurrentTimeIndicatorState extends State<_CurrentTimeIndicator> {
  late Timer _timer;
  late TimeOfDay _now;

  @override
  void initState() {
    super.initState();
    _now = TimeOfDay.now();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          _now = TimeOfDay.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minuteOfDay = _now.hour * 60 + _now.minute;
    final left = (minuteOfDay / (24 * 60.0)) * widget.totalWidth;

    return Positioned(
      left: left - 1,
      top: 0,
      bottom: 0,
      child: Container(
        width: 2,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(1),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 4)],
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
