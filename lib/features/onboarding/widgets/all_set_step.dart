import 'package:tara_travel/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Final onboarding confirmation screen (Step 5 of 5).
///
/// Displays the refined summary of the user's travel setup:
/// - Connected Google Account
/// - Home Location (City, Country)
/// - Preferred Currency
/// - Health & Safety summary (Blood type and medical notes if provided)
///
/// Provides launchpad actions to jump straight into planning a first trip
/// or explore the app.
class AllSetStep extends StatefulWidget {
  final String userName;
  final String accountEmail;
  final String homeCity;
  final String homeCountry;
  final String currency;
  final String? bloodType;
  final List<String> healthNotes;
  final VoidCallback onLetsGo;
  final VoidCallback? onCreateFirstTrip;

  const AllSetStep({
    super.key,
    required this.userName,
    required this.accountEmail,
    required this.homeCity,
    required this.homeCountry,
    required this.currency,
    this.bloodType,
    this.healthNotes = const [],
    required this.onLetsGo,
    this.onCreateFirstTrip,
  });

  @override
  State<AllSetStep> createState() => _AllSetStepState();
}

class _AllSetStepState extends State<AllSetStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _formatHealthSafetySummary() {
    final hasBloodType = widget.bloodType != null &&
        widget.bloodType!.isNotEmpty &&
        widget.bloodType != 'Unknown';
    final notes = widget.healthNotes
        .where((n) => n.trim().isNotEmpty && n != 'None')
        .toList();

    if (hasBloodType && notes.isNotEmpty) {
      return '${widget.bloodType} • ${notes.length} ${notes.length == 1 ? "note" : "notes"}';
    } else if (hasBloodType) {
      return widget.bloodType!;
    } else if (notes.isNotEmpty) {
      return '${notes.length} ${notes.length == 1 ? "condition noted" : "conditions noted"}';
    }
    return 'None specified';
  }

  @override
  Widget build(BuildContext context) {
    final healthSummary = _formatHealthSafetySummary();
    final hasSafetyInfo = healthSummary != 'None specified';

    return Scaffold(
      backgroundColor: AppColors.deepEarth,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),

              // Plain Logo
              ScaleTransition(
                scale: _scaleAnim,
                child: Image.asset(
                  'assets/logo.png',
                  width: 88,
                  height: 88,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 20),

              // Step pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Step 5 of 5',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Title
              FadeTransition(
                opacity: _ctrl,
                child: Text(
                  "You're all set,\n${widget.userName}!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontHeading,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              FadeTransition(
                opacity: _ctrl,
                child: Text(
                  'Your profile is synced and travel-ready.\nYour next journey begins here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.white.withValues(alpha: 0.5),
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Your Setup card
              FadeTransition(
                opacity: _ctrl,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    children: [
                      _SetupRow(
                        label: 'Google Account',
                        value: widget.accountEmail.isNotEmpty
                            ? widget.accountEmail
                            : 'Connected',
                        valueColor: const Color(0xFF4CAF50),
                        showDot: true,
                        isFirst: true,
                      ),
                      _divider(),
                      _SetupRow(
                        label: 'Home',
                        value: widget.homeCity.isNotEmpty
                            ? '${widget.homeCity}, ${widget.homeCountry}'
                            : widget.homeCountry,
                      ),
                      _divider(),
                      _SetupRow(
                        label: 'Currency',
                        value: widget.currency,
                      ),
                      _divider(),
                      _SetupRow(
                        label: 'Health & Safety',
                        value: healthSummary,
                        valueColor: hasSafetyInfo ? AppColors.sand : Colors.white54,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Primary Launch Option: Create First Trip
              if (widget.onCreateFirstTrip != null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: widget.onCreateFirstTrip,
                    icon: const Icon(Icons.add_location_alt_rounded, size: 20),
                    label: const Text(
                      'Plan your first trip',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Secondary Launch Option: Go to Home
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: widget.onLetsGo,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: widget.onCreateFirstTrip != null ? 0.25 : 0.6),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    widget.onCreateFirstTrip != null
                        ? 'Explore Tara Travel'
                        : "Tara na! Let's go",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: widget.onCreateFirstTrip != null
                          ? Colors.white.withValues(alpha: 0.85)
                          : Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() => Divider(
        height: 0.5,
        color: Colors.white.withValues(alpha: 0.06),
      );
}

class _SetupRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool showDot;
  final bool isFirst;
  final bool isLast;

  const _SetupRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.showDot = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showDot) ...[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: valueColor ?? Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
