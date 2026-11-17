import 'package:shared_database/shared_database.dart';

/// One product line on a sale receipt.
class SaleLine {
  const SaleLine({
    required this.itemId,
    required this.itemName,
    required this.unitPrice,
    required this.quantity,
    required this.total,
    this.listPrice = 0,
    this.costPrice = 0,
  });

  final String itemId;
  final String itemName;
  final double unitPrice;
  final int quantity;
  final double total;
  final double listPrice;
  final double costPrice;

  double? get profit =>
      costPrice > 0 ? (unitPrice - costPrice) * quantity : null;

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'itemName': itemName,
        'unitPrice': unitPrice,
        'listPrice': listPrice,
        'costPrice': costPrice,
        'quantity': quantity,
        'total': total,
      };

  static SaleLine fromJson(Map<String, dynamic> json) {
    return SaleLine(
      itemId: json['itemId'] as String? ?? '',
      itemName: json['itemName'] as String? ?? 'Unknown item',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      listPrice: (json['listPrice'] as num?)?.toDouble() ?? 0,
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// A sale receipt — one or more lines sold together at [soldAt].
class ShopSale {
  const ShopSale({
    required this.id,
    required this.soldAt,
    required this.lines,
  });

  final String id;
  final DateTime soldAt;
  final List<SaleLine> lines;

  bool get isMultiItem => lines.length > 1;

  int get lineCount => lines.length;

  int get quantity => lines.fold<int>(0, (sum, l) => sum + l.quantity);

  double get total => lines.fold<double>(0, (sum, l) => sum + l.total);

  /// Profit when every line has cost; otherwise null.
  double? get profit {
    var known = true;
    var sum = 0.0;
    for (final line in lines) {
      final p = line.profit;
      if (p == null) {
        known = false;
        break;
      }
      sum += p;
    }
    return known ? sum : null;
  }

  /// Title for list rows.
  String get headline {
    if (lines.isEmpty) return 'Empty sale';
    if (lines.length == 1) return lines.first.itemName;
    return '${lines.first.itemName} +${lines.length - 1} more';
  }

  /// Legacy single-line accessors (first line).
  String get itemId => lines.isNotEmpty ? lines.first.itemId : '';
  String get itemName => headline;
  double get unitPrice => lines.length == 1 ? lines.first.unitPrice : 0;
  double get listPrice => lines.length == 1 ? lines.first.listPrice : 0;
  double get costPrice => lines.length == 1 ? lines.first.costPrice : 0;

  static ShopSale fromRecord(SharedRecord record) {
    final data = record.data;
    final soldAt =
        DateTime.tryParse(data['soldAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);

    final rawLines = data['lines'];
    if (rawLines is List && rawLines.isNotEmpty) {
      final lines = rawLines
          .whereType<Map>()
          .map((e) => SaleLine.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return ShopSale(id: record.id, soldAt: soldAt, lines: lines);
    }

    final unitPrice = (data['unitPrice'] as num?)?.toDouble() ?? 0;
    final qty = (data['quantity'] as num?)?.toInt() ?? 0;
    return ShopSale(
      id: record.id,
      soldAt: soldAt,
      lines: [
        SaleLine(
          itemId: data['itemId'] as String? ?? '',
          itemName: data['itemName'] as String? ?? 'Unknown item',
          unitPrice: unitPrice,
          listPrice: (data['listPrice'] as num?)?.toDouble() ?? 0,
          costPrice: (data['costPrice'] as num?)?.toDouble() ?? 0,
          quantity: qty,
          total: (data['total'] as num?)?.toDouble() ?? unitPrice * qty,
        ),
      ],
    );
  }

  Map<String, dynamic> toData() => {
        'soldAt': soldAt.toIso8601String(),
        'lines': lines.map((l) => l.toJson()).toList(),
        'total': total,
        'quantity': quantity,
      };
}