import 'dart:async';

import 'package:any/any.dart';

import '../models/shop_item_model.dart';
import '../states/item_form_state.dart';

/// (Re)initializes the form state when the sheet opens: prefilled from
/// [existing] when editing, blank otherwise.
class const BeginItemFormCommand(final ShopItem? existing) extends Command {
  @override
  FutureOr<void> call(f) {
    final item = existing;
    f<ItemFormState>(
      (_) => ItemFormState(
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
}

/// Mirrors the name field into the state and clears its error.
class const SetItemNameCommand(final String name) extends Command {
  @override
  FutureOr<void> call(f) {
    f<ItemFormState>((s) => s.copyWith(name: name, nameError: null));
  }
}

/// Mirrors the price field into the state and clears its error.
class const SetItemPriceCommand(final String price) extends Command {
  @override
  FutureOr<void> call(f) {
    f<ItemFormState>((s) => s.copyWith(price: price, priceError: null));
  }
}

/// Mirrors the cost field into the state and clears its error.
class const SetItemCostPriceCommand(final String costPrice) extends Command {
  @override
  FutureOr<void> call(f) {
    f<ItemFormState>(
      (s) => s.copyWith(costPrice: costPrice, costPriceError: null),
    );
  }
}

/// Mirrors the quantity field into the state and clears its error.
class const SetItemQuantityCommand(final String quantity) extends Command {
  @override
  FutureOr<void> call(f) {
    f<ItemFormState>(
      (s) => s.copyWith(quantity: quantity, quantityError: null),
    );
  }
}

/// Sets (or clears, with null) the item's photo path.
class const SetItemPhotoCommand(final String? imagePath) extends Command {
  @override
  FutureOr<void> call(f) {
    f<ItemFormState>((s) => s.copyWith(imagePath: imagePath));
  }
}

/// Runs validation and puts any field errors into the state;
/// the sheet pops itself only when the result is valid.
class const SubmitItemFormCommand() extends Command {
  @override
  FutureOr<void> call(f) {
    f<ItemFormState>((s) {
      final price = s.parsedPrice;
      final cost = s.parsedCostPrice;
      return s.copyWith(
        nameError: s.name.trim().isEmpty ? 'Enter a name' : null,
        priceError: s.price.trim().isEmpty
            ? 'Enter a sell price'
            : (price == null || price < 0 ? 'Invalid price' : null),
        costPriceError: s.costPrice.trim().isEmpty
            ? 'Enter a cost'
            : (cost == null || cost < 0 ? 'Invalid cost' : null),
        quantityError: s.parsedQuantity == null ? 'Enter a quantity' : null,
      );
    });
  }
}

// Plain, input-friendly price text: 12.0 -> "12", 12.50 -> "12.5".
String _priceToText(double price) {
  final s = price.toStringAsFixed(2);
  if (s.endsWith('.00')) return s.substring(0, s.length - 3);
  if (s.endsWith('0')) return s.substring(0, s.length - 1);
  return s;
}
