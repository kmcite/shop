import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shop/business/sell_cart_cubit.dart';
import 'package:shop/business/shop_cubit.dart';

import '../../models/sale_line_request.dart';
import '../../models/sell_cart_line_model.dart';
import '../../models/shop_item_model.dart';
import '../../ui/format.dart';
import '../../ui/item_photo.dart';
import '../../ui/spacing.dart';
import '../customers/pick_customer_sheet.dart';
import '../design/metro.dart';

/// Opens the review-sale screen. Returns `true` for cash checkout.
/// Credit sales complete inside this screen and return `false`.
Future<bool?> openReviewSaleScreen(BuildContext context) {
  return Navigator.of(context).push<bool>(
    metroRoute(context: context, builder: (_) => const ReviewSaleScreen()),
  );
}

/// Review cart before completing a sale — edit qty, price, or remove lines.
class ReviewSaleScreen extends StatelessWidget {
  const ReviewSaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartCubit = context.watch<SellCartCubit>();
    final cart = cartCubit.state;
    final items = {
      for (final i in context.watch<ShopCubit>().state.items) i.id: i,
    };
    final theme = Theme.of(context);
    final metro = MetroTheme.of(context);

    var grandTotal = 0.0;
    for (final line in cart.lines) {
      grandTotal += line.unitPrice * line.quantity;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('review sale')),
      body: cart.isEmpty
          ? MetroEmptyState(message: 'Cart is empty — add items to sell.')
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.xxl,
              ),
              children: [
                Text(
                  '${cart.itemTypeCount} line${cart.itemTypeCount == 1 ? '' : 's'} · '
                  '${cart.unitCount} units',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: metro.colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (var index = 0; index < cart.lines.length; index++) ...[
                  if (index > 0) const SizedBox(height: AppSpacing.md),
                  _ReviewSaleLineTile(
                    index: index,
                    item: items[cart.lines[index].itemId],
                    line: cart.lines[index],
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                MetroPanel(
                  margin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: theme.textTheme.titleMedium),
                      Text(
                        formatMoney(grandTotal),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: metro.colors.accent,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: double.infinity,
                child: MetroButton.accent(
                  onPressed: cart.isEmpty
                      ? null
                      : () => Navigator.pop(context, true),
                  style: const MetroButtonStyle(minimumSize: Size(0, 44)),
                  child: Text(
                    cart.isEmpty
                        ? 'Nothing to sell'
                        : 'Cash sale · ${formatMoney(grandTotal)}',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: MetroButton(
                  onPressed: cart.isEmpty
                      ? null
                      : () => _sellOnCredit(context, cartCubit, items),
                  style: const MetroButtonStyle(minimumSize: Size(0, 44)),
                  child: const Text('Sell on credit'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: MetroButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: const MetroButtonStyle(minimumSize: Size(0, 44)),
                  child: const Text('Back to cart'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sellOnCredit(
    BuildContext context,
    SellCartCubit cart,
    Map<String, ShopItem> items,
  ) async {
    final customer = await openPickCustomer(context);
    if (customer == null || !context.mounted || cart.state.isEmpty) return;

    final requests = <SaleLineRequest>[];
    for (final line in cart.state.lines) {
      final item = items[line.itemId];
      if (item == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An item left inventory — refresh cart')),
        );
        return;
      }
      requests.add(
        SaleLineRequest(
          item: item,
          count: line.quantity,
          unitPrice: line.unitPrice,
        ),
      );
    }

    final ok = await context.read<ShopCubit>().sellToCustomer(
          customerId: customer.id,
          lines: requests,
        );
    if (!context.mounted) return;
    if (ok) {
      cart.clear();
      Navigator.pop(context, false);
    }
  }
}

/// One editable cart line — Metro settings-row layout (label · control).
class _ReviewSaleLineTile extends StatefulWidget {
  const _ReviewSaleLineTile({
    required this.index,
    required this.item,
    required this.line,
  });

  final int index;
  final ShopItem? item;
  final SellCartLine line;

  @override
  State<_ReviewSaleLineTile> createState() => _ReviewSaleLineTileState();
}

class _ReviewSaleLineTileState extends State<_ReviewSaleLineTile> {
  static const double _labelWidth = 64;
  static const double _qtyWidth = 128;

  late final TextEditingController _priceCtrl;
  late final FocusNode _priceFocus;

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController(text: _priceText(widget.line.unitPrice));
    _priceFocus = FocusNode()..addListener(_onPriceFocus);
  }

  void _onPriceFocus() {
    if (!_priceFocus.hasFocus) _commitPrice(_priceCtrl.text);
  }

  @override
  void didUpdateWidget(covariant _ReviewSaleLineTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.line.unitPrice - widget.line.unitPrice).abs() >= 0.001 &&
        !_priceFocus.hasFocus) {
      final next = _priceText(widget.line.unitPrice);
      if (_priceCtrl.text != next) {
        _priceCtrl.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _priceFocus.removeListener(_onPriceFocus);
    _priceFocus.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _commitPrice(String raw) {
    final parsed = double.tryParse(raw.trim());
    if (parsed == null || parsed < 0) {
      _priceCtrl.text = _priceText(widget.line.unitPrice);
      return;
    }
    context.read<SellCartCubit>().setUnitPrice(widget.index, parsed);
  }

  void _applyPrice(double price) {
    context.read<SellCartCubit>().setUnitPrice(widget.index, price);
    _priceCtrl.text = _priceText(price);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metro = MetroTheme.of(context);
    final cart = context.read<SellCartCubit>();
    final name = widget.item?.name ?? 'Unknown';
    final onHand = widget.item?.quantity ?? widget.line.quantity;
    final maxQty = cart.maxQuantityFor(widget.index, onHand);
    final qty = widget.line.quantity.clamp(1, maxQty);
    final lineTotal = widget.line.unitPrice * widget.line.quantity;
    final listPrice = widget.item?.price;
    final border = MetroTheme.of(context).colors.border;
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: metro.colors.mutedForeground,
      fontWeight: FontWeight.w600,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          MetroSpacing.md,
          MetroSpacing.sm,
          MetroSpacing.xs,
          MetroSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (widget.item != null)
                  ItemPhotoBadge(item: widget.item!, size: 36)
                else
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 22,
                    color: metro.colors.mutedForeground,
                  ),
                const SizedBox(width: MetroSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        [
                          '$onHand on hand',
                          if (listPrice != null)
                            'list ${formatMoney(listPrice)}',
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: metro.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                MetroIconButton(
                  icon: const Icon(Icons.close, size: 18),
                  semanticLabel: 'Remove',
                  onPressed: () => cart.removeLine(widget.index),
                  style: const MetroButtonStyle(
                    minimumSize: Size.square(44),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: MetroSpacing.md),
            Row(
              children: [
                SizedBox(
                  width: _labelWidth,
                  child: Text('Qty', style: labelStyle),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: _qtyWidth,
                      child: MetroNumberBox<int>(
                        value: qty,
                        min: 1,
                        max: maxQty,
                        allowNull: false,
                        decimalPlaces: 0,
                        onChanged: (v) {
                          if (v != null) {
                            cart.setQuantity(widget.index, v);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MetroSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: _labelWidth,
                  child: Text('Price', style: labelStyle),
                ),
                Expanded(
                  child: MetroTextField(
                    controller: _priceCtrl,
                    focusNode: _priceFocus,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    onChanged: (raw) {
                      final parsed = double.tryParse(raw.trim());
                      if (parsed != null && parsed >= 0) {
                        cart.setUnitPrice(widget.index, parsed);
                      }
                    },
                    onSubmitted: _commitPrice,
                  ),
                ),
              ],
            ),
            if (listPrice != null) ...[
              const SizedBox(height: MetroSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(left: _labelWidth),
                child: Wrap(
                  spacing: MetroSpacing.xs,
                  runSpacing: MetroSpacing.xs,
                  alignment: WrapAlignment.end,
                  children: [
                    _PriceChip(
                      label: 'list',
                      onTap: () => _applyPrice(listPrice),
                    ),
                    _PriceChip(
                      label: '−10%',
                      onTap: () => _applyPrice(listPrice * 0.9),
                    ),
                    if (widget.item?.hasCost == true)
                      _PriceChip(
                        label: 'at cost',
                        onTap: () => _applyPrice(widget.item!.costPrice),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: MetroSpacing.md),
            Container(height: 1, color: border),
            const SizedBox(height: MetroSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$qty × ${formatMoney(widget.line.unitPrice)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: metro.colors.mutedForeground,
                    ),
                  ),
                ),
                Text(
                  formatMoney(lineTotal),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: metro.colors.accent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Quiet tap target for price presets (not a full MetroButton).
class _PriceChip extends StatelessWidget {
  const _PriceChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metro = MetroTheme.of(context);
    final border = MetroTheme.of(context).colors.border;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: MetroSpacing.sm),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: metro.colors.foreground,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

String _priceText(double price) {
  final s = price.toStringAsFixed(2);
  if (s.endsWith('.00')) return s.substring(0, s.length - 3);
  if (s.endsWith('0')) return s.substring(0, s.length - 1);
  return s;
}
