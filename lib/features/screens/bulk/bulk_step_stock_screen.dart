import 'package:any/any.dart';
import 'package:flutter/material.dart';

import '../../../models/bulk_shipment_model.dart';
import '../../../states/shop_state.dart';
import '../../../ui/format.dart';
import '../../../ui/spacing.dart';
import '../../widgets/bulk/bulk_ui.dart';
import 'bulk_step_access.dart';

/// Stock-in step: summary (read-only). Finalize only from hub when priced.
class BulkStepStockScreen extends StatelessWidget {
  const BulkStepStockScreen({
    required this.shipmentId,
    this.readOnly = true,
    super.key,
  });

  final String shipmentId;
  final bool readOnly;

  static Route<void> route(String shipmentId, {bool readOnly = true}) {
    return MaterialPageRoute<void>(
      builder: (_) => BulkStepStockScreen(
        shipmentId: shipmentId,
        readOnly: readOnly,
      ),
    );
  }

  BulkShipment? _bulk(BuildContext context) {
    for (final b in context.of<ShopState>().bulkShipments) {
      if (b.id == shipmentId) return b;
    }
    return null;
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

    final completed = bulk.status == BulkShipmentStatus.completed;
    final awaitingStockIn = bulk.status == BulkShipmentStatus.priced;

    return BulkFlowScaffold(
      title: 'Stock in',
      children: [
        if (completed)
          const BulkReadOnlyBanner(
            message: 'This bulk was added to inventory.',
          )
        else if (awaitingStockIn)
          const BulkIntroText(
            'Listing prices are set — add this bulk to inventory from the hub.',
          )
        else if (readOnly &&
            BulkStepAccess.isReadOnly(bulk.status, 4)) ...[
          const BulkReadOnlyBanner(),
          const SizedBox(height: AppSpacing.md),
        ],
        if (completed || awaitingStockIn) const SizedBox(height: AppSpacing.md),
        BulkOutlineGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ReadOnlyRow(
                label: 'Types',
                value: '${bulk.lines.length}',
              ),
              _ReadOnlyRow(
                label: 'Units',
                value: '${bulk.actualUnitCount}',
              ),
              _ReadOnlyRow(
                label: 'Total paid',
                value: formatMoney(bulk.totalPaid),
              ),
              if (completed)
                _ReadOnlyRow(
                  label: 'Stocked in',
                  value: formatBulkDate(bulk.completedAt),
                ),
            ],
          ),
        ),
        if (bulk.lines.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          BulkSection(
            title: 'Lines',
            child: BulkOutlineGroup(
              child: Column(
                children: [
                  for (final line in bulk.lines)
                    BulkListTileRow(
                      title: line.name,
                      subtitle:
                          '×${line.actualQty ?? 0} · list ${formatMoney(line.listPrice ?? 0)}',
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}