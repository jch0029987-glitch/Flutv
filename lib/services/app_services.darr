import 'package:flutter/services.dart';

class AppInfo {
  final String name;
  final String packageName;
  final String graphicBase64;

  AppInfo({required this.name, required this.packageName, required this.graphicBase64});

  factory AppInfo.fromMap(Map<dynamic, dynamic> map) {
    return AppInfo(
      name: map['name'] ?? '',
      packageName: map['packageName'] ?? '',
      graphicBase64: map['graphic'] ?? '',
    );
  }
}

class AppService {
  static const platform = MethodChannel('com.flutv/apps');

  Future<List<AppInfo>> getInstalledApps() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getInstalledApps');
      return result.map((app) => AppInfo.fromMap(app)).toList();
    } on PlatformException catch (e) {
      print("Failed to get installed apps: '${e.message}'.");
      return [];
    }
  }

  Future<bool> launchApp(String packageName) async {
    try {
      final bool result = await platform.invokeMethod('launchApp', {'packageName': packageName});
      return result;
    } on PlatformException catch (e) {
      print("Failed to launch app: '${e.message}'.");
      return false;
    }
  }
}
