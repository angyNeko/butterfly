import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Core imports
import 'core/database/sembast_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/ui/main_screen.dart';

// Create a global Riverpod Provider for our new Sembast database
final dbProvider = Provider<SembastService>((ref) {
  throw UnimplementedError('SembastService has not been initialized');
});

void main() async {
  // Ensure Flutter engine is fully initialized before doing async work
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize our pure-Dart Sembast database
  final sembastService = await SembastService.create();

  runApp(
    // Wrap app in ProviderScope and pass the initialized database to it
    ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(sembastService),
      ],
      child: const ButterflyApp(),
    ),
  );
}

class ButterflyApp extends ConsumerWidget {
  const ButterflyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the current theme state (System, Light, or Dark)
    final currentThemeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Butterfly',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: currentThemeMode,
      home: const MainScreen(),
    );
  }
}