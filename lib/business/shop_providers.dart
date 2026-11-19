import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/widgets.dart';

import '../features/app/app_router.dart';
import '../repositories/shop_repository.dart';
import 'bulk_order_draft_cubit.dart';
import 'item_form_cubit.dart';
import 'sell_cart_cubit.dart';
import 'shop_cubit.dart';

/// App root: data repository + blocs. Navigation is [AppRouter], not a repo.
class ShopScope extends StatelessWidget {
  const ShopScope({
    super.key,
    required this.router,
    required this.child,
  });

  final AppRouter router;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<ShopRepository>(
      create: (_) => SharedDbShopRepository(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (ctx) => ShopCubit(
              repository: ctx.read<ShopRepository>(),
              router: router,
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
