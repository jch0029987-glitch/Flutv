import 'package:flutter/services.dart';

class AppInfo {
  final String name;
  final String packageName;
  final String graphicBase64;

  AppInfo({
    required this.name,
    required this.packageName,
    required this.graphicBase64,
  });

  factory AppInfo.fromMap(Map<dynamic, dynamic> map) {
    return AppInfo(
      name: map['name'] ?? '',
      packageName: map['packageName'] ?? '',
      graphicBase64: map['graphicBase64'] ?? '',
    );
  }
}

class AppService {
  static const MethodChannel _channel = MethodChannel('com.flutv.flutv/apps');

  Future<List<AppInfo>> getInstalledApps() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getInstalledApps');
      return result.map((app) => AppInfo.fromMap(app)).toList();
    } on PlatformException catch (_) {
      return [];
    }
  }

  Future<void> launchApp(String packageName) async {
    try {
      await _channel.invokeMethod('launchApp', {'packageName': packageName});
    } on PlatformException catch (_) {
      // Handle launch error if needed
    }
  }
}
