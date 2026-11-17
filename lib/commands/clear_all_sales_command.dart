import 'dart:async';

import 'package:any/any.dart';

import '../repositories/shop_repository.dart';
import 'reload_shop_data.dart';

/// Deletes every sale record from the database, then reloads state.
class ClearAllSalesCommand extends Command {
  const ClearAllSalesCommand();

  @override
  FutureOr<void> call(Ref ref) async {
    await ref.get<ShopRepository>().clearAllSales();
    await reloadShopData(ref);
  }
}