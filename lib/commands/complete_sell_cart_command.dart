import 'dart:async';

import 'package:any/any.dart';

import '../models/sale_line_request.dart';
import '../repositories/shop_repository.dart';
import '../states/sell_cart_state.dart';
import '../states/shop_state.dart';
import 'reload_shop_data.dart';
import 'sell_cart_commands.dart';

/// Validates cart against live inventory and records one multi-line receipt.
class CompleteSellCartCommand extends Command {
  const CompleteSellCartCommand();

  @override
  FutureOr<void> call(Ref ref) async {
    final cart = ref.of<SellCartState>();
    if (cart.lines.isNotEmpty) {
    final inventory = {for (final i in ref.of<ShopState>().items) i.id: i};
    final needed = <String, int>{};
    for (final line in cart.lines) {
      needed[line.itemId] = (needed[line.itemId] ?? 0) + line.quantity;
    }
    for (final entry in needed.entries) {
      final item = inventory[entry.key];
      if (item == null) {
        throw StateError('Item no longer in inventory.');
      }
      if (item.quantity < entry.value) {
        throw StateError(
          'Not enough ${item.name} (have ${item.quantity}, need ${entry.value}).',
        );
      }
    }

    final requests = <SaleLineRequest>[
      for (final line in cart.lines)
        SaleLineRequest(
          item: inventory[line.itemId]!,
          count: line.quantity,
          unitPrice: line.unitPrice,
        ),
    ];

    await ref.get<ShopRepository>().sellMany(requests);
    await reloadShopData(ref);
    await ClearSellCartCommand().call(ref);
    }
  }
}