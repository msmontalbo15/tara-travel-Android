import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/trip_model.dart';

class NextTripCard extends StatefulWidget {
  final TripModel trip;
  const NextTripCard({super.key, required this.trip});

  @override
  State<NextTripCard> createState() => _NextTripCardState();
}

class _NextTripCardState extends State<NextTripCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Stack(
            children: [
              // Ambient glow blob
              Positioned(
                right: -24,
                top: -24,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.18),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.25)),
                      ),
                      child: const Text(
                        'NEXT TRIP',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryLight,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Days countdown with pulse
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (context, child) {
                            final glow = 0.25 + (_pulseCtrl.value * 0.35);
                            final now = DateTime.now();
                            final daysAway = widget.trip.fromDate
                                .difference(DateTime(now.year, now.month, now.day))
                                .inDays;
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
                                    color: AppColors.primary.withValues(alpha: glow),
                                    blurRadius: 24,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'days',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                            Text(
                              'away',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.30),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Location and dates row
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            size: 15,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.trip.destination,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.10)),
                          ),
                          child: Text(
                            '${DateFormat('MMM d').format(widget.trip.fromDate)}–${DateFormat('d').format(widget.trip.toDate)}',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.40),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
