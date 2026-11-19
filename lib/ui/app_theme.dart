import 'package:flutter/material.dart';
import 'package:metro_ui/metro_ui.dart';

/// Builds a minimal Material [ThemeData] from Metro color tokens for Scaffold /
/// AppBar / Icons while Metro widgets read [MetroTheme].
ThemeData buildShopTheme(
  Brightness brightness, {
  Color accentColor = MetroColors.cyan,
}) {
  final metro = brightness == Brightness.dark
      ? MetroThemeData.dark(accentColor: accentColor)
      : MetroThemeData.light(accentColor: accentColor);
  final colors = metro.colors;
  final isDark = brightness == Brightness.dark;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: colors.accent,
    onPrimary: colors.onAccent,
    secondary: colors.accent,
    onSecondary: colors.onAccent,
    error: colors.error,
    onError: colors.onAccent,
    surface: colors.background,
    onSurface: colors.foreground,
    surfaceContainerHighest: colors.surfaceVariant,
    outline: colors.border,
    outlineVariant: colors.border.withValues(alpha: 0.45),
  );

  final textTheme = TextTheme(
    displayLarge: metro.typography.hero,
    displayMedium: metro.typography.header,
    displaySmall: metro.typography.header,
    headlineMedium: metro.typography.subheader,
    headlineSmall: metro.typography.subheader,
    titleLarge: metro.typography.title,
    titleMedium: metro.typography.bodyStrong,
    titleSmall: metro.typography.bodyStrong,
    bodyLarge: metro.typography.body,
    bodyMedium: metro.typography.body,
    bodySmall: metro.typography.caption,
    labelLarge: metro.typography.button,
    labelMedium: metro.typography.caption,
    labelSmall: metro.typography.caption,
  );

  return ThemeData(
    brightness: brightness,
    colorScheme: scheme,
    textTheme: textTheme,
    useMaterial3: true,
    splashFactory: NoSplash.splashFactory,
    highlightColor: colors.accent.withValues(alpha: 0.12),
    visualDensity: VisualDensity.compact,
    scaffoldBackgroundColor: colors.background,
    canvasColor: colors.background,
    dividerColor: colors.border.withValues(alpha: 0.45),
    iconTheme: IconThemeData(color: colors.mutedForeground, size: 22),
    primaryIconTheme: IconThemeData(color: colors.accent, size: 22),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colors.background,
      foregroundColor: colors.foreground,
      centerTitle: false,
      titleTextStyle: metro.typography.title,
      iconTheme: IconThemeData(color: colors.foreground),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: DividerThemeData(
      color: colors.border.withValues(alpha: 0.45),
      thickness: 1,
      space: 1,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.accent,
      linearTrackColor: colors.surfaceVariant,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colors.accent,
      foregroundColor: colors.onAccent,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark ? colors.surface : colors.foreground,
      contentTextStyle: metro.typography.body.copyWith(
        color: isDark ? colors.foreground : colors.background,
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
  );
}
