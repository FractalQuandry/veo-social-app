import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

enum AppColorScheme {
  purple(Color(0xFF6750A4), 'Purple'),
  blue(Color(0xFF1976D2), 'Blue'),
  green(Color(0xFF2E7D32), 'Green'),
  orange(Color(0xFFE65100), 'Orange'),
  pink(Color(0xFFC2185B), 'Pink');

  const AppColorScheme(this.seed, this.label);
  final Color seed;
  final String label;
}

class ThemePreferences {
  final AppThemeMode themeMode;
  final AppColorScheme colorScheme;

  const ThemePreferences({
    this.themeMode = AppThemeMode.dark,
    this.colorScheme = AppColorScheme.purple,
  });

  ThemePreferences copyWith({
    AppThemeMode? themeMode,
    AppColorScheme? colorScheme,
  }) {
    return ThemePreferences(
      themeMode: themeMode ?? this.themeMode,
      colorScheme: colorScheme ?? this.colorScheme,
    );
  }
}

class ThemeController extends StateNotifier<ThemePreferences> {
  ThemeController() : super(const ThemePreferences()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt('theme_mode') ?? 1; // default dark
    final colorSchemeIndex =
        prefs.getInt('color_scheme') ?? 0; // default purple

    state = ThemePreferences(
      themeMode: AppThemeMode.values[themeModeIndex],
      colorScheme: AppColorScheme.values[colorSchemeIndex],
    );
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setColorScheme(AppColorScheme scheme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('color_scheme', scheme.index);
    state = state.copyWith(colorScheme: scheme);
  }

  ThemeData get lightTheme {
    return ThemeData(
      colorSchemeSeed: state.colorScheme.seed,
      brightness: Brightness.light,
      useMaterial3: true,
    );
  }

  ThemeData get darkTheme {
    final base = ThemeData(
      colorSchemeSeed: state.colorScheme.seed,
      brightness: Brightness.dark,
      useMaterial3: true,
    );
    return base.copyWith(
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  ThemeMode get themeMode {
    switch (state.themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemePreferences>((ref) {
  return ThemeController();
});
