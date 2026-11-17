import 'dart:async';

import 'package:any/any.dart';

import '../repositories/shop_navigator.dart';
import '../states/shop_state.dart';
import 'clear_all_bulks_command.dart';

/// Confirms, then wipes all bulk shipment records.
class ClearAllBulksFlowCommand extends Command {
  const ClearAllBulksFlowCommand();

  @override
  FutureOr<void> call(Ref ref) async {
    final ui = ref.get<ShopNavigator>();
    final bulks = ref.of<ShopState>().bulkShipments;
    final count = bulks.length;
    if (count == 0) {
      ui.showToast('No bulks to clear', success: false);
      return;
    }

    final confirmed = await ui.confirmClearAllBulks(count);
    if (!confirmed || !ui.isMounted) return;

    try {
      await const ClearAllBulksCommand().call(ref);
      if (!ui.isMounted) return;
      ui.showToast(
        count == 1 ? 'Cleared 1 bulk' : 'Cleared $count bulks',
        success: true,
      );
    } catch (e) {
      if (ui.isMounted) {
        ui.showToast('Could not clear bulks: $e', success: false);
      }
    }
  }
}