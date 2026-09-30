import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/payment_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/services/ewallet_verification_service.dart';
import '../../../core/services/gcash_verification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/feedback/app_feedback.dart';

/// Modal bottom sheet guiding the user through Firebase Phone Auth OTP verification
/// for their Philippine e-wallet (GCash / Maya) mobile number.
class GcashOtpVerificationSheet extends ConsumerStatefulWidget {
  final PaymentProvider initialProvider;

  const GcashOtpVerificationSheet({
    super.key,
    this.initialProvider = PaymentProvider.gcash,
  });

  static Future<bool?> show(
    BuildContext context, {
    PaymentProvider initialProvider = PaymentProvider.gcash,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GcashOtpVerificationSheet(initialProvider: initialProvider),
    );
  }

  @override
  ConsumerState<GcashOtpVerificationSheet> createState() => _GcashOtpVerificationSheetState();
}

class _GcashOtpVerificationSheetState extends ConsumerState<GcashOtpVerificationSheet> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  late PaymentProvider _selectedProvider;
  bool _isCodeSent = false;
  bool _isLoading = false;
  String? _verificationId;
  String? _errorMessage;

  int _resendCountdown = 60;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _selectedProvider = widget.initialProvider;
    final currentNumber = ref.read(profileProvider).gcashNumber;
    if (currentNumber != null && currentNumber.isNotEmpty) {
      _phoneController.text = currentNumber;
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _resendCountdown = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown <= 1) {
        timer.cancel();
        setState(() => _resendCountdown = 0);
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  Future<void> _handleSendOtp() async {
    final rawNumber = _phoneController.text.trim();
    if (!EWalletVerificationService.isValidPhilippineNumber(rawNumber)) {
      setState(() {
        _errorMessage = 'Please enter a valid 11-digit Philippine mobile number.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final normalized = EWalletVerificationService.formatForDisplay(rawNumber);

    await GcashVerificationService.instance.sendOtp(
      phoneNumber: rawNumber,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() {
          _isCodeSent = true;
          _isLoading = false;
          _verificationId = verificationId;
        });
        _startCountdown();
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = error;
        });
      },
      onAutoVerified: (verificationId) async {
        if (!mounted) return;
        _saveVerifiedNumber(normalized);
      },
    );
  }

  Future<void> _handleVerifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit code sent to your phone.');
      return;
    }

    if (_verificationId == null) {
      setState(() => _errorMessage = 'Verification session expired. Please request a new code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final isSuccess = await GcashVerificationService.instance.verifyOtp(
      verificationId: _verificationId!,
      smsCode: code,
    );

    if (!mounted) return;

    if (isSuccess) {
      final formatted = EWalletVerificationService.formatForDisplay(_phoneController.text);
      _saveVerifiedNumber(formatted);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid or expired verification code. Please check and try again.';
      });
    }
  }

  void _saveVerifiedNumber(String formattedNumber) {
    ref.read(profileProvider.notifier).updatePaymentProvider(_selectedProvider);
    ref.read(profileProvider.notifier).setGcashVerified(
          number: formattedNumber,
          verifiedAt: DateTime.now(),
        );

    if (mounted) {
      AppFeedback.showSuccess(
        context,
        '${_selectedProvider.displayName} number verified successfully!',
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _selectedProvider.brandColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _selectedProvider.icon,
                  color: _selectedProvider.brandColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verify ${_selectedProvider.displayName} Number',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontHeading,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isCodeSent
                          ? 'Enter the 6-digit code sent via SMS'
                          : 'Confirm ownership via 1-time SMS code',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.warmMuted, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Provider selector tabs
          if (!_isCodeSent) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _providerTab(
                      provider: PaymentProvider.gcash,
                      label: 'GCash',
                      isSelected: _selectedProvider == PaymentProvider.gcash,
                    ),
                  ),
                  Expanded(
                    child: _providerTab(
                      provider: PaymentProvider.maya,
                      label: 'Maya',
                      isSelected: _selectedProvider == PaymentProvider.maya,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Step 1: Phone input
          if (!_isCodeSent) ...[
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              autofocus: true,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'Philippine Mobile Number',
                hintText: '0917 123 4567',
                prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppColors.primary, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _selectedProvider.brandColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'A standard 6-digit SMS code will be sent to confirm this number belongs to you.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ] else ...[
            // Step 2: OTP input
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SMS sent to ${_phoneController.text}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _isCodeSent = false;
                              _otpController.clear();
                              _errorMessage = null;
                            });
                          },
                    child: const Text(
                      'Change',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              autofocus: true,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '••••••',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _selectedProvider.brandColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: _resendCountdown > 0
                  ? Text(
                      'Resend code in ${_resendCountdown}s',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    )
                  : TextButton(
                      onPressed: _isLoading ? null : _handleSendOtp,
                      child: const Text('Resend SMS Code', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
            ),
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Primary action button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedProvider.brandColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isLoading
                ? null
                : (_isCodeSent ? _handleVerifyOtp : _handleSendOtp),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    _isCodeSent ? 'Verify & Save Number' : 'Send Verification Code',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _providerTab({
    required PaymentProvider provider,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _selectedProvider = provider;
          _errorMessage = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? provider.brandColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
