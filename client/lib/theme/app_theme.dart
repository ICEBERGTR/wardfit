import 'package:flutter/material.dart';

class AppColors {
  // Core brand palette from UI mockups
  static const Color background = Color(0xFFF8F9F8);
  static const Color primaryGreen = Color(0xFF0E3A23);
  static const Color hangerGreen = Color(0xFF1E493B);
  static const Color splashGreen = Color(0xFF0A7D28);
  static const Color limeAccent = Color(0xFF8CE54D);
  static const Color limeBright = Color(0xFFA5F257);

  // Neutral surfaces & text
  static const Color cardWhite = Colors.white;
  static const Color textDark = Color(0xFF222222);
  static const Color textMuted = Color(0xFF7A7D7A);
  static const Color settingsTileDark = Color(0xFF3E3F3E);
  static const Color saveButtonGrey = Color(0xFF434543);
  static const Color previewGrey = Color(0xFFDADADA);

  // Calendar & Chatbot accents
  static const Color coralPill = Color(0xFFFF745C);
  static const Color bluePill = Color(0xFF5AB0FF);
  static const Color sageCircle = Color(0xFFA8CE93);
  static const Color timelineLine = Color(0xFFF5A642);
  static const Color botNavy = Color(0xFF173B8A);
  static const Color botBubbleBlue = Color(0xFF0095FF);
}

class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        primary: AppColors.primaryGreen,
        secondary: AppColors.limeAccent,
        surface: Colors.white,
      ),
      fontFamily: 'Segoe UI',
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF141815),
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: AppColors.limeAccent,
        primary: AppColors.limeAccent,
        secondary: AppColors.primaryGreen,
      ),
      fontFamily: 'Segoe UI',
    );
  }
}
