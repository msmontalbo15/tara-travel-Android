import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
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

/// Service for downloading Tara Travel release APKs directly inside the app
/// and immediately launching the native Android package installer.
class ApkDownloadInstaller {
  static const MethodChannel _otaChannel =
      MethodChannel('com.taratravel.app/ota_installer');

  const ApkDownloadInstaller();

  /// Directly streams the APK download to internal cache and hands off to the Android installer.
  Future<void> startUpdate({
    required String downloadUrl,
    required void Function(DownloadProgress progress) onProgress,
  }) async {
    try {
      // Non-Android platforms open web release link directly
      if (kIsWeb || !Platform.isAndroid) {
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

      final cacheDir = await getTemporaryDirectory();
      final saveFile = File('${cacheDir.path}/tara_travel_latest.apk');

      // Purge stale downloaded APK if present
      if (await saveFile.exists()) {
        try {
          await saveFile.delete();
        } catch (_) {}
      }

      onProgress(const DownloadProgress(
        progress: 0.0,
        receivedBytes: 0,
        totalBytes: 0,
      ));

      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await request.send();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Download failed with HTTP status ${response.statusCode}',
          uri: Uri.parse(downloadUrl),
        );
      }

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      final sink = saveFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        final p = totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;
        onProgress(DownloadProgress(
          progress: p,
          receivedBytes: receivedBytes,
          totalBytes: totalBytes,
        ));
      }

      await sink.flush();
      await sink.close();

      onProgress(DownloadProgress(
        progress: 1.0,
        receivedBytes: receivedBytes,
        totalBytes: totalBytes > 0 ? totalBytes : receivedBytes,
        isCompleted: true,
      ));

      // Trigger native Android package installer via FileProvider
      await _otaChannel.invokeMethod('installApk', {
        'filePath': saveFile.path,
      });
    } catch (e) {
      debugPrint('[ApkDownloadInstaller] Error during in-app update: $e');
      onProgress(DownloadProgress(
        progress: 0.0,
        receivedBytes: 0,
        totalBytes: 0,
        error: e.toString(),
      ));

      // Fallback: Open URL in external browser if local installation fails
      try {
        final uri = Uri.parse(downloadUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    }
  }
}
