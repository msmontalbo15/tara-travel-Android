import 'package:tara_travel/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// The 9 ABO/Rh blood type options available in the dropdown.
const List<String> kBloodTypes = [
  'A+', 'A−', 'B+', 'B−', 'AB+', 'AB−', 'O+', 'O−', 'Unknown',
];

class HealthSafetyStep extends StatefulWidget {
  final List<String> initialHealthNotes;
  final String? initialBloodType;
  final Function(List<String> notes) onNotesChanged;
  final Function(String? bloodType) onBloodTypeSelected;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const HealthSafetyStep({
    super.key,
    required this.initialHealthNotes,
    this.initialBloodType,
    required this.onNotesChanged,
    required this.onBloodTypeSelected,
    required this.onNext,
    required this.onSkip,
  });

  @override
  State<HealthSafetyStep> createState() => _HealthSafetyStepState();
}

class _HealthSafetyStepState extends State<HealthSafetyStep>
    with SingleTickerProviderStateMixin {
  static const String _noneOption = 'None';
  final List<String> _selectedNotes = [];
  final TextEditingController _customController = TextEditingController();
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;

  /// Currently selected blood type from dropdown.
  String? _selectedBloodType;

  final Map<String, bool> _genericOptions = {
    'None': false,
    'Allergies': false,
    'Asthma': false,
    'Dietary Restrictions': false,
    'Medical Condition': false,
  };

  @override
  void initState() {
    super.initState();
    _selectedBloodType = widget.initialBloodType;
    _selectedNotes.addAll(widget.initialHealthNotes);
    for (var note in _selectedNotes) {
      if (_genericOptions.containsKey(note)) {
        _genericOptions[note] = true;
      }
    }

    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();

    _customController.addListener(_onCustomChange);
  }

  @override
  void dispose() {
    _customController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _onCustomChange() {
    setState(() {}); // Rebuild for button state
    _updateNotes();
  }

  void _updateNotes() {
    if (_genericOptions[_noneOption] == true) {
      widget.onNotesChanged([_noneOption]);
      return;
    }

    final List<String> notes = [];
    _genericOptions.forEach((key, value) {
      if (value) notes.add(key);
    });
    if (_customController.text.isNotEmpty) {
      notes.add(_customController.text);
    }
    widget.onNotesChanged(notes);
  }

  void _onBloodTypeDropdownChanged(String? newValue) {
    setState(() {
      _selectedBloodType = newValue;
    });
    widget.onBloodTypeSelected(_selectedBloodType);
  }

  bool get _hasAnySelection =>
      _genericOptions.values.any((v) => v) ||
      _customController.text.trim().isNotEmpty ||
      _selectedBloodType != null;

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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.sand,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Step 5 of 6',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Safety & health',
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
                          'Optional info to help organizers look out\nfor you during group trips.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Blood Type Dropdown ─────────────────────────────
                        const Text(
                          'Blood Type',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Select your ABO/Rh blood type.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        BloodTypeDropdown(
                          value: _selectedBloodType,
                          onChanged: _onBloodTypeDropdownChanged,
                        ),

                        const SizedBox(height: 24),

                        // ── Health / Medical Checkboxes ──────────────────────
                        const Text(
                          'Health & Medical Info',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Checkboxes
                        ..._genericOptions.keys.map((option) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Theme(
                              data: Theme.of(context).copyWith(unselectedWidgetColor: AppColors.warmMuted),
                              child: CheckboxListTile(
                                value: _genericOptions[option],
                                onChanged: (val) {
                                  setState(() {
                                    final isSelected = val ?? false;
                                    _genericOptions[option] = isSelected;

                                    if (option == _noneOption && isSelected) {
                                      for (final key in _genericOptions.keys) {
                                        if (key != _noneOption) {
                                          _genericOptions[key] = false;
                                        }
                                      }
                                      _customController.clear();
                                    } else if (option != _noneOption && isSelected) {
                                      _genericOptions[_noneOption] = false;
                                    }
                                  });
                                  _updateNotes();
                                },
                                title: Text(
                                  option,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: _genericOptions[option]! ? AppColors.primary : AppColors.dividerLight),
                                ),
                                tileColor: Colors.white,
                                activeColor: AppColors.primary,
                                checkColor: Colors.white,
                                dense: true,
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 16),
                        const Text(
                          'Specific details',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _customController,
                          maxLines: 3,
                          enabled: _genericOptions[_noneOption] != true,
                          decoration: InputDecoration(
                            hintText: 'e.g. Peanuts allergy, asthma, medical notes...',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          ),
                        ),

                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.sand,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'This info is private and only shared with organizers of trips you join.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.primary.withValues(alpha: 0.8),
                                    height: 1.4,
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

                // Bottom Buttons
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _hasAnySelection ? widget.onNext : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
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

// ── Blood Type Dropdown Widget ────────────────────────────────────────────────

class BloodTypeDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const BloodTypeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveValue = (value != null && kBloodTypes.contains(value)) ? value : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: effectiveValue != null ? AppColors.primary : AppColors.cardBorder,
          width: effectiveValue != null ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveValue,
          hint: const Row(
            children: [
              Icon(Icons.bloodtype_outlined, color: AppColors.warmMuted, size: 20),
              SizedBox(width: 10),
              Text(
                'Select blood type...',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.warmMuted,
                ),
              ),
            ],
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.warmMuted, size: 24),
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          dropdownColor: Colors.white,
          elevation: 4,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          items: kBloodTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEB),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.favorite_border_rounded,
                      size: 14,
                      color: Color(0xFFE53935),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    type,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
