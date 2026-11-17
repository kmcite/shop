/// Draft line waiting in the sell cart (before checkout).
class SellCartLine {
  const SellCartLine({
    required this.itemId,
    required this.quantity,
    required this.unitPrice,
  });

  final String itemId;
  final int quantity;
  final double unitPrice;

  SellCartLine copyWith({
    int? quantity,
    double? unitPrice,
  }) {
    return SellCartLine(
      itemId: itemId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
}