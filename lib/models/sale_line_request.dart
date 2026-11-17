import 'shop_item_model.dart';

/// One line to persist on a multi-item sale receipt.
class SaleLineRequest {
  const SaleLineRequest({
    required this.item,
    required this.count,
    required this.unitPrice,
  });

  final ShopItem item;
  final int count;
  final double unitPrice;
}