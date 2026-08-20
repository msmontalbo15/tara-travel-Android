import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/trip_types.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_brand_logo.dart';
import '../../../core/utils/currency_utils.dart';
import '../models/new_trip_model.dart';
import '../widgets/step_indicator.dart';

class ConfirmStep extends StatelessWidget {
  final NewTripModel trip;
  final VoidCallback onConfirm;
  final VoidCallback onSaveDraft;
  final VoidCallback onBack;
  final void Function(int stepIndex)? onEditStep;

  const ConfirmStep({
    super.key,
    required this.trip,
    required this.onConfirm,
    required this.onSaveDraft,
    required this.onBack,
    this.onEditStep,
  });

  // ── Date Helpers ─────────────────────────────────────────────────────────────

  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _fmtShortDate(DateTime? d) {
    if (d == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  int get _nights {
    if (trip.fromDate == null || trip.toDate == null) return 0;
    final diff = trip.toDate!.difference(trip.fromDate!).inDays;
    return diff < 0 ? 0 : diff;
  }

  int get _days {
    if (trip.fromDate == null || trip.toDate == null) return 1;
    final diff = trip.toDate!.difference(trip.fromDate!).inDays;
    return diff < 0 ? 1 : diff + 1;
  }

  String get _countdownText {
    if (trip.fromDate == null) return 'Upcoming';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(trip.fromDate!.year, trip.fromDate!.month, trip.fromDate!.day);
    final daysUntil = start.difference(today).inDays;

    if (daysUntil == 0) return 'Starts Today! 🎉';
    if (daysUntil == 1) return 'Starts Tomorrow! 🚀';
    if (daysUntil > 1) return 'In $daysUntil days ⏳';
    if (daysUntil == -1) return 'Started yesterday';
    return '${daysUntil.abs()} days ago';
  }

  // ── Trip Type & Accent Color ────────────────────────────────────────────────

  TripTypeOption get _tripTypeOption {
    return AppTripTypes.getOption(trip.tripType);
  }

  Color get _themeColor {
    if (trip.coverColor != null) {
      return Color(trip.coverColor!);
    }
    return _tripTypeOption.accentColor;
  }

  // ── Readiness & Validation ──────────────────────────────────────────────────

  int get _readinessScore {
    int score = 0;
    if (trip.tripName.isNotEmpty && trip.destination.isNotEmpty && trip.fromDate != null && trip.toDate != null) {
      score++;
    }
    if (trip.transportDetail != null) {
      score++;
    }
    if ((trip.totalBudget ?? 0) > 0) {
      score++;
    }
    if (trip.travelers.isNotEmpty) {
      score++;
    }
    return score;
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF140704);
    const cardBg = Color(0xFF220E08);
    const innerSurface = Color(0xFF33160D);
    const muted = Color(0xFFA68579);
    const white = Colors.white;

    final themeColor = _themeColor;
    final totalBudget = trip.totalBudget ?? 0;
    final travelerCount = trip.travelers.isNotEmpty ? trip.travelers.length : 1;
    final perPersonBudget = totalBudget > 0 ? totalBudget / travelerCount : 0.0;
    final dailyBudget = totalBudget > 0 && _days > 0 ? totalBudget / _days : 0.0;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            'Back',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Review Trip',
                        style: TextStyle(
                          fontFamily: 'Playfair Display',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                  const AppBrandLogo(size: 32, isDark: true),
                ],
              ),
            ),

