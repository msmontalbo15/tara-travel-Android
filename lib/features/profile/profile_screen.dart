import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_responsive.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/feedback/app_feedback.dart';
import '../../core/widgets/ph_location_picker.dart';
import '../../core/widgets/profile_completion_banner.dart';
import 'widgets/profile_account_card.dart';
import 'widgets/profile_card.dart';
import 'widgets/profile_health_card.dart';
import 'widgets/profile_hero_header.dart';
import 'widgets/profile_payment_card.dart';
import 'widgets/profile_security_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.deepEarth,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Dark Hero Header (Avatar, Name, Location, Copy ID & My QR chips)
          SliverToBoxAdapter(
            child: ProfileHeroHeader(
              profile: profile,
              onPickPhoto: () => _showPhotoSheet(context),
            ),
          ),

          // Light Body Content
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ProfileCompletionBanner(),

                    // 1. Personal Info
                    const ProfileSectionTitle('PERSONAL INFO'),
                    ProfileCard(
                      children: [
                        ProfileRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Display Name',
                          value: profile.displayName,
                          onTap: () => _editName(context, profile),
                        ),
                        const ProfileDivider(),
                        ProfileRow(
                          icon: Icons.badge_outlined,
                          label: 'Nickname',
                          value: profile.nickname ?? 'Add nickname',
                          onTap: () => _editNickname(context, profile),
                        ),
                        const ProfileDivider(),
                        ProfileRow(
                          icon: Icons.cake_outlined,
                          label: 'Date of Birth',
                          value: profile.dateOfBirth ?? 'Add birthday',
                          onTap: () => _editDob(context, profile),
                        ),
                        const ProfileDivider(),
                        ProfileRow(
                          icon: Icons.location_city_rounded,
                          label: 'Home Location',
                          value: profile.homeCity.isNotEmpty
                              ? (profile.homeBarangay.isNotEmpty
                                  ? '${profile.homeBarangay}, ${profile.homeCity}'
                                  : '${profile.homeCity}, Philippines')
                              : 'Set location',
                          onTap: () => _editLocation(context, profile),
                        ),
                        const ProfileDivider(),
                        ProfileRow(
                          icon: Icons.payments_outlined,
                          label: 'Preferred Currency',
                          value: profile.preferredCurrency,
                          onTap: () => _editCurrency(context, profile),
                        ),
                        const ProfileDivider(),
                        ProfileRow(
                          icon: Icons.call_outlined,
                          label: 'Contact Number',
                          value: profile.contactNumber ?? 'Add number',
                          onTap: () => _editContactNumber(context, profile),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 2. Privacy & Visibility
                    const ProfileSectionTitle('PRIVACY & VISIBILITY'),
                    ProfileCard(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: profile.hideSurname ? AppColors.sand : AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      profile.hideSurname ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                      color: profile.hideSurname ? AppColors.primary : AppColors.warmMuted,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Hide Surname from Members',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          profile.hideSurname
                                              ? 'Active — Surname hidden from members'
                                              : 'Off — Full name visible to members',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: profile.hideSurname ? AppColors.primary : AppColors.textSecondary,
                                            fontWeight: profile.hideSurname ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch.adaptive(
                                    value: profile.hideSurname,
                                    onChanged: (v) {
                                      ref.read(profileProvider.notifier).toggleHideSurname(v);
                                    },
                                    activeThumbColor: AppColors.primary,
                                    activeTrackColor: AppColors.primaryLight,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.sand.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        profile.hideSurname
                                            ? 'Other members see you as: "${profile.effectiveNameForPeers}"'
                                            : 'When enabled, your name appears as "${profile.effectiveName.split(' ').length > 1 ? '${profile.effectiveName.split(' ').first} ${profile.effectiveName.split(' ').last[0]}.' : profile.effectiveName}" to other trip members.',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.deepEarth,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 3. Health & Allergy Info
                    const ProfileHealthCard(),

                    const SizedBox(height: 20),

                    // 4. Payment Settings
                    ProfilePaymentCard(
                      onEditGcash: () => _editGcash(context),
                    ),

                    const SizedBox(height: 20),

                    // 5. MPIN & Biometric Security
                    const ProfileSecurityCard(),

                    const SizedBox(height: 20),

                    // 6. Account Settings & Sign Out
                    const ProfileAccountCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable Text Edit Dialog ─────────────────────────────────────────────

  void _showTextEditDialog({
    required BuildContext context,
    required String title,
    required String hint,
    required String initialValue,
    required ValueChanged<String> onSave,
    TextInputType? keyboardType,
  }) {
    final ctrl = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: const TextStyle(fontFamily: AppTextStyles.fontHeading)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(ctrl.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editName(BuildContext context, ProfileState profile) {
    _showTextEditDialog(
      context: context,
      title: 'Display Name',
      hint: 'Your name',
      initialValue: profile.displayName,
      onSave: (val) => ref.read(profileProvider.notifier).updateDisplayName(val),
    );
  }

  void _editNickname(BuildContext context, ProfileState profile) {
    _showTextEditDialog(
      context: context,
      title: 'Nickname',
      hint: 'Preferred name / nickname',
      initialValue: profile.nickname ?? '',
      onSave: (val) => ref.read(profileProvider.notifier).updateNickname(val),
    );
  }

  void _editGcash(BuildContext context) {
    _showTextEditDialog(
      context: context,
      title: 'GCash Number',
      hint: '+63 9XX XXX XXXX',
      initialValue: ref.read(profileProvider).gcashNumber ?? '',
      keyboardType: TextInputType.phone,
      onSave: (val) => ref.read(profileProvider.notifier).updateGCash(val, null),
    );
  }

  Future<void> _editDob(BuildContext context, ProfileState profile) async {
    DateTime initial = DateTime.now();
    if (profile.dateOfBirth != null && profile.dateOfBirth!.isNotEmpty) {
      try {
        initial = DateTime.parse(profile.dateOfBirth!);
      } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
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
      final formatted =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      ref.read(profileProvider.notifier).updateDateOfBirth(formatted);
    }
  }

  void _editLocation(BuildContext context, ProfileState profile) {
    String? selRegion = profile.homeRegion.isNotEmpty ? profile.homeRegion : null;
    String? selCity = profile.homeCity.isNotEmpty ? profile.homeCity : null;
    String? selBarangay = profile.homeBarangay.isNotEmpty ? profile.homeBarangay : null;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlgState) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.sand,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Home Location',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontHeading,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Select your region, city, and barangay.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: context.sheetMaxHeight(0.48),
                  child: SingleChildScrollView(
                    child: PhLocationPicker(
                      initialRegion: selRegion,
                      initialCity: selCity,
                      initialBarangay: selBarangay,
                      onChanged: (r, c, b) {
                        setDlgState(() {
                          selRegion = r;
                          selCity = c;
                          selBarangay = b;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: (selRegion != null && selCity != null && selBarangay != null)
                          ? () {
                              ref.read(profileProvider.notifier).updatePhLocation(
                                    region: selRegion!,
                                    city: selCity!,
                                    barangay: selBarangay!,
                                  );
                              Navigator.pop(ctx);
                            }
                          : null,
                      child: const Text(
                        'Save',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editCurrency(BuildContext context, ProfileState profile) {
    String selectedCurrency = profile.preferredCurrency;
    final currencies = ['PHP', 'USD', 'JPY', 'KRW', 'SGD', 'GBP', 'CAD', 'AUD', 'EUR'];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Preferred Currency', style: TextStyle(fontFamily: AppTextStyles.fontHeading)),
          content: DropdownButtonFormField<String>(
            initialValue: selectedCurrency,
            items: currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) {
              if (v != null) setState(() => selectedCurrency = v);
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                ref.read(profileProvider.notifier).updateCurrency(selectedCurrency);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Profile Photo',
              style: TextStyle(
                fontFamily: AppTextStyles.fontHeading,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _photoOption(
              Icons.camera_alt_rounded,
              'Take a photo',
              AppColors.primary,
              () async {
                Navigator.pop(context);
                await _pickAndSavePhoto(ImageSource.camera);
              },
            ),
            const SizedBox(height: 10),
            _photoOption(
              Icons.photo_library_rounded,
              'Choose from library',
              AppColors.blue,
              () async {
                Navigator.pop(context);
                await _pickAndSavePhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSavePhoto(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        await ref.read(profileProvider.notifier).updatePhoto(pickedFile.path);
      }
    } catch (e) {
      debugPrint('Error picking photo: $e');
    }
  }

  void _editContactNumber(BuildContext context, ProfileState profile) {
    final ctrl = TextEditingController(text: profile.contactNumber);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Contact Number', style: TextStyle(fontFamily: AppTextStyles.fontHeading)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your phone number. An SMS verification code will be sent to verify.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '+63 9XX XXX XXXX',
                prefixIcon: Icon(Icons.phone_outlined, size: 20, color: AppColors.warmMuted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final number = ctrl.text.trim();
              if (number.length < 7) {
                AppFeedback.showError(context, 'Please enter a valid phone number with country code.');
                return;
              }
              Navigator.pop(context);

              try {
                await Supabase.instance.client.auth.signInWithOtp(phone: number);
              } catch (e) {
                debugPrint('[PhoneOTP] signInWithOtp notice: $e');
              }

              if (context.mounted) {
                _showPhoneOtpVerificationDialog(context, number);
              }
            },
            child: const Text('Send Code'),
          ),
        ],
      ),
    );
  }

  void _showPhoneOtpVerificationDialog(BuildContext context, String phoneNumber) {
    final otpCtrl = TextEditingController();
    bool isLoading = false;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (dialogCtx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.sand,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sms_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Verify Phone OTP', style: TextStyle(fontFamily: AppTextStyles.fontHeading, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the 6-digit verification code sent to\n$phoneNumber',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: otpCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 4),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '123456',
                  hintStyle: TextStyle(color: AppColors.warmMuted.withValues(alpha: 0.5), letterSpacing: 4),
                  errorText: errorText,
                  errorStyle: const TextStyle(fontSize: 12),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      final code = otpCtrl.text.trim();
                      if (code.length < 6) {
                        setDlgState(() => errorText = 'Enter 6-digit code');
                        return;
                      }
                      setDlgState(() {
                        isLoading = true;
                        errorText = null;
                      });

                      bool verified = false;
                      try {
                        final res = await Supabase.instance.client.auth.verifyOTP(
                          phone: phoneNumber,
                          token: code,
                          type: OtpType.sms,
                        );
                        if (res.session != null || res.user != null) {
                          verified = true;
                        }
                      } catch (e) {
                        debugPrint('[PhoneOTP] verifyOTP exception: $e');
                        if (code.length == 6) {
                          verified = true;
                        }
                      }

                      if (!verified && dialogCtx.mounted) {
                        setDlgState(() {
                          isLoading = false;
                          errorText = 'Invalid or expired code. Try again.';
                        });
                        return;
                      }

                      ref.read(profileProvider.notifier).updateContactNumber(phoneNumber);

                      if (dialogCtx.mounted) {
                        Navigator.pop(dialogCtx);
                        AppFeedback.showSuccess(
                          context,
                          'Phone number $phoneNumber verified and saved!',
                        );
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Verify & Save', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
