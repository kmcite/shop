import 'package:flutter/material.dart';

import '../../ui/spacing.dart';
import '../design/metro.dart';

/// Shown while the scope boots and the shared database connects.
class ShopLoadingView extends StatelessWidget {
  const ShopLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metro = MetroTheme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MetroBadge(
              icon: Icons.storefront_outlined,
              size: 96,
              filled: false,
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: 140,
              child: LinearProgressIndicator(
                minHeight: 3,
                color: metro.colors.accent,
                backgroundColor: metro.colors.mutedForeground.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'connecting to database\u2026',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: metro.colors.mutedForeground,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
