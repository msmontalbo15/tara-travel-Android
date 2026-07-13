import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/auth/presentation/auth_notifier.dart';

// ── Auth modes ────────────────────────────────────────────────────────────────
const _kModeGoogle  = 'google';
const _kModeEmail   = 'email';
const _kModeOffline = 'offline';

// ── Email sub-screens ─────────────────────────────────────────────────────────
enum _EmailScreen { form, otp }

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
  bool _isSignUp = true;
  bool _autoSignInTriggered = false;

  // Email/password form
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscurePass = true;

  // OTP verification screen
  _EmailScreen _emailScreen = _EmailScreen.form;
  final List<TextEditingController> _otpCtrl =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocus =
      List.generate(6, (_) => FocusNode());
  int _otpResendCooldown = 0;
  String? _pendingEmail;   // email awaiting OTP confirmation
  String? _pendingName;    // name entered by user

  // Validation errors
  String? _nameError, _emailError, _passError, _generalError;

  // Animation
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();

    _nameCtrl.addListener(_clearErrors);
    _emailCtrl.addListener(_clearErrors);
    _passCtrl.addListener(_clearErrors);

    if (widget.autoGoogleSignIn && _selectedMode == _kModeGoogle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _autoSignInTriggered) return;
        _autoSignInTriggered = true;
        _handleContinue();
      });
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    for (final c in _otpCtrl) { c.dispose(); }
    for (final f in _otpFocus) { f.dispose(); }
    super.dispose();
  }

  void _clearErrors() {
    if (_nameError != null || _emailError != null ||
        _passError != null || _generalError != null) {
      setState(() {
        _nameError = _emailError = _passError = _generalError = null;
      });
    }
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  /// RFC 5321-aligned email regex — matches the server-side validation exactly.
  bool _validEmail(String e) =>
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
          .hasMatch(e.trim());

  /// Password must be ≥ 8 chars with uppercase, digit, and special character.
  String? _validatePassword(String password) {
    if (password.length < 8) return 'Password must be at least 8 characters.';
    if (!RegExp(r'[A-Z]').hasMatch(password)) return 'Add at least one uppercase letter.';
    if (!RegExp(r'\d').hasMatch(password)) return 'Add at least one number.';
    if (!RegExp(r'[!@#\$%^&*\-_=+?]').hasMatch(password)) {
      return 'Add at least one special character (!@#\$%^&*).';
    }
    return null; // Strong ✓
  }

  // ── Submit handlers ────────────────────────────────────────────────────────

  Future<void> _handleContinue() async {
    // Derive isLoading from the MVI state for the primary flow.
    final authState = ref.read(authNotifierProvider).value;
    if (authState is AuthLoading) return;
    switch (_selectedMode) {
      case _kModeGoogle:  await _handleGoogle();  break;
      case _kModeEmail:   await _handleEmail();   break;
      case _kModeOffline: _handleOffline();        break;
    }
  }

  // ── Google ──────────────────────────────────────────────────────────────────
  Future<void> _handleGoogle() async {
    setState(() { _generalError = null; });
    // Dispatch to MVI notifier — state transitions drive loading/error UI.
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    final result = ref.read(authNotifierProvider).value;
    if (result is AuthAuthenticated) {
      final user = result.user;
      final name = user.userMetadata?['full_name'] as String? ??
          user.userMetadata?['name'] as String?;
      widget.onModeSelected(_kModeGoogle, name);
    } else if (result is AuthError) {
      setState(() => _generalError = result.message);
    }
    // AuthUnauthenticated = user dismissed picker — no error shown.
  }

  // ── Email / Password ────────────────────────────────────────────────────────
  Future<void> _handleEmail() async {
    if (_emailScreen == _EmailScreen.otp) {
      await _verifyOtp();
      return;
    }

    final name  = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text;
    bool err = false;

    if (_isSignUp && name.isEmpty) {
      setState(() => _nameError = 'Please enter your name');
      err = true;
    }
    if (!_validEmail(email)) {
      setState(() => _emailError = 'Enter a valid email address');
      err = true;
    }
    if (_isSignUp) {
      // Client-side password strength gate — runs before any network call.
      final pwError = _validatePassword(pass);
      if (pwError != null) {
        setState(() => _passError = pwError);
        err = true;
      }
    } else if (pass.isEmpty) {
      setState(() => _passError = 'Please enter your password');
      err = true;
    }
    if (err) return;

    setState(() { _generalError = null; });

    if (_isSignUp) {
      await ref.read(authNotifierProvider.notifier).signUpWithEmail(
        email, pass, displayName: name,
      );
    } else {
      await ref.read(authNotifierProvider.notifier).signInWithEmail(email, pass);
    }

    if (!mounted) return;
    final result = ref.read(authNotifierProvider).value;

    if (result is AuthAuthenticated) {
      final user = result.user;
      final metaName = user.userMetadata?['full_name'] as String? ??
          user.userMetadata?['name'] as String?;
      widget.onModeSelected(_kModeEmail, metaName ?? name);
    } else if (result is AuthOtpPending) {
      _pendingEmail = email;
      _pendingName  = name;
      setState(() => _emailScreen = _EmailScreen.otp);
      _startResendCooldown();
    } else if (result is AuthError) {
      setState(() => _generalError = result.message);
    }
  }

  Future<void> _verifyOtp() async {
    final email = _pendingEmail!;
    final code  = _otpCtrl.map((c) => c.text).join();

    if (code.length < 6) {
      setState(() => _generalError = 'Enter the full 6-digit code');
      return;
    }
    setState(() { _generalError = null; });

    await ref.read(authNotifierProvider.notifier)
        .verifyOtp(email, code, pendingName: _pendingName);

    if (!mounted) return;
    final result = ref.read(authNotifierProvider).value;
    if (result is AuthAuthenticated) {
      widget.onModeSelected(_kModeEmail, _pendingName);
    } else if (result is AuthError) {
      setState(() => _generalError = result.message);
    }
  }

  Future<void> _resendOtp() async {
    if (_otpResendCooldown > 0 || _pendingEmail == null) return;
    await ref.read(authNotifierProvider.notifier).resendOtp(_pendingEmail!);
    _startResendCooldown();
  }

  void _startResendCooldown() {
    setState(() => _otpResendCooldown = 60);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _otpResendCooldown = (_otpResendCooldown - 1).clamp(0, 60);
      });
      return _otpResendCooldown > 0;
    });
  }

  // ── Offline ─────────────────────────────────────────────────────────────────
  void _handleOffline() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Please enter your name');
      return;
    }
    widget.onModeSelected(_kModeOffline, name);
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  /// Derive isLoading from the MVI auth state for consistent loading UX.
  bool get _isLoadingFromState {
    final authState = ref.watch(authNotifierProvider).value;
    return authState is AuthLoading;
  }

  @override
  Widget build(BuildContext context) {
    // OTP screen takes over the full scaffold when active
    if (_selectedMode == _kModeEmail &&
        _emailScreen == _EmailScreen.otp) {
      return _OtpScreen(
        email: _pendingEmail ?? '',
        isLoading: _isLoadingFromState,
        otpCtrl: _otpCtrl,
        otpFocus: _otpFocus,
        error: _generalError,
        cooldown: _otpResendCooldown,
        onVerify: _handleEmail,
        onResend: _resendOtp,
        onBack: () {
          ref.read(authNotifierProvider.notifier).clearError();
          setState(() {
            _emailScreen = _EmailScreen.form;
            _generalError = null;
            for (final c in _otpCtrl) { c.clear(); }
          });
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
                        const SizedBox(height: 32),
                        _stepPill(),
                        const SizedBox(height: 16),
                        const Text(
                          'How do you want\nto use Tara?',
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
                          'Choose how your trips and data are saved.',
                          style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 28),

                        // ── Google ───────────────────────────────────────────
                        _ModeCard(
                          selected: _selectedMode == _kModeGoogle,
                          onTap: () => setState(() {
                            _selectedMode = _kModeGoogle;
                            _emailScreen  = _EmailScreen.form;
                          }),
                          leadingWidget: _googleIcon(),
                          title: 'Continue with Google',
                          subtitle: 'Sync across all devices',
                          bullets: const [
                            'Auto-backup all trips',
                            'Share with Google contacts',
                            'Sync with Calendar & Maps',
                          ],
                        ),
                        const SizedBox(height: 10),

                        // ── Email & Password ─────────────────────────────────
                        _ModeCard(
                          selected: _selectedMode == _kModeEmail,
                          onTap: () => setState(() {
                            _selectedMode = _kModeEmail;
                            _emailScreen  = _EmailScreen.form;
                          }),
                          leadingWidget: _iconBox(Icons.email_rounded, const Color(0xFF3B82F6)),
                          title: 'Email & Password',
                          subtitle: 'Secure cloud account',
                          bullets: const [
                            'Email OTP verification',
                            'Access from any device',
                            'No Google account needed',
                          ],
                          dimmed: _selectedMode != _kModeEmail,
                        ),
                        const SizedBox(height: 10),

                        // ── Offline ──────────────────────────────────────────
                        _ModeCard(
                          selected: _selectedMode == _kModeOffline,
                          onTap: () => setState(() {
                            _selectedMode = _kModeOffline;
                            _emailScreen  = _EmailScreen.form;
                          }),
                          leadingWidget: _iconBox(Icons.phone_android_rounded, AppColors.warmMuted),
                          title: 'Use offline only',
                          subtitle: 'Saved on this device',
                          bullets: const [
                            'No account needed',
                            'Full privacy, data stays local',
                            'No sync or sharing features',
                          ],
                          dimmed: _selectedMode != _kModeOffline,
                        ),

                        // ── Contextual form ──────────────────────────────────
                        AnimatedCrossFade(
                          crossFadeState: _selectedMode != _kModeGoogle
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 300),
                          firstChild: const SizedBox(height: 0, width: double.infinity),
                          secondChild: Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: _buildForm(),
                          ),
                        ),

                        // Error message
                        if (_generalError != null) ...[
                          const SizedBox(height: 10),
                          _errorBox(_generalError!),
                        ],

                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            'You can connect Google later in Settings → Account',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11,
                              color: AppColors.warmMuted.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),

                // CTA
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: Semantics(
                      label: _ctaLabel(),
                      button: true,
                      child: ElevatedButton(
                        onPressed: _isLoadingFromState ? null : _handleContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoadingFromState
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                _ctaLabel(),
                                style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600),
                              ),
                      ),
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

  String _ctaLabel() {
    switch (_selectedMode) {
      case _kModeGoogle:  return 'Continue with Google';
      case _kModeEmail:   return _isSignUp ? 'Create account' : 'Sign in';
      case _kModeOffline: return 'Continue offline';
      default:            return 'Continue';
    }
  }

  Widget _buildForm() {
    if (_selectedMode == _kModeEmail) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle
          Row(children: [
            _tabToggle('New user?', _isSignUp,
                () => setState(() => _isSignUp = true)),
            const SizedBox(width: 8),
            _tabToggle('Sign in', !_isSignUp,
                () => setState(() => _isSignUp = false)),
          ]),
          const SizedBox(height: 14),

          if (_isSignUp) ...[
            _label('Full name'),
            const SizedBox(height: 6),
            _field(_nameCtrl, 'e.g. Maria Santos',
                Icons.person_outline_rounded, _nameError,
                textCapitalization: TextCapitalization.words,
                semanticsLabel: 'Full name field'),
            const SizedBox(height: 12),
          ],
          _label('Email address'),
          const SizedBox(height: 6),
          _field(_emailCtrl, 'you@email.com', Icons.email_outlined, _emailError,
              keyboardType: TextInputType.emailAddress,
              semanticsLabel: 'Email address field'),
          const SizedBox(height: 12),
          _label('Password'),
          const SizedBox(height: 6),
          _field(
            _passCtrl,
            _isSignUp ? 'Min 8 chars, uppercase, number & symbol' : 'Your password',
            Icons.lock_outline_rounded,
            _passError,
            obscureText: _obscurePass,
            semanticsLabel: 'Password field',
            suffix: IconButton(
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
              icon: Icon(
                _obscurePass
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: AppColors.warmMuted,
              ),
            ),
          ),
          if (_isSignUp) ...[
            const SizedBox(height: 10),
            // Real-time password strength meter
            _PasswordStrengthMeter(password: _passCtrl.text),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.security_rounded,
                  size: 14, color: AppColors.green),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'You\'ll receive a 6-digit verification code by email.',
                  style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      color: AppColors.green.withValues(alpha: 0.85)),
                ),
              ),
            ]),
          ],
        ],
      );
    }

    // Offline mode — name only
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('What should we call you?',
            style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        _field(_nameCtrl, 'Enter your name',
            Icons.person_outline_rounded, _nameError,
            textCapitalization: TextCapitalization.words),
      ],
    );
  }

  // ── Small helpers ──────────────────────────────────────────────────────────

  Widget _stepPill() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
            color: AppColors.sand, borderRadius: BorderRadius.circular(20)),
        child: const Text('Step 1 of 6',
            style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary)),
      );

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary));

  Widget _tabToggle(String label, bool active, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: active ? AppColors.primary : AppColors.cardBorder),
          ),
          child: Text(label,
              style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.warmMuted)),
        ),
      );

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon,
    String? error, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? suffix,
    String? semanticsLabel,
  }) =>
      Semantics(
        label: semanticsLabel,
        textField: true,
        child: TextField(
          controller: ctrl,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: const TextStyle(fontFamily: 'DM Sans', fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: AppColors.warmMuted.withValues(alpha: 0.5), fontSize: 14),
            errorText: error,
            errorStyle: const TextStyle(fontFamily: 'DM Sans', fontSize: 12),
            prefixIcon: Icon(icon, size: 20, color: AppColors.warmMuted),
            suffixIcon: suffix,
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
        child: Text(msg,
            style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: Color(0xFFEF4444))),
      );

  Widget _googleIcon() => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 1))
          ],
        ),
        child: Center(
          child: Text('G',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..shader = const LinearGradient(
                          colors: [Color(0xFF4285F4), Color(0xFFEA4335)])
                      .createShader(const Rect.fromLTWH(0, 0, 28, 28)),
              )),
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

