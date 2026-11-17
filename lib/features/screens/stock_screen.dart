/// "Buy bulk" screen: scrollable portrait list for inventory management.
library;

import 'package:any/any.dart';
import 'package:flutter/material.dart';

import '../../commands/start_bulk_flow_command.dart';
import '../../commands/delete_item_flow_command.dart';
import '../../commands/edit_item_flow_command.dart';
import '../../commands/refresh_inventory_flow_command.dart';
import '../../commands/restock_item_flow_command.dart';
import '../../commands/update_search_query_command.dart';
import '../../models/shop_item_model.dart';
import '../../states/shop_state.dart';
import '../../ui/spacing.dart';
import '../widgets/bulk_shipment_card.dart';
import '../widgets/empty_views.dart';
import '../widgets/search_field.dart';
import '../widgets/stock_item_tile.dart';
import '../widgets/summary_strip.dart';

enum _StockFilter { all, low, out }

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  _StockFilter _filter = _StockFilter.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shopState = context.of<ShopState>();
    final activeBulks = shopState.activeBulkShipments;
    final all = shopState.items;
    final searched = shopState.filteredItems;
    final items = _applyStockFilter(searched);

    final lowCount = all.where((i) => i.inStock && i.quantity <= 3).length;
    final outCount = all.where((i) => !i.inStock).length;

    return RefreshIndicator(
      onRefresh: () => context(const RefreshInventoryFlowCommand()),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SummaryStrip(),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Bulks',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            context(const OpenBulkHistoryCommand()),
                        icon: const Icon(Icons.history, size: 20),
                        label: const Text('History'),
                      ),
                    ],
                  ),
                  if (activeBulks.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'In progress',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...activeBulks.map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: BulkShipmentCard(
                          shipment: b,
                          onTap: () =>
                              context(OpenBulkShipmentCommand(b.id)),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  SearchField(
                    query: shopState.searchQuery,
                    onChanged: (v) => context(UpdateSearchQueryCommand(v)),
                  ),
                  if (all.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _StockFilterChips(
                      filter: _filter,
                      lowCount: lowCount,
                      outCount: outCount,
                      onChanged: (f) => setState(() => _filter = f),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _stockFilterHint(all.length, items.length),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (all.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(),
            )
          else if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: shopState.searchQuery.isNotEmpty
                  ? NoSearchResults(
                      query: shopState.searchQuery,
                      onClear: () =>
                          context(const UpdateSearchQueryCommand('')),
                    )
                  : _FilteredEmptyStock(
                      filter: _filter,
                      onShowAll: () =>
                          setState(() => _filter = _StockFilter.all),
                    ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                96,
              ),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return StockItemTile(
                    item: item,
                    onEdit: () => context(EditItemFlowCommand(item)),
                    onRestock: () => context(RestockItemFlowCommand(item)),
                    onDelete: () => context(DeleteItemFlowCommand(item)),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  List<ShopItem> _applyStockFilter(List<ShopItem> items) {
    return switch (_filter) {
      _StockFilter.all => items,
      _StockFilter.low =>
        items.where((i) => i.inStock && i.quantity <= 3).toList(),
      _StockFilter.out => items.where((i) => !i.inStock).toList(),
    };
  }

  String _stockFilterHint(int total, int visible) {
    if (_filter == _StockFilter.all && visible == total) {
      return 'List view for portrait — Buy or Edit on each row.';
    }
    final name = switch (_filter) {
      _StockFilter.all => 'items',
      _StockFilter.low => 'low-stock items',
      _StockFilter.out => 'out-of-stock items',
    };
    return 'Showing $visible $name';
  }
}

class _StockFilterChips extends StatelessWidget {
  const _StockFilterChips({
    required this.filter,
    required this.lowCount,
    required this.outCount,
    required this.onChanged,
  });

  final _StockFilter filter;
  final int lowCount;
  final int outCount;
  final ValueChanged<_StockFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        FilterChip(
          label: const Text('All'),
          selected: filter == _StockFilter.all,
          onSelected: (_) => onChanged(_StockFilter.all),
        ),
        FilterChip(
          label: Text('Low ($lowCount)'),
          selected: filter == _StockFilter.low,
          onSelected: (_) => onChanged(_StockFilter.low),
        ),
        FilterChip(
          label: Text('Out ($outCount)'),
          selected: filter == _StockFilter.out,
          onSelected: (_) => onChanged(_StockFilter.out),
        ),
      ],
    );
  }
}

class _FilteredEmptyStock extends StatelessWidget {
  const _FilteredEmptyStock({
    required this.filter,
    required this.onShowAll,
  });

  final _StockFilter filter;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = switch (filter) {
      _StockFilter.low => 'No low-stock items — shelves look healthy.',
      _StockFilter.out => 'Nothing is out of stock right now.',
      _StockFilter.all => '',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.tonal(
              onPressed: onShowAll,
              child: const Text('Show all inventory'),
            ),
          ],
        ),
      ),
    );
  }
}