import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.font,
      textTheme: AppTypography.textTheme,
      colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.ocean, brightness: Brightness.light),
      scaffoldBackgroundColor: AppColors.cloud,
      appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.midnight),
      inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white.withValues(alpha: .72)),
    );
  }
}
