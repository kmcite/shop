import 'package:material_ui/material_ui.dart';

import '../../models/bulk_shipment_model.dart';
import '../../ui/format.dart';
import '../../ui/spacing.dart';
import 'bulk_progress_stepper.dart';

class BulkShipmentCard extends StatelessWidget {
  const BulkShipmentCard({
    super.key,
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
        borderRadius: BorderRadius.circular(16),
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
                  Chip(
                    label: Text(shipment.status.label),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    side: BorderSide(color: scheme.outlineVariant),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${formatMoney(shipment.agreedPrice)} lot'
                '${shipment.deliveryCharge > 0 ? ' · ${formatMoney(shipment.deliveryCharge)} delivery' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (shipment.lines.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${shipment.lines.length} types'
                  '${shipment.status.index >= BulkShipmentStatus.counted.index ? ' · ${shipment.actualUnitCount} units' : shipment.expectedUnitCount > 0 ? ' · ~${shipment.expectedUnitCount} expected' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              BulkProgressStepper(
                current: shipment.status,
                shipmentId: shipment.id,
                compact: true,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      shipment.nextActionLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: scheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}