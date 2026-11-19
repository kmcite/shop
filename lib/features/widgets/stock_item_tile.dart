/// Portrait-friendly inventory row: photo, pricing, stock, actions.
library;

import 'package:material_ui/material_ui.dart';

import '../../models/shop_item_model.dart';
import '../../ui/format.dart';
import '../../ui/item_photo.dart';
import '../../ui/spacing.dart';

class StockItemTile extends StatelessWidget {
  const StockItemTile({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onRestock,
    required this.onDelete,
  });

  final ShopItem item;
  final VoidCallback onEdit;
  final VoidCallback onRestock;
  final VoidCallback onDelete;

  static const double _photoSize = 72;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tone = _stockTone(scheme, item.quantity);

    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ItemPhotoBadge(item: item, size: _photoSize),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Sell ${formatMoney(item.price)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (item.hasCost) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Cost ${formatMoney(item.costPrice)} · '
                          '${item.marginPerUnit >= 0 ? '+' : ''}'
                          '${formatMoney(item.marginPerUnit)}/u',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: item.marginPerUnit >= 0
                                ? scheme.tertiary
                                : scheme.error,
                          ),
                        ),
                      ] else
                        Text(
                          'Cost not set',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(tone.icon, size: 18, color: tone.foreground),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    tone.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: tone.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: tone.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item.quantity}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: tone.foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.end,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onRestock,
                  icon: const Icon(Icons.add_box_outlined, size: 18),
                  label: const Text('Buy'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, color: scheme.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _StockTone _stockTone(ColorScheme scheme, int quantity) {
    if (quantity <= 0) {
      return _StockTone(
        icon: Icons.remove_shopping_cart_outlined,
        label: 'Out of stock',
        background: scheme.errorContainer,
        foreground: scheme.onErrorContainer,
      );
    }
    if (quantity <= 3) {
      return _StockTone(
        icon: Icons.warning_amber_rounded,
        label: 'Low stock',
        background: scheme.tertiaryContainer,
        foreground: scheme.onTertiaryContainer,
      );
    }
    return _StockTone(
      icon: Icons.inventory_2_outlined,
      label: 'In stock',
      background: scheme.primaryContainer,
      foreground: scheme.onPrimaryContainer,
    );
  }
}

class _StockTone {
  const _StockTone({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
}