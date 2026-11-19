import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shop/business/bulk_order_draft_cubit.dart';
import 'package:shop/business/shop_cubit.dart';
import '../../../repositories/item_photo_store.dart';
import '../../ui/format.dart';
import '../../ui/item_photo.dart';
import '../../ui/spacing.dart';
import '../widgets/bulk/bulk_ui.dart';

class BulkPriceScreen extends StatefulWidget {
  const BulkPriceScreen({
    required this.shipmentId,
    this.readOnly = false,
    super.key,
  });

  final String shipmentId;
  final bool readOnly;

  static Route<void> route(String shipmentId, {bool readOnly = false}) {
    return MaterialPageRoute<void>(
      builder: (_) => BulkPriceScreen(
        shipmentId: shipmentId,
        readOnly: readOnly,
      ),
    );
  }

  @override
  State<BulkPriceScreen> createState() => _BulkPriceScreenState();
}

class _BulkPriceScreenState extends State<BulkPriceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ShopCubit>().prepareBulkPriceDraft(
            widget.shipmentId,
            context.read<BulkOrderDraftCubit>(),
          );
    });
  }

  double _defaultCost(BuildContext context) {
    for (final b in context.watch<ShopCubit>().state.bulkShipments) {
      if (b.id == widget.shipmentId) return b.defaultUnitCost;
    }
    return 0;
  }

  Future<void> _save(BuildContext context) async {
    await context.read<ShopCubit>().saveBulkPriced(
          widget.shipmentId,
          context.read<BulkOrderDraftCubit>(),
        );
    if (!context.mounted) return;
    if (context.read<BulkOrderDraftCubit>().state.error != null) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Listing prices saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<BulkOrderDraftCubit>().state;
    final defaultCost = _defaultCost(context);
    return BulkFlowScaffold(
      title: 'Set listing prices',
      bottom: widget.readOnly
          ? null
          : BulkStickyPrimaryButton(
              label: 'Save prices',
              onPressed: () => _save(context),
            ),
      children: [
        if (widget.readOnly) const BulkReadOnlyBanner(),
        if (widget.readOnly) const SizedBox(height: AppSpacing.md),
        BulkIntroText(
          'Your blended cost is about ${formatMoney(defaultCost)} per unit '
          '(lot + delivery ÷ total units). Set list prices — you can still '
          'negotiate at sale time.',
        ),
        const SizedBox(height: AppSpacing.xl),
        BulkSection(
          title: 'Listing prices',
          child: Column(
            children: [
              for (var i = 0; i < draft.lines.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: BulkOutlineGroup(
                    child: _PriceRow(
                      index: i,
                      name: draft.lines[i].name,
                      qty: draft.lines[i].actualQty ?? 0,
                      listPrice: draft.lines[i].listPrice,
                      unitCost: draft.lines[i].unitCost ?? defaultCost,
                      imagePath: draft.lines[i].imagePath,
                      readOnly: widget.readOnly,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (!widget.readOnly) BulkErrorText(draft.error),
      ],
    );
  }
}

class _PriceRow extends StatefulWidget {
  const _PriceRow({
    required this.index,
    required this.name,
    required this.qty,
    required this.listPrice,
    required this.unitCost,
    required this.imagePath,
    this.readOnly = false,
  });

  final int index;
  final String name;
  final int qty;
  final double? listPrice;
  final double unitCost;
  final String? imagePath;
  final bool readOnly;

  @override
  State<_PriceRow> createState() => _PriceRowState();
}

class _PriceRowState extends State<_PriceRow> {
  late final TextEditingController _price;
  String? _image;

  @override
  void initState() {
    super.initState();
    _price = TextEditingController(
      text: widget.listPrice != null ? '${widget.listPrice}' : '',
    );
    _image = widget.imagePath;
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  void _push(BuildContext context) {
    final parsed = double.tryParse(_price.text.trim());
    if (parsed == null) return;
    context.read<BulkOrderDraftCubit>().updatePricedLine(
          index: widget.index,
          listPrice: parsed,
          unitCost: widget.unitCost,
          imagePath: _image,
        );
  }

  Future<void> _photo(BuildContext context) async {
    final path = await ItemPhotoStore.pickAndStore(context);
    if (path == null || !context.mounted) return;
    setState(() => _image = path);
    _push(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = widget.listPrice ?? double.tryParse(_price.text.trim());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '${widget.qty} units · cost ${formatMoney(widget.unitCost)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (widget.readOnly)
          Row(
            children: [
              ItemPhoto(
                imagePath: _image,
                width: 56,
                height: 56,
                borderRadius: 12,
                fallback: CircleAvatar(
                  child: Text(
                    widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  price != null && price > 0
                      ? 'List ${formatMoney(price)}'
                      : 'No list price',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              ItemPhoto(
                imagePath: _image,
                width: 56,
                height: 56,
                borderRadius: 12,
                fallback: CircleAvatar(
                  child: Text(
                    widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () => _photo(context),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Photo'),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  controller: _price,
                  decoration: const InputDecoration(
                    labelText: 'List price',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  onChanged: (_) => _push(context),
                ),
              ),
            ],
          ),
      ],
    );
  }
}