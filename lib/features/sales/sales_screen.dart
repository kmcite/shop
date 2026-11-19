import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shop/business/shop_cubit.dart';

import '../../models/sale_model.dart';
import '../../ui/format.dart';
import '../../ui/spacing.dart';
import '../design/metro.dart';
import '../widgets/empty_views.dart';
import '../widgets/sales_summary_card.dart';
import '../widgets/search_field.dart';

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
    final subtle = MetroTheme.of(context).colors.mutedForeground;
    final allSales = context.watch<ShopCubit>().state.sales;
    final filtered = _applyFilters(allSales);
    final groups = _groupByDay(filtered);

    return MetroRefresh(
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
                  SearchField(
                    query: _query,
                    onChanged: (value) =>
                        setState(() => _query = value.trim()),
                    hintText: 'search sales by item\u2026',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  MetroPivotBar<_SalesFilter>(
                    selected: _filter,
                    onSelected: (value) => setState(() => _filter = value),
                    options: const [
                      MetroPivotOption(
                        value: _SalesFilter.all,
                        label: 'all',
                        icon: Icons.history,
                      ),
                      MetroPivotOption(
                        value: _SalesFilter.today,
                        label: 'today',
                        icon: Icons.today_outlined,
                      ),
                      MetroPivotOption(
                        value: _SalesFilter.week,
                        label: '7 days',
                        icon: Icons.date_range_outlined,
                      ),
                    ],
                  ),
                  if (allSales.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _filterSummary(allSales, filtered),
                      style: theme.textTheme.bodySmall?.copyWith(color: subtle),
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
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _SaleTile(sale: group.sales[index]),
                    childCount: group.sales.length,
                  ),
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
      return 'showing all ${all.length} sale${all.length == 1 ? '' : 's'}';
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
    return 'showing ${visible.length} of ${all.length} · ${parts.join(', ')}';
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
    final subtle = MetroTheme.of(context).colors.mutedForeground;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            label.toLowerCase(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w200,
              color: subtle,
            ),
          ),
        ),
        Text(
          formatMoney(dayTotal),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: MetroColors.cyan,
          ),
        ),
        const SizedBox(width: MetroSpacing.xs),
        Text(
          '· $saleCount',
          style: theme.textTheme.bodySmall?.copyWith(color: subtle),
        ),
      ],
    );
  }
}

class _SaleTile extends StatelessWidget {
  const _SaleTile({required this.sale});

  final ShopSale sale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtle = MetroTheme.of(context).colors.mutedForeground;
    final profit = sale.profit;
    final hasDiscount = sale.lines.any(
      (l) => l.listPrice > 0 && l.unitPrice < l.listPrice - 0.001,
    );

    return MetroListRow(
      onTap: () => Navigator.of(context).push(
        metroRoute(context: context, builder: (_) => SaleDetailScreen(sale: sale)),
      ),
      leading: Icon(Icons.shopping_bag_outlined, size: 22, color: subtle),
      title: sale.headline,
      subtitle: [
        if (sale.isMultiItem)
          sale.lines.map((l) => '${l.itemName} ×${l.quantity}').join(' · '),
        formatSaleClock(sale.soldAt),
      ].whereType<String>().where((s) => s.isNotEmpty).join('\n'),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatMoney(sale.total),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sale.isMultiItem
                ? '${sale.lineCount} lines · ${sale.quantity} units'
                : '×${sale.quantity} · ${formatMoney(sale.unitPrice)}',
            style: theme.textTheme.labelMedium?.copyWith(color: subtle),
          ),
          if (hasDiscount || profit != null) ...[
            const SizedBox(height: MetroSpacing.xxs),
            Wrap(
              spacing: MetroSpacing.xs,
              runSpacing: 2,
              alignment: WrapAlignment.end,
              children: [
                if (hasDiscount)
                  const MetroTag.inline(
                    icon: Icons.local_offer_outlined,
                    label: 'below list',
                  ),
                if (profit != null)
                  MetroTag.inline(
                    icon: Icons.trending_up,
                    label:
                        '${profit >= 0 ? '+' : ''}${formatMoney(profit)}',
                    accent: profit >= 0,
                    danger: profit < 0,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

}

class SaleDetailScreen extends StatelessWidget {
  const SaleDetailScreen({super.key, required this.sale});

  final ShopSale sale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profit = sale.profit;
    final title = (sale.isMultiItem ? 'multi-item sale' : sale.headline)
        .toLowerCase();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        children: [
          _DetailRow(label: 'when', value: sale.soldAt.toLocal().toString()),
          if (sale.isMultiItem)
            ...sale.lines.map(
              (l) => _DetailRow(
                label: l.itemName.toLowerCase(),
                value:
                    '×${l.quantity} @ ${formatMoney(l.unitPrice)} = ${formatMoney(l.total)}',
              ),
            )
          else ...[
            _DetailRow(
              label: 'quantity',
              value: '${sale.quantity} unit${sale.quantity == 1 ? '' : 's'}',
            ),
            _DetailRow(
              label: 'unit price',
              value: formatMoney(sale.unitPrice),
            ),
            if (sale.listPrice > 0)
              _DetailRow(
                label: 'list price',
                value: formatMoney(sale.listPrice),
              ),
          ],
          _DetailRow(label: 'total', value: formatMoney(sale.total)),
          if (profit != null)
            _DetailRow(
              label: 'est. profit',
              value: formatMoney(profit),
              valueColor: profit >= 0
                  ? MetroColors.cyan
                  : theme.colorScheme.error,
            ),
        ],
      ),
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
    final subtle = MetroTheme.of(context).colors.mutedForeground;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: subtle),
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

class _SalesEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtle = MetroTheme.of(context).colors.mutedForeground;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EmptyStateBadge(
            icon: Icons.receipt_long_outlined,
            color: subtle,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'no sales yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w200,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'build a sale on the sell tab, then complete it — '
            'each receipt shows here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: subtle),
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
    final subtle = MetroTheme.of(context).colors.mutedForeground;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EmptyStateBadge(
              icon: Icons.filter_alt_off_outlined,
              color: subtle,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'nothing matches',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'try another time range or clear your search.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: subtle),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton(
              onPressed: onClear,
              child: const Text('reset filters'),
            ),
          ],
        ),
      ),
    );
  }
}
