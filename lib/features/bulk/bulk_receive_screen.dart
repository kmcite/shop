import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shop/business/bulk_order_draft_cubit.dart';
import 'package:shop/business/shop_cubit.dart';

import '../../models/bulk_shipment_model.dart';
import '../../ui/format.dart';
import '../../ui/spacing.dart';
import '../design/metro.dart';
import '../widgets/bulk/bulk_ui.dart';

class BulkReceiveScreen extends StatelessWidget {
  const BulkReceiveScreen({
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
      builder: (_) => BulkReceiveScreen(
        shipmentId: shipmentId,
        readOnly: readOnly,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bulk = _findBulk(context, shipmentId);
    if (bulk == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Bulk not found')),
      );
    }

    return _ReceiveBody(
      bulk: bulk,
      shipmentId: shipmentId,
      readOnly: readOnly,
      embedded: embedded,
      onStepCompleted: onStepCompleted,
    );
  }

  BulkShipment? _findBulk(BuildContext context, String id) {
    for (final b in context.watch<ShopCubit>().state.bulkShipments) {
      if (b.id == id) return b;
    }
    return null;
  }
}

class _ReceiveBody extends StatefulWidget {
  const _ReceiveBody({
    required this.bulk,
    required this.shipmentId,
    required this.readOnly,
    this.embedded = false,
    this.onStepCompleted,
  });

  final BulkShipment bulk;
  final String shipmentId;
  final bool readOnly;
  final bool embedded;
  final VoidCallback? onStepCompleted;

  @override
  State<_ReceiveBody> createState() => _ReceiveBodyState();
}

class _ReceiveBodyState extends State<_ReceiveBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final shop = context.read<ShopCubit>().state;
      context
          .read<BulkOrderDraftCubit>()
          .loadFromShipment(widget.shipmentId, shop);
    });
  }

  Future<void> _confirm(BuildContext context) async {
    await context.read<ShopCubit>().saveBulkReceived(
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
      const SnackBar(content: Text('Marked received — open the box when ready')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<BulkOrderDraftCubit>().state;
    final bulk = widget.bulk;

    final delivery = draft.parsedDeliveryCharge ?? widget.bulk.deliveryCharge;

    return BulkFlowScaffold(
      title: 'Receive & pay',
      embedded: widget.embedded,
      bottom: widget.embedded || widget.readOnly
          ? null
          : BulkStickyPrimaryButton(
              label: 'Paid — bulk is at home',
              onPressed: () => _confirm(context),
            ),
      children: [
        BulkStepContextHeader(status: bulk.status, stepIndex: 1),
        if (!widget.readOnly) ...[
          BulkIntroText(
            'Pay ${formatMoney(bulk.agreedPrice)} to ${bulk.sellerLabel}, '
            'then log delivery so your true cost is tracked.',
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        BulkSection(
          title: 'Order recap',
          child: BulkOutlineGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatMoney(bulk.agreedPrice),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w200,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  bulk.qualityNotes.toLowerCase(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w300,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        BulkSection(
          title: 'Delivery',
          child: widget.readOnly
              ? BulkOutlineGroup(child: _ReadOnlyDelivery(value: delivery))
              : MetroTextField(
                  label: const Text('Delivery charge'),
                  prefix: const Icon(Icons.local_shipping_outlined, size: 18),
                  supportingText:
                      const Text('Courier / fuel — added to your bulk cost'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  onChanged: (v) =>
                      context.read<BulkOrderDraftCubit>().setDelivery(v),
                ),
        ),
        if (!widget.readOnly) BulkErrorText(draft.error),
      ],
    );
  }
}

class _ReadOnlyDelivery extends StatelessWidget {
  const _ReadOnlyDelivery({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.local_shipping_outlined),
      title: const Text('Delivery charge'),
      trailing: Text(
        formatMoney(value),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}