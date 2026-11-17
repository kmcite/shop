import 'package:any/any.dart';
import 'package:flutter/material.dart';

import '../../../commands/bulk_shipment_persist_commands.dart';
import '../../../models/bulk_shipment_model.dart';
import '../../../states/shop_state.dart';
import '../../../ui/format.dart';
import '../../../ui/spacing.dart';
import '../../widgets/bulk/bulk_ui.dart';
import '../../widgets/bulk_progress_stepper.dart';
import 'bulk_step_navigation.dart';

class BulkShipmentHubScreen extends StatelessWidget {
  const BulkShipmentHubScreen({required this.shipmentId, super.key});

  final String shipmentId;

  static Route<void> route(String shipmentId) {
    return MaterialPageRoute<void>(
      builder: (_) => BulkShipmentHubScreen(shipmentId: shipmentId),
    );
  }

  BulkShipment? _bulk(BuildContext context) {
    for (final b in context.of<ShopState>().bulkShipments) {
      if (b.id == shipmentId) return b;
    }
    return null;
  }

  void _openStep(BuildContext context, BulkShipment bulk) {
    if (!bulk.status.isActive) return;
    openBulkTimelineStep(
      context,
      shipmentId: bulk.id,
      status: bulk.status,
      stepIndex: bulk.editableStepIndex.clamp(0, 4),
    );
  }

  Future<void> _finalize(BuildContext context) async {
    await context(FinalizeBulkShipmentCommand(shipmentId));
    if (!context.mounted) return;
    final updated = _bulk(context);
    if (updated?.status != BulkShipmentStatus.completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not stock in — complete listing prices and counts first.',
          ),
        ),
      );
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk added to sellable inventory')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bulk = _bulk(context);
    if (bulk == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Bulk not found')),
      );
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BulkFlowScaffold(
      title: bulk.sellerLabel,
      bottom: bulk.status.isActive
          ? BulkStickyPrimaryButton(
              label: bulk.status == BulkShipmentStatus.priced
                  ? 'Add to inventory'
                  : bulk.nextActionLabel,
              onPressed: bulk.status == BulkShipmentStatus.priced
                  ? () => _finalize(context)
                  : () => _openStep(context, bulk),
            )
          : null,
      children: [
        BulkOutlineGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BulkProgressStepper(
                current: bulk.status,
                shipmentId: bulk.id,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                bulk.status.label,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                bulk.qualityNotes,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        BulkSection(
          title: 'Costs',
          child: _MetricGrid(bulk: bulk),
        ),
        if (bulk.status.isActive && bulk.status != BulkShipmentStatus.priced)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              'Continue step by step. Inventory updates only after stock in.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        if (!bulk.status.isActive)
          BulkOutlineGroup(
            child: Row(
              children: [
                Icon(Icons.check_circle, color: scheme.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    '${bulk.lines.length} types · ${bulk.actualUnitCount} units in inventory',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.bulk});

  final BulkShipment bulk;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tiles = <Widget>[
      _MetricTile(label: 'Lot price', value: formatMoney(bulk.agreedPrice)),
      _MetricTile(label: 'Delivery', value: formatMoney(bulk.deliveryCharge)),
      _MetricTile(label: 'Total paid', value: formatMoney(bulk.totalPaid)),
      if (bulk.actualUnitCount > 0)
        _MetricTile(
          label: 'Cost / unit',
          value: formatMoney(bulk.defaultUnitCost),
        ),
    ];

    return BulkOutlineGroup(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: tiles
            .map(
              (t) => SizedBox(
                width:
                    (MediaQuery.sizeOf(context).width -
                            AppSpacing.lg * 2 -
                            AppSpacing.sm * 3) /
                        2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: t,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}