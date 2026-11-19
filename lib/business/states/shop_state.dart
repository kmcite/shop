import 'package:flutter/material.dart';

import '../../models/bulk_shipment_model.dart';
import '../../models/customer_model.dart';
import '../../models/sale_model.dart';
import '../../models/shop_item_model.dart';

const _keep = Object();

/// Immutable application state held in [ShopCubit].
class ShopState {
  const ShopState({
    this.items = const [],
    this.bulkShipments = const [],
    this.sales = const [],
    this.customers = const [],
    this.customerLedger = const [],
    this.isLoading = true,
    this.error,
    this.searchQuery = '',
    this.bootstraped = false,
    this.themeMode = ThemeMode.system,
  });
  final bool bootstraped;

  /// All inventory items, sorted by name.
  final List<ShopItem> items;

  /// Wholesale lots in progress or completed.
  final List<BulkShipment> bulkShipments;

  /// All recorded sales, newest first.
  final List<ShopSale> sales;

  /// Credit customers.
  final List<ShopCustomer> customers;

  /// All customer ledger entries, newest first.
  final List<CustomerLedgerEntry> customerLedger;

  /// True while connecting to the database or loading the first page.
  final bool isLoading;

  /// Fatal connection/initialization error, shown with a Retry action.
  final Object? error;

  /// Current inventory search text.
  final String searchQuery;

  /// Light/dark preference; [ThemeMode.system] follows the platform
  /// until the user flips the toggle.
  final ThemeMode themeMode;

  bool get hasError => error != null;

  /// Bulks that still need receive, count, price, or stock-in steps.
  List<BulkShipment> get activeBulkShipments =>
      bulkShipments.where((b) => b.status.isActive).toList();

  List<BulkShipment> get completedBulkShipments {
    final list = bulkShipments
        .where((b) => b.status == BulkShipmentStatus.completed)
        .toList();
    list.sort((a, b) {
      final ac = a.completedAt ?? a.createdAt;
      final bc = b.completedAt ?? b.createdAt;
      return bc.compareTo(ac);
    });
    return list;
  }

  /// Items matching the current [searchQuery] (case-insensitive).
  List<ShopItem> get filteredItems {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((i) => i.name.toLowerCase().contains(q)).toList();
  }

  List<CustomerAccount> get customerAccounts {
    final byCustomer = <String, List<CustomerLedgerEntry>>{};
    for (final entry in customerLedger) {
      byCustomer.putIfAbsent(entry.customerId, () => []).add(entry);
    }
    return [
      for (final customer in customers)
        CustomerAccount(
          customer: customer,
          entries: byCustomer[customer.id] ?? const [],
        ),
    ];
  }

  /// Customers with money still owed, highest balance first.
  List<CustomerAccount> get customersWithBalance {
    final list = customerAccounts.where((a) => a.remaining > 0.005).toList()
      ..sort((a, b) => b.remaining.compareTo(a.remaining));
    return list;
  }

  double get totalCustomerReceivables => customerAccounts.fold<double>(
        0,
        (sum, account) => sum + (account.remaining > 0 ? account.remaining : 0),
      );

  CustomerAccount? accountFor(String customerId) {
    for (final account in customerAccounts) {
      if (account.customer.id == customerId) return account;
    }
    return null;
  }

  ShopState copyWith({
    List<ShopItem>? items,
    List<BulkShipment>? bulkShipments,
    List<ShopSale>? sales,
    List<ShopCustomer>? customers,
    List<CustomerLedgerEntry>? customerLedger,
    bool? isLoading,
    Object? error = _keep,
    String? searchQuery,
    bool? bootstraped,
    ThemeMode? themeMode,
  }) {
    return ShopState(
      items: items ?? this.items,
      bulkShipments: bulkShipments ?? this.bulkShipments,
      sales: sales ?? this.sales,
      customers: customers ?? this.customers,
      customerLedger: customerLedger ?? this.customerLedger,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _keep) ? this.error : error,
      searchQuery: searchQuery ?? this.searchQuery,
      bootstraped: bootstraped ?? this.bootstraped,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
