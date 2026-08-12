import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../core/theme/app_colors.dart';
import '../../../core/auth/presentation/auth_notifier.dart';
import '../../../core/auth/services/biometric_service.dart';
import '../../../core/auth/services/mpin_service.dart';
import '../../../core/services/database_service.dart';
import '../../../core/providers/profile_provider.dart';
import 'gcash_mpin_view.dart';

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
  // ── State ──────────────────────────────────────────────────────────────────
  bool _autoSignInTriggered = false;

  // MPIN / Biometric quick login
  bool _showMpinView = false;

  // Biometrics — null means not yet determined or unavailable
  bool _biometricsAvailable = false;
  bool _biometricsRegistered = false;
  BiometricType? _biometricType; // strongest enrolled type

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

    _checkBiometrics();
    _checkMpinSession();
  }

  Future<void> _checkMpinSession() async {
    final hasMpin = await MpinSecurityService.instance.hasMpin();
    final sessionValid = await MpinSecurityService.instance.isSessionValid();

    if (!mounted) return;

    if (hasMpin && sessionValid) {
      setState(() => _showMpinView = true);
    } else {
      // Only auto sign-in after MPIN check is complete
      if (widget.autoGoogleSignIn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _autoSignInTriggered) return;
          _autoSignInTriggered = true;
          _handleGoogle();
        });
      }
    }
  }

  Future<void> _checkBiometrics() async {
    final service = BiometricAuthService.instance;
    final available = await service.isBiometricsAvailable();
    final registered = await service.isBiometricsRegistered();
    final strongestType = await service.getStrongestAvailableType();
    if (mounted) {
      setState(() {
        _biometricsAvailable = available && strongestType != null;
        _biometricsRegistered = registered;
        _biometricType = strongestType;
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
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();
  }

  // ── Biometric Login Handler (Face ID / Fingerprint) ────────────────────────
  Future<void> _handleBiometrics() async {
    final type = _biometricType;
    final title = type == BiometricType.face ? 'Face ID' : 'Fingerprint';

    // 1. Verify registration status
    final isRegistered = await BiometricAuthService.instance.isBiometricsRegistered();
    if (!isRegistered) {
      setState(() {
        _generalError =
            '$title is not registered yet. Please sign in with Google first, then register $title in Profile Settings.';
      });
      return;
    }

    // 2. Prompt biometric scanner
    final authenticated = await BiometricAuthService.instance.authenticate(
      reason: 'Scan your $title to unlock Tara Travel',
    );
    if (!mounted) return;
    if (!authenticated) return;

    // 3. Hydrate session if user is not already logged in
    User? user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      await ref.read(authNotifierProvider.notifier).restoreSession();
      if (!mounted) return;
      final result = ref.read(authNotifierProvider).value;
      if (result is AuthAuthenticated) {
        user = result.user;
      }
    }

    if (user != null) {
      await DatabaseService.instance.switchUser(user.id);
      await ref.read(profileProvider.notifier).refreshProfile();
      if (!mounted) return;

      // Biometric unlock authenticated successfully -> navigate straight to home
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      setState(() {
        _generalError =
            'Session expired or missing. Please sign in with Google first to reactivate $title login.';
      });
    }
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
        setState(() => _generalError = state.message);
      }
    });

    // Show GCash MPIN quick-login screen if MPIN is set and 30-day session is valid
    if (_showMpinView) {
      final profile = ref.watch(profileProvider);
      return GCashMpinView(
        userNickname: profile.displayNameForHome,
        onSwitchToGoogle: () {
          setState(() => _showMpinView = false);
        },
      );
    }

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
                        _stepPill(),
                        const SizedBox(height: 14),
                        const Text(
                          'Welcome to\nTara Travel',
                          style: TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Sign in with your Google account to automatically set up your profile and sync your trips.',
                          style: TextStyle(
                              fontFamily: 'DM Sans',
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

                        // ── 2. BIOMETRIC QUICK UNLOCK ──
                        if (_biometricsAvailable && _biometricType != null) ...[
                          _BiometricQuickTile(
                            biometricType: _biometricType!,
                            isRegistered: _biometricsRegistered,
                            onTap: _handleBiometrics,
                          ),
                          const SizedBox(height: 14),
                        ],

                        // General Error Box
                        if (_generalError != null) ...[
                          const SizedBox(height: 4),
                          _errorBox(_generalError!),
                        ],

                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            'Your Google account data is encrypted & secure.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11,
                              color: AppColors.warmMuted.withValues(alpha: 0.7),
                            ),
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
                fontFamily: 'DM Sans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary)),
      );

  Widget _errorBox(String msg) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFEF4444), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg,
                  style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      color: Color(0xFFEF4444))),
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
                              fontFamily: 'DM Sans',
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
                          fontFamily: 'DM Sans',
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

// ── Biometric Quick Tile ─────────────────────────────────────────────────────

class _BiometricQuickTile extends StatelessWidget {
  final BiometricType biometricType;
  final bool isRegistered;
  final VoidCallback onTap;

  const _BiometricQuickTile({
    required this.biometricType,
    required this.isRegistered,
    required this.onTap,
  });

  bool get _isFace => biometricType == BiometricType.face;

  String get _title => _isFace ? 'Unlock with Face ID' : 'Unlock with Fingerprint';
  IconData get _icon => _isFace ? Icons.face_unlock_outlined : Icons.fingerprint_rounded;
  String get _subtitle => isRegistered
      ? 'Registered & ready for 1-tap unlock'
      : 'Not registered yet (Tap for info)';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRegistered
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.cardBorder,
          width: isRegistered ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isRegistered
                ? AppColors.primary.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isRegistered
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _icon,
                    color: isRegistered ? AppColors.primary : AppColors.warmMuted,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _title,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isRegistered
                                  ? AppColors.sand
                                  : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isRegistered ? 'Registered' : 'Not setup',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isRegistered
                                    ? AppColors.primary
                                    : AppColors.warmMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitle,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          color: isRegistered
                              ? AppColors.textSecondary
                              : AppColors.warmMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.warmMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
