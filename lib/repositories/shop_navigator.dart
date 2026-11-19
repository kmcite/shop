import 'package:material_ui/material_ui.dart';

import '../features/bulk/bulk_history_screen.dart';
import '../features/bulk/bulk_order_screen.dart';
import '../features/bulk/bulk_shipment_hub_screen.dart';
import '../features/widgets/item_form_sheet.dart';
import '../features/widgets/restock_sheet.dart';
import '../features/widgets/sell_checkout_sheet.dart';
import '../features/widgets/sell_sheet.dart';
import '../models/shop_item_model.dart';
import '../ui/spacing.dart';

/// Modal dialogs, sheets, and toasts for inventory flows — used from
/// [ShopCubit] flow methods that cannot take a [BuildContext].
abstract interface class ShopNavigator {
  bool get isMounted;

  void showToast(String message, {required bool success});

  Future<bool> confirmDeleteItem(ShopItem item);

  Future<ShopItem?> showItemForm({required ShopItem existing});

  Future<void> openNewBulkOrder();

  Future<void> openBulkShipment(String shipmentId);

  Future<void> openBulkHistory();

  Future<RestockResult?> showRestockSheet(ShopItem item);

  Future<SellSheetResult?> showSellSheet(ShopItem item);

  Future<bool?> showSellCheckout();

  Future<bool> confirmClearAllSales(int saleCount);

  Future<bool> confirmClearAllInventory(int itemCount);

  Future<bool> confirmClearAllBulks(int bulkCount);
}

class ShopNavigatorImpl implements ShopNavigator {
  ShopNavigatorImpl(this._navigatorKey);

  final GlobalKey<NavigatorState> _navigatorKey;

  BuildContext? get _context => _navigatorKey.currentContext;

  @override
  bool get isMounted => _context?.mounted ?? false;

  @override
  void showToast(String message, {required bool success}) {
    final context = _context;
    if (context == null || !context.mounted) return;

    final scheme = Theme.of(context).colorScheme;
    final fg = scheme.onInverseSurface;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: fg,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: fg, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: scheme.inverseSurface,
      ),
    );
  }

  @override
  Future<bool> confirmDeleteItem(ShopItem item) async {
    final context = _context;
    if (context == null || !context.mounted) return false;

    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from inventory?'),
        content: Text(
          '“${item.name}” will be deleted. Past sales stay in the database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return yes == true;
  }

  @override
  Future<ShopItem?> showItemForm({required ShopItem existing}) {
    final context = _context;
    if (context == null || !context.mounted) {
      return Future.value();
    }
    return openItemFormSheet(context, existing: existing);
  }

  @override
  Future<void> openNewBulkOrder() async {
    final context = _context;
    if (context == null || !context.mounted) return;
    await Navigator.of(context).push(BulkOrderScreen.route());
  }

  @override
  Future<void> openBulkHistory() async {
    final context = _context;
    if (context == null || !context.mounted) return;
    await Navigator.of(context).push(BulkHistoryScreen.route());
  }

  @override
  Future<void> openBulkShipment(String shipmentId) async {
    final context = _context;
    if (context == null || !context.mounted) return;
    await Navigator.of(context).push(BulkShipmentHubScreen.route(shipmentId));
  }

  @override
  Future<RestockResult?> showRestockSheet(ShopItem item) {
    final context = _context;
    if (context == null || !context.mounted) {
      return Future.value();
    }
    return openRestockSheet(context, item);
  }

  @override
  Future<bool?> showSellCheckout() {
    final context = _context;
    if (context == null || !context.mounted) {
      return Future.value();
    }
    return openSellCheckoutSheet(context);
  }

  @override
  Future<SellSheetResult?> showSellSheet(ShopItem item) {
    final context = _context;
    if (context == null || !context.mounted) {
      return Future.value();
    }
    return openSellSheet(context, item);
  }

  @override
  Future<bool> confirmClearAllSales(int saleCount) async {
    final context = _context;
    if (context == null || !context.mounted) return false;

    final noun = saleCount == 1 ? 'sale' : 'sales';
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all sales?'),
        content: Text(
          'This permanently removes all $saleCount $noun from the database. '
          'Inventory is not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear sales'),
          ),
        ],
      ),
    );
    return yes == true;
  }

  @override
  Future<bool> confirmClearAllInventory(int itemCount) async {
    final context = _context;
    if (context == null || !context.mounted) return false;

    final noun = itemCount == 1 ? 'item' : 'items';
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all inventory?'),
        content: Text(
          'This permanently removes all $itemCount $noun from the database. '
          'Past sales records stay, but stock will be empty.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear inventory'),
          ),
        ],
      ),
    );
    return yes == true;
  }

  @override
  Future<bool> confirmClearAllBulks(int bulkCount) async {
    final context = _context;
    if (context == null || !context.mounted) return false;

    final noun = bulkCount == 1 ? 'bulk' : 'bulks';
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all bulks?'),
        content: Text(
          'This permanently removes all $bulkCount $noun from the database '
          '(in progress and history). Inventory and sales are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear bulks'),
          ),
        ],
      ),
    );
    return yes == true;
  }
}
