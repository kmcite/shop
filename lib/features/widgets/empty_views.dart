/// Empty and no-results placeholders for the home page, plus the shared
/// icon badge used by both.
library;

import 'package:flutter/material.dart';

import '../../ui/spacing.dart';

/// Tinted circle behind empty-state icons.
class EmptyStateBadge extends StatelessWidget {
  const EmptyStateBadge({
    super.key,
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 48,
      backgroundColor: color.withValues(alpha: 0.12),
      child: Icon(icon, size: 44, color: color),
    );
  }
}

class NoSearchResults extends StatelessWidget {
  const NoSearchResults({
    super.key,
    required this.query,
    required this.onClear,
  });

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EmptyStateBadge(
              icon: Icons.search_off,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'No matches',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Nothing in your inventory matches \u201c$query\u201d.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.close),
              label: const Text('Clear search'),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EmptyStateBadge(
            icon: Icons.storefront_outlined,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Stock your shop',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Order a bulk from a seller, receive it at home, count what '
            'arrived, set listing prices, then sell from the Sell tab.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