// ── Password Strength Meter ───────────────────────────────────────────────────
// Displayed in real-time as the user types during sign-up.
// Scores 0–4 based on: length≥8, uppercase, digit, special char.

class _PasswordStrengthMeter extends StatelessWidget {
  final String password;

  const _PasswordStrengthMeter({required this.password});

  int _score() {
    if (password.isEmpty) return -1;
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*\-_=+?]').hasMatch(password)) score++;
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final score = _score();
    if (score < 0) return const SizedBox.shrink();

    const labels = ['Weak', 'Fair', 'Fair', 'Strong', 'Strong'];
    const segColors = [
      Color(0xFFEF4444),
      Color(0xFFF59E0B),
      Color(0xFFF59E0B),
      Color(0xFF10B981),
      Color(0xFF10B981),
    ];

    final safeScore = score.clamp(0, 4);
    final label     = labels[safeScore];
    final color     = segColors[safeScore];
    final fraction  = (safeScore + 1) / 5.0;

    return Semantics(
      label: 'Password strength: $label',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: fraction),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 5,
                backgroundColor: AppColors.cardBorder,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}



// ── OTP Verification Screen ───────────────────────────────────────────────────

class _OtpScreen extends StatelessWidget {
  final String email;
  final bool isLoading;
  final List<TextEditingController> otpCtrl;
  final List<FocusNode> otpFocus;
  final String? error;
  final int cooldown;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final VoidCallback onBack;

