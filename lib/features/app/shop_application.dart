import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:metro_ui/metro_ui.dart';
import 'package:shop/business/shop_cubit.dart';

import '../../ui/app_theme.dart';
import 'app_router.dart';
import 'shop_root_screen.dart';

class ShopApplication extends StatefulWidget {
  const ShopApplication({super.key, required this.router});

  final AppRouter router;

  @override
  State<ShopApplication> createState() => _ShopApplicationState();
}

class _ShopApplicationState extends State<ShopApplication> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final shop = context.read<ShopCubit>();
      if (!shop.state.bootstraped) {
        shop.initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ShopCubit>().state.themeMode;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shop',
      navigatorKey: widget.router.navigatorKey,
      theme: buildShopTheme(Brightness.light),
      darkTheme: buildShopTheme(Brightness.dark),
      themeMode: themeMode,
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        return MetroTheme(
          data: brightness == Brightness.dark
              ? MetroThemeData.dark(accentColor: MetroColors.cyan)
              : MetroThemeData.light(accentColor: MetroColors.cyan),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const ShopRootScreen(),
    );
  }
}
