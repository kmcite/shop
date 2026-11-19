import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shop/business/shop_cubit.dart';

import '../../models/customer_model.dart';
import '../../models/sale_line_request.dart';
import '../../models/shop_item_model.dart';
import '../../ui/format.dart';
import '../../ui/item_photo.dart';
import '../../ui/spacing.dart';
import '../design/metro.dart';
import '../widgets/search_field.dart';

Future<bool?> openRecordCreditSale(
  BuildContext context, {
  required ShopCustomer customer,
}) {
  return Navigator.of(context).push<bool>(
    metroRoute(
      context: context,
      builder: (_) => RecordCreditSaleScreen(customer: customer),
    ),
  );
}

class _DraftLine {
  _DraftLine({
    required this.item,
    required this.quantity,
    required this.unitPrice,
  });

  final ShopItem item;
  int quantity;
  double unitPrice;

  double get total => unitPrice * quantity;
}

/// Pick inventory items for a credit sale, then optionally take a down payment.
class RecordCreditSaleScreen extends StatefulWidget {
  const RecordCreditSaleScreen({super.key, required this.customer});

  final ShopCustomer customer;

  @override
  State<RecordCreditSaleScreen> createState() => _RecordCreditSaleScreenState();
}

class _RecordCreditSaleScreenState extends State<RecordCreditSaleScreen> {
  final _lines = <_DraftLine>[];
  final _paidCtrl = TextEditingController(text: '0');
  final _noteCtrl = TextEditingController();
  String _query = '';
  var _saving = false;

  @override
  void dispose() {
    _paidCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  double get _saleTotal =>
      _lines.fold<double>(0, (sum, line) => sum + line.total);

  void _addOrBump(ShopItem item) {
    final existing = _lines.where((l) => l.item.id == item.id).firstOrNull;
    if (existing != null) {
      if (existing.quantity >= item.quantity) return;
      setState(() => existing.quantity += 1);
      return;
    }
    if (item.quantity < 1) return;
    setState(() {
      _lines.add(
        _DraftLine(
          item: item,
          quantity: 1,
          unitPrice: item.price,
        ),
      );
    });
  }

  Future<void> _save() async {
    if (_saving || _lines.isEmpty) return;
    final paid =
        double.tryParse(_paidCtrl.text.trim().replaceAll(',', '')) ?? 0;
    setState(() => _saving = true);
    final ok = await context.read<ShopCubit>().sellToCustomer(
          customerId: widget.customer.id,
          lines: [
            for (final line in _lines)
              SaleLineRequest(
                item: line.item,
                count: line.quantity,
                unitPrice: line.unitPrice,
              ),
          ],
          amountPaid: paid,
          note: _noteCtrl.text,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metro = MetroTheme.of(context);
    final items = context.watch<ShopCubit>().state.items;
    final q = _query.toLowerCase();
    final filtered = q.isEmpty
        ? items
        : items.where((i) => i.name.toLowerCase().contains(q)).toList();
    final remaining = (_saleTotal -
            (double.tryParse(_paidCtrl.text.trim().replaceAll(',', '')) ?? 0))
        .clamp(0.0, double.infinity);

    return Scaffold(
      appBar: AppBar(title: const Text('credit sale')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Selling to ${widget.customer.name}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SearchField(
                  query: _query,
                  onChanged: (v) => setState(() => _query = v.trim()),
                  hintText: 'find item to add\u2026',
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: [
                if (_lines.isNotEmpty) ...[
                  Text(
                    'on this sale',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: metro.colors.mutedForeground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final line in _lines) ...[
                    _CreditSaleLineTile(
                      line: line,
                      onChanged: () => setState(() {}),
                      onRemove: () => setState(() => _lines.remove(line)),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  MetroPanel(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _MoneyRow(
                          label: 'Sale total',
                          value: formatMoney(_saleTotal),
                          emphasize: true,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        MetroTextField(
                          controller: _paidCtrl,
                          label: const Text('Paid now'),
                          placeholder: '0',
                          prefix: const Icon(Icons.payments_outlined, size: 18),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          ],
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _MoneyRow(
                          label: 'Remains on credit',
                          value: formatMoney(remaining.toDouble()),
                          color: remaining > 0
                              ? metro.colors.accent
                              : metro.colors.success,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        MetroTextField(
                          controller: _noteCtrl,
                          label: const Text('Note'),
                          placeholder: 'Optional',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
                Text(
                  'inventory',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: metro.colors.mutedForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (filtered.isEmpty)
                  Text(
                    'No items match',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: metro.colors.mutedForeground,
                    ),
                  )
                else
                  for (final item in filtered)
                    MetroListRow(
                      title: item.name,
                      subtitle:
                          '${formatMoney(item.price)} · ${formatStock(item.quantity)}',
                      leading: ItemPhoto(
                        imagePath: item.imagePath,
                        width: 40,
                        height: 40,
                      ),
                      trailing: Icon(
                        Icons.add,
                        color: item.quantity > 0
                            ? metro.colors.accent
                            : metro.colors.disabledForeground,
                      ),
                      enabled: item.quantity > 0,
                      onTap: item.quantity > 0 ? () => _addOrBump(item) : null,
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
              onPressed: _saving || _lines.isEmpty ? null : _save,
              style: const MetroButtonStyle(minimumSize: Size(0, 44)),
              child: Text(
                _lines.isEmpty
                    ? 'Add items to sell'
                    : 'Record sale · ${formatMoney(_saleTotal)}',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreditSaleLineTile extends StatelessWidget {
  const _CreditSaleLineTile({
    required this.line,
    required this.onChanged,
    required this.onRemove,
  });

  final _DraftLine line;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metro = MetroTheme.of(context);
    return MetroPanel(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  line.item.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              MetroIconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onRemove,
                semanticLabel: 'Remove ${line.item.name}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              MetroIconButton(
                icon: const Icon(Icons.remove, size: 18),
                onPressed: line.quantity <= 1
                    ? null
                    : () {
                        line.quantity -= 1;
                        onChanged();
                      },
                semanticLabel: 'Decrease quantity',
              ),
              Text(
                '${line.quantity}',
                style: theme.textTheme.titleMedium,
              ),
              MetroIconButton(
                icon: const Icon(Icons.add, size: 18),
                onPressed: line.quantity >= line.item.quantity
                    ? null
                    : () {
                        line.quantity += 1;
                        onChanged();
                      },
                semanticLabel: 'Increase quantity',
              ),
              const Spacer(),
              Text(
                formatMoney(line.total),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: metro.colors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.color,
  });

  final String label;
  final String value;
  final bool emphasize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: emphasize
              ? theme.textTheme.titleMedium
              : theme.textTheme.bodyMedium,
        ),
        Text(
          value,
          style: (emphasize
                  ? theme.textTheme.titleLarge
                  : theme.textTheme.titleMedium)
              ?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
