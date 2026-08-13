import 'package:flutter/animation.dart';

abstract final class AppMotion {
  static const Duration hover = Duration(milliseconds: 200);
  static const Duration tap = Duration(milliseconds: 150);
  static const Duration state = Duration(milliseconds: 300);
  static const Duration page = Duration(milliseconds: 320);
  static const Duration sheet = Duration(milliseconds: 300);
  static const Duration overlay = Duration(milliseconds: 420);
  static const Duration lyrics = Duration(milliseconds: 450);

  static const Duration micro = hover;
  static const Duration short = state;
  static const Duration medium = page;
  static const Duration long = overlay;

  static const Curve standard = Curves.easeOut;
  static const Curve enter = Cubic(0.2, 0, 0.13, 1);
  static const Curve exit = Curves.easeIn;
  static const Curve emphasized = Cubic(0.2, 0, 0, 1);
}
