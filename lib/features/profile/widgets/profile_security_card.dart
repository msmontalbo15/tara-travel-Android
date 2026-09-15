import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/auth/services/biometric_service.dart';
import '../../../core/auth/services/mpin_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/feedback/app_feedback.dart';
import 'profile_card.dart';

class ProfileSecurityCard extends StatefulWidget {
  const ProfileSecurityCard({super.key});

  @override
  State<ProfileSecurityCard> createState() => _ProfileSecurityCardState();
}

class _ProfileSecurityCardState extends State<ProfileSecurityCard> {
  bool _biometricsAvailable = false;
  bool _biometricsRegistered = false;
  bool _isBiometricLoading = false;

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
    final hasMpin = await mpin.hasMpin();
    final daysLeft = await mpin.getDaysRemaining();

    if (mounted) {
      setState(() {
        _biometricsAvailable = available;
        _biometricsRegistered = registered;
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
          customReason: 'Confirm your Biometrics to enable quick login',
        );
        if (success) {
          await _loadSecurityStatus();
          if (mounted) {
            AppFeedback.showSuccess(context, 'Biometric login enabled!');
          }
        } else {
          if (mounted) {
            AppFeedback.showError(context, 'Biometric registration was cancelled or failed.');
          }
        }
      } else {
        await service.unregisterBiometrics();
        await _loadSecurityStatus();
        if (mounted) {
          AppFeedback.showInfo(context, 'Biometric login disabled.');
        }
      }
    } finally {
      if (mounted) setState(() => _isBiometricLoading = false);
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
                    final success = await MpinSecurityService.instance.setMpin(pin1);
                    await _loadSecurityStatus();
                    if (mounted) {
                      setState(() => _isMpinLoading = false);
                      if (success) {
                        AppFeedback.showSuccess(context, '4-Digit MPIN set! 30-Day session is now active.');
                      } else {
                        AppFeedback.showError(context, 'Failed to set MPIN. Please try again.');
                      }
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                step == 0 ? 'Enter New MPIN' : 'Confirm MPIN',
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontHeading,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    step == 0
                        ? 'Enter a 4-digit MPIN to secure your account.'
                        : 'Re-enter the same 4-digit MPIN to confirm.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorText!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.red,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  PinInputRow(
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
                  child: const Text('Cancel', style: TextStyle(color: AppColors.warmMuted)),
                ),
                TextButton(
                  onPressed: processPinSubmit,
                  child: Text(
                    step == 0 ? 'Next' : 'Confirm',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSectionTitle('MPIN & BIOMETRIC SECURITY'),
        ProfileCard(
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
                            const Text(
                              '4-Digit MPIN',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              _hasMpin
                                  ? 'Active • $_mpinDaysRemaining days remaining'
                                  : 'Not set — Tap to configure',
                              style: TextStyle(
                                fontSize: 12,
                                color: _hasMpin ? AppColors.primary : AppColors.warmMuted,
                                fontWeight: _hasMpin ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isMpinLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      else
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _showSetMpinDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _hasMpin ? 'Change' : 'Set MPIN',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const ProfileDivider(),
                  // Biometric Login Row (Consolidated Fingerprint / Face)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _biometricsRegistered ? AppColors.sand : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.fingerprint_rounded,
                          color: _biometricsRegistered ? AppColors.primary : AppColors.warmMuted,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Biometric Login',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              !_biometricsAvailable
                                  ? 'Hardware unavailable or not enrolled'
                                  : (_biometricsRegistered ? 'Registered & Active' : 'Fingerprint / Face ID unlock'),
                              style: TextStyle(
                                fontSize: 12,
                                color: _biometricsRegistered ? AppColors.primary : AppColors.warmMuted,
                                fontWeight: _biometricsRegistered ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_biometricsAvailable)
                        _isBiometricLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              )
                            : Switch.adaptive(
                                value: _biometricsRegistered,
                                onChanged: (v) => _toggleBiometrics(v),
                                activeThumbColor: AppColors.primary,
                                activeTrackColor: AppColors.primaryLight,
                              ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Session security banner
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
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
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
      ],
    );
  }
}

// ── PIN Input Row for MPIN Dialog ─────────────────────────────────────────────

class PinInputRow extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const PinInputRow({super.key, required this.onChanged});

  @override
  State<PinInputRow> createState() => _PinInputRowState();
}

class _PinInputRowState extends State<PinInputRow> {
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
      final newChar = digits.substring(digits.length - 1);
      _controllers[index].text = newChar;
    } else {
      _controllers[index].text = digits;
    }

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
