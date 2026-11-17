import 'package:flutter/material.dart';

/// Shared spacing scale and reusable paddings so every screen uses the
/// same rhythm: 16 between sections, 24 inside sheets, 32 for empty states.
abstract class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Horizontal inset for page-level content.
  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: lg);

  /// Padding inside modal bottom sheets (add view insets on the bottom).
  static const EdgeInsets sheet = EdgeInsets.fromLTRB(xl, sm, xl, lg);

  /// Uniform inner padding for cards and chip-like surfaces.
  static const EdgeInsets card = EdgeInsets.all(lg);
}
