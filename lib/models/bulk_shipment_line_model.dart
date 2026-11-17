/// One product type tracked through a bulk shipment (expected → counted → priced).
class BulkShipmentLine {
  const BulkShipmentLine({
    required this.name,
    this.expectedQty,
    this.actualQty,
    this.listPrice,
    this.unitCost,
    this.imagePath,
    this.extraFind = false,
  });

  final String name;

  /// What the seller said would be in the bulk (order step).
  final int? expectedQty;

  /// Units found after opening the package.
  final int? actualQty;

  /// Planned sell price per unit (listing step).
  final double? listPrice;

  /// Purchase cost per unit; filled when pricing or on finalize.
  final double? unitCost;

  final String? imagePath;

  /// Found when opening the box but not on the original order list.
  final bool extraFind;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (expectedQty != null) 'expectedQty': expectedQty,
        if (actualQty != null) 'actualQty': actualQty,
        if (listPrice != null) 'listPrice': listPrice,
        if (unitCost != null) 'unitCost': unitCost,
        if (imagePath != null) 'imagePath': imagePath,
        if (extraFind) 'extraFind': true,
      };

  static BulkShipmentLine fromJson(Map<String, dynamic> json) {
    return BulkShipmentLine(
      name: json['name'] as String? ?? 'Unnamed',
      expectedQty: (json['expectedQty'] as num?)?.toInt(),
      actualQty: (json['actualQty'] as num?)?.toInt(),
      listPrice: (json['listPrice'] as num?)?.toDouble(),
      unitCost: (json['unitCost'] as num?)?.toDouble(),
      imagePath: json['imagePath'] as String?,
      extraFind: json['extraFind'] == true,
    );
  }

  BulkShipmentLine copyWith({
    String? name,
    int? expectedQty,
    int? actualQty,
    double? listPrice,
    double? unitCost,
    String? imagePath,
    bool? extraFind,
    bool clearExpectedQty = false,
    bool clearActualQty = false,
    bool clearListPrice = false,
    bool clearUnitCost = false,
    bool clearImagePath = false,
  }) {
    return BulkShipmentLine(
      name: name ?? this.name,
      expectedQty: clearExpectedQty ? null : (expectedQty ?? this.expectedQty),
      actualQty: clearActualQty ? null : (actualQty ?? this.actualQty),
      listPrice: clearListPrice ? null : (listPrice ?? this.listPrice),
      unitCost: clearUnitCost ? null : (unitCost ?? this.unitCost),
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      extraFind: extraFind ?? this.extraFind,
    );
  }
}