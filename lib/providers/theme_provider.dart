import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  static const String _prefPaletteKey = 'selected_palette';
  static const String _prefDarkModeKey = 'is_dark_mode';

  AppPalette _currentPalette = AppPalette.sage;
  bool _isDarkMode = false;

  AppPalette get currentPalette => _currentPalette;
  bool get isDarkMode => _isDarkMode;

  ThemeData get themeData => AppTheme.getTheme(
    palette: _currentPalette,
    isDarkMode: _isDarkMode,
  );

  Color get primaryColor => _currentPalette.primaryColor;
  Color get lightBg => _currentPalette.lightBg;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final paletteIndex = prefs.getInt(_prefPaletteKey);
      if (paletteIndex != null && paletteIndex >= 0 && paletteIndex < AppPalette.values.length) {
        _currentPalette = AppPalette.values[paletteIndex];
      }
      _isDarkMode = prefs.getBool(_prefDarkModeKey) ?? false;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setPalette(AppPalette palette) async {
    _currentPalette = palette;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefPaletteKey, palette.index);
    } catch (_) {}
  }

  Future<void> toggleDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefDarkModeKey, isDark);
    } catch (_) {}
  }
}
