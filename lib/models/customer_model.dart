import 'package:shared_database/shared_database.dart';

/// A person who buys on credit.
class ShopCustomer {
  const ShopCustomer({
    required this.id,
    required this.name,
    required this.createdAt,
    this.note = '',
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final String note;

  Map<String, dynamic> toData() => {
        'name': name.trim(),
        'note': note.trim(),
        'createdAt': createdAt.toIso8601String(),
      };

  static ShopCustomer fromRecord(SharedRecord record) {
    final data = record.data;
    return ShopCustomer(
      id: record.id,
      name: (data['name'] as String? ?? '').trim(),
      note: (data['note'] as String? ?? '').trim(),
      createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  ShopCustomer copyWith({
    String? name,
    String? note,
  }) {
    return ShopCustomer(
      id: id,
      name: name ?? this.name,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }
}

/// One product line on a credit sale.
class CustomerSaleLine {
  const CustomerSaleLine({
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.itemId = '',
  });

  final String itemId;
  final String itemName;
  final int quantity;
  final double unitPrice;
  final double total;

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'itemName': itemName,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'total': total,
      };

  static CustomerSaleLine fromJson(Map<String, dynamic> json) {
    final qty = (json['quantity'] as num?)?.toInt() ?? 0;
    final unit = (json['unitPrice'] as num?)?.toDouble() ?? 0;
    return CustomerSaleLine(
      itemId: json['itemId'] as String? ?? '',
      itemName: json['itemName'] as String? ?? 'Item',
      quantity: qty,
      unitPrice: unit,
      total: (json['total'] as num?)?.toDouble() ?? unit * qty,
    );
  }
}

enum CustomerLedgerKind { sale, payment }

/// Sale or payment against a customer's credit book.
class CustomerLedgerEntry {
  const CustomerLedgerEntry({
    required this.id,
    required this.customerId,
    required this.kind,
    required this.createdAt,
    this.lines = const [],
    this.amount = 0,
    this.note = '',
    this.shopSaleId,
  });

  final String id;
  final String customerId;
  final CustomerLedgerKind kind;
  final DateTime createdAt;
  final List<CustomerSaleLine> lines;
  final double amount;
  final String note;
  final String? shopSaleId;

  bool get isSale => kind == CustomerLedgerKind.sale;
  bool get isPayment => kind == CustomerLedgerKind.payment;

  double get saleTotal =>
      lines.fold<double>(0, (sum, line) => sum + line.total);

  /// Money movement for balance: sales increase owed, payments decrease.
  double get signedAmount => isSale ? saleTotal : -amount;

  String get headline {
    if (isPayment) return 'Payment received';
    if (lines.isEmpty) return 'Sale';
    if (lines.length == 1) return lines.first.itemName;
    return '${lines.first.itemName} +${lines.length - 1} more';
  }

  Map<String, dynamic> toData() => {
        'customerId': customerId,
        'kind': kind.name,
        'createdAt': createdAt.toIso8601String(),
        'lines': lines.map((l) => l.toJson()).toList(),
        'amount': amount,
        'note': note,
        if (shopSaleId != null) 'shopSaleId': shopSaleId,
      };

  static CustomerLedgerEntry fromRecord(SharedRecord record) {
    final data = record.data;
    final kindName = data['kind'] as String? ?? 'sale';
    final kind = kindName == CustomerLedgerKind.payment.name
        ? CustomerLedgerKind.payment
        : CustomerLedgerKind.sale;
    final rawLines = data['lines'];
    final lines = rawLines is List
        ? rawLines
            .whereType<Map>()
            .map((e) => CustomerSaleLine.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <CustomerSaleLine>[];

    return CustomerLedgerEntry(
      id: record.id,
      customerId: data['customerId'] as String? ?? '',
      kind: kind,
      createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      lines: lines,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      note: data['note'] as String? ?? '',
      shopSaleId: data['shopSaleId'] as String?,
    );
  }
}

/// Aggregated view for list/detail screens.
class CustomerAccount {
  const CustomerAccount({
    required this.customer,
    required this.entries,
  });

  final ShopCustomer customer;
  final List<CustomerLedgerEntry> entries;

  double get totalSold => entries
      .where((e) => e.isSale)
      .fold<double>(0, (sum, e) => sum + e.saleTotal);

  double get totalPaid => entries
      .where((e) => e.isPayment)
      .fold<double>(0, (sum, e) => sum + e.amount);

  /// Positive = still owes you. Negative = credit on account.
  double get remaining => totalSold - totalPaid;

  bool get hasBalance => remaining.abs() >= 0.005;

  DateTime? get lastActivity {
    if (entries.isEmpty) return null;
    return entries.first.createdAt;
  }

  int get saleCount => entries.where((e) => e.isSale).length;
  int get paymentCount => entries.where((e) => e.isPayment).length;
}
