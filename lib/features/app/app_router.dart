import 'package:flutter/material.dart';

import '../../models/shop_item_model.dart';
import '../../ui/spacing.dart';
import '../bulk/bulk_history_screen.dart';
import '../bulk/bulk_order_screen.dart';
import '../bulk/bulk_shipment_hub_screen.dart';
import '../design/metro.dart';
import '../widgets/item_form_sheet.dart';
import '../stock/restock_screen.dart';
import '../sell/review_sale_screen.dart';
import '../widgets/sell_sheet.dart';

/// App-wide navigation: screens, dialogs, and toasts.
///
/// Owns the [MaterialApp] [navigatorKey]. Not a repository — construct once
/// in `main` and pass into [ShopCubit] / [ShopApplication].
class AppRouter {
  AppRouter() : navigatorKey = GlobalKey<NavigatorState>();

  final GlobalKey<NavigatorState> navigatorKey;

  BuildContext? get _context => navigatorKey.currentContext;

  bool get isMounted => _context?.mounted ?? false;

  NavigatorState? get _nav => navigatorKey.currentState;

  // — Feedback —

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

  // — Dialogs —

  Future<bool> confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final context = _context;
    if (context == null || !context.mounted) return false;

    final yes = await showMetroDialog<bool>(
      context: context,
      title: title,
      message: message,
      actions: [
        MetroDialogAction(
          label: 'Keep',
          onPressed: () => Navigator.pop(context, false),
        ),
        MetroDialogAction(
          label: confirmLabel,
          accent: true,
          destructive: true,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
    return yes == true;
  }

  Future<bool> confirmDeleteItem(ShopItem item) {
    return confirm(
      title: 'Remove from inventory?',
      message:
          '“${item.name}” will be deleted. Past sales stay in the database.',
      confirmLabel: 'Delete',
    );
  }

  Future<bool> confirmClearAllSales(int saleCount) {
    final noun = saleCount == 1 ? 'sale' : 'sales';
    return confirm(
      title: 'Clear all sales?',
      message:
          'This permanently removes all $saleCount $noun from the database. '
          'Inventory is not affected.',
      confirmLabel: 'Clear sales',
    );
  }

  Future<bool> confirmClearAllInventory(int itemCount) {
    final noun = itemCount == 1 ? 'item' : 'items';
    return confirm(
      title: 'Clear all inventory?',
      message:
          'This permanently removes all $itemCount $noun from the database. '
          'Past sales records stay, but stock will be empty.',
      confirmLabel: 'Clear inventory',
    );
  }

  Future<bool> confirmClearAllBulks(int bulkCount) {
    final noun = bulkCount == 1 ? 'bulk' : 'bulks';
    return confirm(
      title: 'Clear all bulks?',
      message:
          'This permanently removes all $bulkCount $noun from the database '
          '(in progress and history). Inventory and sales are not affected.',
      confirmLabel: 'Clear bulks',
    );
  }

  // — Screens —

  Future<ShopItem?> openItemForm({required ShopItem existing}) {
    final context = _context;
    if (context == null || !context.mounted) return Future.value();
    return openItemFormSheet(context, existing: existing);
  }

  Future<RestockResult?> openRestock(ShopItem item) {
    final context = _context;
    if (context == null || !context.mounted) return Future.value();
    return openRestockScreen(context, item);
  }

  Future<SellSheetResult?> openSell(ShopItem item) {
    final context = _context;
    if (context == null || !context.mounted) return Future.value();
    return openSellSheet(context, item);
  }

  Future<bool?> openSellCheckout() {
    final context = _context;
    if (context == null || !context.mounted) return Future.value();
    return openReviewSaleScreen(context);
  }

  Future<void> openNewBulkOrder() async {
    final context = _context;
    if (context == null || !context.mounted) return;
    await _nav?.push(BulkOrderScreen.route(context));
  }

  Future<void> openBulkHistory() async {
    final context = _context;
    if (context == null || !context.mounted) return;
    await _nav?.push(BulkHistoryScreen.route(context));
  }

  Future<void> openBulkShipment(String shipmentId, {int? initialStep}) async {
    final context = _context;
    if (context == null || !context.mounted) return;
    await _nav?.push(
      BulkShipmentHubScreen.route(
        context,
        shipmentId,
        initialStep: initialStep,
      ),
    );
  }
}
