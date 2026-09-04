import 'package:tara_travel/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';

/// Opens the NPC-compliant Privacy Policy & Terms of Service modal bottom sheet.
void showNpcPrivacyPolicySheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const NpcPrivacyPolicySheet(),
  );
}

/// A bottom sheet presenting Tara Travel's Terms and Conditions and Data Privacy
/// Policy in full compliance with Republic Act No. 10173 (Data Privacy Act of 2012)
/// and guidelines established by the National Privacy Commission (NPC) of the Philippines.
class NpcPrivacyPolicySheet extends StatelessWidget {
  const NpcPrivacyPolicySheet({super.key});

  static const String _kNpUrl = 'https://privacy.gov.ph';

  Future<void> _launchNpcWebsite() async {
    final uri = Uri.parse(_kNpUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[NpcPrivacyPolicySheet] Could not launch NPC URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.warmMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Terms & Data Privacy Policy',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontHeading,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Republic Act No. 10173 (DPA of 2012) • NPC Compliant',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.warmMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.cardBorder),

          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Official NPC Banner Callout
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified_user_rounded,
                                color: Color(0xFF10B981), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'National Privacy Commission Compliance',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tara Travel strictly adheres to the data privacy principles of Transparency, Legitimate Purpose, and Proportionality as mandated by the National Privacy Commission of the Philippines (NPC).',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _launchNpcWebsite,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Visit Official NPC Website (privacy.gov.ph)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.open_in_new_rounded,
                                  size: 13, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  _buildSection(
                    title: '1. Collection of Personal Data',
                    content:
                        'When registering or signing in via Google, Tara Travel collects:\n'
                        '• Basic Identity: Full Name, Google Email Address, and Avatar image.\n'
                        '• Travel & Trip Data: Itinerary stops, packing lists, expense records, and chat messages created within trips.\n'
                        '• Sensitive Personal Information (Opt-in): Blood type, allergies, emergency health notes, and GCash contact numbers. These are encrypted client-side using AES-256 before storage and are private by default.\n'
                        '• Location Coordinates: GPS tracking is only collected when explicitly enabled for real-time group safety during active trips.',
                  ),

                  _buildSection(
                    title: '2. Purpose of Processing',
                    content:
                        'Your data is processed strictly for:\n'
                        '• Creating and managing your user account and multi-device synchronization.\n'
                        '• Facilitating collaborative group travel planning, split-bill tracking, and offline itinerary caching.\n'
                        '• Providing opt-in emergency health sharing with trip organizers during group excursions.\n'
                        '• Tara Travel does NOT sell, monetize, or disclose your personal information to third-party advertisers.',
                  ),

                  _buildSection(
                    title: '3. Security Measures & Encryption',
                    content:
                        'In compliance with NPC circulars on security of personal data in the government and private sector:\n'
                        '• 3-Layer Client-Side Encryption: Sensitive information is encrypted with AES-256 using keys stored in the Android Keystore.\n'
                        '• Database Security: Row-Level Security (RLS) is strictly enforced on all tables.\n'
                        '• Transport Encryption: All data in transit is encrypted using TLS 1.3/HTTPS.',
                  ),

                  _buildSection(
                    title: '4. Your Rights under Republic Act No. 10173',
                    content:
                        'As a data subject under Section 16 of the Data Privacy Act of 2012, you hold the following rights:\n'
                        '• Right to be Informed: To know how your data is collected and processed.\n'
                        '• Right to Access: To request copies of your stored travel and profile data.\n'
                        '• Right to Rectification: To modify or update inaccurate data at any time via Profile Settings.\n'
                        '• Right to Erasure or Blocking: To permanently delete your account and all associated trip data.\n'
                        '• Right to File a Complaint: You have the right to lodge a complaint with the National Privacy Commission at complaints@privacy.gov.ph or via https://privacy.gov.ph if you believe your privacy rights have been violated.',
                  ),

                  _buildSection(
                    title: '5. Consent & Acceptance',
                    content:
                        'By continuing with Google Sign-In or creating a Tara Travel account, you provide explicit, informed consent for Tara Travel to process your personal data in accordance with this policy and Republic Act No. 10173.',
                  ),

                  const SizedBox(height: 20),

                  // Bottom Close Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'I Understand & Agree',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
