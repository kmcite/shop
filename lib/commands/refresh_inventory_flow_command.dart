import 'dart:async';

import 'package:any/any.dart';

import '../repositories/shop_navigator.dart';
import 'reload_shop_data.dart';

/// Pull-to-refresh with an error toast when the reload fails.
class RefreshInventoryFlowCommand extends Command {
  const RefreshInventoryFlowCommand();

  @override
  FutureOr<void> call(Ref ref) async {
    final ui = ref.get<ShopNavigator>();
    try {
      await reloadShopData(ref);
    } catch (e) {
      if (ui.isMounted) {
        ui.showToast('Could not refresh: $e', success: false);
      }
    }
  }
}
