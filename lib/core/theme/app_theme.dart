import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppPalette {
  sage,       // Adaçayı Yeşili & Taze Nane (Default)
  peach,      // Zarif Gül & Pudra (Soft Rose)
  ocean,      // Okyanus Mavisi & Gökyüzü
  lavender,   // Asil Lavanta & Leylak
  earth,      // Sıcak Cappuccino & Latte
  emerald,    // Zümrüt & Turkuaz
  midnight,   // Gece Safiri & Çelik
}

extension AppPaletteExtension on AppPalette {
  String get displayName {
    switch (this) {
      case AppPalette.sage:
        return 'Adaçayı Yeşili';
      case AppPalette.peach:
        return 'Zarif Gül & Pudra';
      case AppPalette.ocean:
        return 'Okyanus Mavisi';
      case AppPalette.lavender:
        return 'Asil Lavanta';
      case AppPalette.earth:
        return 'Sıcak Cappuccino';
      case AppPalette.emerald:
        return 'Zümrüt & Turkuaz';
      case AppPalette.midnight:
        return 'Gece Safiri';
    }
  }

  Color get primaryColor {
    switch (this) {
      case AppPalette.sage:
        return const Color(0xFF2E7D5B); // Modern Forest / Sage
      case AppPalette.peach:
        return const Color(0xFFC05C7E); // Elegant Soft Rose / Berry
      case AppPalette.ocean:
        return const Color(0xFF0284C7); // Vibrant Ocean Blue
      case AppPalette.lavender:
        return const Color(0xFF705697); // Noble Lavender
      case AppPalette.earth:
        return const Color(0xFF6F4E37); // Warm Cappuccino Espresso
      case AppPalette.emerald:
        return const Color(0xFF0F766E); // Deep Teal Emerald
      case AppPalette.midnight:
        return const Color(0xFF1E293B); // Slate Midnight
    }
  }

  Color get secondaryColor {
    switch (this) {
      case AppPalette.sage:
        return const Color(0xFF52B788); // Fresh Mint Green
      case AppPalette.peach:
        return const Color(0xFFE58EA7); // Soft Rose Blossom
      case AppPalette.ocean:
        return const Color(0xFF38BDF8); // Crystal Sky Blue
      case AppPalette.lavender:
        return const Color(0xFFA593C4); // Soft Lilac
      case AppPalette.earth:
        return const Color(0xFFA68A78); // Warm Latte Foam
      case AppPalette.emerald:
        return const Color(0xFF2DD4BF); // Aquamarine Teal
      case AppPalette.midnight:
        return const Color(0xFF64748B); // Cool Steel Slate
    }
  }

  Color get lightBg {
    switch (this) {
      case AppPalette.sage:
        return const Color(0xFFEBF5EE);
      case AppPalette.peach:
        return const Color(0xFFFFF1F2);
      case AppPalette.ocean:
        return const Color(0xFFF0F9FF);
      case AppPalette.lavender:
        return const Color(0xFFF5F3FF);
      case AppPalette.earth:
        return const Color(0xFFF7F3EE);
      case AppPalette.emerald:
        return const Color(0xFFF0FDFA);
      case AppPalette.midnight:
        return const Color(0xFFF8FAFC);
    }
  }
}

class AppTheme {
  // Income / Expense / Cash Transfer colors (Soft & Pleasing)
  static const Color incomeColor = Color(0xFF2E7D32); // Soft Emerald Green
  static const Color incomeBg = Color(0xFFE8F5E9);
  
  static const Color expenseColor = Color(0xFFD32F2F); // Soft Warm Coral
  static const Color expenseBg = Color(0xFFFFEBEE);

  static const Color cashColor = Color(0xFF673AB7); // Soft Purple/Violet for Cash/ATM
  static const Color cashBg = Color(0xFFEDE7F6);

  static const Color bankColor = Color(0xFF1976D2); // Soft Royal Blue
  static const Color bankBg = Color(0xFFE3F2FD);

  // Background & Surfaces (Light)
  static const Color backgroundLight = Color(0xFFF7F9FA);
  static const Color cardSurfaceLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF242A38);
  static const Color textSecondaryLight = Color(0xFF718096);
  static const Color textMutedLight = Color(0xFFA0AEC0);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color dividerLight = Color(0xFFEDF2F7);

  // Background & Surfaces (Dark Soft)
  static const Color backgroundDark = Color(0xFF161A23);
  static const Color cardSurfaceDark = Color(0xFF1E2330);
  static const Color textPrimaryDark = Color(0xFFF0F4F8);
  static const Color textSecondaryDark = Color(0xFFA0AEC0);
  static const Color textMutedDark = Color(0xFF718096);
  static const Color borderDark = Color(0xFF2D3748);
  static const Color dividerDark = Color(0xFF262C3D);

  // Fallback direct references
  static const Color primary = Color(0xFF2E7D5B);
  static const Color primaryLight = Color(0xFFEBF5EE);
  static const Color primaryDark = Color(0xFF1B4D36);
  static const Color secondary = Color(0xFF52B788);
  static const Color border = borderLight;
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color textMuted = textMutedLight;
  static const Color divider = dividerLight;
  static const Color cardSurface = cardSurfaceLight;

  static ThemeData getTheme({
    AppPalette palette = AppPalette.sage,
    bool isDarkMode = false,
  }) {
    final primaryCol = palette.primaryColor;
    final secondaryCol = palette.secondaryColor;
    final bg = isDarkMode ? backgroundDark : backgroundLight;
    final cardSurfaceCol = isDarkMode ? cardSurfaceDark : cardSurfaceLight;
    final textPrimaryCol = isDarkMode ? textPrimaryDark : textPrimaryLight;
    final textSecondaryCol = isDarkMode ? textSecondaryDark : textSecondaryLight;
    final textMutedCol = isDarkMode ? textMutedDark : textMutedLight;
    final borderCol = isDarkMode ? borderDark : borderLight;

    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(
      isDarkMode ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bg,
      primaryColor: primaryCol,
      colorScheme: ColorScheme(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        primary: primaryCol,
        onPrimary: Colors.white,
        secondary: secondaryCol,
        onSecondary: Colors.white,
        surface: cardSurfaceCol,
        onSurface: textPrimaryCol,
        error: expenseColor,
        onError: Colors.white,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          color: textPrimaryCol,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: textPrimaryCol,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: textPrimaryCol,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: textPrimaryCol,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: textPrimaryCol,
          fontSize: 16,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: textSecondaryCol,
          fontSize: 14,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: textMutedCol,
          fontSize: 12,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimaryCol),
        titleTextStyle: TextStyle(
          color: textPrimaryCol,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardSurfaceCol,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderCol, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryCol,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimaryCol,
          side: BorderSide(color: borderCol, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardSurfaceCol,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderCol, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderCol, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryCol, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: expenseColor, width: 1.5),
        ),
        hintStyle: TextStyle(color: textMutedCol, fontSize: 14),
        labelStyle: TextStyle(color: textSecondaryCol, fontSize: 14),
      ),
    );
  }
}
