import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/widgets.dart';

import '../repositories/shop_navigator.dart';
import '../repositories/shop_repository.dart';
import 'bulk_order_draft_cubit.dart';
import 'item_form_cubit.dart';
import 'sell_cart_cubit.dart';
import 'shop_cubit.dart';

/// App root: repositories + blocs.
class ShopProviders extends StatelessWidget {
  const ShopProviders({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ShopRepository>(
          create: (_) => SharedDbShopRepository(),
        ),
        RepositoryProvider<ShopNavigator>(
          create: (_) => ShopNavigatorImpl(navigatorKey),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (ctx) => ShopCubit(
              repository: ctx.read<ShopRepository>(),
              navigator: ctx.read<ShopNavigator>(),
            ),
          ),
          BlocProvider(create: (_) => ItemFormCubit()),
          BlocProvider(create: (_) => BulkOrderDraftCubit()),
          BlocProvider(create: (_) => SellCartCubit()),
        ],
        child: child,
      ),
    );
  }
}