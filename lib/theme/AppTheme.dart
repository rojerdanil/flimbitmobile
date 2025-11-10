import 'package:flutter/material.dart';

class AppTheme {
  // 🎨 Brand Color Palette
  static const Color primaryColor = Color(0xFFFFD700); // Gold
  static const Color backgroundColor = Colors.white;
  static const Color accentColor = Color(0xFFFFF8E1); // Soft gold tint
  static const Color textColor = Colors.black;
  static const Color secondaryText = Colors.black87;
  static const Color shadowColor = Colors.black12;

  // ✨ Extended Theme Colors
  static const Color shimmerBase = Color(0xFFFFECB3); // pale gold
  static const Color shimmerHighlight = Color(0xFFFFF8E1);
  static const Color overlayDark = Colors.black54;
  static const Color blurOverlay = Colors.black38;

  // 🖋️ Text Styles
  static TextStyle get headline1 => const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static TextStyle get headline2 => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: secondaryText,
  );

  static TextStyle get subtitle =>
      const TextStyle(fontSize: 14, color: Colors.black54);

  static TextStyle get goldTitle => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  // 🧱 Theme Configuration
  static ThemeData get themeData {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: primaryColor,
        secondary: primaryColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: accentColor.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }
}
