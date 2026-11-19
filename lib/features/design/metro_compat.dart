import 'package:flutter/material.dart';
import 'package:metro_ui/metro_ui.dart';

/// Old ThemeExtension-style accessors on package [MetroThemeData].
extension ShopMetroThemeDataX on MetroThemeData {
  Color get accentColor => colors.accent;
  Color get primaryTextColor => colors.foreground;
  Color get secondaryTextColor => colors.mutedForeground;
  Color get surfaceColor => colors.surface;
  Color get canvasColor => colors.background;
  Color get trackColor => colors.surfaceVariant;
  Color get borderColor => colors.border;
}

/// Lookup Metro theme (package InheritedWidget).
MetroThemeData metroOf(BuildContext context) => MetroTheme.of(context);

/// Push a Metro page route (package API needs [context]).
Route<T> metroRoute<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  MetroPageTransition transition = MetroPageTransition.slideForward,
}) {
  return MetroPageRoute<T>(
    context: context,
    builder: builder,
    transition: transition,
  );
}
