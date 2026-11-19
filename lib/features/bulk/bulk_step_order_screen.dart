import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shop/business/shop_cubit.dart';

import '../../models/bulk_shipment_model.dart';
import '../../ui/format.dart' show formatBulkDate, formatMoney;
import '../../ui/spacing.dart';
import '../design/metro.dart';
import '../widgets/bulk/bulk_ui.dart';

/// Read-only view of the original bulk order (step 1).
class BulkStepOrderScreen extends StatelessWidget {
  const BulkStepOrderScreen({
    required this.shipmentId,
    this.embedded = false,
    super.key,
  });

  final String shipmentId;
  final bool embedded;

  static Route<void> route(BuildContext context, String shipmentId) {
    return metroRoute(
      context: context,
      builder: (_) => BulkStepOrderScreen(shipmentId: shipmentId),
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

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BulkFlowScaffold(
      title: 'Order details',
      embedded: embedded,
      children: [
        BulkStepContextHeader(status: bulk.status, stepIndex: 0),
        BulkSection(
          title: 'Deal details',
          child: BulkOutlineGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ReadOnlyRow(label: 'Seller', value: bulk.sellerLabel),
                _ReadOnlyRow(
                  label: 'Agreed price',
                  value: formatMoney(bulk.agreedPrice),
                ),
                _ReadOnlyRow(label: 'Promised quality', value: bulk.qualityNotes),
                _ReadOnlyRow(
                  label: 'Ordered on',
                  value: formatBulkDate(bulk.createdAt),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        BulkSection(
          title: 'Expected types',
          child: BulkOutlineGroup(
            child: bulk.lines.isEmpty
                ? Text(
                    'No types recorded.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < bulk.lines.length; i++)
                        if (!bulk.lines[i].extraFind)
                          BulkListTileRow(
                            leading: BulkIndexBadge(i + 1),
                            title: bulk.lines[i].name,
                            subtitle:
                                'Expected ~${bulk.lines[i].expectedQty ?? 0}',
                          ),
                    ],
                  ),
          ),
        ),
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
      child: Column(
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
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}