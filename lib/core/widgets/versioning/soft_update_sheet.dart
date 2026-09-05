import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/app_version_service.dart';
import '../../services/apk_download_installer.dart';

/// Dismissible bottom sheet recommending soft updates (Tier 2).
class SoftUpdateSheet extends StatefulWidget {
  final VersionCheckResult checkResult;

  const SoftUpdateSheet({
    super.key,
    required this.checkResult,
  });

  /// Static helper to display the sheet
  static Future<void> show(BuildContext context, VersionCheckResult checkResult) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SoftUpdateSheet(checkResult: checkResult),
    );
  }

  @override
  State<SoftUpdateSheet> createState() => _SoftUpdateSheetState();
}

class _SoftUpdateSheetState extends State<SoftUpdateSheet> {
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
    final releaseNotes = remote?.releaseNotes ??
        'Check out the latest features, improved itinerary planning, and performance boosts.';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.sand,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Update Available',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontHeading,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Version $latestVer is ready to install',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Release Notes Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.amber),
                    SizedBox(width: 6),
                    Text(
                      "What's New:",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
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

          const SizedBox(height: 20),

          // Download Progress if in-flight
          if (_isDownloading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _downloadProgress.progress > 0 ? _downloadProgress.progress : null,
                backgroundColor: AppColors.surfaceLight,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _downloadProgress.totalBytes > 0
                  ? '${(_downloadProgress.progress * 100).toStringAsFixed(0)}% • ${(_downloadProgress.receivedBytes / 1024 / 1024).toStringAsFixed(1)} MB / ${(_downloadProgress.totalBytes / 1024 / 1024).toStringAsFixed(1)} MB'
                  : 'Preparing download...',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.warmMuted,
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _isDownloading ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Later',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warmMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isDownloading ? null : _triggerUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isDownloading ? Icons.hourglass_top_rounded : Icons.download_rounded,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isDownloading ? 'Downloading...' : 'Update Now',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
