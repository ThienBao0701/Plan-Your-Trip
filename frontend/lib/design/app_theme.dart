import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.ocean,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.ocean,
      onPrimary: AppColors.white,
      secondary: AppColors.turquoise600,
      onSecondary: AppColors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFallback,
      textTheme: AppTypography.textTheme,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.cloud,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.midnight,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.minTouchTarget),
          backgroundColor: AppColors.ocean,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.xl),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.xl),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ocean,
          minimumSize: const Size(
            AppSpacing.minTouchTarget,
            AppSpacing.minTouchTarget,
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(
            AppSpacing.minTouchTarget,
            AppSpacing.minTouchTarget,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: const BorderSide(color: AppColors.ocean, width: 1.4),
        ),
        filled: true,
        fillColor: AppColors.surfaceOverlay,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        side: const BorderSide(color: AppColors.divider),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.ocean,
        circularTrackColor: AppColors.mist,
      ),
      visualDensity: VisualDensity.standard,
    );
  }
}