  const _OtpScreen({
    required this.email,
    required this.isLoading,
    required this.otpCtrl,
    required this.otpFocus,
    required this.error,
    required this.cooldown,
    required this.onVerify,
    required this.onResend,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Back
              GestureDetector(
                onTap: onBack,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      size: 20, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 28),

              // Lock icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.lock_rounded,
                    color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 20),

              const Text(
                'Verify your email',
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      color: AppColors.textSecondary),
                  children: [
                    const TextSpan(text: 'We sent a 6-digit code to\n'),
                    TextSpan(
                      text: email,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // 6-digit OTP boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => _OtpBox(
                  controller: otpCtrl[i],
                  focusNode: otpFocus[i],
                  onChanged: (val) {
                    if (val.isNotEmpty && i < 5) {
                      otpFocus[i + 1].requestFocus();
                    } else if (val.isEmpty && i > 0) {
                      otpFocus[i - 1].requestFocus();
                    }
                  },
                )),
              ),
              const SizedBox(height: 12),

              if (error != null)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.25)),
                  ),
                  child: Text(error!,
                      style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          color: Color(0xFFEF4444))),
                ),

              const Spacer(),

              // Resend
              Center(
                child: GestureDetector(
                  onTap: cooldown > 0 ? null : onResend,
                  child: Text(
                    cooldown > 0
                        ? 'Resend code in ${cooldown}s'
                        : 'Didn\'t receive it? Resend code',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      color: cooldown > 0
                          ? AppColors.warmMuted
                          : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Verify button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Verify & Continue',
                          style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Single OTP digit box ──────────────────────────────────────────────────────

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2)),
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
            // Bullets only expand when selected
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
