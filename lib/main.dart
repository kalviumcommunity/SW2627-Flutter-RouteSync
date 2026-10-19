import 'package:flutter/material.dart';
import 'package:routesync/screens/dispatcher/home.dart';

void main() {
  runApp(const RouteSyncApp());
}

class RouteSyncApp extends StatelessWidget {
  const RouteSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF176B87),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'RouteSync Dispatcher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F8FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF6F8FA),
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE8EDF0)),
          ),
        ),
      ),
      home: const DispatcherHome(),
    );
  }
}
