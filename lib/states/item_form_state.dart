import '../models/shop_item_model.dart';

const Object _keep = Object();

/// Immutable draft of the add/edit item form, held in the `any.dart` [Scope].
///
/// All mutations happen through commands in `item_form_commands.dart`;
/// the form sheet reads it with `context.of<ItemFormState>()`. Validation
/// errors live in the state too, set by [SubmitItemFormCommand] —
/// no Form key or per-field validators are needed.
class ItemFormState {
  const ItemFormState({
    this.name = '',
    this.price = '',
    this.costPrice = '',
    this.quantity = '1',
    this.nameError,
    this.priceError,
    this.costPriceError,
    this.quantityError,
    this.imagePath,
  });

  /// Item name as typed.
  final String name;

  /// Raw expected selling price text as typed.
  final String price;

  /// Raw purchase cost per unit text as typed.
  final String costPrice;

  /// Raw quantity text as typed; parsed lazily via [parsedQuantity].
  final String quantity;
  final String? nameError;
  final String? priceError;
  final String? costPriceError;
  final String? quantityError;

  /// Path to the item's photo, or null when none was captured.
  final String? imagePath;
  /// Parsed price text, or null while it is not a number.
  double? get parsedPrice => double.tryParse(price.trim());

  /// Parsed cost text, or null while it is not a number.
  double? get parsedCostPrice => double.tryParse(costPrice.trim());

  /// Parsed quantity text clamped to stock range, or null while invalid.
  int? get parsedQuantity {
    final q = int.tryParse(quantity.trim());
    return q?.clamp(0, 999999);
  }

  /// True when the draft can be submitted.
  bool get isValid =>
      nameError == null &&
      priceError == null &&
      costPriceError == null &&
      quantityError == null &&
      name.trim().isNotEmpty &&
      parsedPrice != null &&
      parsedCostPrice != null &&
      parsedQuantity != null;

  /// The item this draft represents, preserving [existing]'s id when editing.
  ShopItem draft(ShopItem? existing) {
    return ShopItem(
      id: existing?.id ?? '',
      name: name.trim(),
      price: parsedPrice ?? 0,
      quantity: parsedQuantity ?? 0,
      costPrice: parsedCostPrice ?? 0,
      imagePath: imagePath,
    );
  }

  ItemFormState copyWith({
    String? name,
    String? price,
    String? costPrice,
    String? quantity,
    Object? nameError = _keep,
    Object? priceError = _keep,
    Object? costPriceError = _keep,
    Object? quantityError = _keep,
    Object? imagePath = _keep,
  }) {
    return ItemFormState(
      name: name ?? this.name,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      quantity: quantity ?? this.quantity,
      nameError: identical(nameError, _keep)
          ? this.nameError
          : nameError as String?,
      priceError: identical(priceError, _keep)
          ? this.priceError
          : priceError as String?,
      costPriceError: identical(costPriceError, _keep)
          ? this.costPriceError
          : costPriceError as String?,
      quantityError: identical(quantityError, _keep)
          ? this.quantityError
          : quantityError as String?,
      imagePath: identical(imagePath, _keep)
          ? this.imagePath
          : imagePath as String?,
    );
  }
}
