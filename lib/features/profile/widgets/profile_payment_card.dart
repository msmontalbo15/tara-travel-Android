import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/feedback/app_feedback.dart';
import 'profile_card.dart';

class ProfilePaymentCard extends ConsumerWidget {
  final VoidCallback onEditGcash;

  const ProfilePaymentCard({
    super.key,
    required this.onEditGcash,
  });

  Future<void> _pickGcashQr(BuildContext context, WidgetRef ref) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (image != null && context.mounted) {
        final currentGcash = ref.read(profileProvider).gcashNumber ?? '';
        ref.read(profileProvider.notifier).updateGCash(currentGcash, image.path);
        AppFeedback.showSuccess(context, 'GCash QR updated successfully!');
      }
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showError(context, 'Error picking image: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.blueLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Color(0xFF0066CC),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GCash Number',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              profile.gcashNumber ?? 'Not set',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onEditGcash,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.sand,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const ProfileDivider(),
                  const SizedBox(height: 14),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _pickGcashQr(context, ref),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder, width: 1),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Upload GCash QR Code',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
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
