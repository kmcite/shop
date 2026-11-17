import 'dart:async';

import 'package:any/any.dart';

import '../models/sell_cart_line_model.dart';
import '../models/shop_item_model.dart';
import '../states/sell_cart_state.dart';

class ClearSellCartCommand extends Command {
  const ClearSellCartCommand();

  @override
  FutureOr<void> call(Ref ref) {
    ref<SellCartState>((_) => const SellCartState());
  }
}

/// Adds or merges a line (same [itemId] + same unit price merges qty).
class AddToSellCartCommand extends Command {
  const AddToSellCartCommand({
    required this.itemId,
    required this.quantity,
    required this.unitPrice,
  });

  final String itemId;
  final int quantity;
  final double unitPrice;

  @override
  FutureOr<void> call(Ref ref) {
    if (quantity >= 1) {
    final cart = ref.of<SellCartState>();
    final lines = List<SellCartLine>.of(cart.lines);
    final index = lines.indexWhere(
      (l) => l.itemId == itemId && (l.unitPrice - unitPrice).abs() < 0.001,
    );
    if (index >= 0) {
      lines[index] = lines[index].copyWith(
        quantity: lines[index].quantity + quantity,
      );
    } else {
      lines.add(
        SellCartLine(
          itemId: itemId,
          quantity: quantity,
          unitPrice: unitPrice,
        ),
      );
    }
      ref<SellCartState>((s) => s.copyWith(lines: lines));
    }
  }
}

class UpdateSellCartLineCommand extends Command {
  const UpdateSellCartLineCommand({
    required this.index,
    required this.quantity,
    required this.unitPrice,
  });

  final int index;
  final int quantity;
  final double unitPrice;

  @override
  FutureOr<void> call(Ref ref) {
    final lines = List<SellCartLine>.of(ref.of<SellCartState>().lines);
    if (index >= 0 && index < lines.length) {
      if (quantity < 1) {
        lines.removeAt(index);
      } else {
        lines[index] = lines[index].copyWith(
          quantity: quantity,
          unitPrice: unitPrice,
        );
      }
      ref<SellCartState>((s) => s.copyWith(lines: lines));
    }
  }
}

class RemoveSellCartLineCommand extends Command {
  const RemoveSellCartLineCommand(this.index);

  final int index;

  @override
  FutureOr<void> call(Ref ref) {
    final lines = List<SellCartLine>.of(ref.of<SellCartState>().lines);
    if (index >= 0 && index < lines.length) {
      lines.removeAt(index);
      ref<SellCartState>((s) => s.copyWith(lines: lines));
    }
  }
}

/// Convenience: add from a [ShopItem] at list price.
class AddShopItemToCartCommand extends Command {
  const AddShopItemToCartCommand(this.item, {this.quantity = 1, this.unitPrice});

  final ShopItem item;
  final int quantity;
  final double? unitPrice;

  @override
  FutureOr<void> call(Ref ref) {
    final qty = quantity.clamp(1, item.quantity);
    if (qty >= 1 && item.inStock) {
      AddToSellCartCommand(
        itemId: item.id,
        quantity: qty,
        unitPrice: unitPrice ?? item.price,
      ).call(ref);
    }
  }
}