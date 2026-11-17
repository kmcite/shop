/// Portrait list row optimized for one-thumb selling.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/shop_item_model.dart';
import '../../ui/format.dart';
import '../../ui/item_photo.dart';
import '../../ui/spacing.dart';

class SellItemTile extends StatelessWidget {
  const SellItemTile({
    super.key,
    required this.item,
    required this.onSell,
    required this.onRestock,
    this.onQuickAdd,
  });

  final ShopItem item;
  final VoidCallback onSell;
  final VoidCallback onRestock;
  final VoidCallback? onQuickAdd;

  bool get _canSell => item.inStock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: _canSell ? scheme.surfaceContainerLow : scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (_canSell) {
            onQuickAdd?.call();
          } else {
            onRestock();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ItemPhotoBadge(item: item, size: 64),
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
                      formatMoney(item.price),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _statusLine(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: !_canSell
                            ? scheme.error
                            : item.quantity <= 3
                            ? scheme.tertiary
                            : scheme.onSurfaceVariant,
                        fontWeight:
                            _canSell && item.quantity <= 3 ? FontWeight.w600 : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: _canSell
                          ? scheme.primaryContainer
                          : scheme.errorContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _canSell ? '×${item.quantity}' : '0',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: _canSell
                            ? scheme.onPrimaryContainer
                            : scheme.onErrorContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _canSell
                      ? FilledButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            onSell();
                          },
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            minimumSize: const Size(72, 36),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                          ),
                          child: const Text('Add'),
                        )
                      : OutlinedButton(
                          onPressed: onRestock,
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            minimumSize: const Size(72, 36),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                          ),
                          child: const Text('Stock'),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLine() {
    if (!_canSell) return 'Out of stock — restock to sell';
    if (item.quantity <= 3) return 'Only ${item.quantity} left';
    return '${item.quantity} on the floor';
  }
}