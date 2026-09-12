import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_brand_logo.dart';
import '../../../core/auth/presentation/auth_notifier.dart';
import '../../../core/widgets/npc_privacy_policy_sheet.dart';
import '../../../core/services/app_version_service.dart';

// ── Auth mode constant ────────────────────────────────────────────────────────
const _kModeGoogle = 'google';

class ChooseModeStep extends ConsumerStatefulWidget {
  final void Function(String mode, String? name) onModeSelected;
  final bool autoGoogleSignIn;
  final String initialMode;

  const ChooseModeStep({
    super.key,
    required this.onModeSelected,
    this.autoGoogleSignIn = false,
    this.initialMode = _kModeGoogle,
  });

  @override
  ConsumerState<ChooseModeStep> createState() => _ChooseModeStepState();
}

class _ChooseModeStepState extends ConsumerState<ChooseModeStep>
    with SingleTickerProviderStateMixin {
  bool _autoSignInTriggered = false;

  // Error display
  String? _generalError;

  // Animation
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();

    if (widget.autoGoogleSignIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _autoSignInTriggered) return;
        _autoSignInTriggered = true;
        _handleGoogle();
      });
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Google (PRIMARY HERO ACTION) ────────────────────────────────────────────
  Future<void> _handleGoogle() async {
    setState(() => _generalError = null);

    await ref.read(authNotifierProvider.notifier).signInWithGoogle(
      onConfirmNewAccount: _showCreateAccountConfirmationDialog,
    );
  }

  /// Displays a confirmation dialog when the selected Google account is not yet
  /// registered in Tara Travel. Returns true if the user chooses to create an account.
  Future<bool> _showCreateAccountConfirmationDialog({
    required String email,
    required String? displayName,
    required String? photoUrl,
  }) async {
    if (!mounted) return false;

    bool hasReadTerms = false;
    bool hasAgreed = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            Future<void> openTermsSheet() async {
              final agreed = await showNpcPrivacyPolicySheet(dialogCtx);
              if (agreed) {
                setDialogState(() {
                  hasReadTerms = true;
                  hasAgreed = true;
                });
              }
            }

            final canCreate = hasReadTerms && hasAgreed;

            return Dialog(
              backgroundColor: AppColors.surfaceLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top header icon / badge
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
                            Icon(Icons.person_add_alt_1_rounded,
                                size: 16, color: AppColors.primary),
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

                      // Avatar / Profile preview card
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
                            // Google Avatar
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

                      // Question & Description
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
                        'No account was found for this Google email. Review and accept our terms to create your account and start planning trips.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── MANDATORY TERMS & NPC PRIVACY POLICY SECTION ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: hasReadTerms
                              ? const Color(0xFF10B981).withValues(alpha: 0.07)
                              : AppColors.sand.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: hasReadTerms
                                ? const Color(0xFF10B981).withValues(alpha: 0.35)
                                : AppColors.primaryLight.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  hasReadTerms
                                      ? Icons.verified_user_rounded
                                      : Icons.shield_outlined,
                                  size: 18,
                                  color: hasReadTerms
                                      ? const Color(0xFF10B981)
                                      : AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    hasReadTerms
                                        ? 'Terms & Privacy Policy Reviewed'
                                        : 'Terms & NPC Privacy Policy',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: hasReadTerms
                                          ? const Color(0xFF065F46)
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: hasReadTerms
                                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                        : AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    hasReadTerms ? 'VERIFIED' : 'REQUIRED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                      color: hasReadTerms
                                          ? const Color(0xFF059669)
                                          : AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              hasReadTerms
                                  ? 'You have read and accepted Tara Travel\'s Terms of Service and NPC Privacy Policy (RA 10173).'
                                  : 'Republic Act No. 10173 mandates reviewing our Terms and Data Privacy Policy before creating your account.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Action button / Re-read link
                            if (!hasReadTerms)
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: openTermsSheet,
                                  icon: const Icon(Icons.auto_stories_outlined,
                                      size: 16, color: AppColors.primary),
                                  label: const Text(
                                    'Read Terms & Conditions',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(
                                        color: AppColors.primaryLight, width: 1.2),
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              )
                            else
                              GestureDetector(
                                onTap: openTermsSheet,
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.open_in_new_rounded,
                                        size: 13, color: AppColors.primary),
                                    SizedBox(width: 4),
                                    Text(
                                      'View terms again',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 10),

                            // Mandatory Checkbox Row
                            InkWell(
                              onTap: () {
                                if (!hasReadTerms) {
                                  openTermsSheet();
                                } else {
                                  setDialogState(() => hasAgreed = !hasAgreed);
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: Checkbox(
                                        value: hasReadTerms && hasAgreed,
                                        activeColor: AppColors.primary,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        onChanged: (checked) {
                                          if (!hasReadTerms) {
                                            openTermsSheet();
                                          } else {
                                            setDialogState(
                                                () => hasAgreed = checked ?? false);
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'I have read and agree to the Terms of Service & NPC Privacy Policy.',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          // Cancel Ghost Button
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                side: const BorderSide(
                                    color: AppColors.cardBorder, width: 1.2),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Confirm Create Account Primary Button
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: canCreate
                                  ? () => Navigator.of(ctx).pop(true)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor:
                                    AppColors.primary.withValues(alpha: 0.3),
                                foregroundColor: Colors.white,
                                disabledForegroundColor:
                                    Colors.white.withValues(alpha: 0.6),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Helper text when locked
                      if (!canCreate) ...[
                        const SizedBox(height: 10),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline_rounded,
                                size: 13, color: AppColors.warmMuted),
                            SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Please read and agree to the terms to create your account',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.warmMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider).value;
    final isLoading = authState is AuthLoading;

    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (previous, next) {
      final state = next.value;
      if (state is AuthAuthenticated) {
        TextInput.finishAutofillContext();
        final user = state.user;
        final name = user.userMetadata?['full_name'] as String? ??
            user.userMetadata?['name'] as String?;
        widget.onModeSelected(_kModeGoogle, name);
      } else if (state is AuthError) {
        setState(() => _generalError = state.rawDetails ?? state.message);
      }
    });

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
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const AppBrandLogo(size: 44, showWordmark: true),
                            _stepPill(),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Welcome to\nTara Travel',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontHeading,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Your journey, your way',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontHeading,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: AppColors.darkAccent,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sign in with your Google account to automatically set up your profile and sync your trips.',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 28),

                        // ── 1. PRIMARY GOOGLE ACCOUNT BUTTON (REGISTER & LOGIN) ──
                        _PrimaryGoogleButton(
                          isLoading: isLoading,
                          onTap: _handleGoogle,
                        ),
                        const SizedBox(height: 14),

                        // General Error Box
                        if (_generalError != null) ...[
                          const SizedBox(height: 4),
                          _errorBox(_generalError!),
                        ],

                        const SizedBox(height: 20),
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'Your Google account data is encrypted & secure.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.warmMuted.withValues(alpha: 0.8),
                                ),
                              ),
                                const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.black.withValues(alpha: 0.08)),
                                ),
                                child: const Text(
                                  'Release Version: ${AppVersionService.currentAppVersionString}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.muted,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
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



  Widget _stepPill() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
            color: AppColors.sand, borderRadius: BorderRadius.circular(20)),
        child: const Text('Authentication',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary)),
      );

  Widget _errorBox(String msg) => Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.4), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Color(0xFFEF4444), size: 18),
                const SizedBox(width: 8),
                const Text(
                  'NOTICE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFFEF4444)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Copy error message',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: msg));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notice copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            SelectableText(
              msg,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFB91C1C),
                height: 1.3,
              ),
            ),
          ],
        ),
      );
}

// ── Hero Google Primary Button ─────────────────────────────────────────────────

class _PrimaryGoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _PrimaryGoogleButton({
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF4285F4), Color(0xFF34A853)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4285F4).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Center(
                    child: Text('G',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          foreground: Paint()
                            ..shader = const LinearGradient(
                                    colors: [Color(0xFF4285F4), Color(0xFFEA4335)])
                                .createShader(const Rect.fromLTWH(0, 0, 42, 42)),
                        )),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.star_rounded,
                              color: Color(0xFFFFD700), size: 16),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(
                        '1-tap sign in or automatic registration',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                else
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
