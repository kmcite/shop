import 'dart:async';

import 'package:any/any.dart';

import '../models/shop_item_model.dart';
import '../repositories/shop_navigator.dart';
import 'update_item_command.dart';

/// Opens the edit form for [item], saves changes, and shows feedback.
class EditItemFlowCommand extends Command {
  const EditItemFlowCommand(this.item);

  final ShopItem item;

  @override
  FutureOr<void> call(Ref ref) async {
    final ui = ref.get<ShopNavigator>();
    final updated = await ui.showItemForm(existing: item);
    if (updated == null || !ui.isMounted) return;

    try {
      await UpdateItemCommand(updated).call(ref);
      if (!ui.isMounted) return;
      ui.showToast('Updated ${updated.name}', success: true);
    } catch (e) {
      if (ui.isMounted) {
        ui.showToast('Could not save: $e', success: false);
      }
    }
  }
}
