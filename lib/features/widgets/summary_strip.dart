/// Horizontally scrollable metrics row shown at the top of the home page.
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shop/business/shop_cubit.dart';
import '../../ui/format.dart';
import '../../ui/spacing.dart';
import '../../ui/widgets/metric_chip.dart';

class SummaryStrip extends StatelessWidget {
  const SummaryStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final items = context.watch<ShopCubit>().state.items;
    final sku = items.length;
    final units = items.fold<int>(0, (sum, i) => sum + i.quantity);
    final retail = items.fold<double>(
      0,
      (sum, i) => sum + i.price * i.quantity,
    );
    final invested = items.fold<double>(
      0,
      (sum, i) => sum + (i.hasCost ? i.costPrice * i.quantity : 0),
    );
    final low = items.where((i) => i.quantity > 0 && i.quantity <= 3).length;
    final out = items.where((i) => !i.inStock).length;

    final chips = <Widget>[
      MetricChip(icon: Icons.category_outlined, label: '$sku products'),
      MetricChip(icon: Icons.inventory_outlined, label: '$units units'),
      if (invested > 0)
        MetricChip(
          icon: Icons.savings_outlined,
          label: formatMoney(invested),
          subtitle: 'invested',
        ),
      MetricChip(
        icon: Icons.payments_outlined,
        label: formatMoney(retail),
        subtitle: 'retail value',
      ),
      if (low > 0)
        MetricChip(
          icon: Icons.warning_amber_rounded,
          label: '$low low',
          tint: Colors.amber,
        ),
      if (out > 0)
        MetricChip(
          icon: Icons.remove_shopping_cart_outlined,
          label: '$out out',
          tint: Theme.of(context).colorScheme.error,
        ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            chips[i],
          ],
        ],
      ),
    );
  }
}
