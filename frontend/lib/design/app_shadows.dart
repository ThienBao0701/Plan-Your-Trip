import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppShadows {
  const AppShadows._();

  static List<BoxShadow> get soft => [
        BoxShadow(
          color: AppColors.ocean800.withValues(alpha: .08),
          blurRadius: 24,
          offset: const Offset(0, 14),
        ),
      ];

  static List<BoxShadow> get medium => [
        BoxShadow(
          color: AppColors.ocean800.withValues(alpha: .12),
          blurRadius: 34,
          offset: const Offset(0, 18),
        ),
      ];

  static List<BoxShadow> get nav => [
        BoxShadow(
          color: AppColors.ocean800.withValues(alpha: .10),
          blurRadius: 28,
          offset: const Offset(0, -8),
        ),
      ];
}
