import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/services/app_version_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/feedback/app_dialog.dart';
import '../../../core/widgets/feedback/app_feedback.dart';
import '../../../core/widgets/npc_privacy_policy_sheet.dart';
import '../../../core/widgets/versioning/force_update_screen.dart';
import '../../../core/widgets/versioning/maintenance_mode_screen.dart';
import '../../../core/widgets/versioning/soft_update_sheet.dart';
import '../../../core/widgets/versioning/version_info_sheet.dart';
import '../screens/notification_settings_screen.dart';
import 'profile_card.dart';

class ProfileAccountCard extends ConsumerStatefulWidget {
  const ProfileAccountCard({super.key});

  @override
  ConsumerState<ProfileAccountCard> createState() => _ProfileAccountCardState();
}

class _ProfileAccountCardState extends ConsumerState<ProfileAccountCard> {
  bool _isCheckingUpdate = false;

  Future<void> _handleCheckUpdate(BuildContext context) async {
    if (_isCheckingUpdate) return;
    setState(() => _isCheckingUpdate = true);

    try {
      final service = ref.read(appVersionServiceProvider);
      final result = await service.checkVersionStatus();

      if (!mounted) return;
      setState(() => _isCheckingUpdate = false);

      if (!context.mounted) return;

      if (result.isMaintenance) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MaintenanceModeScreen(checkResult: result),
          ),
        );
      } else if (result.isForceUpdate) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ForceUpdateScreen(checkResult: result),
          ),
        );
      } else if (result.isSoftUpdate) {
        AppFeedback.showSuccess(
          context,
          'New update available (v${result.remoteConfig?.latestVersion.displayVersion})! Tap Update to install.',
          title: 'Update Ready 🚀',
        );
        SoftUpdateSheet.show(context, result);
      } else {
        VersionInfoSheet.show(context, result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingUpdate = false);
        if (context.mounted) {
          AppFeedback.showError(context, 'Unable to check updates right now. Please try again.');
        }
      }
    }
  }

  Future<void> _connectGoogle(BuildContext context) async {
    try {
      final user = await ref.read(authRepositoryProvider).signInWithGoogle(
        onConfirmNewAccount: ({
          required String email,
          required String? displayName,
          required String? photoUrl,
        }) =>
            _showConnectAccountConfirmationDialog(
          context: context,
          email: email,
          displayName: displayName,
          photoUrl: photoUrl,
        ),
      );
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
          AppFeedback.showSuccess(context, 'Google account connected!');
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showError(context, 'Failed to connect: $e');
      }
    }
  }

  Future<bool> _showConnectAccountConfirmationDialog({
    required BuildContext context,
    required String email,
    required String? displayName,
    required String? photoUrl,
  }) async {
    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppColors.surfaceLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add_alt_1_rounded, size: 16, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'New Account Confirmation',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.sand,
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: photoUrl != null && photoUrl.isNotEmpty
                                  ? Image.network(
                                      photoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _fallbackAvatar(displayName ?? email),
                                    )
                                  : _fallbackAvatar(displayName ?? email),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: Color(0xFF34A853),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (displayName != null && displayName.isNotEmpty)
                                  ? displayName
                                  : 'Google User',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Create your Tara Travel account?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontHeading,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No account was found for this Google email. Would you like to create a new profile to start planning and syncing your trips?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => showNpcPrivacyPolicySheet(ctx),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.sand.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primaryLight.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_outlined, size: 15, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                              children: [
                                TextSpan(text: 'By continuing, you accept our '),
                                TextSpan(
                                  text: 'Terms & NPC Privacy Policy',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                TextSpan(text: ' (RA 10173 • National Privacy Commission).'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Create Account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return result ?? false;
  }

  Widget _fallbackAvatar(String nameOrEmail) {
    final initial = nameOrEmail.trim().isNotEmpty
        ? nameOrEmail.trim().substring(0, 1).toUpperCase()
        : 'U';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontHeading,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
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

  Future<void> _signOut(BuildContext context) async {
    AppDialog.showDestructive(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
      confirmLabel: 'Sign Out',
      onConfirm: () async {
        await ref.read(profileProvider.notifier).signOut();
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/onboarding', (route) => false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final versionAsync = ref.watch(appVersionCheckProvider);
    final hasUpdate = versionAsync.value?.hasUpdate ?? false;
    final latestVersion = versionAsync.value?.remoteConfig?.latestVersion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSectionTitle('ACCOUNT SETTINGS'),
        ProfileCard(
          children: [
            // Google Account Row
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
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _googleIconSmall(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Google Account',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          profile.isGoogleConnected
                              ? (profile.accountEmail ?? 'Connected')
                              : 'Not connected',
                          style: TextStyle(
                            fontSize: 12,
                            color: profile.isGoogleConnected
                                ? AppColors.textSecondary
                                : AppColors.warmMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!profile.isGoogleConnected)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _connectGoogle(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Connect',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const ProfileDivider(),
            // Notifications Sub-Screen Row
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.sand,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.notifications_none_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Customize expenses, itinerary & trip alerts',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.warmMuted, size: 20),
                  ],
                ),
              ),
            ),
            const ProfileDivider(),
            // Terms & NPC Privacy Row
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => showNpcPrivacyPolicySheet(context),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.sand,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Terms & NPC Data Privacy',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Republic Act No. 10173 • privacy.gov.ph',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.warmMuted, size: 20),
                  ],
                ),
              ),
            ),
            const ProfileDivider(),
            // App Version & Updates Row
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _handleCheckUpdate(context),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hasUpdate ? AppColors.sand : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        hasUpdate ? Icons.rocket_launch_rounded : Icons.system_update_rounded,
                        color: hasUpdate ? AppColors.primary : AppColors.warmMuted,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'App Version & Updates',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (hasUpdate) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'UPDATE',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasUpdate
                                ? 'v${latestVersion?.displayVersion ?? 'New'} available • Tap to update'
                                : 'v${AppVersionService.currentAppDisplayVersion} • Tap to view details',
                            style: TextStyle(
                              fontSize: 12,
                              color: hasUpdate ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: hasUpdate ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isCheckingUpdate)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    else
                      const Icon(Icons.chevron_right_rounded, color: AppColors.warmMuted, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Sign Out Button
        GestureDetector(
          behavior: HitTestBehavior.opaque,
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
                Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
