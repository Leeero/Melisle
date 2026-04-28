import 'package:flutter/animation.dart';

abstract final class AppMotion {
  static const Duration micro = Duration(milliseconds: 150);
  static const Duration short = Duration(milliseconds: 220);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration long = Duration(milliseconds: 420);

  static const Curve standard = Curves.easeInOut;
  static const Curve enter = Curves.easeOut;
  static const Curve exit = Curves.easeIn;
}
