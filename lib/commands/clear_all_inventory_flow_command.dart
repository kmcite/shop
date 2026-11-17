import 'dart:async';

import 'package:any/any.dart';

import '../repositories/shop_navigator.dart';
import '../states/shop_state.dart';
import 'clear_all_inventory_command.dart';

/// Confirms, then wipes all inventory items.
class ClearAllInventoryFlowCommand extends Command {
  const ClearAllInventoryFlowCommand();

  @override
  FutureOr<void> call(Ref ref) async {
    final ui = ref.get<ShopNavigator>();
    final count = ref.of<ShopState>().items.length;
    if (count == 0) {
      ui.showToast('No inventory to clear', success: false);
      return;
    }

    final confirmed = await ui.confirmClearAllInventory(count);
    if (!confirmed || !ui.isMounted) return;

    try {
      await const ClearAllInventoryCommand().call(ref);
      if (!ui.isMounted) return;
      ui.showToast(
        count == 1 ? 'Cleared 1 item' : 'Cleared $count items',
        success: true,
      );
    } catch (e) {
      if (ui.isMounted) {
        ui.showToast('Could not clear inventory: $e', success: false);
      }
    }
  }
}