import 'package:flutter/material.dart';

class AppMotion {
  const AppMotion._();

  static const fast = Duration(milliseconds: 140);
  static const normal = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 320);
  static const curve = Curves.easeOutCubic;
}
