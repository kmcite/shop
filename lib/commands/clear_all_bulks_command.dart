import 'dart:async';

import 'package:any/any.dart';

import '../repositories/shop_repository.dart';
import 'reload_shop_data.dart';

/// Deletes every bulk shipment from the database, then reloads state.
class ClearAllBulksCommand extends Command {
  const ClearAllBulksCommand();

  @override
  FutureOr<void> call(Ref ref) async {
    await ref.get<ShopRepository>().clearAllBulkShipments();
    await reloadShopData(ref);
  }
}