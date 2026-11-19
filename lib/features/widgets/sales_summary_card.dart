/// "Sales so far" card on the Sell page: today's take, all-time
/// revenue, units sold and estimated profit — all read from [ShopState].
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shop/business/shop_cubit.dart';
import '../../ui/format.dart';
import '../../ui/spacing.dart';

class SalesSummaryCard extends StatelessWidget {
  const SalesSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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

    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payments_outlined, size: 20, color: scheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Sales',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (sales.isNotEmpty)
                  Text(
                    '${sales.length} sale${sales.length == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (sales.isEmpty)
              Text(
                'No sales yet — completed sales will add up here.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              )
            else ...[
              Text(
                formatMoney(revenue),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'all-time revenue',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _SalesStat(
                    label: 'Today',
                    value: formatMoney(todayTotal),
                    hint: '$todayCount sale${todayCount == 1 ? '' : 's'}',
                  ),
                  _SalesStat(
                    label: 'Units sold',
                    value: '$units',
                  ),
                  _SalesStat(
                    label: 'Est. profit',
                    value: profit != 0 ? formatMoney(profit) : '—',
                    tint: profit >= 0 ? scheme.primary : scheme.error,
                  ),
                ],
              ),
            ],
          ],
        ),
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
    final scheme = theme.colorScheme;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: tint,
            ),
          ),
          if (hint != null)
            Text(
              hint!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
