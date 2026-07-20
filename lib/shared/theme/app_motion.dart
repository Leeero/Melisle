import 'package:flutter/animation.dart';

abstract final class AppMotion {
  static const Duration micro = Duration(milliseconds: 200);
  static const Duration short = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration long = Duration(milliseconds: 420);

  static const Curve standard = Curves.easeOut;
  static const Curve enter = Cubic(0.2, 0, 0.13, 1);
  static const Curve exit = Curves.easeIn;
}
