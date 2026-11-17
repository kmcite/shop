import 'dart:async';

import 'package:any/any.dart';

import '../repositories/shop_repository.dart';
import 'reload_shop_data.dart';

/// Deletes every inventory item from the database, then reloads state.
class ClearAllInventoryCommand extends Command {
  const ClearAllInventoryCommand();

  @override
  FutureOr<void> call(Ref ref) async {
    await ref.get<ShopRepository>().clearAllItems();
    await reloadShopData(ref);
  }
}