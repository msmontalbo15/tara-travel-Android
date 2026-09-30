import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/models/payment_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/services/gcash_qr_processor.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/feedback/app_feedback.dart';
import 'gcash_otp_verification_sheet.dart';
import 'profile_card.dart';

class ProfilePaymentCard extends ConsumerStatefulWidget {
  final VoidCallback onEditGcash;

  const ProfilePaymentCard({
    super.key,
    required this.onEditGcash,
  });

  @override
  ConsumerState<ProfilePaymentCard> createState() => _ProfilePaymentCardState();
}

class _ProfilePaymentCardState extends ConsumerState<ProfilePaymentCard> {
  bool _isProcessingQr = false;

  Future<void> _handleUploadQr() async {
    final profile = ref.read(profileProvider);

    if (!profile.gcashVerified || profile.gcashNumber == null || profile.gcashNumber!.isEmpty) {
      if (mounted) {
        AppFeedback.showError(
          context,
          'Please verify your ${profile.paymentProvider.displayName} number first before uploading a QR code.',
        );
      }
      return;
    }

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null || !mounted) return;

      setState(() => _isProcessingQr = true);

      // Decode, cross-validate against verified number, and regenerate clean branded QR
      final result = await GcashQrProcessor.instance.processAndValidate(
        imageFile: File(image.path),
        verifiedNumber: profile.gcashNumber!,
      );

      if (!mounted) return;
      setState(() => _isProcessingQr = false);

      if (result.isSuccess && result.processedImageFile != null) {
        await ref.read(profileProvider.notifier).updateGcashQr(result.processedImageFile!.path);
        if (mounted) {
          AppFeedback.showSuccess(
            context,
            '${profile.paymentProvider.displayName} QR verified and attached successfully!',
          );
        }
      } else if (result.isMismatch) {
        if (mounted) {
          _showMismatchDialog(result.errorMessage ?? 'Mismatched QR code.');
        }
      } else {
        if (mounted) {
          AppFeedback.showError(context, result.errorMessage ?? 'Failed to process QR code.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingQr = false);
        AppFeedback.showError(context, 'Error processing image: $e');
      }
    }
  }

  void _showMismatchDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text('QR Code Mismatch'),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final provider = profile.paymentProvider;
    final isVerified = profile.gcashVerified;
    final hasNumber = profile.gcashNumber != null && profile.gcashNumber!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSectionTitle('PAYMENT SETTINGS'),
        ProfileCard(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Provider segmented selector
                  Row(
                    children: [
                      _providerChip(
                        provider: PaymentProvider.gcash,
                        isSelected: provider == PaymentProvider.gcash,
                        onTap: () {
                          ref.read(profileProvider.notifier).updatePaymentProvider(PaymentProvider.gcash);
                        },
                      ),
                      const SizedBox(width: 8),
                      _providerChip(
                        provider: PaymentProvider.maya,
                        isSelected: provider == PaymentProvider.maya,
                        onTap: () {
                          ref.read(profileProvider.notifier).updatePaymentProvider(PaymentProvider.maya);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Phone number row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: provider.brandColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          provider.icon,
                          color: provider.brandColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${provider.displayName} Number',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (isVerified)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.green.shade300, width: 0.8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle_rounded, color: Colors.green, size: 11),
                                        SizedBox(width: 3),
                                        Text(
                                          'Verified',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else if (hasNumber)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.orange.shade300, width: 0.8),
                                    ),
                                    child: const Text(
                                      'Unverified',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profile.gcashNumber ?? 'Not set',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: hasNumber ? FontWeight.w600 : FontWeight.normal,
                                color: hasNumber ? AppColors.textPrimary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          GcashOtpVerificationSheet.show(
                            context,
                            initialProvider: provider,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isVerified ? AppColors.sand : provider.brandColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isVerified ? 'Edit' : (hasNumber ? 'Verify Now' : 'Set Up'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isVerified ? AppColors.primary : provider.brandColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const ProfileDivider(),
                  const SizedBox(height: 14),

                  // QR Code Section
                  if (profile.gcashQrUrl != null && profile.gcashQrUrl!.isNotEmpty) ...[
                    // Preview of attached QR code
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              profile.gcashQrUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.qr_code_2_rounded,
                                size: 50,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Verified ${provider.displayName} QR',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Ready for automatic group settlements',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _isProcessingQr ? null : () => _handleUploadQr(),
                            child: const Text('Replace', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Upload button gated behind verified state
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _isProcessingQr ? null : () => _handleUploadQr(),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isVerified ? AppColors.surfaceLight : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isVerified ? AppColors.cardBorder : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isProcessingQr)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else if (!isVerified)
                              const Icon(Icons.lock_outline_rounded, color: Colors.grey, size: 18)
                            else
                              Icon(Icons.qr_code_scanner_rounded, color: provider.brandColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _isProcessingQr
                                  ? 'Analyzing & Verifying QR...'
                                  : (isVerified
                                      ? 'Upload ${provider.displayName} QR Code'
                                      : 'Verify Number First to Upload QR'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isVerified ? provider.brandColor : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _providerChip({
    required PaymentProvider provider,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? provider.brandColor : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? provider.brandColor : AppColors.cardBorder,
          ),
        ),
        child: Text(
          provider.displayName,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
