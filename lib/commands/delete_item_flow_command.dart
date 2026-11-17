import 'dart:async';

import 'package:any/any.dart';

import '../models/shop_item_model.dart';
import '../repositories/shop_navigator.dart';
import 'delete_item_command.dart';

/// Confirms deletion, removes [item], and surfaces errors via toast.
class DeleteItemFlowCommand extends Command {
  const DeleteItemFlowCommand(this.item);

  final ShopItem item;

  @override
  FutureOr<void> call(Ref ref) async {
    final ui = ref.get<ShopNavigator>();
    final confirmed = await ui.confirmDeleteItem(item);
    if (!confirmed || !ui.isMounted) return;

    try {
      await DeleteItemCommand(item.id).call(ref);
    } catch (e) {
      if (ui.isMounted) {
        ui.showToast('Could not delete: $e', success: false);
      }
    }
  }
}
