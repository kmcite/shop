import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shop/business/shop_cubit.dart';

import '../widgets/database_error_view.dart';
import '../widgets/shop_loading_view.dart';
import 'shop_home_screen.dart';

/// Routes between loading, connection-error and the inventory,
/// purely from [ShopState].
class ShopRootScreen extends StatelessWidget {
  const ShopRootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shopState = context.watch<ShopCubit>().state;

    if (shopState.isLoading) {
      return const ShopLoadingView();
    }

    if (shopState.hasError) {
      return DatabaseErrorView(error: '${shopState.error}');
    }

    return const ShopHomeScreen();
  }
}