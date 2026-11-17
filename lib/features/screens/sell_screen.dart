/// "Sell" screen: portrait list rows with a compact floor counter.
library;

import 'package:any/any.dart';
import 'package:flutter/material.dart';

import '../../commands/refresh_inventory_flow_command.dart';
import '../../commands/restock_item_flow_command.dart';
import '../../commands/add_to_sell_cart_flow_command.dart';
import '../../commands/sell_cart_commands.dart';
import '../../models/shop_item_model.dart';
import '../../states/shop_state.dart';
import '../../ui/format.dart';
import '../../ui/spacing.dart';
import '../widgets/empty_views.dart';
import '../widgets/sell_cart_bar.dart';
import '../widgets/sell_item_tile.dart';

enum _SellScope { ready, all }

class SellScreen extends StatefulWidget {
  const SellScreen({super.key, required this.onGoToStock});

  final VoidCallback onGoToStock;

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  _SellScope _scope = _SellScope.ready;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shopState = context.of<ShopState>();
    final all = shopState.items;
    final items = _visibleItems(shopState);
    final inStock = all.where((i) => i.inStock);
    final readyCount = inStock.length;
    final floorUnits = inStock.fold<int>(0, (sum, i) => sum + i.quantity);
    final floorRetail = inStock.fold<double>(
      0,
      (sum, i) => sum + i.price * i.quantity,
    );

    return Scaffold(
      body: RefreshIndicator(
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
                  if (all.isNotEmpty) ...[
                    _SellCounterHeader(
                      readySkus: readyCount,
                      floorUnits: floorUnits,
                      floorRetail: floorRetail,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  SearchBar(
                    hintText: 'Find something to sell\u2026',
                    leading: Icon(Icons.search, color: scheme.onSurfaceVariant),
                    trailing: _query.isEmpty
                        ? null
                        : [
                            IconButton(
                              tooltip: 'Clear',
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() => _query = ''),
                            ),
                          ],
                    onChanged: (value) => setState(() => _query = value.trim()),
                  ),
                  if (all.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        FilterChip(
                          label: Text('Ready ($readyCount)'),
                          selected: _scope == _SellScope.ready,
                          onSelected: (_) =>
                              setState(() => _scope = _SellScope.ready),
                        ),
                        FilterChip(
                          label: Text('All (${all.length})'),
                          selected: _scope == _SellScope.all,
                          onSelected: (_) =>
                              setState(() => _scope = _SellScope.all),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _sellHint(items.length, readyCount),
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
            SliverFillRemaining(
              hasScrollBody: false,
              child: _SellEmptyState(onGoToStock: widget.onGoToStock),
            )
          else if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _query.isNotEmpty
                  ? _SellNoSearch(
                      query: _query,
                      onClear: () => setState(() => _query = ''),
                    )
                  : _SellScopeEmpty(
                      onShowAll: () =>
                          setState(() => _scope = _SellScope.all),
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
                  return SellItemTile(
                    item: item,
                    onSell: () => context(AddToSellCartFlowCommand(item)),
                    onQuickAdd: item.inStock
                        ? () => context(AddShopItemToCartCommand(item))
                        : null,
                    onRestock: () => context(RestockItemFlowCommand(item)),
                  );
                },
              ),
            ),
        ],
      ),
    ),
      bottomNavigationBar: const SellCartBar(),
    );
  }

  List<ShopItem> _visibleItems(ShopState shopState) {
    var list = shopState.filteredItems;
    final q = _query.toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((i) => i.name.toLowerCase().contains(q)).toList();
    }
    if (_scope == _SellScope.ready) {
      list = list.where((i) => i.inStock).toList();
    } else {
      final inStock = <ShopItem>[];
      final out = <ShopItem>[];
      for (final item in list) {
        (item.inStock ? inStock : out).add(item);
      }
      list = [...inStock, ...out];
    }
    return list;
  }

  String _sellHint(int visible, int ready) {
    if (_scope == _SellScope.ready) {
      return visible == 0
          ? 'Nothing on the floor — show all or restock.'
          : 'Tap row for +1 at list · Sell to negotiate · Review when ready.';
    }
    return 'In-stock rows first · tap to sell or restock.';
  }
}

class _SellCounterHeader extends StatelessWidget {
  const _SellCounterHeader({
    required this.readySkus,
    required this.floorUnits,
    required this.floorRetail,
  });

  final int readySkus;
  final int floorUnits;
  final double floorRetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primaryContainer,
              scheme.secondaryContainer.withValues(alpha: 0.85),
            ],
          ),
        ),
        child: Padding(
          padding: AppSpacing.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.point_of_sale_rounded,
                    color: scheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'On the floor',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$readySkus',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onPrimaryContainer,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'SKU${readySkus == 1 ? '' : 's'} · $floorUnits units',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimaryContainer.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatMoney(floorRetail),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ),
              Text(
                'list value on hand',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSecondaryContainer.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SellEmptyState extends StatelessWidget {
  const _SellEmptyState({required this.onGoToStock});

  final VoidCallback onGoToStock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EmptyStateBadge(
            icon: Icons.point_of_sale,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Floor is empty',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Stock in from Buy bulk, then add items to a sale here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: onGoToStock,
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Go to inventory'),
          ),
        ],
      ),
    );
  }
}

class _SellNoSearch extends StatelessWidget {
  const _SellNoSearch({required this.query, required this.onClear});

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EmptyStateBadge(
              icon: Icons.search_off,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'No matches',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Nothing matches “$query”.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.tonalIcon(
              onPressed: onClear,
              icon: const Icon(Icons.clear),
              label: const Text('Clear search'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SellScopeEmpty extends StatelessWidget {
  const _SellScopeEmpty({required this.onShowAll});

  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EmptyStateBadge(
              icon: Icons.remove_shopping_cart_outlined,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Nothing ready to sell',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Restock from Buy bulk, or browse all products.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.tonal(
              onPressed: onShowAll,
              child: const Text('Show all products'),
            ),
          ],
        ),
      ),
    );
  }
}