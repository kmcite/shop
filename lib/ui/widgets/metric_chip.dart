/// Reusable metric tile used by summary strips and dashboards.
library;

import 'package:flutter/material.dart';

import '../spacing.dart';

class const MetricChip({
  super.key,
  required final IconData icon,
  required final String label,
  final String? subtitle,
  final Color? tint,
}) extends StatelessWidget {
  // Uniform footprint so a strip never looks ragged: every chip is
  // the same size regardless of content or subtitle presence.
  static const double _chipWidth = 132;
  static const double _chipHeight = 56;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = tint ?? scheme.primary;

    return Card(
      margin: EdgeInsets.zero,
      child: SizedBox(
        width: _chipWidth,
        height: _chipHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                // scaleDown keeps long labels (e.g. the stock value) inside
                // the uniform chip size instead of overflowing.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
