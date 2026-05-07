import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFF8F6FF);
  static const primary = Color(0xFF7C6FC4);
  static const primaryDark = Color(0xFF594C9A);
  static const textDark = Color(0xFF1A192E);
  static const textMuted = Color(0xFF8F8BA2);
  static const lightPurple = Color(0xFFEFE9FF);
  static const border = Color(0xFFEAE7F4);
  static const expense = Color(0xFFF06969);
  static const income = Color(0xFF4CAF82);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.background,
        ),
        useMaterial3: true,
      );
}
