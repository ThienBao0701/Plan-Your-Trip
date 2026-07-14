import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  static const font = 'Roboto';

  static TextTheme textTheme = const TextTheme(
    displaySmall: TextStyle(
        fontSize: 38,
        height: 1.05,
        fontWeight: FontWeight.w900,
        color: AppColors.midnight,
        letterSpacing: -1.2),
    headlineMedium: TextStyle(
        fontSize: 28,
        height: 1.12,
        fontWeight: FontWeight.w800,
        color: AppColors.midnight,
        letterSpacing: -0.8),
    titleLarge: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
    titleMedium: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
    bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w500,
        color: AppColors.ink),
    bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: AppColors.slate),
    labelLarge: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
  );
}
