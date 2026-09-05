import 'package:tara_travel/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/models/member_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_responsive.dart';
import '../../../core/widgets/multi_member_picker_sheet.dart';
import '../../../core/widgets/member_avatar_circle.dart';
import '../utils/transit_conflict_helper.dart';
import 'navigate_route_button.dart';
import 'slide_to_arrive_button.dart';

/// Full-detail bottom sheet for an itinerary stop (IDEA-007).
///
/// Features:
/// - Real-time Estimated Time of Arrival (Live GPS ETA & Origin calculation)
/// - 1-tap Stop Details Share (Messenger, WhatsApp, SMS, Copy)
/// - Top-right Edit, Share, and Dismiss actions in header
/// - Fixed bottom driver-ready "Slide to Confirm Arrival" confirmation bar
/// - Auto-dismiss back to itinerary upon arrival confirmation
/// - Responsive Undo support with immediate Supabase sync
/// - Dedicated "Members" arrival hub with interactive companion arrival roster & per-member arrival times
/// - 1-tap Google Maps navigation & expense logging shortcut
/// - Booking reference & attachments
class StopDetailSheet extends StatefulWidget {
  final ItineraryStop stop;
  final List<MemberModel> members;
  final ItineraryStop? previousStop;
  final VoidCallback onEdit;
  final VoidCallback? onLogExpense;
  /// Toggles self check-in for the current user.
  final VoidCallback? onCheckIn;
  /// Toggles arrival presence for a specific member.
  final void Function(String memberId)? onMemberToggle;
  /// Marks all group members as arrived in batch.
  final VoidCallback? onMarkAllArrived;
  final String? currentUserId;
  final bool canManage;

  const StopDetailSheet({
    super.key,
    required this.stop,
    required this.members,
    this.previousStop,
    required this.onEdit,
    this.onLogExpense,
    this.onCheckIn,
    this.onMemberToggle,
    this.onMarkAllArrived,
    this.currentUserId,
    this.canManage = false,
  });

  @override
  State<StopDetailSheet> createState() => _StopDetailSheetState();
}

class _StopDetailSheetState extends State<StopDetailSheet> {
  late ItineraryStop _currentStop;
  bool _isRosterExpanded = false;

  // ── Real Live ETA State ──────────────────────────────────────────────────
  double? _userLat;
  double? _userLng;
  bool _isLoadingGps = false;

  @override
  void initState() {
    super.initState();
    _currentStop = widget.stop;
    _fetchLiveGpsForEta();
  }

