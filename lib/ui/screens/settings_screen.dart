import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/app_update_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppUpdateService _updateService = AppUpdateService();
  final TextEditingController _wallpaperController = TextEditingController();
  bool _isCheckingUpdate = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _wallpaperController.text = prefs.getString('custom_wallpaper') ?? '';
    });
  }

  Future<void> _saveWallpaper(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_wallpaper', path);
    setState(() {
      _statusMessage = 'Wallpaper saved successfully!';
    });
  }

  Future<void> _manualUpdateCheck() async {
    setState(() {
      _isCheckingUpdate = true;
      _statusMessage = 'Checking for updates...';
    });

    try {
      // Corrected to call checkForUpdates with the progress callback
      await _updateService.checkForUpdates('1.0.0+1', onProgress: (progress, statusText) {
        if (!mounted) return;
        setState(() {
          int percent = (progress * 100).toInt();
          _statusMessage = percent > 0 ? '$statusText ($percent%)' : statusText;
        });
      });

      setState(() {
        _statusMessage = 'Update process completed.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Failed to check or download update: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Launcher Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: ListView(
          children: [
            const Text('System & Updates', style: TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildTvButton(
              label: _isCheckingUpdate ? 'Processing Update...' : 'Check for GitHub Updates',
              onPressed: _isCheckingUpdate ? null : _manualUpdateCheck,
            ),
            const SizedBox(height: 30),
            const Text('Custom Background', style: TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _wallpaperController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter Image URL or File Path',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF222222),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            _buildTvButton(
              label: 'Save Wallpaper',
              onPressed: () => _saveWallpaper(_wallpaperController.text.trim()),
            ),
            const SizedBox(height: 30),
            if (_statusMessage.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 14),
                  ),
                  if (_isCheckingUpdate) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTvButton({required String label, required VoidCallback? onPressed}) {
    return Focus(
      child: Builder(
        builder: (context) {
          final bool isFocused = Focus.of(context).hasFocus;
          return InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: isFocused ? Colors.blue : const Color(0xFF222222),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isFocused ? Colors.white : Colors.transparent, width: 2),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: isFocused ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
