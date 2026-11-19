import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shop/business/sell_cart_cubit.dart';
import 'package:shop/business/shop_cubit.dart';
import '../../ui/format.dart';
import '../../ui/spacing.dart';

/// Sticky checkout bar on the Sell tab while the cart has lines.
class SellCartBar extends StatelessWidget {
  const SellCartBar({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<SellCartCubit>().state;
    if (cart.isEmpty) return const SizedBox.shrink();

    var total = 0.0;
    for (final line in cart.lines) {
      total += line.unitPrice * line.quantity;
    }

    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${cart.itemTypeCount} type${cart.itemTypeCount == 1 ? '' : 's'} · ${cart.unitCount} units',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    formatMoney(total),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () => context.read<ShopCubit>().completeSellCartFlow(
                    context.read<SellCartCubit>(),
                  ),
              child: const Text('Review & sell'),
            ),
          ],
        ),
      ),
    );
  }
}
