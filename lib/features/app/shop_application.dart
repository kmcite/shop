import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shop/business/shop_cubit.dart';

import '../../ui/app_theme.dart';
import 'shop_root_screen.dart';

class ShopApplication extends StatefulWidget {
  const ShopApplication({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

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
      navigatorKey: widget.navigatorKey,
      theme: buildShopTheme(Brightness.light),
      darkTheme: buildShopTheme(Brightness.dark),
      themeMode: themeMode,
      home: const ShopRootScreen(),
    );
  }
}