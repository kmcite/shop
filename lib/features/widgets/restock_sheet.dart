import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../models/shop_item_model.dart';
import '../../ui/format.dart';
import '../../ui/item_photo.dart';
import '../../ui/spacing.dart';

class RestockResult {
  const RestockResult({required this.count, required this.unitCost});

  /// Units added by this purchase.
  final int count;

  /// What was paid per unit in this purchase.
  final double unitCost;
}

/// Opens the "buy bulk" sheet for an existing item: pick how many units
/// arrived and what each cost, then the repository folds them into the
/// item's weighted-average cost.
Future<RestockResult?> openRestockSheet(
  BuildContext context,
  ShopItem item,
) {
  return showModalBottomSheet<RestockResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _RestockSheet(item: item),
  );
}

class _RestockSheet extends StatefulWidget {
  const _RestockSheet({required this.item});

  final ShopItem item;

  @override
  State<_RestockSheet> createState() => _RestockSheetState();
}

class _RestockSheetState extends State<_RestockSheet> {
  late int _count = 1;
  late final TextEditingController _costCtrl = TextEditingController(
    text: widget.item.hasCost ? _priceText(widget.item.costPrice) : '',
  );

  double? get _unitCost {
    final text = _costCtrl.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  void _bump(int delta) {
    final next = (_count + delta).clamp(1, 999999);
    if (next == _count) {
      HapticFeedback.lightImpact();
      return;
    }
    setState(() => _count = next);
    HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    _costCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final unitCost = _unitCost;
    final canConfirm = unitCost != null && unitCost >= 0;

    // Projected weighted-average cost after this purchase.
    final newQty = item.quantity + _count;
    final newAvgCost = unitCost != null && unitCost >= 0
        ? (item.hasCost
            ? (item.quantity * item.costPrice + _count * unitCost) / newQty
            : unitCost)
        : null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Buy bulk', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                ItemPhotoBadge(item: item, size: 52),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: item.name,
                      children: [
                        TextSpan(
                          text: '  ·  ${item.quantity} on hand',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                IconButton(
                  tooltip: 'Decrease',
                  onPressed: _count > 1 ? () => _bump(-1) : null,
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$_count',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'units received',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Increase',
                  onPressed: _count < 999999 ? () => _bump(1) : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _costCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Cost per unit',
                helperText: 'What you paid per unit in this purchase',
                prefixIcon: const Icon(Icons.shopping_bag_outlined),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: AppSpacing.card,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.4),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Purchase total',
                    value: unitCost != null ? unitCost * _count : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _SummaryRow(
                    label: 'Stock after',
                    valueText: '$newQty units',
                  ),
                  if (newAvgCost != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _SummaryRow(
                      label: 'New avg cost',
                      value: newAvgCost,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: canConfirm
                  ? () => Navigator.pop(
                      context,
                      RestockResult(count: _count, unitCost: unitCost),
                    )
                  : null,
              icon: const Icon(Icons.inventory_2_outlined),
              label: Text(
                canConfirm
                    ? 'Add $_count units · ${formatMoney(unitCost * _count)}'
                    : 'Enter a cost to continue',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, this.value, this.valueText});

  final String label;
  final double? value;
  final String? valueText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          valueText ?? (value != null ? formatMoney(value!) : '—'),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// Plain, input-friendly price text: 12.0 -> "12", 12.50 -> "12.5".
String _priceText(double price) {
  final s = price.toStringAsFixed(2);
  if (s.endsWith('.00')) return s.substring(0, s.length - 3);
  if (s.endsWith('0')) return s.substring(0, s.length - 1);
  return s;
}
