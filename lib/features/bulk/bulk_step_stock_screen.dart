import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shop/business/shop_cubit.dart';

import '../../models/bulk_shipment_model.dart';
import '../../ui/format.dart';
import '../../ui/spacing.dart';
import '../design/metro.dart';
import '../widgets/bulk/bulk_ui.dart';

/// Stock-in step: summary (read-only). Finalize only from hub when priced.
class BulkStepStockScreen extends StatelessWidget {
  const BulkStepStockScreen({
    required this.shipmentId,
    this.readOnly = true,
    this.embedded = false,
    super.key,
  });

  final String shipmentId;
  final bool readOnly;
  final bool embedded;

  static Route<void> route(
    BuildContext context,
    String shipmentId, {
    bool readOnly = true,
  }) {
    return metroRoute(
      context: context,
      builder: (_) => BulkStepStockScreen(
        shipmentId: shipmentId,
        readOnly: readOnly,
      ),
    );
  }

  BulkShipment? _bulk(BuildContext context) {
    for (final b in context.watch<ShopCubit>().state.bulkShipments) {
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

    return BulkFlowScaffold(
      title: 'Stock in',
      embedded: embedded,
      children: [
        BulkStepContextHeader(status: bulk.status, stepIndex: 4),
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