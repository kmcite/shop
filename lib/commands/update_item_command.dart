import 'dart:async';

import 'package:any/any.dart';

import '../models/shop_item_model.dart';
import '../repositories/shop_repository.dart';
import 'reload_shop_data.dart';

/// Saves changes to an existing item, then refreshes the list.
class UpdateItemCommand extends Command {
  const UpdateItemCommand(this.item);

  final ShopItem item;

  @override
  FutureOr<void> call(Ref ref) async {
    await ref.get<ShopRepository>().updateItem(item);
    await reloadShopData(ref);
  }
}