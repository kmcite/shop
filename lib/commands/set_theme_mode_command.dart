import 'dart:async';

import 'package:any/any.dart';
import 'package:flutter/material.dart';

import '../states/shop_state.dart';

/// Switches between light and dark themes from the app bar toggle.
class SetThemeModeCommand extends Command {
  const SetThemeModeCommand(this.mode);

  final ThemeMode mode;

  @override
  FutureOr<void> call(Ref ref) {
    ref<ShopState>((s) => s.copyWith(themeMode: mode));
  }
}