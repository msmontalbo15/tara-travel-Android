import 'package:tara_travel/core/theme/app_text_styles.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/trip_model.dart';

/// Collapsible Next Trip card.
///
/// When [collapsed] is true the card shrinks to a compact single-line form
/// showing just the trip name + "X days away".  The parent drives this value
/// from a [ScrollController].
class NextTripCard extends StatefulWidget {
  final TripModel trip;
  final bool collapsed;
  final VoidCallback? onTap;
  final VoidCallback? onNavigation;

  const NextTripCard({
    super.key,
    required this.trip,
    this.collapsed = false,
    this.onTap,
    this.onNavigation,
  });

  @override
  State<NextTripCard> createState() => _NextTripCardState();
}

class _NextTripCardState extends State<NextTripCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _collapseCtrl;
  late Animation<double> _expandFactor;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _collapseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.collapsed ? 0.0 : 1.0,
    );

    _expandFactor = CurvedAnimation(
      parent: _collapseCtrl,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(NextTripCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.collapsed != oldWidget.collapsed) {
      widget.collapsed ? _collapseCtrl.reverse() : _collapseCtrl.forward();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _collapseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.trip.coverColor;
    final emojiDisplay = widget.trip.coverEmoji;

    final now = DateTime.now();
    final daysAway = widget.trip.fromDate
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;

    final tripDuration =
        widget.trip.toDate.difference(widget.trip.fromDate).inDays + 1;
    final isOngoing = widget.trip.isOngoing;
    final currentDay = (now
                .difference(DateTime(widget.trip.fromDate.year,
                    widget.trip.fromDate.month, widget.trip.fromDate.day))
                .inDays +
            1)
        .clamp(1, tripDuration);

    final dateLabel =
        '${DateFormat('MMM d').format(widget.trip.fromDate)} – ${DateFormat('MMM d').format(widget.trip.toDate)}';

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  themeColor.withValues(alpha: 0.20),
                  Colors.white.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: themeColor.withValues(alpha: 0.35)),
            ),
            child: Stack(
              children: [
                // Top-right decorative circular gradient bloom
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          themeColor.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Emoji watermark
                Positioned(
                  right: 8,
                  bottom: -10,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.12,
                      child: Text(
                        emojiDisplay,
                        style: const TextStyle(fontSize: 70, height: 1.0),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Header row: NEXT TRIP badge + date pill ──
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOngoing
                                  ? AppColors.green.withValues(alpha: 0.35)
                                  : themeColor.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: isOngoing
                                      ? AppColors.greenBright
                                          .withValues(alpha: 0.60)
                                      : Colors.white.withValues(alpha: 0.30)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isOngoing) ...[
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.greenBright,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                ],
                                Text(
                                  isOngoing ? 'ONGOING TRIP' : 'NEXT TRIP',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12)),
                            ),
                            child: Text(
                              dateLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                        ],
                      ),

                    // ── Expanded content ─────────────────────────────────
                    SizeTransition(
                      sizeFactor: _expandFactor,
                      axisAlignment: -1.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 12),

                          // Days countdown or ongoing day counter
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              AnimatedBuilder(
                                animation: _pulseCtrl,
                                builder: (context, _) {
                                  final glow =
                                      0.25 + (_pulseCtrl.value * 0.35);
                                  return Text(
                                    isOngoing
                                        ? '$currentDay'
                                        : (daysAway > 0 ? '$daysAway' : '0'),
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontBody,
                                      fontSize: 52,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -2,
                                      height: 1,
                                      shadows: [
                                        Shadow(
                                          color: (isOngoing
                                                  ? AppColors.greenBright
                                                  : themeColor)
                                              .withValues(alpha: glow),
                                          blurRadius: 24,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isOngoing ? 'Day of trip' : 'days away',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white
                                            .withValues(alpha: 0.55),
                                      ),
                                    ),
                                    Text(
                                      isOngoing
                                          ? 'Day $currentDay of $tripDuration days'
                                          : '$tripDuration day${tripDuration == 1 ? '' : 's'} trip',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white
                                            .withValues(alpha: 0.35),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Destination + member count
                          Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  size: 15,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  widget.trip.destination,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        Colors.white.withValues(alpha: 0.65),
                                  ),
                                ),
                              ),
                              if (widget.trip.members.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: themeColor.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color:
                                            themeColor.withValues(alpha: 0.30)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.group_rounded,
                                          size: 12,
                                          color: Colors.white
                                              .withValues(alpha: 0.70)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${widget.trip.members.length}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white
                                              .withValues(alpha: 0.75),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Trip name / title
                          Text(
                            widget.trip.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontHeading,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.3,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Collapsed mini row ───────────────────────────────
                    SizeTransition(
                      sizeFactor: ReverseAnimation(_expandFactor),
                      axisAlignment: -1.0,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.trip.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontHeading,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isOngoing
                                  ? 'Day $currentDay of $tripDuration'
                                  : '${daysAway > 0 ? daysAway : 0}d away',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isOngoing
                                    ? AppColors.greenBright
                                    : themeColor.withValues(alpha: 0.90),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
