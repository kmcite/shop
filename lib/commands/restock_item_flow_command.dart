import 'dart:async';

import 'package:any/any.dart';

import '../models/shop_item_model.dart';
import '../repositories/shop_navigator.dart';
import '../ui/format.dart';
import 'restock_item_command.dart';

/// Opens the restock sheet for [item], logs the purchase, and shows feedback.
class RestockItemFlowCommand extends Command {
  const RestockItemFlowCommand(this.item);

  final ShopItem item;

  @override
  FutureOr<void> call(Ref ref) async {
    final ui = ref.get<ShopNavigator>();
    final result = await ui.showRestockSheet(item);
    if (result == null || !ui.isMounted) return;

    try {
      await RestockItemCommand(
        item,
        count: result.count,
        unitCost: result.unitCost,
      ).call(ref);
      if (!ui.isMounted) return;
      ui.showToast(
        'Restocked ${result.count} × ${item.name} at '
        '${formatMoney(result.unitCost)} each',
        success: true,
      );
    } catch (e) {
      if (ui.isMounted) {
        ui.showToast('Could not add stock: $e', success: false);
      }
    }
  }
}
