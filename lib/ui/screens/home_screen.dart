import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/app_service.dart';
import '../../services/app_update_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AppService _appService = AppService();
  final AppUpdateService _updateService = AppUpdateService();
  List<AppInfo> _apps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApps();
    
    // Check for GitHub updates silently on startup
    _updateService.checkForUpdates('1.0.0+1');
  }

  Future<void> _loadApps() async {
    try {
      // Timeout after 4 seconds so the UI never hangs indefinitely if the channel is unhandled
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'flutv',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            
            // App Grid / Content Area
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
                                        color: const Color(0xFF222222),
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
    );
  }
}
