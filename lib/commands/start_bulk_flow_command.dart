import 'dart:async';

import 'package:any/any.dart';

import '../repositories/shop_navigator.dart';
import 'bulk_order_draft_commands.dart';

/// Completed & past bulks with timeline dates.
class OpenBulkHistoryCommand extends Command {
  const OpenBulkHistoryCommand();

  @override
  FutureOr<void> call(Ref ref) async {
    await ref.get<ShopNavigator>().openBulkHistory();
  }
}

/// Starts a new bulk order (seller → receive → count → price → stock in).
class StartBulkFlowCommand extends Command {
  const StartBulkFlowCommand();

  @override
  FutureOr<void> call(Ref ref) async {
    final ui = ref.get<ShopNavigator>();
    await ResetBulkOrderDraftCommand().call(ref);
    await ui.openNewBulkOrder();
  }
}

/// Opens the next-step screen for an in-progress bulk.
class OpenBulkShipmentCommand extends Command {
  const OpenBulkShipmentCommand(this.shipmentId);

  final String shipmentId;

  @override
  FutureOr<void> call(Ref ref) async {
    final ui = ref.get<ShopNavigator>();
    await ui.openBulkShipment(shipmentId);
  }
}