import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_responsive.dart';

void showProfileQrCodeModal(BuildContext context, String userId, String displayName) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 16, 24, ctx.safeBottomPadding(24)),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'My Friend Code & QR',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Share your personal QR or ID so friends can add you on Tara Travel',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: QrImageView(
                data: userId,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.deepEarth,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.deepEarth,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              displayName.isNotEmpty ? displayName : 'Traveler',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: userId));
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Friend ID copied!'),
                    backgroundColor: AppColors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.copy_rounded, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      userId.length > 12 ? '${userId.substring(0, 8)}…' : userId,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  SharePlus.instance.share(
                    ShareParams(
                      text:
                          'Add me on Tara Travel! Use my friend code:\n$userId\n\nDownload Tara Travel to connect and plan trips together! 🌴',
                      subject: 'Add me on Tara Travel',
                    ),
                  );
                },
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text(
                  'Share Profile Code',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
