import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shop/business/bulk_order_draft_cubit.dart';
import 'package:shop/business/shop_cubit.dart';

import '../../ui/spacing.dart';
import '../design/metro.dart';
import '../widgets/bulk/bulk_ui.dart';

class BulkOrderScreen extends StatelessWidget {
  const BulkOrderScreen({super.key});

  static Route<void> route(BuildContext context) {
    return metroRoute(
      context: context,
      builder: (_) => const BulkOrderScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const _BulkOrderScreenBody();
  }
}

class _BulkOrderScreenBody extends StatefulWidget {
  const _BulkOrderScreenBody();

  @override
  State<_BulkOrderScreenBody> createState() => _BulkOrderScreenBodyState();
}

class _BulkOrderScreenBodyState extends State<_BulkOrderScreenBody> {
  final _lineName = TextEditingController();
  final _lineQty = TextEditingController(text: '1');
  final _typeNameFocus = FocusNode();
  final _typeQtyFocus = FocusNode();

  @override
  void dispose() {
    _lineName.dispose();
    _lineQty.dispose();
    _typeNameFocus.dispose();
    _typeQtyFocus.dispose();
    super.dispose();
  }

  Future<void> _addLine(BuildContext context) async {
    final name = _lineName.text.trim();
    final qty = int.tryParse(_lineQty.text.trim()) ?? 0;
    if (name.isEmpty || qty < 1) {
      context.read<BulkOrderDraftCubit>().setError(
        'Enter item name and quantity.',
      );
      return;
    }
    context.read<BulkOrderDraftCubit>().upsertExpectedLine(
      index: -1,
      name: name,
      expectedQty: qty,
    );
    _lineName.clear();
    _lineQty.text = '1';
    context.read<BulkOrderDraftCubit>().setError(null);
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _typeNameFocus.requestFocus();
      }
    });
  }

  Future<void> _save(BuildContext context) async {
    FocusScope.of(context).unfocus();
    await context.read<ShopCubit>().saveNewBulkOrder(
      context.read<BulkOrderDraftCubit>(),
    );
    if (!context.mounted) return;
    final err = context.read<BulkOrderDraftCubit>().state.error;
    if (err != null) return;
    final active = context.watch<ShopCubit>().state.activeBulkShipments;
    final newest = active.isNotEmpty ? active.first : null;
    Navigator.pop(context);
    if (newest != null) {
      await context.read<ShopCubit>().openBulkShipment(newest.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<BulkOrderDraftCubit>().state;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BulkFlowScaffold(
      title: 'New bulk order',
      bottom: BulkStickyPrimaryButton(
        label: 'Save order',
        onPressed: () => _save(context),
      ),
      children: [
        const BulkIntroText(
          'Ask the seller to ship the lot. Record what you agreed on '
          'so you can reconcile when the box arrives.',
        ),
        const SizedBox(height: AppSpacing.xl),
        BulkSection(
          title: 'Deal details',
          child: BulkOutlineGroup(
            child: Column(
              children: [
                MetroTextField(
                  label: const Text('Seller / source'),
                  prefix: const Icon(Icons.store_outlined, size: 18),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onChanged: (v) =>
                      context.read<BulkOrderDraftCubit>().setSeller(v),
                ),
                const SizedBox(height: AppSpacing.md),
                MetroTextField(
                  label: const Text('Agreed bulk price'),
                  prefix: const Icon(Icons.payments_outlined, size: 18),
                  supportingText:
                      const Text('What you will pay for the whole lot'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  textInputAction: TextInputAction.next,
                  onChanged: (v) =>
                      context.read<BulkOrderDraftCubit>().setAgreedPrice(v),
                ),
                const SizedBox(height: AppSpacing.md),
                MetroTextField(
                  label: const Text('Promised quality'),
                  prefix: const Icon(Icons.grade_outlined, size: 18),
                  supportingText:
                      const Text('Grade, condition, brand mix, etc.'),
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onChanged: (v) =>
                      context.read<BulkOrderDraftCubit>().setQuality(v),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        BulkSection(
          title: 'Expected item types',
          subtitle: 'What the seller said is in the lot',
          child: BulkOutlineGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (draft.lines.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      'No types yet — add the first one below.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  ...List.generate(draft.lines.length, (i) {
                    final line = draft.lines[i];
                    return Dismissible(
                      key: ValueKey('expected-$i-${line.name}'),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) =>
                          context.read<BulkOrderDraftCubit>().removeLine(i),
                      background: Container(
                        alignment: Alignment.centerRight,
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.only(right: AppSpacing.lg),
                        color: scheme.errorContainer,
                        child: Icon(
                          Icons.delete_outline,
                          color: scheme.onErrorContainer,
                        ),
                      ),
                      child: BulkListTileRow(
                        leading: BulkIndexBadge(i + 1),
                        title: line.name,
                        subtitle: 'Expected ~${line.expectedQty ?? 0}',
                      ),
                    );
                  }),
                const Divider(height: AppSpacing.xl),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: MetroTextField(
                        controller: _lineName,
                        focusNode: _typeNameFocus,
                        label: const Text('Type name'),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _typeQtyFocus.requestFocus(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: MetroTextField(
                        controller: _lineQty,
                        focusNode: _typeQtyFocus,
                        label: const Text('Qty'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addLine(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () => _addLine(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add expected type'),
                ),
              ],
            ),
          ),
        ),
        BulkErrorText(draft.error),
      ],
    );
  }
}
