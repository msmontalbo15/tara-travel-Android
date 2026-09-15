import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/feedback/app_feedback.dart';
import 'profile_qr_modal.dart';

class ProfileHeroHeader extends StatelessWidget {
  final ProfileState profile;
  final VoidCallback onPickPhoto;

  const ProfileHeroHeader({
    super.key,
    required this.profile,
    required this.onPickPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final topPadding = MediaQuery.paddingOf(context).top + 16;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0A04), AppColors.deepEarth],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: EdgeInsets.fromLTRB(24, topPadding, 24, 32),
      child: Column(
        children: [
          // Avatar with Camera button
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: profile.avatarColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: profile.avatarColor.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _buildAvatar(),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onPickPhoto,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.deepEarth, width: 2.5),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            profile.effectiveName.isNotEmpty
                ? profile.effectiveName
                : (profile.isLoaded ? 'Traveler' : ''),
            style: const TextStyle(
              fontFamily: AppTextStyles.fontHeading,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          // Location
          Text(
            profile.homeCity.isNotEmpty
                ? (profile.homeBarangay.isNotEmpty
                    ? '${profile.homeBarangay}, ${profile.homeCity}'
                    : '${profile.homeCity}, Philippines')
                : 'Philippines',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          // User ID & QR Code Chips (Clean named widget, no IIFE)
          if (currentUserId != null && currentUserId.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                // Copy ID Chip
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: currentUserId));
                    AppFeedback.showInfo(context, 'User ID copied to clipboard!');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fingerprint_rounded, size: 14, color: AppColors.amber),
                        const SizedBox(width: 6),
                        Text(
                          'ID: ${currentUserId.length > 12 ? "${currentUserId.substring(0, 8)}…" : currentUserId}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.copy_rounded, size: 12, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
                // My QR Button Chip
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => showProfileQrCodeModal(context, currentUserId, profile.effectiveName),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'My QR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final url = profile.profilePhotoUrl;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          width: 90,
          height: 90,
          errorWidget: (_, __, ___) => _initialsAvatar(),
          placeholder: (_, __) => _initialsAvatar(),
        );
      }
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: 90,
          height: 90,
          errorBuilder: (_, __, ___) => _initialsAvatar(),
        );
      }
    }
    return _initialsAvatar();
  }

  Widget _initialsAvatar() {
    return Center(
      child: profile.initials.isNotEmpty
          ? Text(
              profile.initials,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontHeading,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            )
          : const Icon(
              Icons.person_rounded,
              size: 44,
              color: Colors.white,
            ),
    );
  }
}
