/// "Sales so far" panel: today's take, all-time revenue, units and profit.
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shop/business/shop_cubit.dart';
import '../../ui/format.dart';
import '../design/metro.dart';

class SalesSummaryCard extends StatelessWidget {
  const SalesSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtle = MetroTheme.of(context).colors.mutedForeground;
    final sales = context.watch<ShopCubit>().state.sales;

    final now = DateTime.now();
    var revenue = 0.0;
    var profit = 0.0;
    var units = 0;
    var todayTotal = 0.0;
    var todayCount = 0;

    for (final sale in sales) {
      revenue += sale.total;
      units += sale.quantity;
      final p = sale.profit;
      if (p != null) profit += p;
      final at = sale.soldAt;
      if (at.year == now.year && at.month == now.month && at.day == now.day) {
        todayTotal += sale.total;
        todayCount++;
      }
    }

    return MetroPanel(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments_outlined, size: 18, color: subtle),
              const SizedBox(width: MetroSpacing.xs),
              Expanded(
                child: Text(
                  'sales',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              if (sales.isNotEmpty)
                Text(
                  '${sales.length} sale${sales.length == 1 ? '' : 's'}',
                  style: theme.textTheme.bodySmall?.copyWith(color: subtle),
                ),
            ],
          ),
          const SizedBox(height: MetroSpacing.sm),
          if (sales.isEmpty)
            Text(
              'no sales yet — completed sales will add up here.',
              style: theme.textTheme.bodySmall?.copyWith(color: subtle),
            )
          else ...[
            Text(
              formatMoney(revenue),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w200,
                color: MetroColors.cyan,
              ),
            ),
            Text(
              'all-time revenue',
              style: theme.textTheme.bodySmall?.copyWith(color: subtle),
            ),
            const SizedBox(height: MetroSpacing.sm),
            const Divider(height: 1),
            const SizedBox(height: MetroSpacing.sm),
            Row(
              children: [
                _SalesStat(
                  label: 'today',
                  value: formatMoney(todayTotal),
                  hint: '$todayCount sale${todayCount == 1 ? '' : 's'}',
                ),
                _SalesStat(
                  label: 'units sold',
                  value: '$units',
                ),
                _SalesStat(
                  label: 'est. profit',
                  value: profit != 0 ? formatMoney(profit) : '—',
                  tint: profit < 0
                      ? theme.colorScheme.error
                      : MetroColors.cyan,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SalesStat extends StatelessWidget {
  const _SalesStat({
    required this.label,
    required this.value,
    this.hint,
    this.tint,
  });

  final String label;
  final String value;
  final String? hint;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtle = MetroTheme.of(context).colors.mutedForeground;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: subtle),
          ),
          const SizedBox(height: MetroSpacing.xxs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: tint,
            ),
          ),
          if (hint != null)
            Text(
              hint!,
              style: theme.textTheme.bodySmall?.copyWith(color: subtle),
            ),
        ],
      ),
    );
  }
}
