import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/app_service.dart';
import '../../services/app_update_service.dart';
import '../../services/web_server_service.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AppService _appService = AppService();
  final AppUpdateService _updateService = AppUpdateService();
  final WebServerService _webServerService = WebServerService();
  
  List<AppInfo> _apps = [];
  bool _isLoading = true;
  String? _wallpaperPath;
  
  // Focus node specifically for the settings button to ensure reliable TV remote interaction
  final FocusNode _settingsFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadData();
    _updateService.checkForUpdates('1.0.0+1');
    _webServerService.startServer();
  }

  @override
  void dispose() {
    _settingsFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _wallpaperPath = prefs.getString('custom_wallpaper');
    });

    try {
      final apps = await _appService.getInstalledApps().timeout(
        const Duration(seconds: 4),
        onTimeout: () => [],
      );
      setState(() {
        _apps = apps;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _apps = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _openSettings(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Wallpaper Background
          if (_wallpaperPath != null && _wallpaperPath!.isNotEmpty)
            Positioned.fill(
              child: _wallpaperPath!.startsWith('http')
                  ? Image.network(_wallpaperPath!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFF121212)))
                  : Image.file(File(_wallpaperPath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFF121212))),
            )
          else
            Positioned.fill(
              child: Container(color: const Color(0xFF121212)),
            ),
          
          // Dark Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.6), Colors.black.withOpacity(0.9)],
                ),
              ),
            ),
          ),

          // Main Layout
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Bar with TV-Optimized Focusable Settings Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'flutv',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Colors.white,
                      ),
                    ),
                    Focus(
                      focusNode: _settingsFocusNode,
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent &&
                            (event.logicalKey == LogicalKeyboardKey.select ||
                             event.logicalKey == LogicalKeyboardKey.enter ||
                             event.logicalKey == LogicalKeyboardKey.space)) {
                          _openSettings(context);
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: Builder(
                        builder: (context) {
                          final bool isFocused = Focus.of(context).hasFocus;
                          return InkWell(
                            onTap: () => _openSettings(context),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isFocused ? Colors.blue : Colors.white24,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isFocused ? Colors.white : Colors.transparent,
                                  width: 2.0,
                                ),
                                boxShadow: isFocused
                                    ? [
                                        const BoxShadow(
                                          color: Colors.blueAccent,
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        )
                                      ]
                                    : [],
                              ),
                              child: const Icon(Icons.settings, color: Colors.white, size: 28),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // App Grid Area
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _apps.isEmpty
                          ? const Center(
                              child: Text(
                                'No apps found',
                                style: TextStyle(fontSize: 18, color: Colors.white60),
                              ),
                            )
                          : GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                childAspectRatio: 16 / 9,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                              ),
                              itemCount: _apps.length,
                              itemBuilder: (context, index) {
                                final app = _apps[index];
                                final decodedBytes = base64Decode(app.graphicBase64);

                                return Focus(
                                  child: Builder(
                                    builder: (BuildContext context) {
                                      final bool isFocused = Focus.of(context).hasFocus;
                                      return InkWell(
                                        onTap: () => _appService.launchApp(app.packageName),
                                        borderRadius: BorderRadius.circular(12),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF222222).withOpacity(0.8),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isFocused ? Colors.blue : Colors.transparent,
                                              width: 3.0,
                                            ),
                                            boxShadow: isFocused
                                                ? [
                                                    const BoxShadow(
                                                      color: Colors.blueAccent,
                                                      blurRadius: 8,
                                                      spreadRadius: 2,
                                                    )
                                                  ]
                                                : [],
                                          ),
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Image.memory(decodedBytes),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                app.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                  fontWeight: isFocused ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
