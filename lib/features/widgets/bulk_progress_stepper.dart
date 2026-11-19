import 'package:flutter/material.dart';

import '../../models/bulk_shipment_model.dart';
import '../../ui/spacing.dart';
import '../bulk/bulk_step_access.dart';
import '../bulk/bulk_step_navigation.dart';
import '../design/metro.dart';

/// Sharp Metro step strip for the bulk lifecycle (order → receive → … → stock).
class BulkProgressStepper extends StatelessWidget {
  const BulkProgressStepper({
    super.key,
    required this.current,
    required this.shipmentId,
    this.compact = false,
    this.enableNavigation = true,
    this.selectedStepIndex,
    this.onStepSelected,
  });

  final BulkShipmentStatus current;
  final String shipmentId;
  final bool compact;
  final bool enableNavigation;

  /// Highlighted step (e.g. current panorama section). Defaults to workflow step.
  final int? selectedStepIndex;

  /// When set, step tiles call this instead of pushing a new route.
  final ValueChanged<int>? onStepSelected;

  static const _steps = [
    (BulkShipmentStatus.ordered, 'order', Icons.handshake_outlined),
    (BulkShipmentStatus.received, 'receive', Icons.local_shipping_outlined),
    (BulkShipmentStatus.counted, 'count', Icons.inventory_outlined),
    (BulkShipmentStatus.priced, 'price', Icons.sell_outlined),
    (BulkShipmentStatus.completed, 'stock', Icons.check_circle_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final metro = MetroTheme.of(context);
    final allDone = current == BulkShipmentStatus.completed;
    final workflowIndex = allDone
        ? _steps.length - 1
        : current.isActive
            ? BulkStepAccess.editableStepIndex(current)
                .clamp(0, _steps.length - 1)
            : _steps.length - 1;
    final activeIndex = selectedStepIndex ?? workflowIndex;

    return Row(
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                color: i <= activeIndex
                    ? metro.colors.accent
                    : metro.colors.mutedForeground.withValues(alpha: 0.25),
              ),
            ),
          _StepTile(
            icon: _steps[i].$3,
            label: compact ? null : _steps[i].$2,
            isActive: !allDone && i == activeIndex,
            isComplete: allDone || i < workflowIndex,
            isLocked: BulkStepAccess.isLocked(current, i),
            readOnly: BulkStepAccess.isReadOnly(current, i),
            onTap: enableNavigation &&
                    (onStepSelected != null ||
                        BulkStepAccess.canNavigate(current, i))
                ? () {
                    final handler = onStepSelected;
                    if (handler != null) {
                      handler(i);
                    } else {
                      openBulkTimelineStep(
                        context,
                        shipmentId: shipmentId,
                        status: current,
                        stepIndex: i,
                      );
                    }
                  }
                : null,
          ),
        ],
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
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
    final theme = Theme.of(context);
    final metro = MetroTheme.of(context);
    final subtle = metro.colors.mutedForeground;
    final filled = !isLocked && (isActive || isComplete);

    final bg = isLocked
        ? metro.colors.surface
        : filled
            ? metro.colors.accent
            : Colors.transparent;
    final border = isLocked
        ? subtle.withValues(alpha: 0.3)
        : filled
            ? metro.colors.accent
            : subtle.withValues(alpha: 0.45);
    final iconColor = isLocked
        ? subtle
        : filled
            ? Colors.white
            : subtle;
    final labelColor = isLocked
        ? subtle
        : isActive
            ? metro.colors.accent
            : subtle;

    final tooltip = isLocked
        ? 'Complete earlier steps first'
        : readOnly
            ? 'View ${label ?? 'step'} (read-only)'
            : isActive
                ? 'Continue ${label ?? 'step'}'
                : 'Open ${label ?? 'step'}';

    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: isActive ? 2 : 1.5),
        borderRadius: BorderRadius.zero,
      ),
      alignment: Alignment.center,
      child: Icon(
        isLocked ? Icons.lock_outline : icon,
        size: 18,
        color: iconColor,
      ),
    );

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onTap != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: tile,
          )
        else
          tile,
        if (label != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            label!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: labelColor,
              fontWeight:
                  isActive && !isLocked ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ],
    );

    return Tooltip(message: tooltip, child: column);
  }
}
