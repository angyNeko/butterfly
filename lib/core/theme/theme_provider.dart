import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// The modern Riverpod approach uses a Notifier class to manage state
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return ThemeMode.system; // Default to system theme
  }

  void setTheme(ThemeMode mode) {
    state = mode; // Updates the theme and rebuilds the app
  }
}

// Create the provider referencing your new class
final themeModeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);