import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../models/shop_item_model.dart';
import '../../ui/format.dart';
import '../../ui/item_photo.dart';
import '../../ui/spacing.dart';
import '../design/metro.dart';

class SellSheetResult {
  const SellSheetResult(this.count, this.unitPrice);
  final int count;

  /// The negotiated price per unit actually charged.
  final double unitPrice;
}

Future<SellSheetResult?> openSellSheet(
  BuildContext context,
  ShopItem item,
) {
  return Navigator.of(context).push<SellSheetResult>(
    metroRoute(context: context, builder: (_) => SellItemScreen(item: item)),
  );
}

class SellItemScreen extends StatefulWidget {
  const SellItemScreen({super.key, required this.item});

  final ShopItem item;

  @override
  State<SellItemScreen> createState() => _SellItemScreenState();
}

class _SellItemScreenState extends State<SellItemScreen> {
  late int _count = widget.item.quantity > 0 ? 1 : 0;
  late final TextEditingController _priceCtrl = TextEditingController(
    text: _priceText(widget.item.price),
  );

  double get _unitPrice =>
      double.tryParse(_priceCtrl.text.trim()) ?? widget.item.price;

  void _bump(int delta) {
    final next = (_count + delta).clamp(0, widget.item.quantity);
    if (next == _count) {
      HapticFeedback.lightImpact();
      return;
    }
    setState(() => _count = next);
    HapticFeedback.selectionClick();
  }

  void _setPrice(double price) {
    _priceCtrl.text = _priceText(price);
    _priceCtrl.selection = TextSelection.collapsed(
      offset: _priceCtrl.text.length,
    );
    setState(() {});
    HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final unitPrice = _unitPrice;
    final total = unitPrice * _count;
    final canSell = _count > 0 && item.inStock && unitPrice >= 0;

    return Scaffold(
      appBar: AppBar(title: const Text('sell')),
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
                        text: '  ·  list ${formatMoney(item.price)}',
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
                      'of ${item.quantity} in stock',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Increase',
                onPressed: _count < item.quantity ? () => _bump(1) : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          MetroTextField(
            controller: _priceCtrl,
            label: const Text('Price per unit'),
            prefix: const Icon(Icons.sell_outlined, size: 18),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _PriceChip(label: 'List', onTap: () => _setPrice(item.price)),
              _PriceChip(
                label: '−10%',
                onTap: () => _setPrice(item.price * 0.9),
              ),
              _PriceChip(
                label: '−20%',
                onTap: () => _setPrice(item.price * 0.8),
              ),
              if (item.hasCost)
                _PriceChip(
                  label: 'At cost',
                  onTap: () => _setPrice(item.costPrice),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _MarginHint(item: item, unitPrice: unitPrice),
          const SizedBox(height: AppSpacing.lg),
          MetroPanel(
            margin: EdgeInsets.zero,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: theme.textTheme.titleMedium),
                Text(
                  formatMoney(total),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
              onPressed: canSell
                  ? () => Navigator.pop(
                        context,
                        SellSheetResult(_count, unitPrice),
                      )
                  : null,
              style: const MetroButtonStyle(minimumSize: Size(0, 44)),
              child: Text(canSell ? 'Add to sale' : 'Nothing to sell'),
            ),
          ),
        ),
      ),
    );
  }
}

class _MarginHint extends StatelessWidget {
  const _MarginHint({required this.item, required this.unitPrice});

  final ShopItem item;
  final double unitPrice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (!item.hasCost) {
      final vsList = item.price - unitPrice;
      if (vsList.abs() < 0.005) return const SizedBox.shrink();
      return Text(
        'Discount ${formatMoney(vsList)} below list',
        style: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    final profit = unitPrice - item.costPrice;
    final belowCost = profit < -0.005;
    final atCost = profit.abs() <= 0.005;

    final color = belowCost
        ? scheme.error
        : atCost
            ? scheme.onSurfaceVariant
            : scheme.tertiary;

    final text = belowCost
        ? 'Below cost by ${formatMoney(-profit)}/unit'
        : atCost
            ? 'Selling at cost — no profit'
            : 'Earns ${formatMoney(profit)}/unit';

    return Row(
      children: [
        Icon(
          belowCost
              ? Icons.warning_amber_rounded
              : atCost
                  ? Icons.remove_circle_outline
                  : Icons.trending_up,
          size: 16,
          color: color,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceChip extends StatelessWidget {
  const _PriceChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MetroButton(
      onPressed: onTap,
      style: const MetroButtonStyle(minimumSize: Size(64, 32)),
      child: Text(label),
    );
  }
}

String _priceText(double price) {
  final s = price.toStringAsFixed(2);
  if (s.endsWith('.00')) return s.substring(0, s.length - 3);
  if (s.endsWith('0')) return s.substring(0, s.length - 1);
  return s;
}