  Future<void> _fetchLiveGpsForEta() async {
    if (_currentStop.isCompleted) return;
    if (_currentStop.lat == null || _currentStop.lng == null) return;

    setState(() => _isLoadingGps = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 3),
          ),
        );
        if (mounted) {
          setState(() {
            _userLat = pos.latitude;
            _userLng = pos.longitude;
            _isLoadingGps = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingGps = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingGps = false);
    }
  }

  // ── Share Stop Details ───────────────────────────────────────────────────
  void _shareStopDetails() {
    HapticFeedback.lightImpact();
    final stop = _currentStop;
    final buf = StringBuffer();

    buf.writeln('📍 ${stop.title.toUpperCase()}');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('🏷️ Category: ${stop.type.label}');

    if (stop.startTime != null) {
      final timeStr = _formatTime(stop.startTime!);
      final endStr = stop.endTime != null ? ' – ${_formatTime(stop.endTime!)}' : '';
      buf.writeln('⏰ Schedule: $timeStr$endStr');
    }

    if (stop.location != null && stop.location!.trim().isNotEmpty) {
      buf.writeln('📌 Location: ${stop.location!.trim()}');
    }

    // Distance & Estimated Travel Time in Share
    if (_userLat != null && _userLng != null && stop.lat != null && stop.lng != null) {
      final analysis = TransitConflictHelper.analyze(
        from: ItineraryStop(
          id: 'user_pos',
          title: 'Current Location',
          type: StopType.custom,
          lat: _userLat,
          lng: _userLng,
        ),
        to: stop,
      );
      if (analysis.distanceKm != null) {
        final distStr = analysis.distanceKm! < 1.0
            ? '${(analysis.distanceKm! * 1000).round()} m'
            : '${analysis.distanceKm!.toStringAsFixed(1)} km';
        final speed = stop.transportMode?.averageSpeedKmh ?? 35.0;
        final transitMin = (analysis.distanceKm! / speed * 60.0).round() + 4;
        buf.writeln('📏 Real Distance: $distStr from current location');
        buf.writeln('⏱️ Est. Travel Time: ~$transitMin mins (${stop.transportMode?.label ?? 'Driving'})');
      }
    } else if (widget.previousStop != null && widget.previousStop!.lat != null && widget.previousStop!.lng != null && stop.lat != null && stop.lng != null) {
      final analysis = TransitConflictHelper.analyze(
        from: widget.previousStop!,
        to: stop,
      );
      if (analysis.distanceKm != null) {
        final distStr = analysis.distanceKm! < 1.0
            ? '${(analysis.distanceKm! * 1000).round()} m'
            : '${analysis.distanceKm!.toStringAsFixed(1)} km';
        buf.writeln('📏 Distance: $distStr from ${widget.previousStop!.title}');
        if (analysis.estimatedTransitMinutes != null) {
          buf.writeln('⏱️ Est. Travel Time: ~${analysis.estimatedTransitMinutes} mins');
        }
      }
    }

    // Google Maps link
    final hasCoords = stop.lat != null && stop.lng != null && stop.lat != 0.0 && stop.lng != 0.0;
    if (hasCoords) {
      buf.writeln('🗺️ Map Link: https://maps.google.com/?q=${stop.lat},${stop.lng}');
    } else if (stop.location != null && stop.location!.trim().isNotEmpty) {
      buf.writeln('🗺️ Map Link: https://maps.google.com/?q=${Uri.encodeComponent('${stop.title}, ${stop.location}')}');
    }

    if (stop.estimatedCost != null && stop.estimatedCost! > 0) {
      buf.writeln('💸 Estimated Cost: ₱${stop.estimatedCost!.toStringAsFixed(2)}');
    }

    if (stop.confirmationNumber != null && stop.confirmationNumber!.isNotEmpty) {
      buf.writeln('🎫 Booking Ref: ${stop.confirmationNumber}');
    }

    if (stop.notes != null && stop.notes!.trim().isNotEmpty) {
      buf.writeln('📝 Notes: ${stop.notes!.trim()}');
    }

    if (stop.isCompleted) {
      buf.writeln('✅ Status: Visited / Completed');
    }

    buf.writeln('\nShared via Tara Travel 🇵🇭');

    SharePlus.instance.share(
      ShareParams(
        text: buf.toString().trim(),
        subject: 'Stop: ${stop.title} — Tara Travel',
      ),
    );
  }

  @override
  void didUpdateWidget(covariant StopDetailSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stop != oldWidget.stop) {
      _currentStop = widget.stop;
    }
  }

  String get _effectiveSelfId =>
      widget.currentUserId ??
      (widget.members.isNotEmpty ? widget.members.first.id : 'me');

  bool get _isSelfArrived {
    return _currentStop.checkedInMemberIds.contains(_effectiveSelfId) ||
        _currentStop.isCompleted;
  }

  void _handleSelfArrivalToggle() {
    final selfId = _effectiveSelfId;
    final isNowVisited = !_isSelfArrived;
    final updatedMembers =
        Map<String, DateTime>.from(_currentStop.checkedInMembers);

    if (isNowVisited) {
      updatedMembers[selfId] = DateTime.now();
    } else {
      updatedMembers.remove(selfId);
    }

    final newVisitedAt = isNowVisited
        ? (_currentStop.visitedAt ?? DateTime.now())
        : (updatedMembers.isNotEmpty ? _currentStop.visitedAt : null);

    setState(() {
      _currentStop = _currentStop.copyWith(
        visitedAt: newVisitedAt,
        clearVisitedAt: newVisitedAt == null,
        checkedInMembers: updatedMembers,
      );
    });

    widget.onCheckIn?.call();
  }

  void _handleMemberToggle(String memberId) {
    final updatedMembers =
        Map<String, DateTime>.from(_currentStop.checkedInMembers);
    final isNowPresent = !updatedMembers.containsKey(memberId);

    if (isNowPresent) {
      updatedMembers[memberId] = DateTime.now();
    } else {
      updatedMembers.remove(memberId);
    }

    final newVisitedAt = updatedMembers.isNotEmpty
        ? (_currentStop.visitedAt ?? DateTime.now())
        : null;

    setState(() {
      _currentStop = _currentStop.copyWith(
        checkedInMembers: updatedMembers,
        visitedAt: newVisitedAt,
        clearVisitedAt: newVisitedAt == null,
      );
    });

    widget.onMemberToggle?.call(memberId);
  }

  void _handleMarkAllArrived() {
    final now = DateTime.now();
    final updatedMembers = <String, DateTime>{};
    for (final m in widget.members) {
      updatedMembers[m.id] = _currentStop.checkedInMembers[m.id] ?? now;
    }

    setState(() {
      _currentStop = _currentStop.copyWith(
        checkedInMembers: updatedMembers,
        visitedAt: _currentStop.visitedAt ?? now,
        clearVisitedAt: updatedMembers.isEmpty,
      );
    });

    widget.onMarkAllArrived?.call();
  }

  @override
  Widget build(BuildContext context) {
    final stop = _currentStop;
    final members = widget.members;
    final hasPhotos = stop.photoUrls.isNotEmpty;
    final totalMembers = members.length;
    final checkedInCount = stop.checkedInMemberIds.length;
    final allArrived = totalMembers > 0 && checkedInCount >= totalMembers;

    return Container(
      constraints: BoxConstraints(
        maxHeight: context.sheetMaxHeight(0.88),
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Drag Handle ───────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 14, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header Bar: Category, Title, Share, Edit, Close ──────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: stop.type.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    stop.type.icon,
                    color: stop.type.color,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.title,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontHeading,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepEarth,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (stop.startTime != null)
                        Text(
                          '${_formatTime(stop.startTime!)}${stop.duration.isNotEmpty ? ' · ${stop.duration}' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                // Share Action Button
                IconButton(
                  tooltip: 'Share Stop Details',
                  icon: const Icon(
                    Icons.share_outlined,
                    size: 21,
                    color: AppColors.primary,
                  ),
                  onPressed: _shareStopDetails,
                  visualDensity: VisualDensity.compact,
                ),
                // Top-right Edit button (Driver-friendly tap area)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onEdit();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.sand,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded,
                              size: 14, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Close button
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 24, color: AppColors.muted),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Scrollable Body Content ────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Photo Gallery Carousel (if available)
                  if (hasPhotos) ...[
                    SizedBox(
                      height: 180,
                      child: PageView.builder(
                        itemCount: stop.photoUrls.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
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
                    const SizedBox(height: 16),
                  ],

                  // 2. Real-Time ETA Card (Live GPS / Transit estimation)
                  _buildEtaCard(),
                  const SizedBox(height: 16),

                  // 3. Primary Navigation & Expense Actions (Driver-Ready Big Touch Targets)
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              openGoogleMapsForStop(context, stop);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shadowColor: AppColors.primary.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.directions_rounded, size: 22),
                            label: const Text(
                              'Navigate Maps',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (widget.onLogExpense != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 54,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                widget.onLogExpense!();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.amberText,
                                side: const BorderSide(
                                    color: AppColors.amber, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.receipt_long_rounded,
                                  size: 19),
                              label: const Text(
                                'Expense',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 4. Dedicated "Members" Arrival Hub & Roster (for group trips)
                  if (members.length > 1) ...[
                    _buildMembersArrivalHub(totalMembers, checkedInCount, allArrived),
                    const SizedBox(height: 16),
                  ],

                  // 5. Metadata Info Rows (Arrival Time, Location, Cost, Booking Ref)
                  if (stop.arrivedAtLabel != null)
                    _infoRow(
                      Icons.check_circle_rounded,
                      '${stop.arrivedAtLabel!} (Stop Completed)',
                      color: AppColors.greenBright,
                    ),
                  if (stop.location != null)
                    _infoRow(Icons.place_outlined, stop.location!),
                  if (stop.estimatedCost != null)
                    _infoRow(
                      Icons.attach_money_rounded,
                      '₱${stop.estimatedCost!.toInt()} estimated cost',
                    ),
                  if (stop.confirmationNumber != null)
                    _infoRow(
                      Icons.confirmation_number_outlined,
                      'Booking Reference: ${stop.confirmationNumber}',
                    ),

                  // 5. Notes
                  if (stop.notes != null && stop.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.dividerLight),
                      ),
                      child: Text(
                        stop.notes!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.deepEarth,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],

                  // 6. Booking Attachments
                  if (stop.attachmentUrls.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Attachments',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: stop.attachmentUrls.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.dividerLight),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.attach_file_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Attachment ${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Fixed Bottom Driver-Ready Arrival Dock ───────────────────
          if (widget.onCheckIn != null) ...[
            const Divider(height: 1),
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                context.bottomInset > 0
                    ? context.safeBottomPadding(8)
                    : 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: _isSelfArrived
                  ? _buildArrivedDriverStatus()
                  : SlideToArriveButton(
                      height: 60.0,
                      onConfirmed: () async {
                        _handleSelfArrivalToggle();
                        final nav = Navigator.of(context);
                        // Driver-ready: brief confirmation animation then auto-navigate back to itinerary
                        await Future.delayed(const Duration(milliseconds: 380));
                        if (mounted && nav.canPop()) {
                          nav.pop();
                        }
                      },
                      label: 'Slide to Confirm Arrival',
                      confirmedLabel: '✓ Arrival Confirmed',
                    ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Real Estimated Time of Arrival (ETA) Widget ──────────────────────────
  Widget _buildEtaCard() {
    final stop = _currentStop;

    // If stop is completed, show completion summary
    if (stop.isCompleted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.greenLight.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.greenBright.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.greenBright.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.greenBright,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stop Completed',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenBright,
                    ),
                  ),
                  Text(
                    stop.arrivedAtLabel != null
                        ? '${stop.arrivedAtLabel!} · All set!'
                        : 'Arrival recorded in trip itinerary',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.deepEarth,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Determine calculation method: Live GPS or Inter-Stop Distance
    double? distanceKm;
    int? transitMinutes;
    String calculationSource = '';

    if (_userLat != null && _userLng != null && stop.lat != null && stop.lng != null) {
      distanceKm = TransitConflictHelper.analyze(
        from: ItineraryStop(
          id: 'user_pos',
          title: 'Current Location',
          type: StopType.custom,
          lat: _userLat,
          lng: _userLng,
        ),
        to: stop,
      ).distanceKm;

      final speed = stop.transportMode?.averageSpeedKmh ?? 35.0;
      if (distanceKm != null) {
        transitMinutes = (distanceKm / speed * 60.0).round() + 4;
        calculationSource = 'from your live GPS location';
      }
    } else if (widget.previousStop != null && widget.previousStop!.lat != null && widget.previousStop!.lng != null && stop.lat != null && stop.lng != null) {
      final analysis = TransitConflictHelper.analyze(
        from: widget.previousStop!,
        to: stop,
      );
      distanceKm = analysis.distanceKm;
      transitMinutes = analysis.estimatedTransitMinutes;
      calculationSource = 'from previous stop (${widget.previousStop!.title})';
    }

    // If still loading GPS
    if (_isLoadingGps) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.dividerLight),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Calculating live GPS ETA...',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      );
    }

    // If we have calculated transit minutes
    if (transitMinutes != null) {
      final now = DateTime.now();
      final estimatedArrival = now.add(Duration(minutes: transitMinutes));
      final etaHour = estimatedArrival.hour % 12 == 0 ? 12 : estimatedArrival.hour % 12;
      final etaMinute = estimatedArrival.minute.toString().padLeft(2, '0');
      final etaPeriod = estimatedArrival.hour >= 12 ? 'PM' : 'AM';
      final formattedEta = '$etaHour:$etaMinute $etaPeriod';

      final String distanceLabel = distanceKm != null
          ? (distanceKm < 1.0
              ? '${(distanceKm * 1000).round()} meters'
              : '${distanceKm.toStringAsFixed(1)} km')
          : 'Unknown';

      final String travelTimeLabel = transitMinutes < 60
          ? '$transitMinutes mins'
          : '${transitMinutes ~/ 60}h ${transitMinutes % 60}m';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.08),
              AppColors.sand.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: ETA Title + GPS Pill
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.access_time_filled_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ESTIMATED TIME OF ARRIVAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        formattedEta,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontBody,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepEarth,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_userLat != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.gps_fixed_rounded,
                            size: 11, color: Color(0xFF10B981)),
                        SizedBox(width: 4),
                        Text(
                          'LIVE GPS',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Metrics Grid: Real Distance & Est. Travel Time
            Row(
              children: [
                // 1. Real Distance Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.dividerLight,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.straighten_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'REAL DISTANCE',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.muted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                distanceLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.deepEarth,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 2. Estimated Travel Time Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.dividerLight,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.commute_rounded,
                            size: 16,
                            color: AppColors.amberText,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TRAVEL TIME',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.muted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                travelTimeLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.deepEarth,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (calculationSource.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 2),
                child: Text(
                  'Calculated $calculationSource (${stop.transportMode?.label ?? 'Driving'})',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.muted,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Default scheduled time fallback if coordinates are missing
    if (stop.startTime != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.dividerLight),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule_rounded, size: 18, color: AppColors.muted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Scheduled for ${_formatTime(stop.startTime!)}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepEarth,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ── Driver-Ready Arrived Status Dock ────────────────────────────────────────

  Widget _buildArrivedDriverStatus() {
    final stop = _currentStop;

    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.greenBright.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(31),
        border: Border.all(
          color: AppColors.greenBright.withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.greenBright,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.arrivedAtLabel != null
                      ? '✓ You ${stop.arrivedAtLabel!}'
                      : '✓ You Arrived',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.greenBright,
                  ),
                ),
                const Text(
                  'Arrival recorded · Stop completed',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                HapticFeedback.lightImpact();
                _handleSelfArrivalToggle();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.dividerLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.undo_rounded, size: 15, color: AppColors.muted),
                    SizedBox(width: 5),
                    Text(
                      'Undo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepEarth,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Members Arrival Hub & Companion Roster ─────────────────────────────────

  Widget _buildMembersArrivalHub(
      int totalMembers, int checkedInCount, bool allArrived) {
    final stop = _currentStop;
    final members = widget.members;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Column(
        children: [
          // Expandable Trigger Header
          InkWell(
            onTap: () => setState(() => _isRosterExpanded = !_isRosterExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: allArrived
                          ? AppColors.greenBright.withValues(alpha: 0.15)
                          : AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.people_alt_rounded,
                      size: 16,
                      color: allArrived
                          ? AppColors.greenBright
                          : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Members ($checkedInCount/$totalMembers Arrived)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: allArrived
                                ? AppColors.greenBright
                                : AppColors.deepEarth,
                          ),
                        ),
                        Text(
                          allArrived
                              ? 'All companions present'
                              : '${totalMembers - checkedInCount} companions not yet arrived',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Overlapping avatar stack preview
                  if (stop.checkedInMemberIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: MemberAvatarStack(
                        members: members,
                        memberIds: stop.checkedInMemberIds,
                        size: 22,
                        maxVisible: 3,
                      ),
                    ),
                  Icon(
                    _isRosterExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.muted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Companion Roster
          if (_isRosterExpanded) ...[
            const Divider(height: 1, indent: 14, endIndent: 14),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // List of members with arrival toggles
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: members.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final member = members[idx];
                      final isPresent =
                          stop.checkedInMemberIds.contains(member.id);
                      final memberArrivalLabel =
                          stop.memberArrivedAtLabel(member.id);
                      final formattedName = MemberModel.formatDisplayName(
                        member.name,
                        hideSurname: member.hideSurname,
                      );

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isPresent
                              ? AppColors.greenLight.withValues(alpha: 0.4)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isPresent
                                ? AppColors.greenBright.withValues(alpha: 0.35)
                                : AppColors.dividerLight,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Member Avatar
                            MemberAvatarCircle(
                              photoUrl: member.profilePhotoUrl,
                              initials: member.initials,
                              color: member.color,
                              size: 36,
                              border: isPresent
                                  ? Border.all(
                                      color: AppColors.greenBright,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            // Member Name & Status
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formattedName,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.deepEarth,
                                    ),
                                  ),
                                  Text(
                                    isPresent
                                        ? (memberArrivalLabel != null
                                            ? '✓ Arrived $memberArrivalLabel'
                                            : '✓ Arrived')
                                        : 'Not yet arrived',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isPresent
                                          ? AppColors.greenBright
                                          : AppColors.muted,
                                      fontWeight: isPresent
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 1-Tap Toggle Action Button (Driver-friendly)
                            if (widget.onMemberToggle != null)
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    _handleMemberToggle(member.id);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 13, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isPresent
                                          ? AppColors.greenBright
                                              .withValues(alpha: 0.15)
                                          : AppColors.sand,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isPresent
                                            ? AppColors.greenBright
                                                .withValues(alpha: 0.45)
                                            : AppColors.primary
                                                .withValues(alpha: 0.35),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isPresent
                                              ? Icons.check_rounded
                                              : Icons.add_rounded,
                                          size: 15,
                                          color: isPresent
                                              ? AppColors.greenBright
                                              : AppColors.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isPresent ? 'Undo' : 'Mark Arrived',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: isPresent
                                                ? AppColors.greenBright
                                                : AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Batch Shortcut: "Mark Everyone as Arrived"
                  if (!allArrived && widget.onMarkAllArrived != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _handleMarkAllArrived();
                        },
                        icon: const Icon(Icons.done_all_rounded,
                            size: 18, color: AppColors.primary),
                        label: const Text(
                          'Mark Everyone as Arrived',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.25),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color ?? AppColors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    color != null ? FontWeight.w600 : FontWeight.normal,
                color: color ?? AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final min = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$min $period';
  }
}
