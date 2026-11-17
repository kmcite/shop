import 'package:shared_database/shared_database.dart';

import '../models/bulk_shipment_model.dart';
import '../models/sale_line_request.dart';
import '../models/sale_model.dart';
import '../models/shop_item_model.dart';

/// Data-access contract for the shop. Commands resolve it with
/// `ref.get<ShopRepository>()`; widgets should not touch it directly.
abstract interface class ShopRepository {
  /// Opens the shared database and makes sure the shop collections exist.
  Future<void> connect();

  /// All inventory items, sorted by name.
  Future<List<ShopItem>> getItems();

  /// All recorded sales, newest first.
  Future<List<ShopSale>> getSales();

  Future<String> addItem({
    required String name,
    required double price,
    required double costPrice,
    required int quantity,
  });

  /// Adds [count] units bought at [unitCost] each. Stock grows and the
  /// item's cost becomes the weighted average across all purchases.
  Future<void> restock(ShopItem item, {required int count, required double unitCost});

  Future<void> updateItem(ShopItem item);

  Future<void> deleteItem(String id);

  /// One receipt with multiple lines; all stock checks run before any write.
  Future<void> sellMany(List<SaleLineRequest> lines);

  /// Removes every record in the sales collection.
  Future<void> clearAllSales();

  /// Removes every record in the inventory collection.
  Future<void> clearAllItems();

  /// All bulk shipments, newest first (excluding completed when [activeOnly]).
  Future<List<BulkShipment>> getBulkShipments({bool activeOnly = false});

  Future<BulkShipment?> getBulkShipment(String id);

  Future<String> saveBulkShipment(BulkShipment shipment);

  Future<void> deleteBulkShipment(String id);

  /// Removes every bulk shipment record (in progress and completed).
  Future<void> clearAllBulkShipments();
}

/// [ShopRepository] backed by the cross-app [SharedDatabase].
class SharedDbShopRepository implements ShopRepository {
  SharedDbShopRepository();

  static const itemsCollection = 'shop_items';
  static const salesCollection = 'shop_sales';
  static const bulksCollection = 'shop_bulk_shipments';

  SharedDatabase? _db;

  SharedDatabase get _database {
    final db = _db;
    if (db == null) {
      throw StateError('Repository is not connected; run InitializeCommand.');
    }
    return db;
  }

  @override
  Future<void> connect() async {
    final db = await SharedDatabase.open();
    await db.ensureCollection(itemsCollection);
    await db.ensureCollection(salesCollection);
    await db.ensureCollection(bulksCollection);
    _db = db;
  }

  @override
  Future<List<ShopItem>> getItems() async {
    final records = await _database.getAll(itemsCollection);
    return records.map(ShopItem.fromRecord).toList()..sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
  }

  @override
  Future<List<ShopSale>> getSales() async {
    final records = await _database.getAll(salesCollection);
    return records.map(ShopSale.fromRecord).toList()
      ..sort((a, b) => b.soldAt.compareTo(a.soldAt));
  }

  @override
  Future<String> addItem({
    required String name,
    required double price,
    required double costPrice,
    required int quantity,
  }) {
    return _database.put(itemsCollection, {
      'name': name.trim(),
      'price': price,
      'quantity': quantity,
      'costPrice': costPrice,
    });
  }

  @override
  Future<void> restock(
    ShopItem item, {
    required int count,
    required double unitCost,
  }) async {
    if (count < 1) return;
    final newQty = item.quantity + count;
    // Weighted-average cost across all purchases. When no cost was ever
    // recorded, adopt the latest purchase cost as the baseline.
    final newCost = item.costPrice > 0
        ? (item.quantity * item.costPrice + count * unitCost) / newQty
        : unitCost;
    await _database.put(
      itemsCollection,
      item.copyWith(quantity: newQty, costPrice: newCost).toData(),
      id: item.id,
    );
  }

  @override
  Future<void> updateItem(ShopItem item) {
    return _database.put(
      itemsCollection,
      item.toData(),
      id: item.id,
    );
  }

  @override
  Future<void> deleteItem(String id) {
    return _database.removeById(itemsCollection, id);
  }

  @override
  Future<void> sellMany(List<SaleLineRequest> requests) async {
    if (requests.isEmpty) return;

    final items = <String, ShopItem>{};
    final deduct = <String, int>{};

    for (final req in requests) {
      if (req.count < 1) {
        throw StateError('Invalid quantity for ${req.item.name}.');
      }
      items[req.item.id] = req.item;
      deduct[req.item.id] = (deduct[req.item.id] ?? 0) + req.count;
    }

    for (final entry in deduct.entries) {
      final item = items[entry.key]!;
      if (item.quantity < entry.value) {
        throw StateError(
          'Not enough ${item.name} (have ${item.quantity}, need ${entry.value}).',
        );
      }
    }

    final soldAt = DateTime.now();
    final saleLines = <SaleLine>[];

    for (final req in requests) {
      saleLines.add(
        SaleLine(
          itemId: req.item.id,
          itemName: req.item.name,
          unitPrice: req.unitPrice,
          listPrice: req.item.price,
          costPrice: req.item.costPrice,
          quantity: req.count,
          total: req.unitPrice * req.count,
        ),
      );
    }

    for (final entry in deduct.entries) {
      final item = items[entry.key]!;
      final updated = item.copyWith(quantity: item.quantity - entry.value);
      await _database.put(
        itemsCollection,
        updated.toData(),
        id: item.id,
      );
    }

    await _database.put(salesCollection, {
      'soldAt': soldAt.toIso8601String(),
      'lines': saleLines.map((l) => l.toJson()).toList(),
      'total': saleLines.fold<double>(0, (s, l) => s + l.total),
      'quantity': saleLines.fold<int>(0, (s, l) => s + l.quantity),
    });
  }

  @override
  Future<void> clearAllSales() => _database.removeAll(salesCollection);

  @override
  Future<void> clearAllItems() => _database.removeAll(itemsCollection);

  @override
  Future<List<BulkShipment>> getBulkShipments({bool activeOnly = false}) async {
    final records = await _database.getAll(bulksCollection);
    final bulks = records.map(BulkShipment.fromRecord).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (!activeOnly) return bulks;
    return bulks.where((b) => b.status.isActive).toList();
  }

  @override
  Future<BulkShipment?> getBulkShipment(String id) async {
    final record = await _database.getById(bulksCollection, id);
    if (record == null) return null;
    return BulkShipment.fromRecord(record);
  }

  @override
  Future<String> saveBulkShipment(BulkShipment shipment) {
    return _database.put(
      bulksCollection,
      shipment.toData(),
      id: shipment.id.isEmpty ? null : shipment.id,
    );
  }

  @override
  Future<void> deleteBulkShipment(String id) {
    return _database.removeById(bulksCollection, id);
  }

  @override
  Future<void> clearAllBulkShipments() =>
      _database.removeAll(bulksCollection);
}
