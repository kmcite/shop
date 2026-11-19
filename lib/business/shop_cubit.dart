import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../ui/format.dart';

import '../models/bulk_purchase_line_model.dart';
import '../models/bulk_shipment_line_model.dart';
import '../models/bulk_shipment_model.dart';
import '../models/sale_line_request.dart';
import '../models/shop_item_model.dart';
import '../repositories/shop_navigator.dart';
import '../repositories/shop_repository.dart';
import 'bulk_order_draft_cubit.dart';
import 'sell_cart_cubit.dart';
import 'states/shop_state.dart';

class ShopCubit extends Cubit<ShopState> {
  ShopCubit({
    required this._repository,
    required this._navigator,
  }) : super(const ShopState());

  final ShopRepository _repository;
  final ShopNavigator _navigator;

  Future<void> initialize() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await _repository.connect();
      emit(state.copyWith(bootstraped: true));
      await reloadData();
    } catch (error) {
      emit(state.copyWith(isLoading: false, error: error, bootstraped: false));
    }
  }

  Future<void> reloadData() async {
    final items = await _repository.getItems();
    final sales = await _repository.getSales();
    final bulks = await _repository.getBulkShipments();
    emit(
      state.copyWith(
        items: items,
        bulkShipments: bulks,
        sales: sales,
        isLoading: false,
        error: null,
      ),
    );
  }

  void setThemeMode(ThemeMode mode) =>
      emit(state.copyWith(themeMode: mode));

  void setSearchQuery(String query) =>
      emit(state.copyWith(searchQuery: query));

  Future<void> updateItem(ShopItem item) async {
    await _repository.updateItem(item);
    await reloadData();
  }

  Future<void> deleteItem(String id) async {
    await _repository.deleteItem(id);
    await reloadData();
  }

  Future<void> restockItem(
    ShopItem item, {
    required int count,
    required double unitCost,
  }) async {
    await _repository.restock(item, count: count, unitCost: unitCost);
    await reloadData();
  }

  Future<void> clearAllItems() async {
    await _repository.clearAllItems();
    await reloadData();
  }

  Future<void> clearAllSales() async {
    await _repository.clearAllSales();
    await reloadData();
  }

  Future<void> clearAllBulks() async {
    await _repository.clearAllBulkShipments();
    await reloadData();
  }

  Future<void> completeSellCart(SellCartCubit cart) async {
    if (cart.state.lines.isEmpty) return;

    final inventory = {for (final i in state.items) i.id: i};
    final needed = <String, int>{};
    for (final line in cart.state.lines) {
      needed[line.itemId] = (needed[line.itemId] ?? 0) + line.quantity;
    }
    for (final entry in needed.entries) {
      final item = inventory[entry.key];
      if (item == null) {
        throw StateError('Item no longer in inventory.');
      }
      if (item.quantity < entry.value) {
        throw StateError(
          'Not enough ${item.name} (have ${item.quantity}, need ${entry.value}).',
        );
      }
    }

    final requests = <SaleLineRequest>[
      for (final line in cart.state.lines)
        SaleLineRequest(
          item: inventory[line.itemId]!,
          count: line.quantity,
          unitPrice: line.unitPrice,
        ),
    ];

    await _repository.sellMany(requests);
    await reloadData();
    cart.clear();
  }

  Future<void> addBulkPurchaseLines(List<BulkPurchaseLine> lines) async {
    if (lines.isEmpty) return;

    final inventory = {..._indexByName(state.items)};

    for (final line in lines) {
      final key = _nameKey(line.name);
      final existing = inventory[key];

      if (existing != null) {
        await _repository.restock(
          existing,
          count: line.quantity,
          unitCost: line.costPrice,
        );
        final next = _afterRestock(existing, line);
        if (line.price != existing.price ||
            line.imagePath != existing.imagePath) {
          await _repository.updateItem(next);
        }
        inventory[key] = next;
      } else {
        final id = await _repository.addItem(
          name: line.name,
          price: line.price,
          costPrice: line.costPrice,
          quantity: line.quantity,
        );
        inventory[key] = ShopItem(
          id: id,
          name: line.name,
          price: line.price,
          costPrice: line.costPrice,
          quantity: line.quantity,
          imagePath: line.imagePath,
        );
      }
    }

    await reloadData();
  }

  // — Bulk shipment persistence —

  Future<void> saveNewBulkOrder(BulkOrderDraftCubit draft) async {
    final d = draft.state;
    final seller = d.sellerLabel.trim();
    final price = d.parsedAgreedPrice;
    final quality = d.qualityNotes.trim();

    if (seller.isEmpty) {
      draft.setError('Who is the seller?');
      return;
    }
    if (price == null || price <= 0) {
      draft.setError('Enter the agreed bulk price.');
      return;
    }
    if (quality.isEmpty) {
      draft.setError('Describe the promised quality.');
      return;
    }
    if (d.lines.isEmpty) {
      draft.setError('Add at least one expected item type.');
      return;
    }

    await _repository.saveBulkShipment(
      BulkShipment(
        id: '',
        sellerLabel: seller,
        agreedPrice: price,
        qualityNotes: quality,
        status: BulkShipmentStatus.ordered,
        lines: d.lines,
        createdAt: DateTime.now(),
      ),
    );
    await reloadData();
    draft.reset();
  }

  Future<void> saveBulkReceived(
    String shipmentId,
    BulkOrderDraftCubit draft,
  ) async {
    final delivery = draft.state.parsedDeliveryCharge ?? 0;
    if (delivery < 0) {
      draft.setError('Delivery charge cannot be negative.');
      return;
    }

    final bulk = await _repository.getBulkShipment(shipmentId);
    if (bulk == null) {
      draft.setError('Bulk not found.');
      return;
    }
    if (bulk.status != BulkShipmentStatus.ordered) {
      draft.setError('This bulk is not waiting to be received.');
      return;
    }

    await _repository.saveBulkShipment(
      bulk.copyWith(
        deliveryCharge: delivery,
        status: BulkShipmentStatus.received,
        receivedAt: DateTime.now(),
      ),
    );
    await reloadData();
  }

  Future<void> saveBulkCounted(
    String shipmentId,
    BulkOrderDraftCubit draft,
  ) async {
    final lines = draft.state.lines;
    if (lines.isEmpty) {
      draft.setError('Count at least one item type.');
      return;
    }
    for (final line in lines) {
      if (line.name.trim().isEmpty || (line.actualQty ?? 0) < 1) {
        draft.setError(
          'Every row needs a name and quantity of at least 1.',
        );
        return;
      }
    }

    final bulk = await _repository.getBulkShipment(shipmentId);
    if (bulk == null) {
      draft.setError('Bulk not found.');
      return;
    }
    if (bulk.status != BulkShipmentStatus.received) {
      draft.setError('Open and count this bulk first.');
      return;
    }

    await _repository.saveBulkShipment(
      bulk.copyWith(
        lines: lines,
        status: BulkShipmentStatus.counted,
        countedAt: DateTime.now(),
      ),
    );
    await reloadData();
  }

  Future<void> saveBulkPriced(
    String shipmentId,
    BulkOrderDraftCubit draft,
  ) async {
    final bulk = await _repository.getBulkShipment(shipmentId);
    if (bulk == null) {
      draft.setError('Bulk not found.');
      return;
    }
    if (bulk.status != BulkShipmentStatus.counted) {
      draft.setError('Finish counting before setting listing prices.');
      return;
    }

    final defaultCost = bulk.defaultUnitCost;
    final updated = <BulkShipmentLine>[];

    for (final line in draft.state.lines) {
      final price = line.listPrice;
      if (price == null || price <= 0) {
        draft.setError('Set a listing price for every item type.');
        return;
      }
      updated.add(line.copyWith(unitCost: line.unitCost ?? defaultCost));
    }

    await _repository.saveBulkShipment(
      bulk.copyWith(
        lines: updated,
        status: BulkShipmentStatus.priced,
        pricedAt: DateTime.now(),
      ),
    );
    await reloadData();
  }

  Future<void> finalizeBulkShipment(String shipmentId) async {
    final bulk = await _repository.getBulkShipment(shipmentId);
    if (bulk == null || bulk.status != BulkShipmentStatus.priced) return;

    final purchaseLines = <BulkPurchaseLine>[];
    for (final line in bulk.lines) {
      final qty = line.actualQty ?? 0;
      final price = line.listPrice ?? 0;
      final cost = line.unitCost ?? bulk.defaultUnitCost;
      if (qty < 1 || price <= 0) continue;
      purchaseLines.add(
        BulkPurchaseLine(
          name: line.name,
          price: price,
          costPrice: cost,
          quantity: qty,
          imagePath: line.imagePath,
        ),
      );
    }
    if (purchaseLines.isEmpty) return;

    await addBulkPurchaseLines(purchaseLines);
    await _repository.saveBulkShipment(
      bulk.copyWith(
        status: BulkShipmentStatus.completed,
        completedAt: DateTime.now(),
      ),
    );
    await reloadData();
  }

  Future<void> prepareBulkCountDraft(
    String shipmentId,
    BulkOrderDraftCubit draft,
  ) async {
    final bulk = await _repository.getBulkShipment(shipmentId);
    if (bulk == null) return;
    final lines = bulk.lines
        .map(
          (l) => l.copyWith(
            actualQty: l.actualQty ?? l.expectedQty ?? 1,
            extraFind: l.extraFind,
          ),
        )
        .toList();
    draft.loadFromShipment(shipmentId, state);
    draft.setLines(lines);
  }

  Future<void> prepareBulkPriceDraft(
    String shipmentId,
    BulkOrderDraftCubit draft,
  ) async {
    draft.loadFromShipment(shipmentId, state);
    BulkShipment? bulk;
    for (final b in state.bulkShipments) {
      if (b.id == shipmentId) {
        bulk = b;
        break;
      }
    }
    if (bulk == null) return;
    final defaultCost = bulk.defaultUnitCost;
    final lines = draft.state.lines
        .map((l) => l.copyWith(unitCost: l.unitCost ?? defaultCost))
        .toList();
    draft.setLines(lines);
  }

  // — UI flows (navigator + cubits) —

  Future<void> refreshInventoryFlow() async {
    try {
      await reloadData();
    } catch (e) {
      if (_navigator.isMounted) {
        _navigator.showToast('Could not refresh: $e', success: false);
      }
    }
  }

  Future<void> deleteItemFlow(ShopItem item) async {
    final confirmed = await _navigator.confirmDeleteItem(item);
    if (!confirmed || !_navigator.isMounted) return;
    try {
      await deleteItem(item.id);
    } catch (e) {
      if (_navigator.isMounted) {
        _navigator.showToast('Could not delete: $e', success: false);
      }
    }
  }

  Future<void> editItemFlow(ShopItem item) async {
    final updated = await _navigator.showItemForm(existing: item);
    if (updated == null || !_navigator.isMounted) return;
    try {
      await updateItem(updated);
      if (!_navigator.isMounted) return;
      _navigator.showToast('Updated ${updated.name}', success: true);
    } catch (e) {
      if (_navigator.isMounted) {
        _navigator.showToast('Could not save: $e', success: false);
      }
    }
  }

  Future<void> restockItemFlow(ShopItem item) async {
    final result = await _navigator.showRestockSheet(item);
    if (result == null || !_navigator.isMounted) return;
    try {
      await restockItem(
        item,
        count: result.count,
        unitCost: result.unitCost,
      );
      if (!_navigator.isMounted) return;
      _navigator.showToast(
        'Restocked ${result.count} × ${item.name} at '
        '${formatMoney(result.unitCost)} each',
        success: true,
      );
    } catch (e) {
      if (_navigator.isMounted) {
        _navigator.showToast('Could not restock: $e', success: false);
      }
    }
  }

  Future<void> clearAllSalesFlow() async {
    final count = state.sales.length;
    if (count == 0) {
      _navigator.showToast('No sales to clear', success: false);
      return;
    }
    final confirmed = await _navigator.confirmClearAllSales(count);
    if (!confirmed || !_navigator.isMounted) return;
    try {
      await clearAllSales();
      if (!_navigator.isMounted) return;
      _navigator.showToast(
        count == 1 ? 'Cleared 1 sale' : 'Cleared $count sales',
        success: true,
      );
    } catch (e) {
      if (_navigator.isMounted) {
        _navigator.showToast('Could not clear sales: $e', success: false);
      }
    }
  }

  Future<void> clearAllInventoryFlow() async {
    final count = state.items.length;
    if (count == 0) {
      _navigator.showToast('No inventory to clear', success: false);
      return;
    }
    final confirmed = await _navigator.confirmClearAllInventory(count);
    if (!confirmed || !_navigator.isMounted) return;
    try {
      await clearAllItems();
      if (!_navigator.isMounted) return;
      _navigator.showToast(
        count == 1 ? 'Cleared 1 item' : 'Cleared $count items',
        success: true,
      );
    } catch (e) {
      if (_navigator.isMounted) {
        _navigator.showToast('Could not clear inventory: $e', success: false);
      }
    }
  }

  Future<void> clearAllBulksFlow() async {
    final count = state.bulkShipments.length;
    if (count == 0) {
      _navigator.showToast('No bulks to clear', success: false);
      return;
    }
    final confirmed = await _navigator.confirmClearAllBulks(count);
    if (!confirmed || !_navigator.isMounted) return;
    try {
      await clearAllBulks();
      if (!_navigator.isMounted) return;
      _navigator.showToast(
        count == 1 ? 'Cleared 1 bulk' : 'Cleared $count bulks',
        success: true,
      );
    } catch (e) {
      if (_navigator.isMounted) {
        _navigator.showToast('Could not clear bulks: $e', success: false);
      }
    }
  }

  Future<void> openBulkHistory() => _navigator.openBulkHistory();

  Future<void> startBulkFlow(BulkOrderDraftCubit draft) async {
    draft.reset();
    await _navigator.openNewBulkOrder();
  }

  Future<void> openBulkShipment(String shipmentId) =>
      _navigator.openBulkShipment(shipmentId);

  Future<void> completeSellCartFlow(SellCartCubit cart) async {
    if (cart.state.isEmpty) return;

    final confirm = await _navigator.showSellCheckout();
    if (confirm != true || !_navigator.isMounted || cart.state.lines.isEmpty) {
      return;
    }

    var grandTotal = 0.0;
    var units = 0;
    for (final line in cart.state.lines) {
      grandTotal += line.unitPrice * line.quantity;
      units += line.quantity;
    }

    try {
      await completeSellCart(cart);
      if (_navigator.isMounted) {
        HapticFeedback.mediumImpact();
        _navigator.showToast(
          'Sold $units units · ${formatMoney(grandTotal)}',
          success: true,
        );
      }
    } on StateError catch (e) {
      if (_navigator.isMounted) {
        _navigator.showToast(e.message, success: false);
      }
    } catch (e) {
      if (_navigator.isMounted) {
        _navigator.showToast('Sale failed: $e', success: false);
      }
    }
  }

  Future<void> addToSellCartFlow(ShopItem item, SellCartCubit cart) async {
    final result = await _navigator.showSellSheet(item);
    if (result == null || !_navigator.isMounted) return;

    cart.addToCart(
      itemId: item.id,
      quantity: result.count,
      unitPrice: result.unitPrice,
    );

    if (!_navigator.isMounted) return;
    HapticFeedback.selectionClick();
    final types = cart.state.itemTypeCount;
    _navigator.showToast(
      'Added to sale · $types type${types == 1 ? '' : 's'} in cart',
      success: true,
    );
  }
}

ShopItem _afterRestock(ShopItem existing, BulkPurchaseLine line) {
  final newQty = existing.quantity + line.quantity;
  final newCost = existing.costPrice > 0
      ? (existing.quantity * existing.costPrice +
              line.quantity * line.costPrice) /
          newQty
      : line.costPrice;
  return existing.copyWith(
    quantity: newQty,
    costPrice: newCost,
    price: line.price,
    imagePath: line.imagePath ?? existing.imagePath,
  );
}

Map<String, ShopItem> _indexByName(List<ShopItem> items) {
  final map = <String, ShopItem>{};
  for (final item in items) {
    map[_nameKey(item.name)] = item;
  }
  return map;
}

String _nameKey(String name) => name.toLowerCase().trim();