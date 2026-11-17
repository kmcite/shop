import 'dart:async';

import 'package:any/any.dart';

import '../models/shop_item_model.dart';
import '../repositories/shop_repository.dart';
import 'reload_shop_data.dart';

/// Logs a bulk purchase: adds [count] units at [unitCost] and folds
/// them into the item's weighted-average cost.
class const RestockItemCommand(
  final ShopItem item, {
  required final int count,
  required final double unitCost,
}) extends Command {
  @override
  FutureOr<void> call(Ref ref) async {
    await ref.get<ShopRepository>().restock(
      item,
      count: count,
      unitCost: unitCost,
    );
    await reloadShopData(ref);
  }
}