import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/objectbox_service.dart';
import 'core/ui/main_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

// Global Provider for ObjectBox
final objectBoxProvider = Provider<ObjectBoxService>((ref) {
  throw UnimplementedError('ObjectBoxService has not been initialized');
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final objectBoxService = await ObjectBoxService.create();

  runApp(
    ProviderScope(
      overrides: [
        objectBoxProvider.overrideWithValue(objectBoxService),
      ],
      child: const ButterflyApp(),
    ),
  );
}

class ButterflyApp extends ConsumerWidget {
  const ButterflyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the current theme mode
    final currentThemeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Butterfly',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: currentThemeMode, // This is now dynamic
      home: const MainScreen(),
    );
  }
}
