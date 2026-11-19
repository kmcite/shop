import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shop/business/shop_cubit.dart';

import '../../models/sale_model.dart';
import '../../ui/format.dart';
import '../../ui/spacing.dart';
import '../widgets/empty_views.dart';
import '../widgets/sales_summary_card.dart';

enum _SalesFilter { all, today, week }

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  _SalesFilter _filter = _SalesFilter.all;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final allSales = context.watch<ShopCubit>().state.sales;
    final filtered = _applyFilters(allSales);
    final groups = _groupByDay(filtered);

    return RefreshIndicator(
      onRefresh: () => context.read<ShopCubit>().refreshInventoryFlow(),
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
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SalesSummaryCard(),
                  const SizedBox(height: AppSpacing.lg),
                  SearchBar(
                    hintText: 'Search sales by item\u2026',
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
                  const SizedBox(height: AppSpacing.md),
                  SegmentedButton<_SalesFilter>(
                    segments: const [
                      ButtonSegment(
                        value: _SalesFilter.all,
                        label: Text('All'),
                        icon: Icon(Icons.history),
                      ),
                      ButtonSegment(
                        value: _SalesFilter.today,
                        label: Text('Today'),
                        icon: Icon(Icons.today_outlined),
                      ),
                      ButtonSegment(
                        value: _SalesFilter.week,
                        label: Text('7 days'),
                        icon: Icon(Icons.date_range_outlined),
                      ),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (value) {
                      setState(() => _filter = value.first);
                    },
                  ),
                  if (allSales.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _filterSummary(allSales, filtered),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (allSales.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _SalesEmptyState(),
            )
          else if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _NoMatchingSales(
                onClear: () => setState(() {
                  _query = '';
                  _filter = _SalesFilter.all;
                }),
              ),
            )
          else
            ...groups.expand((group) sync* {
              yield SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                sliver: SliverToBoxAdapter(
                  child: _DaySectionHeader(
                    label: group.label,
                    saleCount: group.sales.length,
                    dayTotal: group.sales.fold<double>(
                      0,
                      (sum, s) => sum + s.total,
                    ),
                  ),
                ),
              );
              yield SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverList.separated(
                  itemCount: group.sales.length,
                  separatorBuilder: (context, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) =>
                      _SaleCard(sale: group.sales[index]),
                ),
              );
            }),
          const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
        ],
      ),
    );
  }

  List<ShopSale> _applyFilters(List<ShopSale> sales) {
    final now = DateTime.now();
    final q = _query.toLowerCase();

    return sales.where((sale) {
      if (q.isNotEmpty &&
          !sale.lines.any((l) => l.itemName.toLowerCase().contains(q))) {
        return false;
      }
      final at = sale.soldAt.toLocal();
      switch (_filter) {
        case _SalesFilter.all:
          return true;
        case _SalesFilter.today:
          return at.year == now.year &&
              at.month == now.month &&
              at.day == now.day;
        case _SalesFilter.week:
          final cutoff = now.subtract(const Duration(days: 7));
          return !at.isBefore(cutoff);
      }
    }).toList();
  }

  List<({String label, List<ShopSale> sales})> _groupByDay(
    List<ShopSale> sales,
  ) {
    if (sales.isEmpty) return [];
    final now = DateTime.now();
    final map = <String, List<ShopSale>>{};
    final order = <String>[];

    for (final sale in sales) {
      final label = formatSaleDayHeading(sale.soldAt, now);
      if (!map.containsKey(label)) {
        map[label] = [];
        order.add(label);
      }
      map[label]!.add(sale);
    }

    return [
      for (final label in order) (label: label, sales: map[label]!),
    ];
  }

  String _filterSummary(List<ShopSale> all, List<ShopSale> visible) {
    if (_filter == _SalesFilter.all && _query.isEmpty) {
      return 'Showing all ${all.length} sale${all.length == 1 ? '' : 's'}';
    }
    final parts = <String>[];
    if (_filter != _SalesFilter.all) {
      parts.add(switch (_filter) {
        _SalesFilter.today => 'today only',
        _SalesFilter.week => 'last 7 days',
        _SalesFilter.all => '',
      });
    }
    if (_query.isNotEmpty) parts.add('matching “$_query”');
    return 'Showing ${visible.length} of ${all.length} · ${parts.join(', ')}';
  }
}

