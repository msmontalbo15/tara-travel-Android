import 'package:tara_travel/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

class NicknameBirthdayStep extends StatefulWidget {
  final String initialNickname;
  final String initialDateOfBirth;
  final String userName;
  final Function(String nickname, String dob) onNext;
  final VoidCallback onSkip;

  const NicknameBirthdayStep({
    super.key,
    required this.initialNickname,
    required this.initialDateOfBirth,
    required this.userName,
    required this.onNext,
    required this.onSkip,
  });

  @override
  State<NicknameBirthdayStep> createState() => _NicknameBirthdayStepState();
}

class _NicknameBirthdayStepState extends State<NicknameBirthdayStep>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nicknameCtrl;
  String _selectedDob = '';
  DateTime? _selectedDate;

  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _nicknameCtrl = TextEditingController(text: widget.initialNickname);
    _selectedDob = widget.initialDateOfBirth;
    if (_selectedDob.isNotEmpty) {
      try {
        _selectedDate = DateTime.parse(_selectedDob);
      } catch (_) {}
    }

    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initialDate = _selectedDate ?? DateTime(now.year - 20, now.month, now.day);
    final firstDate = DateTime(1920);
    final lastDate = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedDob = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _submit() {
    widget.onNext(
      _nicknameCtrl.text.trim(),
      _selectedDob,
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDobDisplay = _selectedDate != null
        ? DateFormat('MMMM d, yyyy').format(_selectedDate!)
        : 'Select Date of Birth';

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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.sand,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Step 4 of 7',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Nickname & Birthday',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontHeading,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Help your travel companions know what to call you and when to celebrate!',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // ── Nickname Input ─────────────────────────────────────
                        const Text(
                          'Nickname / Preferred Name',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nicknameCtrl,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle( fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'e.g. Spence, Alex',
                            hintStyle: TextStyle(
                                color: AppColors.warmMuted.withValues(alpha: 0.5),
                                fontSize: 14),
                            prefixIcon: const Icon(Icons.badge_outlined,
                                size: 20, color: AppColors.warmMuted),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: AppColors.cardBorder)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.cardBorder, width: 0.8)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.primary, width: 1.5)),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Birthday Picker Button ──────────────────────────────
                        const Text(
                          'Date of Birth',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedDate != null
                                    ? AppColors.primary
                                    : AppColors.cardBorder,
                                width: _selectedDate != null ? 1.5 : 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.cake_outlined,
                                    size: 20, color: AppColors.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    formattedDobDisplay,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: _selectedDate != null
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: _selectedDate != null
                                          ? AppColors.textPrimary
                                          : AppColors.warmMuted,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.calendar_today_rounded,
                                    size: 18, color: AppColors.warmMuted),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Bottom CTA Buttons
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: widget.onSkip,
                        child: const Text(
                          'Skip for now',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
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
