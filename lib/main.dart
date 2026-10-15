import 'package:flutter/material.dart';
import 'screens/executive/home.dart';

void main() => runApp(const RouteSyncApp());

class RouteSyncApp extends StatelessWidget {
  const RouteSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0B6E69),
    );
    return MaterialApp(
      title: 'RouteSync',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7F6),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const ExecutiveHome(),
    );
  }
}
