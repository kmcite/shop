import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import '../ui/format.dart';

import '../models/bulk_purchase_line_model.dart';
import '../models/bulk_shipment_line_model.dart';
import '../models/bulk_shipment_model.dart';
import '../models/customer_model.dart';
import '../models/sale_line_request.dart';
import '../models/shop_item_model.dart';
import '../features/app/app_router.dart';
import '../repositories/shop_repository.dart';
import 'bulk_order_draft_cubit.dart';
import 'sell_cart_cubit.dart';
import 'states/shop_state.dart';

const _darknessKey = 'dark';

class ShopCubit extends Cubit<ShopState> {
  ShopCubit({
    required this._repository,
    required this._router,
  }) : super(const ShopState());

  final ShopRepository _repository;
  final AppRouter _router;

  StreamSubscription<void>? _dataWatchSub;
  Timer? _reloadDebounce;

  Future<void> initialize() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await _repository.connect();
      emit(state.copyWith(bootstraped: true));
      await reloadData();
      await _startDatabaseWatch();
      final mode = await getThemeMode();
      emit(state.copyWith(themeMode: mode));
    } catch (error) {
      emit(state.copyWith(isLoading: false, error: error, bootstraped: false));
    }
  }

  Future<void> _startDatabaseWatch() async {
    await _dataWatchSub?.cancel();
    _dataWatchSub = _repository.watchShopData().listen((_) {
      _scheduleReloadFromDatabase();
    });
  }

  void _scheduleReloadFromDatabase() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 120), () {
      reloadData();
    });
  }

  @override
  Future<void> close() {
    _dataWatchSub?.cancel();
    _reloadDebounce?.cancel();
    return super.close();
  }

  Future<void> reloadData() async {
    final items = await _repository.getItems();
    final sales = await _repository.getSales();
    final bulks = await _repository.getBulkShipments();
    final customers = await _repository.getCustomers();
    final customerLedger = await _repository.getAllCustomerLedger();
    emit(
      state.copyWith(
        items: items,
        bulkShipments: bulks,
        sales: sales,
        customers: customers,
        customerLedger: customerLedger,
        isLoading: false,
        error: null,
      ),
    );
  }

  Future<ShopCustomer?> upsertCustomer({
    String id = '',
    required String name,
    String note = '',
    DateTime? createdAt,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      _router.showToast('Customer name is required', success: false);
      return null;
    }
    ShopCustomer? existing;
    if (id.isNotEmpty) {
      for (final c in state.customers) {
        if (c.id == id) {
          existing = c;
          break;
        }
      }
    }
    final customer = ShopCustomer(
      id: id,
      name: trimmed,
      note: note.trim(),
      createdAt: existing?.createdAt ?? createdAt ?? DateTime.now(),
    );
    final savedId = await _repository.upsertCustomer(customer);
    await reloadData();
    return ShopCustomer(
      id: savedId,
      name: customer.name,
      note: customer.note,
      createdAt: customer.createdAt,
    );
  }

  Future<void> deleteCustomer(String id) async {
    await _repository.deleteCustomer(id);
    await reloadData();
  }

  Future<bool> sellToCustomer({
    required String customerId,
    required List<SaleLineRequest> lines,
    double amountPaid = 0,
    String note = '',
  }) async {
    try {
      await _repository.sellToCustomer(
        customerId: customerId,
        lines: lines,
        amountPaid: amountPaid,
        note: note,
      );
      await reloadData();
      if (_router.isMounted) {
        HapticFeedback.mediumImpact();
        final total = lines.fold<double>(
          0,
          (sum, l) => sum + l.unitPrice * l.count,
        );
        final owed = total - amountPaid;
        _router.showToast(
          owed > 0.005
              ? 'Credit sale · owed ${formatMoney(owed)}'
              : 'Credit sale paid in full · ${formatMoney(total)}',
          success: true,
        );
      }
      return true;
    } on StateError catch (e) {
      if (_router.isMounted) {
        _router.showToast(e.message, success: false);
      }
      return false;
    } catch (e) {
      if (_router.isMounted) {
        _router.showToast('Credit sale failed: $e', success: false);
      }
      return false;
    }
  }

  Future<bool> recordCustomerPayment({
    required String customerId,
    required double amount,
    String note = '',
  }) async {
    try {
      await _repository.recordCustomerPayment(
        customerId: customerId,
        amount: amount,
        note: note,
      );
      await reloadData();
      if (_router.isMounted) {
        HapticFeedback.mediumImpact();
        _router.showToast(
          'Payment recorded · ${formatMoney(amount)}',
          success: true,
        );
      }
      return true;
    } on StateError catch (e) {
      if (_router.isMounted) {
        _router.showToast(e.message, success: false);
      }
      return false;
    } catch (e) {
      if (_router.isMounted) {
        _router.showToast('Payment failed: $e', success: false);
      }
      return false;
    }
  }

  void setThemeMode(ThemeMode mode) {
    _repository.setPreference(
      _darknessKey,
      mode == ThemeMode.dark ? 'true' : 'false',
    );
    emit(state.copyWith(themeMode: mode));
  }

  Future<ThemeMode> getThemeMode() async {
    final mode = await _repository.getPreference(_darknessKey);
    return mode == 'true' ? ThemeMode.dark : ThemeMode.light;
  }

  void setSearchQuery(String query) => emit(state.copyWith(searchQuery: query));

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

  // — UI flows (router + cubits) —

  Future<void> refreshInventoryFlow() async {
    try {
      await reloadData();
    } catch (e) {
      if (_router.isMounted) {
        _router.showToast('Could not refresh: $e', success: false);
      }
    }
  }

  Future<void> deleteItemFlow(ShopItem item) async {
    final confirmed = await _router.confirmDeleteItem(item);
    if (!confirmed || !_router.isMounted) return;
    try {
      await deleteItem(item.id);
    } catch (e) {
      if (_router.isMounted) {
        _router.showToast('Could not delete: $e', success: false);
      }
    }
  }

  Future<void> editItemFlow(ShopItem item) async {
    final updated = await _router.openItemForm(existing: item);
    if (updated == null || !_router.isMounted) return;
    try {
      await updateItem(updated);
      if (!_router.isMounted) return;
      _router.showToast('Updated ${updated.name}', success: true);
    } catch (e) {
      if (_router.isMounted) {
        _router.showToast('Could not save: $e', success: false);
      }
    }
  }

  Future<void> restockItemFlow(ShopItem item) async {
    final result = await _router.openRestock(item);
    if (result == null || !_router.isMounted) return;
    try {
      await restockItem(
        item,
        count: result.count,
        unitCost: result.unitCost,
      );
      if (!_router.isMounted) return;
      _router.showToast(
        'Restocked ${result.count} × ${item.name} at '
        '${formatMoney(result.unitCost)} each',
        success: true,
      );
    } catch (e) {
      if (_router.isMounted) {
        _router.showToast('Could not restock: $e', success: false);
      }
    }
  }

  Future<void> clearAllSalesFlow() async {
    final count = state.sales.length;
    if (count == 0) {
      _router.showToast('No sales to clear', success: false);
      return;
    }
    final confirmed = await _router.confirmClearAllSales(count);
    if (!confirmed || !_router.isMounted) return;
    try {
      await clearAllSales();
      if (!_router.isMounted) return;
      _router.showToast(
        count == 1 ? 'Cleared 1 sale' : 'Cleared $count sales',
        success: true,
      );
    } catch (e) {
      if (_router.isMounted) {
        _router.showToast('Could not clear sales: $e', success: false);
      }
    }
  }

  Future<void> clearAllInventoryFlow() async {
    final count = state.items.length;
    if (count == 0) {
      _router.showToast('No inventory to clear', success: false);
      return;
    }
    final confirmed = await _router.confirmClearAllInventory(count);
    if (!confirmed || !_router.isMounted) return;
    try {
      await clearAllItems();
      if (!_router.isMounted) return;
      _router.showToast(
        count == 1 ? 'Cleared 1 item' : 'Cleared $count items',
        success: true,
      );
    } catch (e) {
      if (_router.isMounted) {
        _router.showToast('Could not clear inventory: $e', success: false);
      }
    }
  }

  Future<void> clearAllBulksFlow() async {
    final count = state.bulkShipments.length;
    if (count == 0) {
      _router.showToast('No bulks to clear', success: false);
      return;
    }
    final confirmed = await _router.confirmClearAllBulks(count);
    if (!confirmed || !_router.isMounted) return;
    try {
      await clearAllBulks();
      if (!_router.isMounted) return;
      _router.showToast(
        count == 1 ? 'Cleared 1 bulk' : 'Cleared $count bulks',
        success: true,
      );
    } catch (e) {
      if (_router.isMounted) {
        _router.showToast('Could not clear bulks: $e', success: false);
      }
    }
  }

  Future<void> openBulkHistory() => _router.openBulkHistory();

  Future<void> startBulkFlow(BulkOrderDraftCubit draft) async {
    draft.reset();
    await _router.openNewBulkOrder();
  }

  Future<void> openBulkShipment(String shipmentId, {int? initialStep}) =>
      _router.openBulkShipment(shipmentId, initialStep: initialStep);

  Future<void> completeSellCartFlow(SellCartCubit cart) async {
    if (cart.state.isEmpty) return;

    final confirm = await _router.openSellCheckout();
    if (confirm != true || !_router.isMounted || cart.state.lines.isEmpty) {
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
      if (_router.isMounted) {
        HapticFeedback.mediumImpact();
        _router.showToast(
          'Sold $units units · ${formatMoney(grandTotal)}',
          success: true,
        );
      }
    } on StateError catch (e) {
      if (_router.isMounted) {
        _router.showToast(e.message, success: false);
      }
    } catch (e) {
      if (_router.isMounted) {
        _router.showToast('Sale failed: $e', success: false);
      }
    }
  }

  Future<void> addToSellCartFlow(ShopItem item, SellCartCubit cart) async {
    final result = await _router.openSell(item);
    if (result == null || !_router.isMounted) return;

    cart.addToCart(
      itemId: item.id,
      quantity: result.count,
      unitPrice: result.unitPrice,
    );

    if (!_router.isMounted) return;
    HapticFeedback.selectionClick();
    final types = cart.state.itemTypeCount;
    _router.showToast(
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
