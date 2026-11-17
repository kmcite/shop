import 'dart:async';

import 'package:any/any.dart';
import 'package:flutter/services.dart';

import '../models/shop_item_model.dart';
import '../repositories/shop_navigator.dart';
import '../states/sell_cart_state.dart';
import 'sell_cart_commands.dart';

/// Configure qty/price, append to cart (does not deduct stock yet).
class AddToSellCartFlowCommand extends Command {
  const AddToSellCartFlowCommand(this.item);

  final ShopItem item;

  @override
  FutureOr<void> call(Ref ref) async {
    final ui = ref.get<ShopNavigator>();
    final result = await ui.showSellSheet(item);
    if (result == null || !ui.isMounted) {
      return;
    }

    await AddToSellCartCommand(
      itemId: item.id,
      quantity: result.count,
      unitPrice: result.unitPrice,
    ).call(ref);

    if (!ui.isMounted) {
      return;
    }
    HapticFeedback.selectionClick();
    final types = ref.of<SellCartState>().itemTypeCount;
    ui.showToast(
      'Added to sale · $types type${types == 1 ? '' : 's'} in cart',
      success: true,
    );
  }
}