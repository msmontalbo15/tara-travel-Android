import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/services/database_service.dart';
import '../../../core/auth/services/biometric_service.dart';
import '../../../core/auth/services/mpin_service.dart';
import '../../../core/auth/presentation/auth_notifier.dart';
import '../../../core/auth/domain/auth_state.dart' as domain;

/// GCash-Style 4-Digit MPIN & Biometric Unlock Screen.
class GCashMpinView extends ConsumerStatefulWidget {
  final VoidCallback onSwitchToGoogle;
  final String? userNickname;

  const GCashMpinView({
    super.key,
    required this.onSwitchToGoogle,
    this.userNickname,
  });

  @override
  ConsumerState<GCashMpinView> createState() => _GCashMpinViewState();
}

class _GCashMpinViewState extends ConsumerState<GCashMpinView>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _isVerifying = false;
  String? _errorMessage;
  int _daysRemaining = 30;

  bool _biometricsAvailable = false;
  BiometricType? _biometricType;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _checkDaysAndBiometrics();
  }

  Future<void> _checkDaysAndBiometrics() async {
    final days = await MpinSecurityService.instance.getDaysRemaining();
    final avail = await BiometricAuthService.instance.isBiometricsAvailable();
    final type = await BiometricAuthService.instance.getStrongestAvailableType();

    if (mounted) {
      setState(() {
        _daysRemaining = days;
        _biometricsAvailable = avail && type != null;
        _biometricType = type;
      });
    }

    // Auto-prompt biometrics on launch if registered
    final isBiometricRegistered = await BiometricAuthService.instance.isBiometricsRegistered();
    if (isBiometricRegistered && avail && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleBiometricUnlock();
      });
    }
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    if (_isVerifying || _pin.length >= 4) return;
    HapticFeedback.lightImpact();

    setState(() {
      _errorMessage = null;
      _pin += digit;
    });

    if (_pin.length == 4) {
      _submitPin();
    }
  }

  void _onBackspacePressed() {
    if (_isVerifying || _pin.isEmpty) return;
    HapticFeedback.selectionClick();

    setState(() {
      _errorMessage = null;
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _submitPin() async {
    setState(() => _isVerifying = true);

    final isValid = await MpinSecurityService.instance.verifyMpin(_pin);
    if (!mounted) return;

    if (isValid) {
      HapticFeedback.mediumImpact();
      await _onUnlockSuccess();
    } else {
      HapticFeedback.vibrate();
      _shakeCtrl.forward(from: 0.0);
      setState(() {
        _isVerifying = false;
        _pin = '';
        _errorMessage = 'Incorrect MPIN. Please try again.';
      });
    }
  }

  Future<void> _handleBiometricUnlock() async {
    final type = _biometricType;
    final title = type == BiometricType.face ? 'Face ID' : 'Fingerprint';

    final authenticated = await BiometricAuthService.instance.authenticate(
      reason: 'Scan your $title to log in to Tara Travel',
    );

    if (!mounted) return;
    if (authenticated) {
      HapticFeedback.mediumImpact();
      await MpinSecurityService.instance.extendSessionWindow();
      await _onUnlockSuccess();
    }
  }

  Future<void> _onUnlockSuccess() async {
    // Rehydrate session from secure storage
    await ref.read(authNotifierProvider.notifier).restoreSession();
    if (!mounted) return;

    // Check if we have an authenticated Supabase user to switch local DB context
    final authValue = ref.read(authNotifierProvider).value;
    final supaUser = (authValue is domain.AuthAuthenticated) ? authValue.user : null;

    if (supaUser != null) {
      await DatabaseService.instance.switchUser(supaUser.id);
    }

    await ref.read(profileProvider.notifier).refreshProfile();
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final greetingName = widget.userNickname ?? profile.displayNameForHome;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Header Greeting Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: profile.avatarColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: profile.avatarColor.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        profile.initials,
                        style: const TextStyle(
                          fontFamily: 'Playfair Display',
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      color: AppColors.warmMuted.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    greetingName,
                    style: const TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.sand,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_outlined, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '30-Day Session: $_daysRemaining days remaining',
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // 4 PIN Dots
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnim.value, 0),
                  child: child,
                );
              },
              child: Column(
                children: [
                  const Text(
                    'Enter your 4-Digit MPIN',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isFilled = index < _pin.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled ? AppColors.primary : Colors.transparent,
                          border: Border.all(
                            color: isFilled ? AppColors.primary : AppColors.cardBorder,
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Spacer(),

            // 3x4 Numeric Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                children: [
                  _keypadRow(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _keypadRow(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _keypadRow(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Biometrics / Face ID button
                      if (_biometricsAvailable)
                        _keypadButton(
                          child: Icon(
                            _biometricType == BiometricType.face
                                ? Icons.face_unlock_outlined
                                : Icons.fingerprint_rounded,
                            color: AppColors.primary,
                            size: 26,
                          ),
                          onTap: _handleBiometricUnlock,
                          isAction: true,
                        )
                      else
                        const SizedBox(width: 68, height: 68),

                      _digitButton('0'),

                      // Backspace button
                      _keypadButton(
                        child: const Icon(
                          Icons.backspace_outlined,
                          color: AppColors.textPrimary,
                          size: 22,
                        ),
                        onTap: _onBackspacePressed,
                        isAction: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Fallback: Sign in with Google / Switch Account
            TextButton(
              onPressed: widget.onSwitchToGoogle,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sync_alt_rounded, size: 14, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Sign in with Google / Switch Account',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _keypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _digitButton(d)).toList(),
    );
  }

  Widget _digitButton(String digit) {
    return _keypadButton(
      child: Text(
        digit,
        style: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      onTap: () => _onDigitPressed(digit),
    );
  }

  Widget _keypadButton({
    required Widget child,
    required VoidCallback onTap,
    bool isAction = false,
  }) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: isAction ? AppColors.sand.withValues(alpha: 0.6) : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isAction
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.cardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(child: child),
        ),
      ),
    );
  }
}
