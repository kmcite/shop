import 'dart:async';

import 'package:any/any.dart';

import '../repositories/shop_repository.dart';
import 'reload_shop_data.dart';

/// Deletes an item from the inventory, then refreshes the list.
class DeleteItemCommand extends Command {
  const DeleteItemCommand(this.id);

  final String id;

  @override
  FutureOr<void> call(Ref ref) async {
    await ref.get<ShopRepository>().deleteItem(id);
    await reloadShopData(ref);
  }
}