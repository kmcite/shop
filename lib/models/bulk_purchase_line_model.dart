/// One product type in a mixed bulk shipment.
class BulkPurchaseLine {
  const BulkPurchaseLine({
    required this.name,
    required this.price,
    required this.costPrice,
    required this.quantity,
    this.imagePath,
  });

  final String name;
  final double price;
  final double costPrice;
  final int quantity;
  final String? imagePath;
}