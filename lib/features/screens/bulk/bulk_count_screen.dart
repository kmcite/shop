import 'package:any/any.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../commands/bulk_order_draft_commands.dart';
import '../../../commands/bulk_shipment_persist_commands.dart';
import '../../../models/bulk_shipment_line_model.dart';
import '../../../states/bulk_order_draft_state.dart';
import '../../../ui/spacing.dart';
import '../../widgets/bulk/bulk_ui.dart';

class BulkCountScreen extends StatefulWidget {
  const BulkCountScreen({
    required this.shipmentId,
    this.readOnly = false,
    super.key,
  });

  final String shipmentId;
  final bool readOnly;

  static Route<void> route(String shipmentId, {bool readOnly = false}) {
    return MaterialPageRoute<void>(
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
  final _name = TextEditingController();
  final _qty = TextEditingController(text: '1');
  final _surpriseNameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context(PrepareBulkCountDraftCommand(widget.shipmentId));
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
    await context(SaveBulkCountedCommand(widget.shipmentId));
    if (!context.mounted) return;
    if (context.read<BulkOrderDraftState>().error != null) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Counts saved — set listing prices next')),
    );
  }

  Future<void> _addSurprise(BuildContext context) async {
    final qty = int.tryParse(_qty.text.trim()) ?? 0;
    await context(
      AddBulkDraftCountedLineCommand(
        name: _name.text,
        actualQty: qty,
      ),
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
    final draft = context.of<BulkOrderDraftState>();
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

    return BulkFlowScaffold(
      title: 'Open & count',
      bottom: widget.readOnly
          ? null
          : BulkStickyPrimaryButton(
              label: 'Save counts',
              onPressed: () => _save(context),
            ),
      children: [
        if (widget.readOnly) const BulkReadOnlyBanner(),
        if (widget.readOnly) const SizedBox(height: AppSpacing.md),
        const BulkIntroText(
          'Counts start from what you ordered — adjust if the box differs. '
          'Add extra types at the bottom if you find surprises.',
        ),
        const SizedBox(height: AppSpacing.xl),
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
                          child: TextField(
                            controller: _name,
                            focusNode: _surpriseNameFocus,
                            decoration: const InputDecoration(
                              labelText: 'Type name',
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextField(
                            controller: _qty,
                            decoration:
                                const InputDecoration(labelText: 'Qty'),
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
                      label: const Text('Add extra type'),
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
    context(
      UpdateBulkDraftCountedLineCommand(
        index: widget.index,
        name: _name.text,
        actualQty: qty,
      ),
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
            child: TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: 'Type',
                helperText: hint != null ? 'Expected ~$hint' : null,
              ),
              onChanged: (_) => _sync(context),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _qty,
              decoration: const InputDecoration(labelText: 'Counted'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => _sync(context),
            ),
          ),
          if (widget.canRemove)
            IconButton(
              tooltip: 'Remove',
              onPressed: () =>
                  context(RemoveBulkDraftLineCommand(widget.index)),
              icon: Icon(Icons.close, color: scheme.error),
            ),
        ],
      ),
    );
  }
}