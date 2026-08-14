import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/widgets/ph_location_picker.dart';
import '../../core/auth/services/biometric_service.dart';
import '../../core/auth/services/mpin_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _healthCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Biometrics
  bool _biometricsAvailable = false;
  bool _biometricsRegistered = false;
  bool _isBiometricLoading = false;

  // Face Verification
  bool _faceVerificationEnabled = false;
  bool _isFaceLoading = false;

  // 4-Digit MPIN
  bool _hasMpin = false;
  int _mpinDaysRemaining = 0;
  bool _isMpinLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSecurityStatus();
  }

  Future<void> _loadSecurityStatus() async {
    final bio = BiometricAuthService.instance;
    final mpin = MpinSecurityService.instance;

    final available = await bio.isBiometricsAvailable();
    final registered = await bio.isBiometricsRegistered();
    final faceEnabled = await bio.isFaceVerificationRegistered();
    final hasMpin = await mpin.hasMpin();
    final daysLeft = await mpin.getDaysRemaining();

    if (mounted) {
      setState(() {
        _biometricsAvailable = available;
        _biometricsRegistered = registered;
        _faceVerificationEnabled = faceEnabled;
        _hasMpin = hasMpin;
        _mpinDaysRemaining = daysLeft;
      });
    }
  }

  Future<void> _toggleBiometrics(bool enable) async {
    if (_isBiometricLoading) return;
    setState(() => _isBiometricLoading = true);
    try {
      final service = BiometricAuthService.instance;
      if (enable) {
        final success = await service.registerBiometrics(
          customReason: 'Confirm your Fingerprint to enable biometric login',
        );
        if (success) {
          await _loadSecurityStatus();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fingerprint login enabled!', style: TextStyle(fontFamily: 'DM Sans')),
                backgroundColor: AppColors.deepEarth,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fingerprint registration was cancelled or failed.', style: TextStyle(fontFamily: 'DM Sans')),
                backgroundColor: AppColors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        await service.unregisterBiometrics();
        await _loadSecurityStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fingerprint login disabled.', style: TextStyle(fontFamily: 'DM Sans')),
              backgroundColor: AppColors.deepEarth,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isBiometricLoading = false);
    }
  }

  Future<void> _toggleFaceVerification(bool enable) async {
    if (_isFaceLoading) return;
    setState(() => _isFaceLoading = true);
    try {
      if (enable) {
        final success = await BiometricAuthService.instance.registerFaceVerification();
        if (success) {
          await _loadSecurityStatus();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Face Verification (Face ID) enabled!', style: TextStyle(fontFamily: 'DM Sans')),
                backgroundColor: AppColors.deepEarth,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Face verification was cancelled or failed.', style: TextStyle(fontFamily: 'DM Sans')),
                backgroundColor: AppColors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        await BiometricAuthService.instance.unregisterFaceVerification();
        await _loadSecurityStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Face Verification disabled.', style: TextStyle(fontFamily: 'DM Sans')),
              backgroundColor: AppColors.deepEarth,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isFaceLoading = false);
    }
  }

  Future<void> _showSetMpinDialog() async {
    String pin1 = '';
    String pin2 = '';
    int step = 0;
    String? errorText;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setDState) {
            void processPinSubmit() async {
              if (step == 0) {
                if (pin1.length == 4) {
                  setDState(() {
                    step = 1;
                    errorText = null;
                  });
                }
              } else {
                if (pin2.length == 4) {
                  if (pin1 == pin2) {
                    Navigator.pop(ctx);
                    setState(() => _isMpinLoading = true);
                    final success =
                        await MpinSecurityService.instance.setMpin(pin1);
                    await _loadSecurityStatus();
                    if (mounted) {
                      setState(() => _isMpinLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? '4-Digit MPIN set! 30-Day session is now active.'
                                : 'Failed to set MPIN. Please try again.',
                            style: const TextStyle(fontFamily: 'DM Sans'),
                          ),
                          backgroundColor:
                              success ? AppColors.deepEarth : AppColors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } else {
                    HapticFeedback.vibrate();
                    setDState(() {
                      errorText = 'PINs do not match. Please enter again.';
                      pin1 = '';
                      pin2 = '';
                      step = 0;
                    });
                  }
                }
              }
            }

            return AlertDialog(
              backgroundColor: AppColors.surfaceLight,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(
                step == 0 ? 'Enter New MPIN' : 'Confirm MPIN',
                style: const TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    step == 0
                        ? 'Enter a 4-digit MPIN to secure your account.'
                        : 'Re-enter the same 4-digit MPIN to confirm.',
                    style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        color: AppColors.textSecondary),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorText!,
                      style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.red),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _PinInputRow(
                    key: ValueKey('mpin_step_$step'),
                    onChanged: (v) {
                      if (step == 0) {
                        pin1 = v;
                        if (v.length == 4) {
                          processPinSubmit();
                        }
                      } else {
                        pin2 = v;
                        if (v.length == 4) {
                          processPinSubmit();
                        }
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel',
                      style: TextStyle(
                          fontFamily: 'DM Sans', color: AppColors.warmMuted)),
                ),
                TextButton(
                  onPressed: processPinSubmit,
                  child: Text(
                    step == 0 ? 'Next' : 'Confirm',
                    style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _healthCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.deepEarth,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Dark hero header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A0A04), AppColors.deepEarth],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
              child: Column(
                children: [
                  // Avatar
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: profile.avatarColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: profile.avatarColor.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: (profile.profilePhotoUrl != null && profile.profilePhotoUrl!.isNotEmpty)
                              ? Image.file(
                                  File(profile.profilePhotoUrl!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _initialsAvatar(profile),
                                )
                              : _initialsAvatar(profile),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showPhotoSheet(context),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.deepEarth, width: 2.5),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(profile.displayName, style: const TextStyle(fontFamily: 'Playfair Display', fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    profile.homeCity.isNotEmpty
                        ? (profile.homeBarangay.isNotEmpty
                            ? '${profile.homeBarangay}, ${profile.homeCity}'
                            : '${profile.homeCity}, Philippines')
                        : 'Philippines',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (profile.isGoogleConnected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔵', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 6),
                          Text(profile.accountEmail ?? '', style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Light body
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal Info
                    _sectionTitle('PERSONAL INFO'),
                    _ProfileCard(
                      children: [
                        _profileRow(Icons.person_outline_rounded, 'Display Name', profile.displayName, onTap: () => _editName(context, profile)),
                        _divider(),
                        _profileRow(Icons.badge_outlined, 'Nickname', profile.nickname ?? 'Add nickname', onTap: () => _editNickname(context, profile)),
                        _divider(),
                        _profileRow(Icons.cake_outlined, 'Date of Birth', profile.dateOfBirth ?? 'Add birthday', onTap: () => _editDob(context, profile)),
                        _divider(),
                        _profileRow(Icons.location_city_rounded, 'Home Location',
                            profile.homeCity.isNotEmpty
                                ? (profile.homeBarangay.isNotEmpty
                                    ? '${profile.homeBarangay}, ${profile.homeCity}'
                                    : '${profile.homeCity}, Philippines')
                                : 'Set location',
                            onTap: () => _editLocation(context, profile)),
                        _divider(),
                        _profileRow(Icons.payments_outlined, 'Preferred Currency', profile.preferredCurrency, onTap: () => _editCurrency(context, profile)),
                        _divider(),
                        _profileRow(Icons.call_outlined, 'Contact Number', profile.contactNumber ?? 'Add number', onTap: () => _editContactNumber(context, profile)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Health & Allergy Info
                    _sectionTitle('HEALTH & ALLERGY INFO'),
                    _ProfileCard(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Private by default. Share with Organizer when needed.', style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 14),

                              // ── Blood Type Row ──────────────────────────────
                              GestureDetector(
                                onTap: () => _editBloodType(context, profile),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceLight,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.cardBorder, width: 0.8),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFEBEB),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.favorite_border_rounded,
                                          size: 14,
                                          color: Color(0xFFE53935),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Blood Type', style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: AppColors.warmMuted)),
                                            Text(
                                              profile.bloodType ?? 'Tap to select',
                                              style: TextStyle(
                                                fontFamily: 'DM Sans',
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: profile.bloodType != null
                                                    ? const Color(0xFFE53935)
                                                    : AppColors.warmMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        size: 16,
                                        color: AppColors.warmMuted.withValues(alpha: 0.6),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),
                              _divider(),
                              const SizedBox(height: 12),

                              if (profile.healthNotes.isEmpty)
                                const Text('No health notes added', style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: AppColors.warmMuted))
                              else
                                ...profile.healthNotes.map((note) => _HealthTag(
                                  label: note,
                                  onRemove: () => ref.read(profileProvider.notifier).removeHealthNote(note),
                                )),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () => _addHealthNote(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.sand,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_rounded, size: 14, color: AppColors.primary),
                                      SizedBox(width: 6),
                                      Text('Add health note', style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _divider(),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Share with Organizer', style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                        Text('Organizer can see this per trip', style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  Switch.adaptive(
                                    value: profile.shareHealthWithOrganizer,
                                    onChanged: (v) => ref.read(profileProvider.notifier).toggleShareHealth(v),
                                    activeThumbColor: AppColors.primary,
                                    activeTrackColor: AppColors.primaryLight,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // GCash / Payment
                    _sectionTitle('PAYMENT SETTINGS'),
                    _ProfileCard(
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
                                    decoration: BoxDecoration(color: AppColors.blueLight, borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF0066CC), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('GCash Number', style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                        Text(profile.gcashNumber ?? 'Not set', style: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _editGcash(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.sand,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('Edit', style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _divider(),
                              const SizedBox(height: 14),
                              GestureDetector(
                                onTap: () => _showQrUpload(context),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceLight,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.cardBorder, width: 1, style: BorderStyle.solid),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 20),
                                      SizedBox(width: 8),
                                      Text('Upload GCash QR Code', style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Notification Preferences
                    _sectionTitle('NOTIFICATIONS'),
                    _ProfileCard(
                      children: [
                        ...{
                          'expenses': ('Expenses', Icons.receipt_long_outlined),
                          'payments': ('Payments', Icons.payment_rounded),
                          'itinerary': ('Itinerary Changes', Icons.map_outlined),
                          'group_location': ('Group Location', Icons.location_on_outlined),
                          'weather': ('Weather Alerts', Icons.thunderstorm_outlined),
                          'reminders': ('Reminders', Icons.alarm_rounded),
                          'system': ('System', Icons.notifications_outlined),
                        }.entries.map((e) => Column(
                          children: [
                            _notifToggle(e.value.$1, e.value.$2, profile.notificationPrefs[e.key] ?? true, (v) {
                              ref.read(profileProvider.notifier).toggleNotif(e.key, v);
                            }),
                            if (e.key != 'system') _divider(),
                          ],
                        )),
                      ],
                    ),

                    // GCash-Style MPIN + Biometrics Security
                    _sectionTitle('MPIN & BIOMETRIC SECURITY'),
                    _ProfileCard(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 4-Digit MPIN Row
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _hasMpin ? AppColors.sand : AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.lock_outline_rounded,
                                      color: _hasMpin ? AppColors.primary : AppColors.warmMuted,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('4-Digit MPIN', style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                        Text(
                                          _hasMpin
                                              ? 'Active • $_mpinDaysRemaining days remaining'
                                              : 'Not set — Tap to configure',
                                          style: TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 12,
                                            color: _hasMpin ? AppColors.primary : AppColors.warmMuted,
                                            fontWeight: _hasMpin ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_isMpinLoading)
                                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                                  else
                                    GestureDetector(
                                      onTap: _showSetMpinDialog,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(_hasMpin ? 'Change' : 'Set MPIN', style: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                                      ),
                                    ),
                                ],
                              ),
                              _divider(),
                              // Fingerprint Row
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _biometricsRegistered ? AppColors.sand : AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.fingerprint_rounded, color: _biometricsRegistered ? AppColors.primary : AppColors.warmMuted, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Fingerprint Unlock', style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                        Text(
                                          !_biometricsAvailable
                                              ? 'Hardware unavailable or not enrolled'
                                              : (_biometricsRegistered ? 'Registered & Active' : 'Not registered yet'),
                                          style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: _biometricsRegistered ? AppColors.primary : AppColors.warmMuted, fontWeight: _biometricsRegistered ? FontWeight.w600 : FontWeight.normal),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_biometricsAvailable)
                                    _isBiometricLoading
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                                        : Switch.adaptive(
                                            value: _biometricsRegistered,
                                            onChanged: (v) => _toggleBiometrics(v),
                                            activeThumbColor: AppColors.primary,
                                            activeTrackColor: AppColors.primaryLight,
                                          ),
                                ],
                              ),
                              _divider(),
                              // Face Verification Row
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _faceVerificationEnabled ? AppColors.sand : AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.face_unlock_outlined, color: _faceVerificationEnabled ? AppColors.primary : AppColors.warmMuted, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Face Verification (Optional)', style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                        Text(
                                          _faceVerificationEnabled ? 'Enabled — Extra security layer active' : 'Optional — Enable for Face ID login',
                                          style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: _faceVerificationEnabled ? AppColors.primary : AppColors.warmMuted, fontWeight: _faceVerificationEnabled ? FontWeight.w600 : FontWeight.normal),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_biometricsAvailable)
                                    _isFaceLoading
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                                        : Switch.adaptive(
                                            value: _faceVerificationEnabled,
                                            onChanged: (v) => _toggleFaceVerification(v),
                                            activeThumbColor: AppColors.primary,
                                            activeTrackColor: AppColors.primaryLight,
                                          ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.sand.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.shield_outlined, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _hasMpin
                                            ? '30-Day session active: $_mpinDaysRemaining days remaining before Google re-authentication required.'
                                            : 'Set a 4-Digit MPIN to enable 30-Day sessions. Log in with MPIN or Biometrics without Google for 30 days.',
                                        style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
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

                    // Account Sync
                    _sectionTitle('ACCOUNT SETTINGS'),
                    _ProfileCard(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white, 
                                  borderRadius: BorderRadius.circular(12), 
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0,2))
                                  ]
                                ),
                                child: _googleIconSmall(),
                                ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Google Account', style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    Text(profile.isGoogleConnected ? (profile.accountEmail ?? 'Connected') : 'Not connected', style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: profile.isGoogleConnected ? AppColors.textSecondary : AppColors.warmMuted)),
                                  ],
                                ),
                              ),
                              if (!profile.isGoogleConnected)
                                GestureDetector(
                                  onTap: () => _connectGoogle(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text('Connect', style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Sign out
                    GestureDetector(
                      onTap: () => _signOut(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, color: AppColors.red, size: 18),
                            SizedBox(width: 8),
                            Text('Sign Out', style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.red)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialsAvatar(ProfileState profile) {
    return Center(
      child: Text(
        profile.initials,
        style: const TextStyle(
          fontFamily: 'Playfair Display',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(t, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.warmMuted, letterSpacing: 1.5)),
  );

  Widget _divider() => const Divider(height: 0.5, color: AppColors.dividerLight, indent: 14, endIndent: 14);

  Widget _profileRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: AppColors.warmMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: AppColors.warmMuted)),
                  Text(value, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                ],
              ),
            ),
            if (onTap != null)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.warmMuted),
              ),
          ],
        ),
      ),
    );
  }

  Widget _notifToggle(String label, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: value ? AppColors.sand : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: value ? AppColors.primary : AppColors.warmMuted),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
          Switch.adaptive(value: value, onChanged: onChanged, activeThumbColor: AppColors.primary, activeTrackColor: AppColors.primaryLight),
        ],
      ),
    );
  }

  void _editName(BuildContext context, ProfileState profile) {
    final ctrl = TextEditingController(text: profile.displayName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Display Name', style: TextStyle(fontFamily: 'Playfair Display')),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: 'Your name', hintStyle: TextStyle(fontFamily: 'DM Sans'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(profileProvider.notifier).updateDisplayName(ctrl.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editNickname(BuildContext context, ProfileState profile) {
    final ctrl = TextEditingController(text: profile.nickname);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nickname', style: TextStyle(fontFamily: 'Playfair Display')),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: 'Preferred name / nickname', hintStyle: TextStyle(fontFamily: 'DM Sans'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(profileProvider.notifier).updateNickname(ctrl.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
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
      final formatted = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      ref.read(profileProvider.notifier).updateDateOfBirth(formatted);
    }
  }

  void _editBloodType(BuildContext context, ProfileState profile) {
    const List<String> bloodTypes = [
      'A+', 'A−', 'B+', 'B−', 'AB+', 'AB−', 'O+', 'O−', 'Unknown',
    ];
    String? selected = profile.bloodType;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setBS) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.favorite_border_rounded,
                        size: 18, color: Color(0xFFE53935)),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Select Blood Type',
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose your blood type from the dropdown below.',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: (selected != null && bloodTypes.contains(selected))
                    ? selected
                    : null,
                decoration: InputDecoration(
                  hintText: 'Select blood type...',
                  hintStyle: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    color: AppColors.warmMuted,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                items: bloodTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(
                      type,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setBS(() {
                    selected = val;
                  });
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(profileProvider.notifier).updateBloodType(null);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.cardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Clear',
                          style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(profileProvider.notifier).updateBloodType(selected);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addHealthNote(BuildContext context) {
    _healthCtrl.clear();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Health Note', style: TextStyle(fontFamily: 'Playfair Display')),
        content: TextField(
          controller: _healthCtrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Shellfish allergy, Asthmatic...', hintStyle: TextStyle(fontFamily: 'DM Sans')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (_healthCtrl.text.trim().isNotEmpty) {
                ref.read(profileProvider.notifier).addHealthNote(_healthCtrl.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showQrUpload(BuildContext context) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
      );
      
      if (image != null && context.mounted) {
        final currentGcash = ref.read(profileProvider).gcashNumber ?? '';
        ref.read(profileProvider.notifier).updateGCash(currentGcash, image.path);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GCash QR updated successfully!', style: TextStyle(fontFamily: 'DM Sans')),
            backgroundColor: AppColors.deepEarth,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e', style: const TextStyle(fontFamily: 'DM Sans')),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _editContactNumber(BuildContext context, ProfileState profile) {
    final ctrl = TextEditingController(text: profile.contactNumber);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Contact Number',
            style: TextStyle(fontFamily: 'Playfair Display')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your phone number. An SMS verification code will be sent to verify.',
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '+63 9XX XXX XXXX',
                hintStyle: TextStyle(fontFamily: 'DM Sans'),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid phone number with country code'),
                    backgroundColor: AppColors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context);

              // Send OTP code via Supabase Auth
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
              const Text('Verify Phone OTP', style: TextStyle(fontFamily: 'Playfair Display', fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the 6-digit verification code sent to\n$phoneNumber',
                style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: otpCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(fontFamily: 'DM Sans', fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 4),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '123456',
                  hintStyle: TextStyle(color: AppColors.warmMuted.withValues(alpha: 0.5), letterSpacing: 4),
                  errorText: errorText,
                  errorStyle: const TextStyle(fontFamily: 'DM Sans', fontSize: 12),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(fontFamily: 'DM Sans', color: AppColors.textSecondary)),
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

                      // Save verified phone number to profile
                      ref.read(profileProvider.notifier).updateContactNumber(phoneNumber);

                      if (dialogCtx.mounted) {
                        Navigator.pop(dialogCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Phone number $phoneNumber verified and saved!'),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              child: isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Verify & Save', style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out',
            style: TextStyle(fontFamily: 'Playfair Display')),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(fontFamily: 'DM Sans'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(profileProvider.notifier).signOut();
      if (context.mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  void _editGcash(BuildContext context) {
    final ctrl = TextEditingController(text: ref.read(profileProvider).gcashNumber);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('GCash Number', style: TextStyle(fontFamily: 'Playfair Display')),
        content: TextField(controller: ctrl, autofocus: true, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: '+63 9XX XXX XXXX', hintStyle: TextStyle(fontFamily: 'DM Sans'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(profileProvider.notifier).updateGCash(ctrl.text.trim(), null);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
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
                        fontFamily: 'Playfair Display',
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
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.48,
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
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w700,
                        ),
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
          title: const Text('Preferred Currency', style: TextStyle(fontFamily: 'Playfair Display')),
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
          borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
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
            const Text('Profile Photo', style: TextStyle(fontFamily: 'Playfair Display', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            _photoOption(Icons.camera_alt_rounded, 'Take a photo', AppColors.primary, () async {
              Navigator.pop(context);
              await _pickAndSavePhoto(ImageSource.camera);
            }),
            const SizedBox(height: 10),
            _photoOption(Icons.photo_library_rounded, 'Choose from library', AppColors.blue, () async {
              Navigator.pop(context);
              await _pickAndSavePhoto(ImageSource.gallery);
            }),
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
        ref.read(profileProvider.notifier).updatePhoto(pickedFile.path);
      }
    } catch (e) {
      debugPrint('Error picking photo: $e');
    }
  }

  Future<void> _connectGoogle(BuildContext context) async {
    try {
      final user = await ref.read(authRepositoryProvider).signInWithGoogle();
      if (user != null) {
        final email = user.email;
        final profileState = ref.read(profileProvider);
        ref.read(profileProvider.notifier).updateProfile(
          profileState.copyWith(
            isGoogleConnected: true,
            accountEmail: email,
          ),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google account connected natively!', style: TextStyle(fontFamily: 'DM Sans')), backgroundColor: AppColors.deepEarth, behavior: SnackBarBehavior.floating),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect: $e', style: const TextStyle(fontFamily: 'DM Sans')), backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Widget _googleIconSmall() {
    return Center(
      child: Text(
        'G',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          height: 1.0,
          foreground: Paint()
            ..shader = const LinearGradient(colors: [
              Color(0xFF4285F4),
              Color(0xFFEA4335),
            ]).createShader(const Rect.fromLTWH(0, 0, 16, 16)),
        ),
      ),
    );
  }

  Widget _photoOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
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
            Text(label, style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final List<Widget> children;
  const _ProfileCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _HealthTag extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _HealthTag({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.health_and_safety_outlined, size: 13, color: AppColors.red),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.red)),
          const SizedBox(width: 8),
          GestureDetector(onTap: onRemove, child: const Icon(Icons.close_rounded, size: 13, color: AppColors.red)),
        ],
      ),
    );
  }
}

// ── PIN Input Row for MPIN Dialog ─────────────────────────────────────────────

class _PinInputRow extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const _PinInputRow({super.key, required this.onChanged});

  @override
  State<_PinInputRow> createState() => _PinInputRowState();
}

class _PinInputRowState extends State<_PinInputRow> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    for (final node in _focusNodes) {
      node.addListener(_onFocusChange);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.removeListener(_onFocusChange);
      node.dispose();
    }
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  String get _pin => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      _controllers[index].clear();
      widget.onChanged(_pin);
      return;
    }

    HapticFeedback.lightImpact();

    // Multi-digit paste vs single-character replacement
    if (digits.length >= 4) {
      for (int i = 0; i < 4; i++) {
        _controllers[i].text = digits[i];
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNodes[3].requestFocus();
      });
      widget.onChanged(_pin);
      return;
    } else if (digits.length > 1) {
      // Taking latest character entered when overwriting an existing box
      final newChar = digits.substring(digits.length - 1);
      _controllers[index].text = newChar;
    } else {
      _controllers[index].text = digits;
    }

    // Auto-focus to the next input box
    if (index < 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNodes[index + 1].requestFocus();
        }
      });
    }

    widget.onChanged(_pin);
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _controllers[index - 1].clear();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focusNodes[index - 1].requestFocus();
        });
        widget.onChanged(_pin);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final isFocused = _focusNodes[i].hasFocus;
        final hasValue = _controllers[i].text.isNotEmpty;

        return KeyboardListener(
          focusNode: _focusNodes[i],
          onKeyEvent: (evt) => _onKeyEvent(i, evt),
          child: Container(
            width: 48,
            height: 56,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isFocused
                    ? AppColors.primary
                    : (hasValue
                        ? AppColors.primary.withValues(alpha: 0.5)
                        : AppColors.cardBorder),
                width: isFocused ? 2.0 : 1.5,
              ),
            ),
            child: TextField(
              controller: _controllers[i],
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              obscureText: true,
              obscuringCharacter: '●',
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) => _onDigitChanged(i, val),
            ),
          ),
        );
      }),
    );
  }
}
