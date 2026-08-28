import 'package:flutter/material.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/models/member_model.dart';
import '../../../core/models/weather_model.dart';
import '../../../core/theme/app_colors.dart';
import 'day_budget_bar.dart';
import 'itinerary_fulfillment_banner.dart';
import 'transport_badge.dart';

/// Collapsible Day Insights accordion consolidating weather, budget burn rate,
/// fulfillment progress ring, and squad presence.
class DayInsightsHeader extends StatefulWidget {
  final ItineraryDay day;
  final List<MemberModel> members;
  final double dailyBudget;
  final DayForecast? weather;

  const DayInsightsHeader({
    super.key,
    required this.day,
    required this.members,
    required this.dailyBudget,
    this.weather,
  });

  @override
  State<DayInsightsHeader> createState() => _DayInsightsHeaderState();
}

class _DayInsightsHeaderState extends State<DayInsightsHeader>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  String _fmt(double v) =>
      '₱${v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final totalStops = day.stops.length;
    final completedStops = day.stops.where((s) => s.isCompleted).length;
    final spent = day.totalDayCost;
    final dailyBudget = widget.dailyBudget;

    if (totalStops == 0 && spent == 0 && widget.weather == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isExpanded
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.dividerLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Collapsed Header Bar (Always Clickable) ─────────────────────────
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  // Icon badge
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Pills summary
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          if (widget.weather != null) ...[
                            _PillItem(
                              icon: Icons.wb_sunny_rounded,
                              iconColor: const Color(0xFFEF9F27),
                              label:
                                  '${widget.weather!.tempMax.round()}°C ${widget.weather!.condition}',
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (spent > 0 || dailyBudget > 0) ...[
                            _PillItem(
                              icon: Icons.account_balance_wallet_rounded,
                              iconColor: spent > dailyBudget && dailyBudget > 0
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF10B981),
                              label: dailyBudget > 0
                                  ? '${_fmt(spent)} / ${_fmt(dailyBudget)}'
                                  : '${_fmt(spent)} spent',
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (totalStops > 0)
                            _PillItem(
                              icon: Icons.check_circle_outline_rounded,
                              iconColor: completedStops == totalStops
                                  ? const Color(0xFF10B981)
                                  : AppColors.primary,
                              label: '$completedStops/$totalStops done',
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.muted,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded Breakdown Drawer ─────────────────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 240),
            firstCurve: Curves.easeInOut,
            secondCurve: Curves.easeInOut,
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Fulfillment Banner (Progress ring + squad presence + next stop CTA)
                  if (totalStops > 0)
                    ItineraryFulfillmentBanner(
                      day: day,
                      allMembers: widget.members,
                    ),

                  // Budget progress bar
                  if (spent > 0 || dailyBudget > 0) ...[
                    const SizedBox(height: 4),
                    DayBudgetBar(
                      spent: spent,
                      dailyBudget: dailyBudget,
                    ),
                  ],

                  // Transport badge
                  if (day.transport != null) ...[
                    const SizedBox(height: 6),
                    TransportBadge(transport: day.transport!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _PillItem({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.deepEarth,
            ),
          ),
        ],
      ),
    );
  }
}
