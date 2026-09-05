import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/app_version_service.dart';
import '../../services/apk_download_installer.dart';

/// Non-dismissible full-screen gate for mandatory app updates (Tier 1).
class ForceUpdateScreen extends StatefulWidget {
  final VersionCheckResult checkResult;

  const ForceUpdateScreen({
    super.key,
    required this.checkResult,
  });

  @override
  State<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<ForceUpdateScreen> {
  final ApkDownloadInstaller _installer = ApkDownloadInstaller();
  DownloadProgress _downloadProgress = DownloadProgress.initial;
  bool _isDownloading = false;

  Future<void> _triggerUpdate() async {
    final url = widget.checkResult.remoteConfig?.forceUpdateUrl ??
        'https://tara-travel.app/download/android';

    setState(() {
      _isDownloading = true;
      _downloadProgress = DownloadProgress.initial;
    });

    await _installer.startUpdate(
      downloadUrl: url,
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _downloadProgress = progress;
            if (progress.isCompleted || progress.error != null) {
              _isDownloading = false;
            }
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final remote = widget.checkResult.remoteConfig;
    final latestVer = remote?.latestVersion.toString() ?? 'Latest';
    final currentVer = widget.checkResult.currentVersion.toString();
    final releaseNotes = remote?.releaseNotes ??
        'A critical update is required to keep Tara Travel running securely with new platform features and database migrations.';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Badge Icon
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.system_update_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Pill Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.sand,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      'MANDATORY UPDATE REQUIRED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Heading
                  const Text(
                    'Time to Update',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontHeading,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Your current version (v$currentVer) is no longer supported. Please update to v$latestVer to continue your journeys worry-free.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Release Notes Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.amber),
                            SizedBox(width: 8),
                            Text(
                              "What's New in This Version",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          releaseNotes,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Progress indicator if downloading
                  if (_isDownloading) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _downloadProgress.progress > 0 ? _downloadProgress.progress : null,
                        backgroundColor: AppColors.surfaceLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _downloadProgress.totalBytes > 0
                          ? '${(_downloadProgress.progress * 100).toStringAsFixed(0)}% • ${(_downloadProgress.receivedBytes / 1024 / 1024).toStringAsFixed(1)} MB / ${(_downloadProgress.totalBytes / 1024 / 1024).toStringAsFixed(1)} MB'
                          : 'Preparing download...',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warmMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_downloadProgress.error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF87171)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Download failed. Tap update to try external browser.',
                              style: TextStyle(fontSize: 11, color: Color(0xFFDC2626)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isDownloading ? null : _triggerUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isDownloading ? Icons.hourglass_top_rounded : Icons.download_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isDownloading ? 'Downloading Update...' : 'Update App Now',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
