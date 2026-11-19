import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shop/business/bulk_order_draft_cubit.dart';
import 'package:shop/business/shop_cubit.dart';
import '../../models/bulk_shipment_model.dart';
import '../../../repositories/item_photo_store.dart';
import '../../ui/format.dart';
import '../../ui/item_photo.dart';
import '../../ui/spacing.dart';
import '../design/metro.dart';
import '../widgets/bulk/bulk_ui.dart';

class BulkPriceScreen extends StatefulWidget {
  const BulkPriceScreen({
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
    if (widget.onStepCompleted != null) {
      widget.onStepCompleted!();
    } else {
      Navigator.pop(context);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Listing prices saved')),
    );
  }

  BulkShipmentStatus _bulkStatus(BuildContext context) {
    for (final b in context.watch<ShopCubit>().state.bulkShipments) {
      if (b.id == widget.shipmentId) return b.status;
    }
    return BulkShipmentStatus.counted;
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<BulkOrderDraftCubit>().state;
    final defaultCost = _defaultCost(context);
    final status = _bulkStatus(context);
    return BulkFlowScaffold(
      title: 'Set listing prices',
      embedded: widget.embedded,
      bottom: widget.embedded || widget.readOnly
          ? null
          : BulkStickyPrimaryButton(
              label: 'Save prices',
              onPressed: () => _save(context),
            ),
      children: [
        BulkStepContextHeader(status: status, stepIndex: 3),
        if (!widget.readOnly) ...[
          BulkIntroText(
            'Your blended cost is about ${formatMoney(defaultCost)} per unit '
            '(lot + delivery ÷ total units). Set list prices — you can still '
            'negotiate at sale time.',
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
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
  static const _photoSize = 56.0;

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

  Widget _photoSlot(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final photo = ItemPhoto(
      imagePath: _image,
      width: _photoSize,
      height: _photoSize,
      borderRadius: 0,
      fallback: Container(
        width: _photoSize,
        height: _photoSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.zero,
          border: Border.all(color: scheme.outlineVariant),
          color: MetroTheme.of(context).surfaceColor,
        ),
        child: Icon(
          Icons.add_a_photo_outlined,
          size: 26,
          color: MetroColors.cyan,
        ),
      ),
    );

    if (widget.readOnly) return photo;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _photo(context),
        borderRadius: BorderRadius.zero,
        child: photo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final price = widget.listPrice ?? double.tryParse(_price.text.trim());

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
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
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (widget.readOnly)
                Text(
                  price != null && price > 0
                      ? 'List ${formatMoney(price)}'
                      : 'No list price',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                )
              else
                MetroTextField(
                  controller: _price,
                  label: const Text('List price'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  onChanged: (_) => _push(context),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        _photoSlot(context),
      ],
    );
  }
}