import 'package:flutter/material.dart';

/// Shop type helpers for panorama / hub titles (not in package typography ramp).
abstract final class ShopMetroTypography {
  static const fontFamily = 'Segoe UI';

  static TextStyle panoramaTitle(Color color) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 72,
        fontWeight: FontWeight.w200,
        height: 1.0,
        letterSpacing: -1.0,
        color: color,
      );

  static TextStyle sectionHeader(Color color) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 36,
        fontWeight: FontWeight.w300,
        height: 1.1,
        color: color,
      );
}
