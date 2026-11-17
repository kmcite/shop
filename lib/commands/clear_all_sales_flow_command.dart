import 'dart:async';

import 'package:any/any.dart';

import '../repositories/shop_navigator.dart';
import '../states/shop_state.dart';
import 'clear_all_sales_command.dart';

/// Confirms, then wipes all sales history.
class ClearAllSalesFlowCommand extends Command {
  const ClearAllSalesFlowCommand();

  @override
  FutureOr<void> call(Ref ref) async {
    final ui = ref.get<ShopNavigator>();
    final count = ref.of<ShopState>().sales.length;
    if (count == 0) {
      ui.showToast('No sales to clear', success: false);
      return;
    }

    final confirmed = await ui.confirmClearAllSales(count);
    if (!confirmed || !ui.isMounted) return;

    try {
      await const ClearAllSalesCommand().call(ref);
      if (!ui.isMounted) return;
      ui.showToast(
        count == 1 ? 'Cleared 1 sale' : 'Cleared $count sales',
        success: true,
      );
    } catch (e) {
      if (ui.isMounted) {
        ui.showToast('Could not clear sales: $e', success: false);
      }
    }
  }
}