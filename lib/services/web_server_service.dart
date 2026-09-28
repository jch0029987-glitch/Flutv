import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebServerService {
  HttpServer? _server;

  // Replace with your actual GitHub repository owner and name
  static const String _repoOwner = 'jch0029987-glitch';
  static const String _repoName = 'flutv';
  static const String _branch = 'main';

  Future<void> startServer() async {
    if (_server != null) return;

    // 1. Attempt to sync/pull the latest index.html from GitHub first
    await _syncWebUiFromGitHub();

    final router = Router();

    // 2. Serve index.html from local device storage
    router.get('/', (Request request) async {
      try {
        final dir = await getExternalStorageDirectory();
        if (dir == null) return Response.internalServerError(body: 'Storage unavailable');

        final indexFile = File('${dir.path}/www/index.html');
        if (await indexFile.exists()) {
          final content = await indexFile.readAsString();
          return Response.ok(content, headers: {'Content-Type': 'text/html; charset=utf-8'});
        } else {
          return Response.notFound('index.html not found.');
        }
      } catch (e) {
        return Response.internalServerError(body: 'Error loading web root: $e');
      }
    });

    // API endpoint to handle actions from the Web UI (e.g., updating wallpaper)
    router.post('/api/wallpaper', (Request request) async {
      final payload = await request.readAsString();
      final params = Uri.splitQueryString(payload);
      final wallpaperUrl = params['url'] ?? '';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_wallpaper', wallpaperUrl);

      return Response.ok('Wallpaper updated successfully!');
    });

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(router.call);

    try {
      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 8080);
      print('Flutv Web UI running on http://${_server!.address.address}:${_server!.port}');
    } catch (e) {
      print('Failed to start web server: $e');
    }
  }

  // Pulls the latest index.html straight from your GitHub repo raw URL
  Future<void> _syncWebUiFromGitHub() async {
    try {
      final url = Uri.parse(
        'https://raw.githubusercontent.com/$_repoOwner/$_repoName/$_branch/web/index.html',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final dir = await getExternalStorageDirectory();
        if (dir != null) {
          final webDir = Directory('${dir.path}/www');
          if (!await webDir.exists()) {
            await webDir.create(recursive: true);
          }
          
          final indexFile = File('${webDir.path}/index.html');
          await indexFile.writeAsString(response.body);
          print('Successfully synced Web UI from GitHub repository.');
        }
      }
    } catch (e) {
      print('Offline or failed to sync Web UI from GitHub, using cached version: $e');
    }
  }

  Future<void> stopServer() async {
    await _server?.close(force: true);
    _server = null;
  }
}
