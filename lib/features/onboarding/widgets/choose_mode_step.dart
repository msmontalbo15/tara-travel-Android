import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/auth/presentation/auth_notifier.dart';
import '../../../core/auth/services/biometric_service.dart';

// ── Auth modes ────────────────────────────────────────────────────────────────
const _kModeGoogle  = 'google';
const _kModeOffline = 'offline';

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
  String _selectedMode = _kModeGoogle;
  bool _autoSignInTriggered = false;

  // Biometrics — null means not yet determined or unavailable
  bool _biometricsAvailable = false;
  BiometricType? _biometricType; // strongest enrolled type

  // Offline mode name input
  final _nameFocus = FocusNode();
  final _nameCtrl  = TextEditingController();

  // Validation errors
  String? _nameError;
  String? _generalError;

  // Animation
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode == _kModeOffline ? _kModeOffline : _kModeGoogle;
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();

    _nameCtrl.addListener(_clearErrors);

    _checkBiometrics();

    if (widget.autoGoogleSignIn && _selectedMode == _kModeGoogle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _autoSignInTriggered) return;
        _autoSignInTriggered = true;
        _handleGoogle();
      });
    }
  }

  Future<void> _checkBiometrics() async {
    final available = await BiometricAuthService.instance.isBiometricsAvailable();
    final strongestType = await BiometricAuthService.instance.getStrongestAvailableType();
    if (mounted) {
      setState(() {
        _biometricsAvailable = available && strongestType != null;
        _biometricType = strongestType;
      });
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameFocus.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _clearErrors() {
    if (_nameError != null || _generalError != null) {
      setState(() {
        _nameError = null;
        _generalError = null;
      });
    }
  }

  // ── Google (PRIMARY HERO ACTION) ────────────────────────────────────────────
  Future<void> _handleGoogle() async {
    setState(() { _generalError = null; });
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    final result = ref.read(authNotifierProvider).value;
    if (result is AuthAuthenticated) {
      TextInput.finishAutofillContext();
      final user = result.user;
      final name = user.userMetadata?['full_name'] as String? ??
          user.userMetadata?['name'] as String?;
      widget.onModeSelected(_kModeGoogle, name);
    } else if (result is AuthError) {
      setState(() => _generalError = result.message);
    }
  }

  // ── Biometric Login Handler (Face ID / Fingerprint) ────────────────────────
  Future<void> _handleBiometrics() async {
    final type = _biometricType;
    final title = type == BiometricType.face ? 'Face ID' : 'Fingerprint';
    final authenticated = await BiometricAuthService.instance.authenticate(
      reason: 'Scan your $title to unlock Tara Travel',
    );
    if (!mounted) return;
    if (authenticated) {
      // Attempt to restore session from Keystore
      await ref.read(authNotifierProvider.notifier).restoreSession();
      if (!mounted) return;
      final result = ref.read(authNotifierProvider).value;
      if (result is AuthAuthenticated) {
        final user = result.user;
        final name = user.userMetadata?['full_name'] as String? ??
            user.userMetadata?['name'] as String?;
        widget.onModeSelected(_kModeGoogle, name);
      } else {
        setState(() {
          _generalError =
              'No saved session found. Please sign in with Google first, then use $title next time.';
        });
      }
    }
  }

  // ── Offline mode handler ───────────────────────────────────────────────────
  void _handleOffline() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Please enter your name');
      return;
    }
    widget.onModeSelected(_kModeOffline, name);
  }

  bool get _isLoadingFromState {
    final authState = ref.watch(authNotifierProvider).value;
    return authState is AuthLoading;
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
                          'Sign in or register using your Google account to sync your trips and itineraries.',
                          style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 28),

                        // ── 1. PRIMARY GOOGLE ACCOUNT BUTTON (REGISTER & LOGIN) ──
                        _PrimaryGoogleButton(
                          selected: _selectedMode == _kModeGoogle,
                          isLoading: _isLoadingFromState && _selectedMode == _kModeGoogle,
                          onTap: () async {
                            setState(() {
                              _selectedMode = _kModeGoogle;
                            });
                            await _handleGoogle();
                          },
                        ),
                        const SizedBox(height: 14),

                        // ── 2. BIOMETRIC QUICK UNLOCK (FACE ID / FINGERPRINT) ───
                        if (_biometricsAvailable && _biometricType != null) ...[
                          _BiometricQuickTile(
                            biometricType: _biometricType!,
                            onTap: _handleBiometrics,
                          ),
                          const SizedBox(height: 14),
                        ],

                        // ── DIVIDER ───────────────────────────────────────────
                        Row(
                          children: [
                            Expanded(child: Container(height: 1, color: AppColors.cardBorder)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                  color: AppColors.warmMuted.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                            Expanded(child: Container(height: 1, color: AppColors.cardBorder)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── 3. OFFLINE MODE OPTION ────────────────────────────
                        _ModeCard(
                          selected: _selectedMode == _kModeOffline,
                          onTap: () => setState(() {
                            _selectedMode = _kModeOffline;
                          }),
                          leadingWidget: _iconBox(Icons.phone_android_rounded, AppColors.warmMuted),
                          title: 'Use offline only',
                          subtitle: 'Saved locally on this device',
                          bullets: const [
                            'No cloud account required',
                            'Full offline privacy',
                            'Upgrade to Google sync anytime',
                          ],
                          dimmed: _selectedMode != _kModeOffline,
                        ),

                        // ── Contextual Name Input for Offline Mode ────────────
                        AnimatedCrossFade(
                          crossFadeState: _selectedMode == _kModeOffline
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 300),
                          firstChild: const SizedBox(height: 0, width: double.infinity),
                          secondChild: Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'What should we call you?',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _field(
                                  _nameCtrl,
                                  'Enter your name',
                                  Icons.person_outline_rounded,
                                  _nameError,
                                  focusNode: _nameFocus,
                                  autofillHints: const [AutofillHints.name],
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _handleOffline(),
                                  textCapitalization: TextCapitalization.words,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // General Error Box
                        if (_generalError != null) ...[
                          const SizedBox(height: 12),
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

                // CTA Button for Offline Mode
                if (_selectedMode == _kModeOffline) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: Semantics(
                        label: 'Continue offline',
                        button: true,
                        child: ElevatedButton(
                          onPressed: _handleOffline,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            'Continue offline',
                            style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon,
    String? error, {
    FocusNode? focusNode,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Iterable<String>? autofillHints,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) =>
      TextField(
        controller: ctrl,
        focusNode: focusNode,
        textCapitalization: textCapitalization,
        autofillHints: autofillHints,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: const TextStyle(fontFamily: 'DM Sans', fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: AppColors.warmMuted.withValues(alpha: 0.5), fontSize: 14),
          errorText: error,
          errorStyle: const TextStyle(fontFamily: 'DM Sans', fontSize: 12),
          prefixIcon: Icon(icon, size: 20, color: AppColors.warmMuted),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder, width: 0.8)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
        ),
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
            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18),
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

  Widget _iconBox(IconData icon, Color color) => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      );
}

// ── Hero Google Primary Button ─────────────────────────────────────────────────

class _PrimaryGoogleButton extends StatelessWidget {
  final bool selected;
  final bool isLoading;
  final VoidCallback onTap;

  const _PrimaryGoogleButton({
    required this.selected,
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
                          Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 16),
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
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                else
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Biometric Quick Tile (Face ID / Fingerprint) ─────────────────────────────

class _BiometricQuickTile extends StatelessWidget {
  final BiometricType biometricType;
  final VoidCallback onTap;

  const _BiometricQuickTile({
    required this.biometricType,
    required this.onTap,
  });

  bool get _isFace => biometricType == BiometricType.face;

  String get _title => _isFace ? 'Unlock with Face ID' : 'Unlock with Fingerprint';
  IconData get _icon  => _isFace ? Icons.face_unlock_outlined : Icons.fingerprint_rounded;
  String get _subtitle => _isFace
      ? 'Instant face recognition login'
      : 'Scan your fingerprint to log in';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
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
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_icon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      Text(
                        _subtitle,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.warmMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Mode Card ──────────────────────────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget leadingWidget;
  final String title;
  final String subtitle;
  final List<String> bullets;
  final bool dimmed;

  const _ModeCard({
    required this.selected,
    required this.onTap,
    required this.leadingWidget,
    required this.title,
    required this.subtitle,
    required this.bullets,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 210),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardBorder,
            width: selected ? 2 : 0.5,
          ),
          boxShadow: selected
              ? [BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 5))]
              : [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                leadingWidget,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: dimmed
                                  ? AppColors.warmMuted
                                  : AppColors.textPrimary)),
                      Text(subtitle,
                          style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11,
                              color: dimmed
                                  ? AppColors.cardBorder
                                  : AppColors.textSecondary)),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.cardBorder,
                        width: 2),
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 13)
                      : null,
                ),
              ],
            ),
            if (selected) ...[
              const SizedBox(height: 10),
              ...bullets.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(b,
                              style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 12,
                                  color: AppColors.deepEarth
                                      .withValues(alpha: 0.7))),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
