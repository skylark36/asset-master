import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors (iOS 26 "Snow Glass" Light Theme)
  static const Color background = Color(0xFFF8FAFC); // Pristine light snow canvas
  static const Color sidebarBackground = Color(0xD9FFFFFF); // Frosted pure white glass
  static const Color cardBg = Color(0x8CFFFFFF); // Translucent snow crystal glass layer
  static const Color glassBorder = Color(0x0D090D1A); // Ultra-refined delicate outline
  
  static const Color primary = Color(0xFF5D5FEF); // Neon Royal Indigo
  static const Color secondary = Color(0xFF00ADB5); // Vivid Teal-Cyan for high contrast in light mode
  
  static const Color success = Color(0xFF10B981); // Emerald Glow
  static const Color error = Color(0xFFE11D48); // Vibrant iOS Rose Red
  static const Color warning = Color(0xFFF59E0B); // Amber Glow
  
  static const Color textPrimary = Color(0xFF0F172A); // Deep Charcoal Midnight Slate
  static const Color textSecondary = Color(0xFF475569); // Muted Slate
  static const Color textMuted = Color(0xFF94A3B8); // Slate Silver Muted

  // Centralized Soft Shadow System (High-blur, no muddy colored glows)
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0x0D000000), // Pure soft overlay shadow 1
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0x04000000), // Pure soft overlay shadow 2
      blurRadius: 40,
      offset: const Offset(0, 20),
    ),
  ];

  // Gradients (iOS 26 High-Vibrancy)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF5D5FEF), Color(0xFF00ADB5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Translucent Frosted Glass Card Shine (Snow Crystal Refraction)
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xF2FFFFFF), Color(0x73FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Modern Premium Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: Color(0xFFFFFFFF),
        error: error,
      ),
      textTheme: ThemeData.light().textTheme.copyWith(
        bodyLarge: const TextStyle(color: textPrimary, fontSize: 14, letterSpacing: -0.2),
        bodyMedium: const TextStyle(color: textSecondary, fontSize: 12, letterSpacing: -0.1),
      ),
      cardTheme: CardThemeData(
        color: Colors.transparent, // Controlled manually via Container and Glass gradients
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: glassBorder, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: glassBorder, width: 1),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: -0.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: -0.2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x0C000000), // Clean dark translucent input fill for light mode
        hintStyle: const TextStyle(color: textSecondary, fontSize: 12),
        labelStyle: const TextStyle(color: textPrimary, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: glassBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: glassBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
  }

  // Alias for seamless backward compatibility
  static ThemeData get darkTheme => lightTheme;

  // Currency helper
  static String getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
      case 'CNY':
        return '¥';
      case 'TWD':
        return 'NT\$';
      case 'CAD':
        return 'C\$';
      case 'AUD':
        return 'A\$';
      case 'HKD':
        return 'HK\$';
      case 'KRW':
        return '₩';
      case 'USD':
      default:
        return '\$';
    }
  }
}
