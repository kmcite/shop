import 'package:flutter/material.dart';
import 'package:metro_ui/metro_ui.dart';

/// Spacing aligned with [MetroSpacing].
abstract class AppSpacing {
  AppSpacing._();

  static const double xs = MetroSpacing.xxs;
  static const double sm = MetroSpacing.xs;
  static const double md = MetroSpacing.sm;
  static const double lg = MetroSpacing.lg;
  static const double xl = MetroSpacing.lg;
  static const double xxl = MetroSpacing.xl;

  static const EdgeInsets page =
      EdgeInsets.symmetric(horizontal: MetroSpacing.lg);

  static const EdgeInsets sheet = EdgeInsets.fromLTRB(xl, sm, xl, lg);

  static const EdgeInsets card = EdgeInsets.all(MetroSpacing.sm);
}
