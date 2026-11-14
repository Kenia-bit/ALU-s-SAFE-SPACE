import 'package:flutter/material.dart';

class AppThemeProvider with ChangeNotifier {
  // light mode by default
  bool _isLightMode = true;

  bool get isLightMode => _isLightMode;

  // Toggles the theme state back and forth
  void toggleTheme() {
    _isLightMode = !_isLightMode;
    notifyListeners();
  }

  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF1E3A8A),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1E3A8A),
        secondary: Color(0xFF3B82F6),
        surface: Colors.white,
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF1E3A8A),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF3B82F6),
        secondary: Color(0xFF60A5FA),
        surface: Color(0xFF1E293B),
      ),
    );
  }
}