            // ── Step Indicator Bar ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const StepIndicator(
                    currentStep: 4,
                    totalSteps: 4,
                    label: 'Review & Launch Trip',
                    isDark: true,
                  ),
                  const SizedBox(height: 8),
                  // Sleek Full Gradient Progress Line
                  Container(
                    height: 3.5,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        colors: [
                          themeColor,
                          AppColors.primary,
                          AppColors.amber,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Scrollable Review Cards ──────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Trip Readiness Banner
                    _buildReadinessBanner(themeColor),
                    const SizedBox(height: 16),

                    // 2. Hero Destination & Overview Card (Step 1)
                    _buildHeroOverviewCard(
                      cardBg: cardBg,
                      innerSurface: innerSurface,
                      muted: muted,
                      white: white,
                      themeColor: themeColor,
                    ),
                    const SizedBox(height: 16),

                    // 3. Journey Route & Transport Card (Step 2)
                    _buildTransportCard(
                      cardBg: cardBg,
                      innerSurface: innerSurface,
                      muted: muted,
                      white: white,
                    ),
                    const SizedBox(height: 16),

                    // 4. Financial & Budget Breakdown Card (Step 3)
                    _buildBudgetCard(
                      cardBg: cardBg,
                      innerSurface: innerSurface,
                      muted: muted,
                      white: white,
                      totalBudget: totalBudget,
                      perPersonBudget: perPersonBudget,
                      dailyBudget: dailyBudget,
                    ),
                    const SizedBox(height: 16),

                    // 5. Travelers & Squad Roster
                    _buildTravelersCard(
                      cardBg: cardBg,
                      innerSurface: innerSurface,
                      muted: muted,
                      white: white,
                      perPersonBudget: perPersonBudget,
                    ),
                    const SizedBox(height: 16),

                    // 6. What's Included Upon Creation
                    _buildIncludedFeaturesCard(cardBg, innerSurface, muted, white),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),

            // ── Bottom Fixed Action Bar ──────────────────────────────
            _buildBottomActionBar(bg, white),
          ],
        ),
      ),
    );
  }

  // ── 1. Readiness Banner ──────────────────────────────────────────────────────

  Widget _buildReadinessBanner(Color themeColor) {
    final score = _readinessScore;
    final isComplete = score == 4;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2C130B),
            themeColor.withValues(alpha: 0.20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete
              ? const Color(0xFF10B981).withValues(alpha: 0.45)
              : AppColors.amber.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: (isComplete ? const Color(0xFF10B981) : AppColors.amber).withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: (isComplete ? const Color(0xFF10B981) : AppColors.amber).withValues(alpha: 0.35),
              ),
            ),
            child: Icon(
              isComplete ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              size: 20,
              color: isComplete ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isComplete ? 'All Set to Travel!' : 'Reviewing Trip Details',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Text(
                        '$score / 4 Ready',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF49D79),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isComplete
                      ? 'Destination, travel dates, transport, and budget are fully configured.'
                      : 'Review all trip details below before launching.',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    color: Color(0xFFD1BDB7),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Hero Destination & Overview Card (Step 1) ─────────────────────────────

  Widget _buildHeroOverviewCard({
    required Color cardBg,
    required Color innerSurface,
    required Color muted,
    required Color white,
    required Color themeColor,
  }) {
    final option = _tripTypeOption;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3F1F17)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dynamic Accent Banner Top Strip
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: themeColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Section Label + Edit Step 1 Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: themeColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(option.emoji, style: const TextStyle(fontSize: 13)),
                              const SizedBox(width: 5),
                              Text(
                                option.label.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: themeColor,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Countdown pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _countdownText,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFEF9F27),
                            ),
                          ),
                        ),
                      ],
                    ),
                    _buildEditButton(
                      label: 'Edit Details',
                      stepIndex: 0,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Trip Title
                Text(
                  trip.tripName.isEmpty ? 'Untitled Epic Journey' : trip.tripName,
                  style: const TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),

                // Destination Pin
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        trip.destination.isEmpty ? 'Destination To Be Announced' : trip.destination,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF0997B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Dates & Duration Grid Tile
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: innerSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF4A2419)),
                  ),
                  child: Row(
                    children: [
                      // Date range
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TRAVEL DATES',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF9C7B70),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              trip.fromDate != null && trip.toDate != null
                                  ? '${_fmtShortDate(trip.fromDate)} – ${_fmtDate(trip.toDate)}'
                                  : 'Dates not set',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 36,
                        width: 1,
                        color: const Color(0xFF4A2419),
                      ),
                      const SizedBox(width: 14),
                      // Duration
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DURATION',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF9C7B70),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.wb_sunny_outlined, size: 14, color: AppColors.amber),
                              const SizedBox(width: 4),
                              Text(
                                '$_days ${_days == 1 ? 'Day' : 'Days'} · $_nights ${_nights == 1 ? 'Night' : 'Nights'}',
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Journey Route & Transport Card (Step 2) ───────────────────────────────

  Widget _buildTransportCard({
    required Color cardBg,
    required Color innerSurface,
    required Color muted,
    required Color white,
  }) {
    final transport = trip.transportDetail;
    final mode = transport?.mode ?? TransportMode.car;
    final departure = transport?.departurePoint ?? trip.departurePoint;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3F1F17)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title + Edit Step 2 Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.directions_transit_rounded, size: 16, color: Color(0xFF3B82F6)),
                  SizedBox(width: 6),
                  Text(
                    'TRANSPORT & ROUTE',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9C7B70),
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              _buildEditButton(
                label: 'Edit Transport',
                stepIndex: 1,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Primary Transport Mode Hero Pill
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: innerSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF4A2419)),
            ),
            child: Row(
              children: [
                // Transport Mode Emoji Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A2419),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      mode.emoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            mode.label,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              mode.category.name.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF60A5FA),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transport != null && transport.estimatedDuration.isNotEmpty
                            ? 'Est. Travel Time: ${transport.estimatedDuration}'
                            : 'Approx. ${mode.averageSpeedKmh.toInt()} km/h average pace',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          color: Color(0xFFEF9F27),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Route Flow Visual: Origin ➔ Destination
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.trip_origin_rounded, size: 14, color: AppColors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    departure != null && departure.isNotEmpty ? departure : 'Departure Point TBD',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD1BDB7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF9C7B70)),
                ),
                const Icon(Icons.place_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trip.destination.isNotEmpty ? trip.destination : 'Destination',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Extra details chips if provided
          if (transport != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (transport.operatorName != null && transport.operatorName!.isNotEmpty)
                  _buildDetailChip('🏢 ${transport.operatorName}'),
                if (transport.flightNumber != null && transport.flightNumber!.isNotEmpty)
                  _buildDetailChip('🎫 Flight/Trip #${transport.flightNumber}'),
                if (transport.bookingReference != null && transport.bookingReference!.isNotEmpty)
                  _buildDetailChip('🔖 Ref: ${transport.bookingReference}'),
                if (transport.pierName != null && transport.pierName!.isNotEmpty)
                  _buildDetailChip('⚓ Pier: ${transport.pierName}'),
                if (transport.vehicleCount != null && transport.vehicleCount! > 1)
                  _buildDetailChip('🚗 ${transport.vehicleCount} Vehicles'),
                if (transport.splitGas)
                  _buildDetailChip('⛽ Fuel Split Enabled', highlight: true),
                if (transport.estimatedCost != null && transport.estimatedCost! > 0)
                  _buildDetailChip('💳 Transport Fare: ${CurrencyUtils.formatCurrency(transport.estimatedCost!)}'),
              ],
            ),
            if (transport.notes != null && transport.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF33160D),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.sticky_note_2_outlined, size: 14, color: Color(0xFFEF9F27)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        transport.notes!,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFFD1BDB7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ── 4. Financial & Budget Breakdown Card (Step 3) ────────────────────────────

  Widget _buildBudgetCard({
    required Color cardBg,
    required Color innerSurface,
    required Color muted,
    required Color white,
    required double totalBudget,
    required double perPersonBudget,
    required double dailyBudget,
  }) {
    final activeCategories = trip.budgetBreakdown.where((c) => c.amount > 0).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3F1F17)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title + Edit Step 3 Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet_rounded, size: 16, color: Color(0xFF10B981)),
                  SizedBox(width: 6),
                  Text(
                    'BUDGET & EXPENSE SPLIT',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9C7B70),
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              _buildEditButton(
                label: 'Edit Budget',
                stepIndex: 2,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Total Budget Hero Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF3B1E14),
                  Color(0xFF2C1510),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF4A2419)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL TRIP BUDGET',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9C7B70),
                        letterSpacing: 0.8,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getSplitModeLabel(trip.splitMode),
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF34D399),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyUtils.formatCurrency(totalBudget),
                  style: const TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFF4A2419), height: 1),
                const SizedBox(height: 12),

                // Metrics: Daily Spending & Per-Person Share
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PER PERSON SHARE',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF9C7B70),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            trip.splitMode == 'treat'
                                ? '🎁 Host treats'
                                : CurrencyUtils.formatCurrency(perPersonBudget),
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF49D79),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 28,
                      width: 1,
                      color: const Color(0xFF4A2419),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DAILY ALLOWANCE',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF9C7B70),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${CurrencyUtils.formatCurrency(dailyBudget)}/day',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Category Allocation Visual Bar (if categories are allocated)
          if (activeCategories.isNotEmpty && totalBudget > 0) ...[
            const SizedBox(height: 16),
            const Text(
              'CATEGORY ALLOCATIONS',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9C7B70),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),

            // Multi-segment progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: trip.budgetBreakdown.map((cat) {
                    final fraction = totalBudget > 0 ? (cat.amount / totalBudget).clamp(0.0, 1.0) : 0.0;
                    if (fraction <= 0) return const SizedBox.shrink();
                    return Expanded(
                      flex: (fraction * 1000).toInt(),
                      child: Container(
                        color: Color(cat.color),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Category breakdown rows
            ...activeCategories.map((cat) {
              final pct = totalBudget > 0 ? ((cat.amount / totalBudget) * 100).toStringAsFixed(0) : '0';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color(cat.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(cat.icon, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cat.name,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          color: Color(0xFFD1BDB7),
                        ),
                      ),
                    ),
                    Text(
                      '$pct% · ',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        color: Color(0xFF9C7B70),
                      ),
                    ),
                    Text(
                      CurrencyUtils.formatCurrency(cat.amount),
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ── 5. Travelers & Squad Roster ─────────────────────────────────────────────

  Widget _buildTravelersCard({
    required Color cardBg,
    required Color innerSurface,
    required Color muted,
    required Color white,
    required double perPersonBudget,
  }) {
    final travelers = trip.travelers;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3F1F17)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_alt_rounded, size: 16, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 6),
                  Text(
                    'TRAVEL SQUAD · ${travelers.length}',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9C7B70),
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              _buildEditButton(
                label: 'Add/Edit',
                stepIndex: 0,
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (travelers.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: innerSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.person_pin_rounded, size: 20, color: Color(0xFF9C7B70)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Solo traveler. You can invite friends anytime with your unique trip code!',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        color: Color(0xFFD1BDB7),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: travelers.map((t) {
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: innerSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF4A2419)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Color(t.color),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              t.initials,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              t.name,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              trip.splitMode == 'treat'
                                  ? 'Host Treats'
                                  : CurrencyUtils.formatCurrency(perPersonBudget),
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 11,
                                color: Color(0xFF9C7B70),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ── 6. What's Included Upon Creation ─────────────────────────────────────────

  Widget _buildIncludedFeaturesCard(Color cardBg, Color innerSurface, Color muted, Color white) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3F1F17)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'WHAT GETS GENERATED',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9C7B70),
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildFeatureItem(
            icon: '📋',
            title: 'Auto-seeded Packing Checklist',
            subtitle: 'Ready-to-use packing items tailored to your ${_tripTypeOption.label} trip.',
          ),
          const SizedBox(height: 10),
          _buildFeatureItem(
            icon: '🗺️',
            title: 'Empty $_days-Day Itinerary Template',
            subtitle: 'A blank timeline created for your dates, ready for you to add stops & activities.',
          ),
          const SizedBox(height: 10),
          _buildFeatureItem(
            icon: '💸',
            title: 'Live Expense & Debt Balances',
            subtitle: 'Log expenses on the go with automatic group split calculations.',
          ),
          const SizedBox(height: 10),
          _buildFeatureItem(
            icon: '🔗',
            title: 'Squad Invite Code & QR',
            subtitle: 'Share your 6-character trip invite code for 1-tap friend joining.',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required String icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  color: Color(0xFF9C7B70),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 7. Bottom Fixed Action Bar ───────────────────────────────────────────────

  Widget _buildBottomActionBar(Color bg, Color white) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: bg,
        border: const Border(top: BorderSide(color: Color(0xFF2C1510))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary Launch Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rocket_launch_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Create My Trip ✨',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Save Draft Button
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              onSaveDraft();
            },
            child: const Text(
              'Save as Draft & Finish Later',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9C7B70),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper Widgets ──────────────────────────────────────────────────────────

  Widget _buildEditButton({required String label, required int stepIndex}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (onEditStep != null) {
          onEditStep!(stepIndex);
        } else {
          onBack();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_outlined, size: 12, color: Color(0xFFF49D79)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF49D79),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(String text, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFF10B981).withValues(alpha: 0.15)
            : const Color(0xFF33160D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : const Color(0xFF4A2419),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: highlight ? const Color(0xFF34D399) : const Color(0xFFD1BDB7),
        ),
      ),
    );
  }

  String _getSplitModeLabel(String mode) {
    switch (mode) {
      case 'equal':
        return '⚖️ Equal Split';
      case 'fixed':
        return '🎯 Custom Fixed';
      case 'percentage':
        return '📊 Percentage Split';
      case 'treat':
        return '🎁 Treat Mode';
      default:
        return '⚖️ Equal Split';
    }
  }
}