class _DaySectionHeader extends StatelessWidget {
  const _DaySectionHeader({
    required this.label,
    required this.saleCount,
    required this.dayTotal,
  });

  final String label;
  final int saleCount;
  final double dayTotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          formatMoney(dayTotal),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.primary,
          ),
        ),
        Badge(
          label: Text('$saleCount'),
          backgroundColor: scheme.secondaryContainer,
          textColor: scheme.onSecondaryContainer,
        ),
      ],
    );
  }
}

class _SaleCard extends StatelessWidget {
  const _SaleCard({required this.sale});

  final ShopSale sale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final profit = sale.profit;
    final hasDiscount = sale.lines.any(
      (l) => l.listPrice > 0 && l.unitPrice < l.listPrice - 0.001,
    );

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showSaleDetail(context),
        child: Padding(
          padding: AppSpacing.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: scheme.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.headline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (sale.isMultiItem) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            sale.lines
                                .map(
                                  (l) =>
                                      '${l.itemName} ×${l.quantity}',
                                )
                                .join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          formatSaleClock(sale.soldAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            formatMoney(sale.total),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          sale.isMultiItem
                              ? '${sale.lineCount} lines · ${sale.quantity} units'
                              : '×${sale.quantity} · ${formatMoney(sale.unitPrice)}',
                          textAlign: TextAlign.end,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (hasDiscount || profit != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (hasDiscount)
                      _SaleTag(
                        icon: Icons.local_offer_outlined,
                        label: 'Below list',
                        background: scheme.tertiaryContainer,
                        foreground: scheme.onTertiaryContainer,
                      ),
                    if (profit != null)
                      _SaleTag(
                        icon: Icons.trending_up,
                        label:
                            '${profit >= 0 ? '+' : ''}${formatMoney(profit)}',
                        background: profit >= 0
                            ? scheme.primaryContainer
                            : scheme.errorContainer,
                        foreground: profit >= 0
                            ? scheme.onPrimaryContainer
                            : scheme.onErrorContainer,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showSaleDetail(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final profit = sale.profit;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                sale.isMultiItem ? 'Multi-item sale' : sale.headline,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _DetailRow(label: 'When', value: sale.soldAt.toLocal().toString()),
              if (sale.isMultiItem)
                ...sale.lines.map(
                  (l) => _DetailRow(
                    label: l.itemName,
                    value:
                        '×${l.quantity} @ ${formatMoney(l.unitPrice)} = ${formatMoney(l.total)}',
                  ),
                )
              else ...[
                _DetailRow(
                  label: 'Quantity',
                  value: '${sale.quantity} unit${sale.quantity == 1 ? '' : 's'}',
                ),
                _DetailRow(
                  label: 'Unit price',
                  value: formatMoney(sale.unitPrice),
                ),
                if (sale.listPrice > 0)
                  _DetailRow(
                    label: 'List price',
                    value: formatMoney(sale.listPrice),
                  ),
              ],
              _DetailRow(label: 'Total', value: formatMoney(sale.total)),
              if (profit != null)
                _DetailRow(
                  label: 'Est. profit',
                  value: formatMoney(profit),
                  valueColor: profit >= 0 ? scheme.primary : scheme.error,
                ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleTag extends StatelessWidget {
  const _SaleTag({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EmptyStateBadge(
            icon: Icons.receipt_long_outlined,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'No sales yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Build a sale on the Sell tab (one or many items), then '
            'complete it — each receipt shows here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoMatchingSales extends StatelessWidget {
  const _NoMatchingSales({required this.onClear});

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
              icon: Icons.filter_alt_off_outlined,
              color: theme.colorScheme.tertiary,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Nothing matches',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Try another time range or clear your search.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.tonalIcon(
              onPressed: onClear,
              icon: const Icon(Icons.clear_all),
              label: const Text('Reset filters'),
            ),
          ],
        ),
      ),
    );
  }
}