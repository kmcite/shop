import 'package:flutter/material.dart';

import '../models/bulk_shipment_model.dart';
import '../models/sale_model.dart';
import '../models/shop_item_model.dart';

const Object _keep = Object();

/// Immutable application state stored in the `any.dart` [Scope].
///
/// All mutations happen through commands in `lib/commands/`;
/// widgets read it with `context.of<ShopState>()`.
class ShopState {
  const ShopState({
    this.items = const [],
    this.bulkShipments = const [],
    this.sales = const [],
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

  ShopState copyWith({
    List<ShopItem>? items,
    List<BulkShipment>? bulkShipments,
    List<ShopSale>? sales,
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
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _keep) ? this.error : error,
      searchQuery: searchQuery ?? this.searchQuery,
      bootstraped: bootstraped ?? this.bootstraped,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
