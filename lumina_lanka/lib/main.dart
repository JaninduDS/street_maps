import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dart:io'; // Required for Platform check
import 'package:flutter/foundation.dart'; // Required for kIsWeb check
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/map/presentation/map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🛑 FIX: Only initialize Firebase on supported platforms (Web, Android, iOS)
  // This prevents the crash on Linux/Windows
  if (kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lumina Lanka',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        platform: TargetPlatform.iOS, // Force Apple Design behaviors globally
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A84FF), // iOS System Blue
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        // Apply Inter font globally
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: 'GoogleSansFlex',
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      builder: (context, child) {
        // Enforce smooth iOS-like bouncing scrolling everywhere
        return ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          ),
          child: child!,
        );
      },
      home: const MapScreen(), // Ensure you have imported map_screen.dart
    );
  }
}
