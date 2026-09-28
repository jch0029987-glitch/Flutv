import 'package:flutter/material.dart';
import 'ui/screens/home_screen.dart';

class FluTvApp extends StatelessWidget {
  const FluTvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutv',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF111111),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
