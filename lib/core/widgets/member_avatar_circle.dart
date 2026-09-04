import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tara_travel/core/theme/app_text_styles.dart';

/// Reusable circular avatar widget that renders:
///  1. A [CachedNetworkImage] if [photoUrl] starts with `http`
///  2. An [Image.file] if [photoUrl] is a non-empty local path
///  3. An initials circle (with [color] background) as fallback
///
/// Used across profile, members, trip detail, trip card, packing,
/// itinerary, and navigation screens to DRY-up avatar rendering.
class MemberAvatarCircle extends StatelessWidget {
  /// HTTP URL or local file path to the user's profile photo.
  final String? photoUrl;

  /// One- or two-character initials shown when no photo is available.
  final String initials;

  /// Background colour for the initials fallback circle.
  final Color color;

  /// Diameter of the avatar circle in logical pixels.
  final double size;

  /// Optional border to apply around the avatar.
  final Border? border;

  /// Font family for initials text. Defaults to [AppTextStyles.fontBody].
  final String fontFamily;

  const MemberAvatarCircle({
    super.key,
    required this.photoUrl,
    required this.initials,
    required this.color,
    this.size = 36,
    this.border,
    this.fontFamily = AppTextStyles.fontBody,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: border,
      ),
      child: ClipOval(
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    final url = photoUrl;
    if (url == null || url.isEmpty) return _initialsWidget();

    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorWidget: (_, __, ___) => _initialsWidget(),
        placeholder: (_, __) => _initialsWidget(),
      );
    }

    // Local file path
    final file = File(url);
    return Image.file(
      file,
      fit: BoxFit.cover,
      width: size,
      height: size,
      errorBuilder: (_, __, ___) => _initialsWidget(),
    );
  }

  Widget _initialsWidget() {
    return Container(
      width: size,
      height: size,
      color: color,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
