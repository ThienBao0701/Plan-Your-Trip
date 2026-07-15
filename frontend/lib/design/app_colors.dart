import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const ocean950 = Color(0xFF061527);
  static const ocean900 = Color(0xFF0B1F35);
  static const ocean800 = Color(0xFF103A5C);
  static const ocean700 = Color(0xFF075985);
  static const ocean600 = Color(0xFF0369A1);
  static const ocean500 = Color(0xFF0B75E5);
  static const ocean400 = Color(0xFF2F8CF4);

  static const turquoise600 = Color(0xFF0891B2);
  static const turquoise500 = Color(0xFF12B8C6);
  static const turquoise400 = Color(0xFF22D3EE);
  static const paleCyan = Color(0xFFE8F9FF);

  static const white = Color(0xFFFFFFFF);
  static const cloud = Color(0xFFF5FAFF);
  static const mist = Color(0xFFEAF4FF);
  static const frost = Color(0xFFF8FCFF);

  static const ink = Color(0xFF102033);
  static const textPrimary = ocean950;
  static const textSecondary = Color(0xFF51637A);
  static const textTertiary = Color(0xFF718098);
  static const textInverse = white;

  static const surface = white;
  static const surfaceMuted = Color(0xFFF2F7FC);
  static const surfaceRaised = Color(0xFAFFFFFF);
  static const surfaceOverlay = Color(0xEFFFFFFF);

  static const glass = Color(0xCCFFFFFF);
  static const glassSubtle = Color(0xAFFFFFFF);
  static const glassStroke = Color(0xD9FFFFFF);
  static const glassStrokeSubtle = Color(0x99FFFFFF);

  static const success = Color(0xFF0F9F8E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFE5484D);
  static const info = ocean500;

  static const coral = Color(0xFFFF6B4A);
  static const violet = Color(0xFF7C6DF2);
  static const mint = success;

  static const divider = Color(0xFFD9E4F0);
  static const disabled = Color(0xFFB8C4D3);

  // Backward-compatible aliases used by the existing FE-1 screens.
  static const midnight = ocean950;
  static const slate = textSecondary;
  static const ocean = ocean500;
  static const aqua = turquoise400;
}
