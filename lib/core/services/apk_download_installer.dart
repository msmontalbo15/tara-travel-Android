import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// State of an in-flight APK download & installation process.
class DownloadProgress {
  final double progress; // 0.0 to 1.0
  final int receivedBytes;
  final int totalBytes;
  final bool isCompleted;
  final String? error;

  const DownloadProgress({
    required this.progress,
    required this.receivedBytes,
    required this.totalBytes,
    this.isCompleted = false,
    this.error,
  });

  static const initial = DownloadProgress(
    progress: 0.0,
    receivedBytes: 0,
    totalBytes: 0,
  );
}

/// Service for streaming download of Tara Travel release APKs from Supabase Storage
/// and handing off to the Android system package installer.
class ApkDownloadInstaller {
  final Dio _dio;

  ApkDownloadInstaller({Dio? dio}) : _dio = dio ?? Dio();

  /// Downloads an APK to cache and launches the installer or download URL.
  Future<void> startUpdate({
    required String downloadUrl,
    required void Function(DownloadProgress progress) onProgress,
  }) async {
    try {
      if (kIsWeb || !Platform.isAndroid) {
        // Non-Android platforms open web release link directly
        final uri = Uri.parse(downloadUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        onProgress(const DownloadProgress(
          progress: 1.0,
          receivedBytes: 0,
          totalBytes: 0,
          isCompleted: true,
        ));
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/tara_travel_latest.apk';

      // Delete existing cached APK if present
      final existingFile = File(savePath);
      if (await existingFile.exists()) {
        await existingFile.delete();
      }

      await _dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          final p = total > 0 ? (received / total).clamp(0.0, 1.0) : 0.0;
          onProgress(DownloadProgress(
            progress: p,
            receivedBytes: received,
            totalBytes: total,
            isCompleted: received >= total && total > 0,
          ));
        },
      );

      // Attempt to launch installer via URL launcher on the downloaded file or direct URL
      final apkUri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(apkUri)) {
        await launchUrl(apkUri, mode: LaunchMode.externalApplication);
      }

      onProgress(const DownloadProgress(
        progress: 1.0,
        receivedBytes: 0,
        totalBytes: 0,
        isCompleted: true,
      ));
    } catch (e) {
      debugPrint('[ApkDownloadInstaller] Error downloading APK: $e');
      onProgress(DownloadProgress(
        progress: 0.0,
        receivedBytes: 0,
        totalBytes: 0,
        error: e.toString(),
      ));

      // Fallback: Open release URL in external browser
      try {
        final uri = Uri.parse(downloadUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    }
  }
}
