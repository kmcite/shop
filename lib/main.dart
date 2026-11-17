import 'package:any/any.dart';
import 'package:flutter/material.dart';

import 'features/screens/shop_application.dart';
import 'repositories/shop_repository.dart';
import 'repositories/shop_navigator.dart';
import 'states/bulk_order_draft_state.dart';
import 'states/item_form_state.dart';
import 'states/sell_cart_state.dart';
import 'states/shop_state.dart';

void main() {
  final navigatorKey = GlobalKey<NavigatorState>();
  runApp(
    AnyScope(
      repositories: [
        Binding<ShopRepository>(SharedDbShopRepository()),
        Binding<ShopNavigator>(ShopNavigatorImpl(navigatorKey)),
      ],
      states: (f) {
        return [
          const ShopState(),
          // Transient draft for the add/edit item sheet, so it stays stateless.
          const ItemFormState(),
          const BulkOrderDraftState(),
          const SellCartState(),
        ];
      },
      child: ShopApplication(navigatorKey: navigatorKey),
    ),
  );
}