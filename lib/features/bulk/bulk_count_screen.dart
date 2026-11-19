import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shop/business/bulk_order_draft_cubit.dart';
import 'package:shop/business/shop_cubit.dart';
import '../../models/bulk_shipment_line_model.dart';
import '../../models/bulk_shipment_model.dart';
import '../../ui/spacing.dart';
import '../design/metro.dart';
import '../widgets/bulk/bulk_ui.dart';

class BulkCountScreen extends StatefulWidget {
  const BulkCountScreen({
    required this.shipmentId,
    this.readOnly = false,
    this.embedded = false,
    this.onStepCompleted,
    super.key,
  });

  final String shipmentId;
  final bool readOnly;
  final bool embedded;
  final VoidCallback? onStepCompleted;

  static Route<void> route(
    BuildContext context,
    String shipmentId, {
    bool readOnly = false,
  }) {
    return metroRoute(
      context: context,
      builder: (_) => BulkCountScreen(
        shipmentId: shipmentId,
        readOnly: readOnly,
      ),
    );
  }

  @override
  State<BulkCountScreen> createState() => _BulkCountScreenState();
}

class _BulkCountScreenState extends State<BulkCountScreen> {
  BulkShipment? _bulk(BuildContext context) {
    for (final b in context.watch<ShopCubit>().state.bulkShipments) {
      if (b.id == widget.shipmentId) return b;
    }
    return null;
  }

  final _name = TextEditingController();
  final _qty = TextEditingController(text: '1');
  final _surpriseNameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ShopCubit>().prepareBulkCountDraft(
            widget.shipmentId,
            context.read<BulkOrderDraftCubit>(),
          );
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _qty.dispose();
    _surpriseNameFocus.dispose();
    super.dispose();
  }

  Future<void> _save(BuildContext context) async {
    FocusScope.of(context).unfocus();
    await context.read<ShopCubit>().saveBulkCounted(
          widget.shipmentId,
          context.read<BulkOrderDraftCubit>(),
        );
    if (!context.mounted) return;
    if (context.read<BulkOrderDraftCubit>().state.error != null) return;
    if (widget.onStepCompleted != null) {
      widget.onStepCompleted!();
    } else {
      Navigator.pop(context);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Counts saved — set listing prices next')),
    );
  }

  Future<void> _addSurprise(BuildContext context) async {
    final qty = int.tryParse(_qty.text.trim()) ?? 0;
    context.read<BulkOrderDraftCubit>().addCountedLine(
          name: _name.text,
          actualQty: qty,
        );
    _name.clear();
    _qty.text = '1';
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _surpriseNameFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<BulkOrderDraftCubit>().state;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final ordered = <({int index, BulkShipmentLine line})>[];
    final extras = <({int index, BulkShipmentLine line})>[];
    for (var i = 0; i < draft.lines.length; i++) {
      final line = draft.lines[i];
      final entry = (index: i, line: line);
      if (line.extraFind) {
        extras.add(entry);
      } else {
        ordered.add(entry);
      }
    }

    final bulk = _bulk(context);
    final status =
        bulk?.status ?? BulkShipmentStatus.received;

    return BulkFlowScaffold(
      title: 'Open & count',
      embedded: widget.embedded,
      bottom: widget.embedded || widget.readOnly
          ? null
          : BulkStickyPrimaryButton(
              label: 'Save counts',
              onPressed: () => _save(context),
            ),
      children: [
        BulkStepContextHeader(status: status, stepIndex: 2),
        if (!widget.readOnly) ...[
          const BulkIntroText(
            'Counts start from what you ordered — adjust if the box differs. '
            'Add extra types at the bottom if you find surprises.',
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        BulkSection(
          title: 'From your order',
          subtitle: 'Names and quantities you can edit',
          child: BulkOutlineGroup(
            child: ordered.isEmpty
                ? Text(
                    'No expected types on this order.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                : Column(
                    children: [
                      for (final entry in ordered)
                        _CountRow(
                          key: ValueKey('ord-${entry.index}-${entry.line.name}'),
                          index: entry.index,
                          name: entry.line.name,
                          qty: entry.line.actualQty ??
                              entry.line.expectedQty ??
                              1,
                          expectedHint: entry.line.expectedQty,
                          canRemove: false,
                          readOnly: widget.readOnly,
                        ),
                    ],
                  ),
          ),
        ),
        if (extras.isNotEmpty || !widget.readOnly) ...[
          const SizedBox(height: AppSpacing.xl),
          BulkSection(
            title: 'Extra finds',
            subtitle: 'Not on the order list',
            child: BulkOutlineGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (extras.isNotEmpty)
                    ...extras.map(
                      (entry) => _CountRow(
                        key: ValueKey('x-${entry.index}-${entry.line.name}'),
                        index: entry.index,
                        name: entry.line.name,
                        qty: entry.line.actualQty ?? 1,
                        canRemove: !widget.readOnly,
                        readOnly: widget.readOnly,
                      ),
                    ),
                  if (!widget.readOnly) ...[
                    if (extras.isNotEmpty) const Divider(height: AppSpacing.xl),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: MetroTextField(
                            controller: _name,
                            focusNode: _surpriseNameFocus,
                            label: const Text('Type name'),
                            textCapitalization: TextCapitalization.words,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: MetroTextField(
                            controller: _qty,
                            label: const Text('Qty'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _addSurprise(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: () => _addSurprise(context),
                      icon: const Icon(Icons.add),
                      label: const Text('add extra type'),
                    ),
                  ] else if (extras.isEmpty)
                    Text(
                      'No extra types.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        if (!widget.readOnly) BulkErrorText(draft.error),
      ],
    );
  }
}

class _CountRow extends StatefulWidget {
  const _CountRow({
    super.key,
    required this.index,
    required this.name,
    required this.qty,
    this.expectedHint,
    this.canRemove = false,
    this.readOnly = false,
  });

  final int index;
  final String name;
  final int qty;
  final int? expectedHint;
  final bool canRemove;
  final bool readOnly;

  @override
  State<_CountRow> createState() => _CountRowState();
}

class _CountRowState extends State<_CountRow> {
  late final TextEditingController _name;
  late final TextEditingController _qty;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.name);
    _qty = TextEditingController(text: '${widget.qty}');
  }

  @override
  void didUpdateWidget(covariant _CountRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name && _name.text != widget.name) {
      _name.text = widget.name;
    }
    if (oldWidget.qty != widget.qty && _qty.text != '${widget.qty}') {
      _qty.text = '${widget.qty}';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _qty.dispose();
    super.dispose();
  }

  void _sync(BuildContext context) {
    final qty = int.tryParse(_qty.text.trim()) ?? 0;
    context.read<BulkOrderDraftCubit>().updateCountedLine(
          index: widget.index,
          name: _name.text,
          actualQty: qty,
        );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final hint = widget.expectedHint;

    if (widget.readOnly) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (hint != null)
                    Text(
                      'Expected ~$hint',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '×${widget.qty}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: MetroTextField(
              controller: _name,
              label: const Text('Type'),
              supportingText:
                  hint != null ? Text('Expected ~$hint') : null,
              onChanged: (_) => _sync(context),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: MetroTextField(
              controller: _qty,
              label: const Text('Counted'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => _sync(context),
            ),
          ),
          if (widget.canRemove)
            IconButton(
              tooltip: 'Remove',
              onPressed: () =>
                  context.read<BulkOrderDraftCubit>().removeLine(widget.index),
              icon: Icon(Icons.close, color: scheme.error),
            ),
        ],
      ),
    );
  }
}