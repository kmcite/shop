import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shop/business/sell_cart_cubit.dart';
import 'package:shop/business/shop_cubit.dart';

import '../../models/sell_cart_line_model.dart';
import '../../models/shop_item_model.dart';
import '../../ui/format.dart';
import '../../ui/spacing.dart';

Future<bool?> openSellCheckoutSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _SellCheckoutSheet(),
  );
}

class _SellCheckoutSheet extends StatelessWidget {
  const _SellCheckoutSheet();

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<SellCartCubit>().state;
    final items = {
      for (final i in context.watch<ShopCubit>().state.items) i.id: i,
    };
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final theme = Theme.of(context);

    var grandTotal = 0.0;
    for (final line in cart.lines) {
      grandTotal += line.unitPrice * line.quantity;
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xl + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Sale receipt', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${cart.itemTypeCount} line${cart.itemTypeCount == 1 ? '' : 's'} · '
            '${cart.unitCount} units',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cart.lines.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final line = cart.lines[index];
              final item = items[line.itemId];
              return _CheckoutLineCard(
                index: index,
                item: item,
                line: line,
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: theme.textTheme.titleMedium),
              Text(
                formatMoney(grandTotal),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: cart.isEmpty
                ? null
                : () => Navigator.pop(context, true),
            child: const Text('Complete sale'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
        ],
      ),
    );
  }
}

class _CheckoutLineCard extends StatelessWidget {
  const _CheckoutLineCard({
    required this.index,
    required this.item,
    required this.line,
  });

  final int index;
  final ShopItem? item;
  final SellCartLine line;

  @override
  Widget build(BuildContext context) {
    final name = item?.name ?? 'Unknown';
    final lineTotal = line.unitPrice * line.quantity;

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: Text(name),
        subtitle: Text(
          '×${line.quantity} @ ${formatMoney(line.unitPrice)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatMoney(lineTotal),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            IconButton(
              tooltip: 'Remove',
              onPressed: () =>
                  context.read<SellCartCubit>().removeLine(index),
              icon: Icon(
                Icons.close,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}