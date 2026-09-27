import 'package:flutter/material.dart';
import '../../models/whats_new_model.dart';
import '../../services/apk_download_installer.dart';
import '../../services/app_version_service.dart';
import '../../services/whats_new_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Operational mode for the What's New presentation.
enum WhatsNewMode {
  /// Post-update celebration or on-demand changelog review for current app version.
  whatsNew,

  /// Pre-update announcement with direct OTA installation capability.
  updateAvailable,
}

/// Rich interactive dialog/sheet showcasing release highlights, new features,
/// and changelog details for Tara Travel.
class WhatsNewDialog extends StatefulWidget {
  final WhatsNewMode mode;
  final VersionCheckResult? checkResult;
  final SemanticVersion? versionOverride;
  final VoidCallback? onDismiss;

  const WhatsNewDialog({
    super.key,
    this.mode = WhatsNewMode.whatsNew,
    this.checkResult,
    this.versionOverride,
    this.onDismiss,
  });

  /// Displays the What's New modal sheet with smooth drag handles and backdrop.
  static Future<void> showSheet(
    BuildContext context, {
    WhatsNewMode mode = WhatsNewMode.whatsNew,
    VersionCheckResult? checkResult,
    SemanticVersion? versionOverride,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WhatsNewDialog(
        mode: mode,
        checkResult: checkResult,
        versionOverride: versionOverride,
      ),
    );
  }

  /// Displays the What's New modal as an elevated centered dialog.
  static Future<void> show(
    BuildContext context, {
    WhatsNewMode mode = WhatsNewMode.whatsNew,
    VersionCheckResult? checkResult,
    SemanticVersion? versionOverride,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: mode == WhatsNewMode.whatsNew,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: WhatsNewDialog(
          mode: mode,
          checkResult: checkResult,
          versionOverride: versionOverride,
        ),
      ),
    );
  }

  @override
  State<WhatsNewDialog> createState() => _WhatsNewDialogState();
}

class _WhatsNewDialogState extends State<WhatsNewDialog> {
  final ApkDownloadInstaller _installer = const ApkDownloadInstaller();
  final WhatsNewService _whatsNewService = WhatsNewService();

  DownloadProgress _downloadProgress = DownloadProgress.initial;
  bool _isDownloading = false;
  WhatsNewCategory? _selectedCategoryFilter;

  late final ReleaseNotesData _releaseNotes;
  late final SemanticVersion _targetVersion;

  @override
  void initState() {
    super.initState();
    _resolveVersionData();
  }

  void _resolveVersionData() {
    if (widget.mode == WhatsNewMode.updateAvailable && widget.checkResult?.remoteConfig != null) {
      final remote = widget.checkResult!.remoteConfig!;
      _targetVersion = remote.latestVersion;
      _releaseNotes = _whatsNewService.getReleaseNotes(
        version: _targetVersion,
        rawNotes: remote.releaseNotes,
        releaseDate: remote.createdAt,
      );
    } else {
      _targetVersion = widget.versionOverride ??
          widget.checkResult?.currentVersion ??
          SemanticVersion.parse(AppVersionService.currentAppVersionString);
      final rawNotes = widget.checkResult?.remoteConfig?.releaseNotes;
      _releaseNotes = _whatsNewService.getReleaseNotes(
        version: _targetVersion,
        rawNotes: rawNotes,
      );
    }
  }

  Future<void> _handleAcknowledge() async {
    await _whatsNewService.markCurrentVersionSeen(version: _targetVersion);
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      widget.onDismiss?.call();
    }
  }

  Future<void> _handleSnooze() async {
    await _whatsNewService.snoozeUpdatePrompt(
      targetVersion: _targetVersion.toString(),
      duration: const Duration(hours: 24),
    );
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      widget.onDismiss?.call();
    }
  }

  Future<void> _triggerOtaUpdate() async {
    final downloadUrl = widget.checkResult?.remoteConfig?.forceUpdateUrl ??
        'https://tara-travel.app/download/android';

    setState(() {
      _isDownloading = true;
      _downloadProgress = DownloadProgress.initial;
    });

    await _installer.startUpdate(
      downloadUrl: downloadUrl,
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
    final isUpdateMode = widget.mode == WhatsNewMode.updateAvailable;
    final filteredItems = _selectedCategoryFilter == null
        ? _releaseNotes.items
        : _releaseNotes.items
            .where((item) => item.category == _selectedCategoryFilter)
            .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
        maxWidth: 520,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle / Top Spacing
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Surface
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Icon Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isUpdateMode
                          ? const [AppColors.amber, AppColors.primary]
                          : const [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (isUpdateMode ? AppColors.amber : AppColors.primary)
                            .withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      isUpdateMode
                          ? Icons.rocket_launch_rounded
                          : Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Title, Badge, and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              isUpdateMode ? 'Update Ready' : "What's New in Tara",
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontHeading,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.sand,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'v${_targetVersion.displayVersion}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isUpdateMode
                            ? 'A new version is available with new features and performance enhancements.'
                            : _releaseNotes.tagline,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),

                // Close button (for non-critical views)
                if (!isUpdateMode)
                  GestureDetector(
                    onTap: _handleAcknowledge,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.warmMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Category Quick-Filter Bar
          if (_releaseNotes.items.length > 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'All (${_releaseNotes.items.length})',
                      isSelected: _selectedCategoryFilter == null,
                      onTap: () => setState(() => _selectedCategoryFilter = null),
                    ),
                    const SizedBox(width: 8),
                    ...WhatsNewCategory.values.where((cat) {
                      return _releaseNotes.items.any((item) => item.category == cat);
                    }).map((cat) {
                      final count =
                          _releaseNotes.items.where((i) => i.category == cat).length;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFilterChip(
                          label: '${cat.label} ($count)',
                          isSelected: _selectedCategoryFilter == cat,
                          badgeColor: cat.color,
                          onTap: () => setState(() {
                            _selectedCategoryFilter =
                                _selectedCategoryFilter == cat ? null : cat;
                          }),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

          const Divider(height: 16, color: AppColors.cardBorder),

          // Scrollable Feature List
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: filteredItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return _buildFeatureCard(item);
              },
            ),
          ),

          // Download Progress Bar (When OTA update is actively downloading)
          if (_isDownloading)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _downloadProgress.progress > 0
                          ? _downloadProgress.progress
                          : null,
                      backgroundColor: AppColors.sand,
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
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

          // Action Buttons Footer
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              MediaQuery.of(context).padding.bottom > 0
                  ? MediaQuery.of(context).padding.bottom + 8
                  : 18,
            ),
            child: Row(
              children: [
                if (isUpdateMode) ...[
                  // Snooze / Later button
                  Expanded(
                    child: TextButton(
                      onPressed: _isDownloading ? null : _handleSnooze,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Remind Later',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warmMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Primary Update Button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isDownloading ? null : _triggerOtaUpdate,
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
                            _isDownloading
                                ? Icons.hourglass_top_rounded
                                : Icons.download_rounded,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isDownloading ? 'Installing...' : 'Update Now',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Post-update primary button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleAcknowledge,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            "Awesome, Let's Explore",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
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
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? badgeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeColor != null && !isSelected) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(WhatsNewItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Icon Box
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.category.bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item.effectiveIcon,
              size: 20,
              color: item.category.color,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: item.category.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.category.label,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: item.category.textColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    if (item.highlightTag != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.amberLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.highlightTag!,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.amberText,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
