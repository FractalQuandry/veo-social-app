import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final base = ThemeData(colorSchemeSeed: const Color(0xFF6750A4), brightness: Brightness.dark, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
      textTheme: base.textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
    );
  }
}
