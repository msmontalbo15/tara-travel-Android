import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class HealthSafetyStep extends StatefulWidget {
  final List<String> initialHealthNotes;
  final Function(List<String> notes) onNotesChanged;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const HealthSafetyStep({
    super.key,
    required this.initialHealthNotes,
    required this.onNotesChanged,
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
                              fontFamily: 'DM Sans',
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
                            fontFamily: 'Playfair Display',
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
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),

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
                                    fontFamily: 'DM Sans',
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
                            fontFamily: 'DM Sans',
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
                            hintText: 'e.g. Peanuts allergy, Blood type O+, etc.',
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
                                    fontFamily: 'DM Sans',
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
                          onPressed: (_genericOptions.values.any((v) => v) || _customController.text.trim().isNotEmpty)
                              ? widget.onNext
                              : null,
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
                              fontFamily: 'DM Sans',
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
                            fontFamily: 'DM Sans',
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

