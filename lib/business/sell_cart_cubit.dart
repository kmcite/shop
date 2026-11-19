import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/sell_cart_line_model.dart';
import '../models/shop_item_model.dart';
import 'states/sell_cart_state.dart';

class SellCartCubit extends Cubit<SellCartState> {
  SellCartCubit() : super(const SellCartState());

  void clear() => emit(const SellCartState());

  void addToCart({
    required String itemId,
    required int quantity,
    required double unitPrice,
  }) {
    if (quantity < 1) return;
    final lines = List<SellCartLine>.of(state.lines);
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
    emit(state.copyWith(lines: lines));
  }

  void updateLine({
    required int index,
    int? quantity,
    double? unitPrice,
  }) {
    final lines = List<SellCartLine>.of(state.lines);
    if (index < 0 || index >= lines.length) return;
    final nextQty = quantity ?? lines[index].quantity;
    if (nextQty < 1) {
      lines.removeAt(index);
    } else {
      lines[index] = lines[index].copyWith(
        quantity: nextQty,
        unitPrice: unitPrice ?? lines[index].unitPrice,
      );
    }
    emit(state.copyWith(lines: lines));
  }

  void setQuantity(int index, int quantity) {
    updateLine(index: index, quantity: quantity);
  }

  void setUnitPrice(int index, double unitPrice) {
    if (unitPrice < 0) return;
    updateLine(index: index, unitPrice: unitPrice);
  }

  void removeLine(int index) {
    final lines = List<SellCartLine>.of(state.lines);
    if (index >= 0 && index < lines.length) {
      lines.removeAt(index);
      emit(state.copyWith(lines: lines));
    }
  }

  /// Max units this line may take given on-hand stock and other cart lines.
  int maxQuantityFor(int index, int onHand) {
    if (index < 0 || index >= state.lines.length) return 0;
    final itemId = state.lines[index].itemId;
    var reservedElsewhere = 0;
    for (var i = 0; i < state.lines.length; i++) {
      if (i == index) continue;
      if (state.lines[i].itemId == itemId) {
        reservedElsewhere += state.lines[i].quantity;
      }
    }
    final available = onHand - reservedElsewhere;
    return available < 1 ? 1 : available;
  }

  void addShopItem(ShopItem item, {int quantity = 1, double? unitPrice}) {
    final qty = quantity.clamp(1, item.quantity);
    if (qty >= 1 && item.inStock) {
      addToCart(
        itemId: item.id,
        quantity: qty,
        unitPrice: unitPrice ?? item.price,
      );
    }
  }
}