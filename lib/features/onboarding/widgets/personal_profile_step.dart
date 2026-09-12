import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tara_travel/core/theme/app_colors.dart';
import 'package:tara_travel/core/theme/app_text_styles.dart';

class PersonalProfileStep extends StatefulWidget {
  final String? initialPhotoPath;
  final String initialNickname;
  final String initialDateOfBirth;
  final String userName;
  final void Function(String? photoPath, String nickname, String dateOfBirth) onNext;
  final VoidCallback onSkip;

  const PersonalProfileStep({
    super.key,
    this.initialPhotoPath,
    required this.initialNickname,
    required this.initialDateOfBirth,
    required this.userName,
    required this.onNext,
    required this.onSkip,
  });

  @override
  State<PersonalProfileStep> createState() => _PersonalProfileStepState();
}

class _PersonalProfileStepState extends State<PersonalProfileStep>
    with SingleTickerProviderStateMixin {
  String? _photoPath;
  late final TextEditingController _nicknameCtrl;
  DateTime? _selectedDate;
  final ImagePicker _picker = ImagePicker();

  late final AnimationController _animCtrl;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _photoPath = widget.initialPhotoPath;
    _nicknameCtrl = TextEditingController(
      text: widget.initialNickname.isNotEmpty
          ? widget.initialNickname
          : _suggestNickname(widget.userName),
    );

    if (widget.initialDateOfBirth.isNotEmpty) {
      _selectedDate = DateTime.tryParse(widget.initialDateOfBirth);
    }

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  String _suggestNickname(String full) {
    final parts = full.trim().split(RegExp(r'\s+'));
    if (parts.isNotEmpty && parts.first.isNotEmpty) {
      return parts.first;
    }
    return '';
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      if (pickedFile != null && mounted) {
        setState(() => _photoPath = pickedFile.path);
      }
    } catch (e) {
      debugPrint('[PersonalProfileStep] Error picking image: $e');
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Profile Photo',
              style: TextStyle(
                fontFamily: AppTextStyles.fontHeading,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _pickerTile(Icons.camera_alt_rounded, 'Camera', () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                }),
                _pickerTile(Icons.photo_library_rounded, 'Gallery', () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                }),
                if (_photoPath != null && _photoPath!.isNotEmpty)
                  _pickerTile(Icons.delete_outline_rounded, 'Remove', () {
                    Navigator.pop(ctx);
                    setState(() => _photoPath = null);
                  }, isDestructive: true),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _pickerTile(IconData icon, String label, VoidCallback onTap,
      {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isDestructive
                  ? const Color(0xFFFEE2E2)
                  : AppColors.sand,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDestructive ? const Color(0xFFDC2626) : AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDestructive ? const Color(0xFFDC2626) : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 100);
    final lastDate = DateTime(now.year - 5);
    final initial = _selectedDate ?? DateTime(now.year - 25);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(lastDate) ? initial : lastDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  String get _formattedDob {
    if (_selectedDate == null) return 'Select Date of Birth';
    final d = _selectedDate!;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String get _rawDobString {
    if (_selectedDate == null) return '';
    final d = _selectedDate!;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  void _handleNext() {
    final nickname = _nicknameCtrl.text.trim();
    widget.onNext(_photoPath, nickname, _rawDobString);
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
                        const SizedBox(height: 24),

                        // Step badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.sand,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Step 2 of 5',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'Your Profile',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontHeading,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Set your photo and nickname so your travel companions recognize you on every trip.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Interactive Profile Photo ───────────────────────
                        Center(
                          child: GestureDetector(
                            onTap: _showPhotoOptions,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 124,
                                  height: 124,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(
                                      color: AppColors.primaryLight.withValues(alpha: 0.5),
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.06),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: _buildAvatarImage(),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: _showPhotoOptions,
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: AppColors.primary,
                            ),
                            child: const Text(
                              'Change Photo',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Nickname Input ──────────────────────────────────
                        const Text(
                          'Nickname / Preferred Name',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nicknameCtrl,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'e.g. Spence, Alex',
                            hintStyle: TextStyle(
                              color: AppColors.warmMuted.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.badge_outlined,
                              size: 20,
                              color: AppColors.warmMuted,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.cardBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.cardBorder,
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.6,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // ── Birthday Picker ─────────────────────────────────
                        const Text(
                          'Date of Birth (Optional)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _selectedDate != null
                                    ? AppColors.primary
                                    : AppColors.cardBorder,
                                width: _selectedDate != null ? 1.6 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.cake_outlined,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _formattedDob,
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
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 18,
                                  color: AppColors.warmMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),

                // ── Bottom Action Buttons ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _handleNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
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
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: TextButton(
                          onPressed: widget.onSkip,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                          ),
                          child: const Text(
                            'Skip for now',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
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

  Widget _buildAvatarImage() {
    if (_photoPath != null && _photoPath!.isNotEmpty) {
      if (_photoPath!.startsWith('http://') || _photoPath!.startsWith('https://')) {
        return Image.network(
          _photoPath!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackLetterAvatar(),
        );
      }
      return Image.file(
        File(_photoPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackLetterAvatar(),
      );
    }
    return _fallbackLetterAvatar();
  }

  Widget _fallbackLetterAvatar() {
    final name = widget.userName.trim().isNotEmpty
        ? widget.userName.trim()
        : _nicknameCtrl.text.trim();
    final letter = name.isNotEmpty ? name[0].toUpperCase() : 'T';

    return Container(
      color: AppColors.sand,
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontHeading,
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
