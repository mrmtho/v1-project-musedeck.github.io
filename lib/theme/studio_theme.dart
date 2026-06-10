import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StudioTheme {
  // Color Palette
  static const Color background = Color(0xFF111318);
  static const Color primaryPanel = Color(0xFF1A1E25);
  static const Color secondaryPanel = Color(0xFF222833);
  static const Color gridLines = Color(0xFF2F3542);
  static const Color accent = Color(0xFF4D8DFF);
  static const Color success = Color(0xFF3DDC84);
  static const Color record = Color(0xFFFF4D5A);
  static const Color activeTabIndicator = Color(0xFFFFD700); // Yellow
  static const Color waveform = Color(0xFF62B6FF);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9EA3B0);
  static const Color textMuted = Color(0xFF636975);

  // Border Radius
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;

  // Custom Dark ThemeData
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: accent,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: primaryPanel,
        background: background,
        error: record,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          bodyLarge: TextStyle(color: textPrimary),
          bodyMedium: TextStyle(color: textSecondary),
          titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: gridLines,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
