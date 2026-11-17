import 'package:any/any.dart';
import 'package:flutter/material.dart';

import '../../commands/initialize_command.dart';
import '../../states/shop_state.dart';
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
    final bootstraped = context.read<ShopState>().bootstraped;
    if (!bootstraped) {
      if (mounted) context(const InitializeCommand());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shop',
      navigatorKey: widget.navigatorKey,
      theme: buildShopTheme(Brightness.light),
      darkTheme: buildShopTheme(Brightness.dark),
      themeMode: context.of<ShopState>().themeMode,
      home: const ShopRootScreen(),
    );
  }
}