import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Unified cloud-native avatar widget for Tara Travel.
///
/// Features:
/// 1. Smoothly renders cached remote photos with [CachedNetworkImage]
/// 2. Falls back to local file if path points to local device file
/// 3. Falls back gracefully to styled initials with [backgroundColor]
/// 4. Handles errors and placeholder loading states cleanly
class AppAvatar extends StatelessWidget {
  final String? photoUrl;
  final String initials;
  final double size;
  final Color backgroundColor;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final String fontFamily;

  const AppAvatar({
    super.key,
    required this.photoUrl,
    required this.initials,
    this.size = 44,
    this.backgroundColor = AppColors.primary,
    this.border,
    this.boxShadow,
    this.fontFamily = AppTextStyles.fontHeading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: border,
        boxShadow: boxShadow,
      ),
      child: ClipOval(
        child: _buildAvatarContent(),
      ),
    );
  }

  Widget _buildAvatarContent() {
    final url = photoUrl?.trim();
    if (url == null || url.isEmpty) {
      return _buildInitials();
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: size,
        height: size,
        placeholder: (_, __) => _buildInitials(),
        errorWidget: (_, __, ___) => _buildInitials(),
      );
    }

    // Local file fallback
    final file = File(url);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => _buildInitials(),
      );
    }

    return _buildInitials();
  }

  Widget _buildInitials() {
    return Center(
      child: initials.isNotEmpty
          ? Text(
              initials,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: size * 0.36,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            )
          : Icon(
              Icons.person_rounded,
              size: size * 0.5,
              color: Colors.white,
            ),
    );
  }
}
