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
    required int quantity,
    required double unitPrice,
  }) {
    final lines = List<SellCartLine>.of(state.lines);
    if (index < 0 || index >= lines.length) return;
    if (quantity < 1) {
      lines.removeAt(index);
    } else {
      lines[index] = lines[index].copyWith(
        quantity: quantity,
        unitPrice: unitPrice,
      );
    }
    emit(state.copyWith(lines: lines));
  }

  void removeLine(int index) {
    final lines = List<SellCartLine>.of(state.lines);
    if (index >= 0 && index < lines.length) {
      lines.removeAt(index);
      emit(state.copyWith(lines: lines));
    }
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