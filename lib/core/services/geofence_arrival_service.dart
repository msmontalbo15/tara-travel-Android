/// geofence_arrival_service.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// Geofence arrival detection service for Tara Travel.
///
/// Monitors the user's real-time GPS coordinates against upcoming itinerary
/// stops and automatically fires arrival events when within the proximity
/// radius (default 100 meters).
///
/// Integrates with:
/// • [LocationTrackingService.instance.snapshotStream] for zero-overhead GPS pings.
/// • [ItineraryStop] location markers for geofence boundaries.
/// • UI arrival celebrations and auto-progression hooks.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/itinerary_model.dart';
import '../services/location_tracking_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Details of a triggered geofence arrival event.
class ArrivalEvent {
  /// Unique identifier of the arrived stop.
  final String stopId;

  /// Human-readable title of the stop.
  final String stopTitle;

  /// Specific stop type if known.
  final StopType stopType;

  /// Distance in meters from user to stop at moment of detection.
  final double distanceMeters;

  /// Timestamp when the geofence perimeter was breached.
  final DateTime timestamp;

  const ArrivalEvent({
    required this.stopId,
    required this.stopTitle,
    required this.stopType,
    required this.distanceMeters,
    required this.timestamp,
  });
}

class GeofenceArrivalService {
  GeofenceArrivalService._();
  static final GeofenceArrivalService instance = GeofenceArrivalService._();

  // ── Configuration ────────────────────────────────────────────────────────
  /// Default arrival radius threshold in meters (100m).
  static const double defaultRadiusMeters = 100.0;

  /// Cooldown period before the same stop can trigger again (prevents flutter).
  static const Duration _triggerCooldown = Duration(minutes: 30);

  // ── State ────────────────────────────────────────────────────────────────
  StreamSubscription<LocationSnapshot>? _locationSub;
  String? _activeTripId;
  String? get activeTripId => _activeTripId;
  final List<ItineraryStop> _monitoredStops = [];
  final Set<String> _visitedStopIds = {};
  final Map<String, DateTime> _lastTriggered = {};

  final StreamController<ArrivalEvent> _arrivalController =
      StreamController<ArrivalEvent>.broadcast();

  /// Broadcast stream of verified arrival events.
  Stream<ArrivalEvent> get arrivalStream => _arrivalController.stream;

  /// Set of stop IDs confirmed visited in this session.
  Set<String> get visitedStopIds => Set.unmodifiable(_visitedStopIds);

  bool get isMonitoring => _locationSub != null;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  /// Starts listening to [LocationTrackingService] and monitors [stops].
  void startMonitoring({
    required String tripId,
    required List<ItineraryStop> stops,
  }) {
    _activeTripId = tripId;
    updateStops(stops);

    _locationSub ??= LocationTrackingService.instance.snapshotStream.listen(
      (snapshot) {
        evaluatePosition(snapshot.lat, snapshot.lng);
      },
      onError: (err) {
        debugPrint('[GeofenceArrival] Location stream error: $err');
      },
    );

    // Immediately evaluate against last known GPS snapshot if present
    final last = LocationTrackingService.instance.lastSnapshot;
    if (last != null) {
      evaluatePosition(last.lat, last.lng);
    }
  }

  /// Updates the list of candidate stops without resetting the stream.
  void updateStops(List<ItineraryStop> stops) {
    _monitoredStops.clear();
    for (final stop in stops) {
      // Only monitor stops with valid coordinates that are not yet completed
      if (stop.lat != null && stop.lng != null && !stop.isCompleted) {
        _monitoredStops.add(stop);
      }
    }
  }

  /// Stops geofence evaluation and closes active subscriptions.
  void stopMonitoring() {
    _locationSub?.cancel();
    _locationSub = null;
    _activeTripId = null;
    _monitoredStops.clear();
  }

  /// Manually marks a stop as visited to suppress duplicate triggers.
  void markVisited(String stopId) {
    _visitedStopIds.add(stopId);
    _monitoredStops.removeWhere((s) => s.id == stopId);
  }

  /// Clears visited state and cooldown history (e.g. for a new day).
  void reset() {
    _visitedStopIds.clear();
    _lastTriggered.clear();
  }

  // ── Proximity Evaluation ─────────────────────────────────────────────────

  /// Evaluates distance to all monitored stops and fires [arrivalStream] if breached.
  void evaluatePosition(double userLat, double userLng) {
    if (_monitoredStops.isEmpty) return;

    final now = DateTime.now();

    for (final stop in List<ItineraryStop>.from(_monitoredStops)) {
      if (stop.lat == null || stop.lng == null) continue;
      if (_visitedStopIds.contains(stop.id)) continue;

      // Cooldown check
      final lastTime = _lastTriggered[stop.id];
      if (lastTime != null && now.difference(lastTime) < _triggerCooldown) {
        continue;
      }

      final distMeters = _haversineMeters(
        userLat,
        userLng,
        stop.lat!,
        stop.lng!,
      );

      if (distMeters <= defaultRadiusMeters) {
        _lastTriggered[stop.id] = now;
        _visitedStopIds.add(stop.id);
        _monitoredStops.removeWhere((s) => s.id == stop.id);

        final event = ArrivalEvent(
          stopId: stop.id,
          stopTitle: stop.title,
          stopType: stop.type,
          distanceMeters: distMeters,
          timestamp: now,
        );

        debugPrint(
          '[GeofenceArrival] 🎯 Breached arrival radius for "${stop.title}" (${distMeters.toStringAsFixed(1)}m)',
        );
        _arrivalController.add(event);
      }
    }
  }

  // ── Haversine Distance (Meters) ──────────────────────────────────────────

  static double _haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusMeters = 6371000.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);

  // ── UI Modal Helper ──────────────────────────────────────────────────────

  /// Displays an arrival celebration modal card.
  static Future<bool?> showArrivalDialog(
    BuildContext context,
    ArrivalEvent event, {
    required Future<void> Function() onConfirmVisited,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return _ArrivalCelebrationDialog(
          event: event,
          onConfirmVisited: onConfirmVisited,
        );
      },
    );
  }
}

// ── UI Arrival Celebration Dialog ────────────────────────────────────────────

class _ArrivalCelebrationDialog extends StatefulWidget {
  final ArrivalEvent event;
  final Future<void> Function() onConfirmVisited;

  const _ArrivalCelebrationDialog({
    required this.event,
    required this.onConfirmVisited,
  });

  @override
  State<_ArrivalCelebrationDialog> createState() =>
      _ArrivalCelebrationDialogState();
}

class _ArrivalCelebrationDialogState extends State<_ArrivalCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.elasticOut,
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Celebration Icon with Glow
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.celebration_rounded,
                  color: AppColors.primary,
                  size: 34,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Heading
            const Text(
              'You Have Arrived!',
              style: TextStyle(
                fontFamily: AppTextStyles.fontHeading,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),

            // Stop title
            Text(
              widget.event.stopTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),

            // Proximity Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.greenBright.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Within ${widget.event.distanceMeters.toStringAsFixed(0)}m of waypoint',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.greenBright,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Dismiss'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () async {
                            setState(() => _isProcessing = true);
                            try {
                              await widget.onConfirmVisited();
                              if (context.mounted) {
                                Navigator.of(context).pop(true);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                setState(() => _isProcessing = false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Mark Visited',
                            style: TextStyle(fontWeight: FontWeight.w700),
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
}
