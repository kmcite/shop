import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shop/business/shop_cubit.dart';

import '../../models/bulk_shipment_model.dart';
import '../../ui/format.dart';
import '../../ui/spacing.dart';
import '../design/metro.dart';
import '../widgets/bulk_progress_stepper.dart';

class BulkHistoryScreen extends StatelessWidget {
  const BulkHistoryScreen({super.key});

  static Route<void> route(BuildContext context) {
    return metroRoute(
      context: context,
      builder: (_) => const BulkHistoryScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completed = context.watch<ShopCubit>().state.completedBulkShipments;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Bulk history')),
      body: completed.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 56,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'No completed bulks yet',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Finish a bulk through Stock in — it will appear here '
                      'with order, receive, and stock-in dates.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: completed.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final bulk = completed[index];
                return _BulkHistoryCard(
                  shipment: bulk,
                  onTap: () =>
                      context.read<ShopCubit>().openBulkShipment(bulk.id),
                );
              },
            ),
    );
  }
}

class _BulkHistoryCard extends StatelessWidget {
  const _BulkHistoryCard({
    required this.shipment,
    required this.onTap,
  });

  final BulkShipment shipment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      shipment.sellerLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(Icons.check_circle, color: scheme.primary, size: 22),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${shipment.lines.length} types · ${shipment.actualUnitCount} units · ${formatMoney(shipment.totalPaid)} paid',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              BulkProgressStepper(
                current: BulkShipmentStatus.completed,
                shipmentId: shipment.id,
                compact: true,
              ),
              const SizedBox(height: AppSpacing.md),
              _DateRow(
                icon: Icons.handshake_outlined,
                label: 'Ordered',
                value: formatBulkDate(shipment.createdAt),
              ),
              _DateRow(
                icon: Icons.local_shipping_outlined,
                label: 'Received',
                value: formatBulkDate(shipment.receivedAt),
              ),
              _DateRow(
                icon: Icons.inventory_outlined,
                label: 'Counted',
                value: formatBulkDate(shipment.countedAt),
              ),
              _DateRow(
                icon: Icons.sell_outlined,
                label: 'Priced',
                value: formatBulkDate(shipment.pricedAt),
              ),
              _DateRow(
                icon: Icons.check_circle_outline,
                label: 'Stocked in',
                value: formatBulkDate(shipment.completedAt),
                emphasize: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              color: emphasize ? scheme.primary : scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}