import 'package:any/any.dart';
import 'package:flutter/material.dart';

import '../../states/shop_state.dart';
import '../widgets/database_error_view.dart';
import '../widgets/shop_loading_view.dart';
import 'shop_home_screen.dart';

/// Routes between loading, connection-error and the inventory,
/// purely from [ShopState].
class ShopRootScreen extends StatelessWidget {
  const ShopRootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shopState = context.of<ShopState>();

    if (shopState.isLoading) {
      return const ShopLoadingView();
    }

    if (shopState.hasError) {
      return DatabaseErrorView(error: '${shopState.error}');
    }

    return const ShopHomeScreen();
  }
}