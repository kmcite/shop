import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../models/shop_item_model.dart';
import '../../ui/format.dart';
import '../../ui/item_photo.dart';
import '../../ui/spacing.dart';
import '../design/metro.dart';

class RestockResult {
  const RestockResult({required this.count, required this.unitCost});

  /// Units added by this purchase.
  final int count;

  /// What was paid per unit in this purchase.
  final double unitCost;
}

/// Opens the buy-stock screen for an existing item.
Future<RestockResult?> openRestockScreen(
  BuildContext context,
  ShopItem item,
) {
  return Navigator.of(context).push<RestockResult>(
    metroRoute(context: context, builder: (_) => RestockScreen(item: item)),
  );
}

class RestockScreen extends StatefulWidget {
  const RestockScreen({super.key, required this.item});

  final ShopItem item;

  @override
  State<RestockScreen> createState() => _RestockScreenState();
}

class _RestockScreenState extends State<RestockScreen> {
  int _count = 1;
  late final TextEditingController _costCtrl = TextEditingController(
    text: widget.item.hasCost ? _priceText(widget.item.costPrice) : '',
  );

  double? get _unitCost {
    final text = _costCtrl.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
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
    final cost = _unitCost;
    final canConfirm = cost != null && cost >= 0 && _count >= 1;

    final newQty = item.quantity + _count;
    final newAvgCost = canConfirm
        ? (item.hasCost
            ? (item.quantity * item.costPrice + _count * cost) / newQty
            : cost)
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('buy stock')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        children: [
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
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Units received',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: MetroTheme.of(context).colors.foreground,
            ),
          ),
          const SizedBox(height: MetroSpacing.xxs),
          MetroNumberBox<int>(
            value: _count,
            min: 1,
            max: 999999,
            allowNull: false,
            decimalPlaces: 0,
            semanticLabel: 'Units received',
            onChanged: (v) {
              if (v != null) setState(() => _count = v);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          MetroTextField(
            controller: _costCtrl,
            label: const Text('Cost per unit'),
            supportingText:
                const Text('What you paid per unit in this purchase'),
            prefix: const Icon(Icons.shopping_bag_outlined, size: 18),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          MetroPanel(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Purchase total',
                  value: canConfirm ? cost * _count : null,
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
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          child: SizedBox(
            width: double.infinity,
            child: MetroButton.accent(
              onPressed: canConfirm
                  ? () => Navigator.pop(
                        context,
                        RestockResult(count: _count, unitCost: cost),
                      )
                  : null,
              style: const MetroButtonStyle(minimumSize: Size(0, 44)),
              child: Text(
                canConfirm
                    ? 'Add $_count units · ${formatMoney(cost * _count)}'
                    : 'Enter units and cost',
              ),
            ),
          ),
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

String _priceText(double price) {
  final s = price.toStringAsFixed(2);
  if (s.endsWith('.00')) return s.substring(0, s.length - 3);
  if (s.endsWith('0')) return s.substring(0, s.length - 1);
  return s;
}
