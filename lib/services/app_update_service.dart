import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:convert';

class AppUpdateService {
  static const String _repoOwner = 'jch0029987-glitch';
  static const String _repoName = 'flutv';

  // Optional progress callback so background checks (like on HomeScreen) 
  // still work seamlessly without breaking.
  Future<void> checkForUpdates(
    String currentVersion, {
    Function(double progress, String statusText)? onProgress,
  }) async {
    try {
      onProgress?.call(0.0, 'Checking for updates...');
      final url = Uri.parse(
        'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String latestTag = data['tag_name'] ?? '';

        if (latestTag.isNotEmpty && latestTag != 'v$currentVersion') {
          onProgress?.call(0.0, 'New version found ($latestTag). Preparing download...');
          final assets = data['assets'] as List;
          final apkAsset = assets.firstWhere(
            (asset) => asset['name'].toString().endsWith('.apk'),
            orElse: () => null,
          );

          if (apkAsset != null) {
            final String downloadUrl = apkAsset['browser_download_url'];
            await _downloadAndInstall(downloadUrl, onProgress);
          } else {
            onProgress?.call(1.0, 'No APK asset found in release.');
          }
        } else {
          onProgress?.call(1.0, 'App is already up to date.');
        }
      } else {
        onProgress?.call(1.0, 'Failed to check for updates.');
      }
    } catch (e) {
      onProgress?.call(1.0, 'Update check failed: $e');
    }
  }

  Future<void> _downloadAndInstall(
    String url,
    Function(double progress, String statusText)? onProgress,
  ) async {
    try {
      final request = http.Request('GET', Uri.parse(url));
      final streamedResponse = await http.Client().send(request);

      if (streamedResponse.statusCode == 200) {
        final contentLength = streamedResponse.contentLength ?? 0;
        final dir = await getExternalStorageDirectory();
        if (dir == null) return;

        final filePath = '${dir.path}/update.apk';
        final file = File(filePath);
        
        final sink = file.openWrite();
        int downloadedBytes = 0;

        await streamedResponse.stream.forEach((chunk) {
          sink.add(chunk);
          downloadedBytes += chunk.length;
          
          if (contentLength > 0) {
            double progress = downloadedBytes / contentLength;
            onProgress?.call(progress, 'Downloading update...');
          }
        });

        await sink.flush();
        await sink.close();

        onProgress?.call(1.0, 'Download complete! Opening installer...');
        await OpenFilex.open(filePath);
      }
    } catch (e) {
      onProgress?.call(1.0, 'Download failed: $e');
    }
  }
}
