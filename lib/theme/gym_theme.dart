import 'package:flutter/material.dart';

class GymTheme {
  static const Color backgroundDark = Color(0xFF121214);
  static const Color surfaceDark = Color(0xFF1A1A1E);
  static const Color primaryBlue = Color(0xFF2F66F6);
  static const Color accentGreen = Color(0xFF00E676);
  static const Color statusCancel = Color(0xFFEF5350);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFF8A8A8E);

  static ThemeData get themeData {
    return ThemeData(
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: primaryBlue,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: accentGreen,
        surface: surfaceDark,
      ),
      fontFamily: 'Roboto',
    );
  }
}