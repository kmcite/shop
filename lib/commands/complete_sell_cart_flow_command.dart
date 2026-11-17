import 'dart:async';

import 'package:any/any.dart';
import 'package:flutter/services.dart';

import '../repositories/shop_navigator.dart';
import '../states/sell_cart_state.dart';
import '../ui/format.dart';
import 'complete_sell_cart_command.dart';

/// Review cart in a sheet, then record one receipt on the Sales tab.
class CompleteSellCartFlowCommand extends Command {
  const CompleteSellCartFlowCommand();

  @override
  FutureOr<void> call(Ref ref) async {
    final ui = ref.get<ShopNavigator>();
    if (ref.of<SellCartState>().isEmpty) {
      return;
    }

    final confirm = await ui.showSellCheckout();
    if (confirm == true && ui.isMounted && ref.of<SellCartState>().lines.isNotEmpty) {

    var grandTotal = 0.0;
    var units = 0;
    for (final line in ref.of<SellCartState>().lines) {
      grandTotal += line.unitPrice * line.quantity;
      units += line.quantity;
    }

      try {
        await const CompleteSellCartCommand().call(ref);
        if (ui.isMounted) {
          HapticFeedback.mediumImpact();
          ui.showToast(
            'Sold $units units · ${formatMoney(grandTotal)}',
            success: true,
          );
        }
      } on StateError catch (e) {
        if (ui.isMounted) {
          ui.showToast(e.message, success: false);
        }
      } catch (e) {
        if (ui.isMounted) {
          ui.showToast('Sale failed: $e', success: false);
        }
      }
    }
  }
}