import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_android_package_installer/flutter_android_package_installer.dart';
import 'dart:convert';

class AppUpdateService {
  // Replace with your actual GitHub owner and repo
  static const String _repoOwner = 'jch0029987-glitch';
  static const String _repoName = 'flutv';

  Future<void> checkForUpdates(String currentVersion) async {
    try {
      final url = Uri.parse(
        'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String latestTag = data['tag_name'] ?? '';

        // Simple tag comparison (e.g., comparing "v1.0.1" against current version)
        if (latestTag.isNotEmpty && latestTag != 'v$currentVersion') {
          // Find the APK asset URL from the release
          final assets = data['assets'] as List;
          final apkAsset = assets.firstWhere(
            (asset) => asset['name'].toString().endsWith('.apk'),
            orElse: () => null,
          );

          if (apkAsset != null) {
            final String downloadUrl = apkAsset['browser_download_url'];
            await _downloadAndInstall(downloadUrl);
          }
        }
      }
    } catch (e) {
      // Fail silently on network or parse errors during startup check
    }
  }

  Future<void> _downloadAndInstall(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dir = await getExternalStorageDirectory();
        if (dir == null) return;

        final filePath = '${dir.path}/update.apk';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Trigger installation using the correct package reference
        await FlutterAndroidPackageInstaller.installApk(filePath: filePath);
      }
    } catch (e) {
      // Handle download or installation exception if necessary
    }
  }
}
