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
              clipBehavior: Clip.hardEdge,
              children: [
                // Ambient glow blob
                Positioned(
                  right: -24,
                  top: -24,
                  child: IgnorePointer(
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: themeColor.withValues(alpha: 0.28),
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
                      // ── Header row: NEXT TRIP badge + date pill + Live Nav CTA ──
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: themeColor.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.30)),
                            ),
                            child: const Text(
                              'NEXT TRIP',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ),
                          if (widget.onNavigation != null) ...[
                            const Spacer(),
                            GestureDetector(
                              onTap: widget.onNavigation,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.navigation_rounded,
                                        color: Colors.white, size: 12),
                                    SizedBox(width: 4),
                                    Text(
                                      'Live Nav',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ] else
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
                                fontFamily: 'DM Sans',
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

                          // Days countdown
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
                                    daysAway > 0 ? '$daysAway' : '0',
                                    style: TextStyle(
                                      fontFamily: 'Playfair Display',
                                      fontSize: 52,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -2,
                                      height: 1,
                                      shadows: [
                                        Shadow(
                                          color: themeColor
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
                                      'days away',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white
                                            .withValues(alpha: 0.55),
                                      ),
                                    ),
                                    Text(
                                      '$tripDuration day${tripDuration == 1 ? '' : 's'} trip',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
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
                                    fontFamily: 'DM Sans',
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
                                          fontFamily: 'DM Sans',
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
                              fontFamily: 'Playfair Display',
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
                                  fontFamily: 'Playfair Display',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${daysAway > 0 ? daysAway : 0}d away',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: themeColor.withValues(alpha: 0.90),
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
