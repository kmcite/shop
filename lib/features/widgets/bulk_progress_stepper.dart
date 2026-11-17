import 'package:flutter/material.dart';

import '../../models/bulk_shipment_model.dart';
import '../../ui/spacing.dart';
import '../screens/bulk/bulk_step_access.dart';
import '../screens/bulk/bulk_step_navigation.dart';

/// Horizontal progress for the bulk lifecycle (order → receive → count → price).
class BulkProgressStepper extends StatelessWidget {
  const BulkProgressStepper({
    super.key,
    required this.current,
    required this.shipmentId,
    this.compact = false,
    this.enableNavigation = true,
  });

  final BulkShipmentStatus current;
  final String shipmentId;
  final bool compact;
  final bool enableNavigation;

  static const _steps = [
    (BulkShipmentStatus.ordered, 'Order', Icons.handshake_outlined),
    (BulkShipmentStatus.received, 'Receive', Icons.local_shipping_outlined),
    (BulkShipmentStatus.counted, 'Count', Icons.inventory_outlined),
    (BulkShipmentStatus.priced, 'Price', Icons.sell_outlined),
    (BulkShipmentStatus.completed, 'Stock', Icons.check_circle_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final allDone = current == BulkShipmentStatus.completed;
    final activeIndex = allDone
        ? _steps.length - 1
        : current.isActive
            ? BulkStepAccess.editableStepIndex(current).clamp(0, _steps.length - 1)
            : _steps.length - 1;

    return Row(
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                color: i <= activeIndex
                    ? scheme.primary
                    : scheme.outlineVariant,
              ),
            ),
          _StepDot(
            icon: _steps[i].$3,
            label: compact ? null : _steps[i].$2,
            isActive: !allDone && i == activeIndex,
            isComplete: allDone || i < activeIndex,
            isLocked: BulkStepAccess.isLocked(current, i),
            readOnly: BulkStepAccess.isReadOnly(current, i),
            onTap: enableNavigation && BulkStepAccess.canNavigate(current, i)
                ? () => openBulkTimelineStep(
                      context,
                      shipmentId: shipmentId,
                      status: current,
                      stepIndex: i,
                    )
                : null,
          ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isComplete,
    required this.isLocked,
    required this.readOnly,
    this.onTap,
  });

  final IconData icon;
  final String? label;
  final bool isActive;
  final bool isComplete;
  final bool isLocked;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isLocked
        ? scheme.outline
        : isComplete || isActive
            ? scheme.primary
            : scheme.outline;

    final tooltip = isLocked
        ? 'Complete earlier steps first'
        : readOnly
            ? 'View ${label ?? 'step'} (read-only)'
            : isActive
                ? 'Continue ${label ?? 'step'}'
                : 'Open ${label ?? 'step'}';

    final dot = CircleAvatar(
      radius: 16,
      backgroundColor: isLocked
          ? scheme.surfaceContainerHighest
          : isActive || isComplete
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
      child: Icon(
        isLocked ? Icons.lock_outline : icon,
        size: 18,
        color: color,
      ),
    );

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onTap != null)
          InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: dot,
          )
        else
          dot,
        if (label != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            label!,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isActive && !isLocked
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                  fontWeight: isActive ? FontWeight.w700 : null,
                ),
          ),
        ],
      ],
    );

    return Tooltip(message: tooltip, child: column);
  }
}