import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/shop_item_model.dart';
import 'states/item_form_state.dart';

class ItemFormCubit extends Cubit<ItemFormState> {
  ItemFormCubit() : super(const ItemFormState());

  void begin(ShopItem? existing) {
    final item = existing;
    emit(
      ItemFormState(
        name: item?.name ?? '',
        price: item == null ? '' : _priceToText(item.price),
        costPrice: item == null || item.costPrice <= 0
            ? ''
            : _priceToText(item.costPrice),
        quantity: '${item?.quantity ?? 1}',
        imagePath: item?.imagePath,
      ),
    );
  }

  void setName(String name) =>
      emit(state.copyWith(name: name, nameError: null));

  void setPrice(String price) =>
      emit(state.copyWith(price: price, priceError: null));

  void setCostPrice(String costPrice) =>
      emit(state.copyWith(costPrice: costPrice, costPriceError: null));

  void setQuantity(String quantity) =>
      emit(state.copyWith(quantity: quantity, quantityError: null));

  void setPhoto(String? imagePath) => emit(state.copyWith(imagePath: imagePath));

  void validateForSubmit() {
    final price = state.parsedPrice;
    final cost = state.parsedCostPrice;
    emit(
      state.copyWith(
        nameError: state.name.trim().isEmpty ? 'Enter a name' : null,
        priceError: state.price.trim().isEmpty
            ? 'Enter a sell price'
            : (price == null || price < 0 ? 'Invalid price' : null),
        costPriceError: state.costPrice.trim().isEmpty
            ? 'Enter a cost'
            : (cost == null || cost < 0 ? 'Invalid cost' : null),
        quantityError:
            state.parsedQuantity == null ? 'Enter a quantity' : null,
      ),
    );
  }
}

String _priceToText(double price) {
  final s = price.toStringAsFixed(2);
  if (s.endsWith('.00')) return s.substring(0, s.length - 3);
  if (s.endsWith('0')) return s.substring(0, s.length - 1);
  return s;
}