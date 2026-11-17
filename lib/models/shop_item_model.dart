import 'package:shared_database/shared_database.dart';

const Object _unset = Object();

class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.costPrice = 0,
    this.imagePath,
  });

  final String id;
  final String name;

  /// Expected selling price per unit — what you plan to charge.
  final double price;

  /// Units currently on hand.
  final int quantity;

  /// Weighted-average purchase cost per unit across all restocks.
  /// Zero means the cost was never recorded (legacy items).
  final double costPrice;

  /// Absolute path to the item's photo on disk, if one was captured.
  final String? imagePath;
  bool get inStock => quantity > 0;
  bool get hasCost => costPrice > 0;

  /// Expected profit per unit at the list price.
  double get marginPerUnit => price - costPrice;

  /// Margin as a percentage of cost; 0 when cost is unknown.
  double get marginPercent =>
      costPrice > 0 ? ((price - costPrice) / costPrice) * 100 : 0;

  static ShopItem fromRecord(SharedRecord record) {
    final data = record.data;
    return ShopItem(
      id: record.id,
      name: data['name'] as String? ?? 'Unnamed',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      costPrice: (data['costPrice'] as num?)?.toDouble() ?? 0,
      imagePath: data['imagePath'] as String?,
    );
  }

  Map<String, dynamic> toData() => {
    'name': name,
    'price': price,
    'quantity': quantity,
    'costPrice': costPrice,
    if (imagePath != null) 'imagePath': imagePath,
  };

  ShopItem copyWith({
    String? name,
    double? price,
    int? quantity,
    double? costPrice,
    Object? imagePath = _unset,
  }) {
    return ShopItem(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      costPrice: costPrice ?? this.costPrice,
      imagePath: identical(imagePath, _unset)
          ? this.imagePath
          : imagePath as String?,
    );
  }
}
