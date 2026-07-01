import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // EVNEIN Brand Colors
  static const Color primaryColor = Color(0xFFFF6B35); // Vibrant Orange
  static const Color secondaryColor = Color(0xFF2EC4B6); // Fresh Teal
  static const Color accentColor = Color(0xFFFFE66D); // Warm Yellow
  static const Color successColor = Color(0xFF06D6A0); // Green
  static const Color errorColor = Color(0xFFEF476F); // Red
  static const Color darkBg = Color(0xFF1A1A2E); // Dark Background
  static const Color cardDark = Color(0xFF16213E); // Dark Card
  static const Color lightBg = Color(0xFFFAFAFA); // Light Background

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      background: lightBg,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      background: darkBg,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    scaffoldBackgroundColor: darkBg,
    cardColor: cardDark,
  );
}
