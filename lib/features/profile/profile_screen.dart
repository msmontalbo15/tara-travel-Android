import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/widgets/ph_location_picker.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _healthCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

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
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: '+63 9XX XXX XXXX',
            hintStyle: TextStyle(fontFamily: 'DM Sans'),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(profileProvider.notifier)
                  .updateContactNumber(ctrl.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
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
