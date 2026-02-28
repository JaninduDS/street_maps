import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dart:io'; // Required for Platform check
import 'package:flutter/foundation.dart'; // Required for kIsWeb check
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/map/presentation/map_screen.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/theme/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://gnwhjfxtmgqofhpujlem.supabase.co/',
    anonKey: 'sb_publishable_00aBOF1uF__Kod3xjZkGxQ_osPncgTn',
  );

  // 🛑 FIX: Only initialize Firebase on supported platforms (Web, Android, iOS)
  // This prevents the crash on Linux/Windows
  if (kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Lumina Lanka',
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      themeMode: themeMode,               // 1. Listens to the toggle
      theme: AppTheme.lightTheme,         // 2. Uses the new light theme
      darkTheme: AppTheme.darkTheme,      // 3. Uses your existing dark theme
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          ),
          child: child!,
        );
      },
      home: const MapScreen(),
    );
  }
}
