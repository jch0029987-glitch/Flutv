import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:android_package_installer/android_package_installer.dart';
import 'dart:convert';

class AppUpdateService {
  // Replace with your actual GitHub repo owner and name
  final String repoOwner = 'jch0029987-glitch';
  final String repoName = 'flutv';

  Future<void> checkForUpdates(String currentVersion) async {
    try {
      final url = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/releases/latest');
      final response = await http.get(url, headers: {'Accept': 'application/vnd.github.v3+json'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String latestTag = data['tag_name']; // e.g., "v1.1.0"
        
        if (latestTag != currentVersion && latestTag != 'v$currentVersion') {
          // Find the APK asset download URL
          List assets = data['assets'];
          String? apkUrl;
          for (var asset in assets) {
            if (asset['name'].toString().endsWith('.apk')) {
              apkUrl = asset['browser_download_url'];
              break;
            }
          }

          if (apkUrl != null) {
            await _downloadAndInstall(apkUrl);
          }
        }
      }
    } catch (e) {
      print("Update check failed: $e");
    }
  }

  Future<void> _downloadAndInstall(String apkUrl) async {
    try {
      final response = await http.get(Uri.parse(apkUrl));
      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/update.apk';
        
        File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Trigger native Android package installer
        await AndroidPackageInstaller.installApk(filePath: filePath);
      }
    } catch (e) {
      print("Download/Install failed: $e");
    }
  }
}
