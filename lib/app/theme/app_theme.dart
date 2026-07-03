import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // EVNEIN Brand Colors — Black & Gold
  static const Color primaryColor = Color(0xFFD4AF37); // Classic Gold
  static const Color secondaryColor = Color(0xFFB8960C); // Deep Gold
  static const Color accentColor = Color(0xFFFFD700); // Bright Gold
  static const Color successColor = Color(0xFF4CAF50); // Green
  static const Color errorColor = Color(0xFFEF476F); // Red
  static const Color warningColor = Color(0xFFFF9800); // Orange

  // Black theme backgrounds
  static const Color darkBg = Color(0xFF0A0A0A); // Pure Black
  static const Color cardDark = Color(0xFF1A1A1A); // Dark Card
  static const Color surfaceDark = Color(0xFF242424); // Slightly lighter
  static const Color lightBg = Color(0xFF121212); // App background

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF); // White
  static const Color textSecondary = Color(0xFFB0B0B0); // Light grey
  static const Color textGold = Color(0xFFD4AF37); // Gold text

  // Divider / border
  static const Color borderColor = Color(0xFF2A2A2A);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      background: lightBg,
      surface: cardDark,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onBackground: textPrimary,
      onSurface: textPrimary,
    ),
    scaffoldBackgroundColor: lightBg,
    textTheme: GoogleFonts.poppinsTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBg,
      foregroundColor: primaryColor,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: primaryColor),
      titleTextStyle: TextStyle(
        color: primaryColor,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    ),
    cardTheme: CardTheme(
      color: cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: borderColor, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceDark,
      labelStyle: const TextStyle(color: textSecondary),
      prefixIconColor: primaryColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkBg,
      selectedItemColor: primaryColor,
      unselectedItemColor: Color(0xFF555555),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerColor: borderColor,
    iconTheme: const IconThemeData(color: primaryColor),
  );

  // Keep dark theme same as light for now
  static ThemeData darkTheme = lightTheme;
}
