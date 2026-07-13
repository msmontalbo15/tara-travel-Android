import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AllSetStep extends StatefulWidget {
  final String userName;
  final String accountEmail;
  final bool isGoogleConnected;
  final String homeCity;
  final String homeCountry;
  final String currency;
  final VoidCallback onLetsGo;

  const AllSetStep({
    super.key,
    required this.userName,
    required this.accountEmail,
    required this.isGoogleConnected,
    required this.homeCity,
    required this.homeCountry,
    required this.currency,
    required this.onLetsGo,
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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepEarth,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),

              // Plain Logo
              ScaleTransition(
                scale: _scaleAnim,
                child: Image.asset(
                  'assets/logo.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 28),

              // Step pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Step 6 of 6',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              FadeTransition(
                opacity: _ctrl,
                child: Text(
                  "You're all set,\n${widget.userName}!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              FadeTransition(
                opacity: _ctrl,
                child: Text(
                  widget.isGoogleConnected
                      ? 'Connected with Google. Your first adventure is\nwaiting to be planned.'
                      : 'You\'re set up offline. Your first adventure is\nwaiting to be planned.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.45),
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Your Setup card
              FadeTransition(
                opacity: _ctrl,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.deepEarth,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    children: [
                      _SetupRow(
                        label: 'Home',
                        value: '${widget.homeCity}, ${widget.homeCountry}',
                        isFirst: true,
                      ),
                      _divider(),
                      _SetupRow(
                        label: 'Currency',
                        value: widget.currency,
                      ),
                      _divider(),
                      _SetupRow(
                        label: 'Sync',
                        value: widget.isGoogleConnected ? 'Google connected' : 'Offline only',
                        valueColor: widget.isGoogleConnected
                            ? const Color(0xFF4CAF50)
                            : Colors.white54,
                        showDot: widget.isGoogleConnected,
                      ),
                      _divider(),
                      _SetupRow(
                        label: 'Mode',
                        value: widget.isGoogleConnected ? 'Online + offline' : 'Offline',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Tara na! Let's go button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: widget.onLetsGo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Tara na! Let\'s go',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),



              const SizedBox(height: 32),
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          Row(
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
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
