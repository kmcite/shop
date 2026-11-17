import 'package:any/any.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../commands/bulk_order_draft_commands.dart';
import '../../../commands/bulk_shipment_persist_commands.dart';
import '../../../models/bulk_shipment_model.dart';
import '../../../states/bulk_order_draft_state.dart';
import '../../../states/shop_state.dart';
import '../../../ui/format.dart';
import '../../../ui/spacing.dart';
import '../../widgets/bulk/bulk_ui.dart';

class BulkReceiveScreen extends StatelessWidget {
  const BulkReceiveScreen({
    required this.shipmentId,
    this.readOnly = false,
    super.key,
  });

  final String shipmentId;
  final bool readOnly;

  static Route<void> route(String shipmentId, {bool readOnly = false}) {
    return MaterialPageRoute<void>(
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
    );
  }

  BulkShipment? _findBulk(BuildContext context, String id) {
    for (final b in context.of<ShopState>().bulkShipments) {
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
  });

  final BulkShipment bulk;
  final String shipmentId;
  final bool readOnly;

  @override
  State<_ReceiveBody> createState() => _ReceiveBodyState();
}

class _ReceiveBodyState extends State<_ReceiveBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context(LoadBulkIntoDraftCommand(widget.shipmentId));
    });
  }

  Future<void> _confirm(BuildContext context) async {
    await context(SaveBulkReceivedCommand(widget.shipmentId));
    if (!context.mounted) return;
    if (context.read<BulkOrderDraftState>().error != null) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marked received — open the box when ready')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.of<BulkOrderDraftState>();
    final bulk = widget.bulk;

    final delivery = draft.parsedDeliveryCharge ?? widget.bulk.deliveryCharge;

    return BulkFlowScaffold(
      title: 'Receive & pay',
      bottom: widget.readOnly
          ? null
          : BulkStickyPrimaryButton(
              label: 'Paid — bulk is at home',
              onPressed: () => _confirm(context),
            ),
      children: [
        if (widget.readOnly) const BulkReadOnlyBanner(),
        if (widget.readOnly) const SizedBox(height: AppSpacing.md),
        BulkIntroText(
          'Pay ${formatMoney(bulk.agreedPrice)} to ${bulk.sellerLabel}, '
          'then log delivery so your true cost is tracked.',
        ),
        const SizedBox(height: AppSpacing.xl),
        BulkSection(
          title: 'Order recap',
          child: BulkOutlineGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatMoney(bulk.agreedPrice),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(bulk.qualityNotes),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        BulkSection(
          title: 'Delivery',
          child: BulkOutlineGroup(
            child: widget.readOnly
                ? _ReadOnlyDelivery(value: delivery)
                : TextField(
                    decoration: const InputDecoration(
                      labelText: 'Delivery charge',
                      prefixIcon: Icon(Icons.local_shipping_outlined),
                      helperText: 'Courier / fuel — added to your bulk cost',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    onChanged: (v) =>
                        context(SetBulkDraftDeliveryCommand(v)),
                  ),
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