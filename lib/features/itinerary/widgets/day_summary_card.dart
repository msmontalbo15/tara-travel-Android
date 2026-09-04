import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/models/itinerary_model.dart';

/// Summary card shown at the bottom of each itinerary day.
/// Displays total estimated cost, time coverage, distance, and a completion ring.
class DaySummaryCard extends StatelessWidget {
  final ItineraryDay day;

  const DaySummaryCard({super.key, required this.day});

  String _fmt(double v) =>
      v >= 1000 ? '₱${(v / 1000).toStringAsFixed(1)}k' : '₱${v.toStringAsFixed(0)}';

  String get _timeRange {
    final timed = day.stops.where((s) => s.startTime != null).toList();
    if (timed.isEmpty) return '—';
    timed.sort((a, b) {
      final aM = a.startTime!.hour * 60 + a.startTime!.minute;
      final bM = b.startTime!.hour * 60 + b.startTime!.minute;
      return aM.compareTo(bM);
    });
    String fmtT(TimeOfDay t) {
      final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      final m = t.minute.toString().padLeft(2, '0');
      final p = t.period == DayPeriod.am ? 'AM' : 'PM';
      return '$h:$m $p';
    }
    final first = timed.first.startTime!;
    final lastStop = timed.last;
    final last = lastStop.endTime ?? lastStop.startTime!;
    return '${fmtT(first)} – ${fmtT(last)}';
  }

  double get _totalDistanceKm {
    final geo = day.stops.where((s) => s.lat != null && s.lng != null).toList();
    if (geo.length < 2) return 0;
    double dist = 0;
    for (int i = 0; i < geo.length - 1; i++) {
      dist += _haversineKm(geo[i].lat!, geo[i].lng!, geo[i + 1].lat!, geo[i + 1].lng!);
    }
    return dist;
  }

  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _deg2rad(double d) => d * math.pi / 180;

  @override
  Widget build(BuildContext context) {
    final total = day.stops.length;
    final completed = day.completedStops;
    final progress = total > 0 ? completed / total : 0.0;
    final dist = _totalDistanceKm;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0A04), Color(0xFF2C1A14)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          // Progress ring
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(64, 64),
                  painter: _RingPainter(progress: progress),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$completed',
                      style: const TextStyle( fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    Text(
                      '/ $total',
                      style: TextStyle( fontSize: 10, color: Colors.white.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Day ${day.dayNumber} summary',
                  style: TextStyle( fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.6), letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),
                _stat('⏱', _timeRange),
                if (day.totalDayCost > 0) _stat('💰', '${_fmt(day.totalDayCost)} estimated'),
                if (dist > 0) _stat('📍', '${dist.toStringAsFixed(1)} km route'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle( fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;

  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4;
    const strokeWidth = 5.0;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = const Color(0xFF10B981)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => oldDelegate.progress != progress;
}
