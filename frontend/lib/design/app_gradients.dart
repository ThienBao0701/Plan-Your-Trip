import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppGradients {
  const AppGradients._();

  static const page = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.frost, AppColors.paleCyan, AppColors.cloud],
  );

  static const oceanAction = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.ocean400, AppColors.ocean500, AppColors.ocean700],
  );

  static const turquoiseAction = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.turquoise400, AppColors.turquoise600],
  );

  static const glassSurface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xEFFFFFFF), Color(0xBFFFFFFF)],
  );
}
