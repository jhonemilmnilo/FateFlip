import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/theme.dart';
import 'features/toss/toss_screen.dart';

/// Provider for pre-initialized SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden before runApp');
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Strict Portrait Lock (spec rule 19)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Pre-load SharedPreferences before runApp (spec rule 17)
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const FateFlipApp(),
    ),
  );
}

class FateFlipApp extends StatelessWidget {
  const FateFlipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fate Flip',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const TossScreen(),
    );
  }
}
