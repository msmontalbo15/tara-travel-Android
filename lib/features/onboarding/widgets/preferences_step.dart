import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ph_location_picker.dart';

class PreferencesStep extends StatefulWidget {
  final String initialCity;
  final String initialCountry;
  final String initialCurrency;
  final Function(String city, String country, String currency) onPreferencesChanged;
  final VoidCallback onNext;

  // Extended PH fields (may be empty on first load)
  final String initialRegion;
  final String initialBarangay;
  final Function(String region, String city, String barangay, String currency)?
      onPhPreferencesChanged;

  const PreferencesStep({
    super.key,
    required this.initialCity,
    required this.initialCountry,
    required this.initialCurrency,
    required this.onPreferencesChanged,
    required this.onNext,
    this.initialRegion = '',
    this.initialBarangay = '',
    this.onPhPreferencesChanged,
  });

  @override
  State<PreferencesStep> createState() => _PreferencesStepState();
}

class _PreferencesStepState extends State<PreferencesStep>
    with SingleTickerProviderStateMixin {
  String? _region;
  String? _city;
  String? _barangay;
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _region = widget.initialRegion.isNotEmpty ? widget.initialRegion : null;
    _city = widget.initialCity.isNotEmpty ? widget.initialCity : null;
    _barangay =
        widget.initialBarangay.isNotEmpty ? widget.initialBarangay : null;

    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _onChange(String? region, String? city, String? barangay) {
    setState(() {
      _region = region;
      _city = city;
      _barangay = barangay;
    });
    // Notify parent — keep backwards-compat signature
    widget.onPreferencesChanged(city ?? '', 'Philippines', 'PHP');
    widget.onPhPreferencesChanged?.call(
        region ?? '', city ?? '', barangay ?? '', 'PHP');
  }

  bool get _isFormValid =>
      _region != null && _city != null && _barangay != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnim,
          child: FadeTransition(
            opacity: _animCtrl,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 32),

                        // Step pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.sand,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Step 4 of 6',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'Your home &\npreferences',
                          style: TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tell us where you live so we can personalize your travel experience.',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // PH Cascading Picker
                        PhLocationPicker(
                          initialRegion: _region,
                          initialCity: _city,
                          initialBarangay: _barangay,
                          onChanged: _onChange,
                        ),

                        const SizedBox(height: 24),

                        // Currency (auto = PHP)
                        const Text(
                          'Preferred Currency',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.payments_outlined,
                                  color: AppColors.warmMuted, size: 18),
                              SizedBox(width: 10),
                              Text(
                                'PHP – Philippine Peso',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Spacer(),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                child: Text(
                                  'Auto',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Currency is set to PHP for Philippine users.',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Continue button
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isFormValid ? widget.onNext : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.3),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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
