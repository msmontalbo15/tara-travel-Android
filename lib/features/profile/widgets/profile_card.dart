import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ProfileCard extends StatelessWidget {
  final List<Widget> children;

  const ProfileCard({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class ProfileSectionTitle extends StatelessWidget {
  final String title;

  const ProfileSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.warmMuted,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class ProfileDivider extends StatelessWidget {
  const ProfileDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 0.5,
      color: AppColors.dividerLight,
      indent: 14,
      endIndent: 14,
    );
  }
}

class ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ProfileRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: AppColors.warmMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.warmMuted,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.warmMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
