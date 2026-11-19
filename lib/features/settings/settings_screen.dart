import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shop/business/shop_cubit.dart';
import '../../ui/spacing.dart';

/// Pushes [SettingsScreen] with a circular reveal: the new page blooms
/// out of the top-right corner — where the settings icon lives — like a
/// spotlight, while fading in. On pop it collapses back into the icon.
Route<void> createSettingsRoute() {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 350),
    pageBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return const SettingsScreen();
        },
    transitionsBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          return AnimatedBuilder(
            animation: animation,
            child: child,
            builder: (context, child) {
              final t = Curves.easeOutCubic.transform(animation.value);
              return ClipPath(
                clipper: _RadialRevealClipper(
                  // Near the top-right, roughly under the settings icon.
                  origin: const Alignment(0.92, -0.92),
                  progress: t,
                ),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.4, end: 1).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: const Interval(0.0, 0.6),
                    ),
                  ),
                  child: child,
                ),
              );
            },
          );
        },
  );
}

/// Clips the incoming page to a circle growing from [origin].
class _RadialRevealClipper extends CustomClipper<Path> {
  const _RadialRevealClipper({required this.origin, required this.progress});

  final Alignment origin;
  final double progress;

  @override
  Path getClip(Size size) {
    final center = origin.alongSize(size);
    // longSide * sqrt(2) covers the farthest corner from any origin.
    final radius = size.longestSide * math.sqrt2 * progress;
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(_RadialRevealClipper oldClipper) =>
      oldClipper.progress != progress || oldClipper.origin != origin;
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shopState = context.watch<ShopCubit>().state;
    final isDark = theme.brightness == Brightness.dark;

    final modeLabel = switch (shopState.themeMode) {
      ThemeMode.system => 'System',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              'APPEARANCE',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: SwitchListTile(
              secondary: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode_outlined,
                color: scheme.primary,
              ),
              title: const Text('Dark mode'),
              subtitle: Text('$modeLabel theme'),
              value: isDark,
              onChanged: (value) => context.read<ShopCubit>().setThemeMode(
                    value ? ThemeMode.dark : ThemeMode.light,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              'DATA',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.receipt_long_outlined,
                    color: scheme.error,
                  ),
                  title: const Text('Clear all sales'),
                  subtitle: Text(
                    shopState.sales.isEmpty
                        ? 'No sales recorded'
                        : '${shopState.sales.length} sale'
                            '${shopState.sales.length == 1 ? '' : 's'} on device',
                  ),
                  enabled: shopState.sales.isNotEmpty,
                  onTap: shopState.sales.isEmpty
                      ? null
                      : () => context.read<ShopCubit>().clearAllSalesFlow(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.inventory_2_outlined,
                    color: scheme.error,
                  ),
                  title: const Text('Clear all inventory'),
                  subtitle: Text(
                    shopState.items.isEmpty
                        ? 'No products in stock'
                        : '${shopState.items.length} product'
                            '${shopState.items.length == 1 ? '' : 's'} in stock',
                  ),
                  enabled: shopState.items.isNotEmpty,
                  onTap: shopState.items.isEmpty
                      ? null
                      : () => context.read<ShopCubit>().clearAllInventoryFlow(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.local_shipping_outlined,
                    color: scheme.error,
                  ),
                  title: const Text('Clear all bulks'),
                  subtitle: Text(
                    shopState.bulkShipments.isEmpty
                        ? 'No bulk records'
                        : '${shopState.bulkShipments.length} bulk'
                            '${shopState.bulkShipments.length == 1 ? '' : 's'} on device',
                  ),
                  enabled: shopState.bulkShipments.isNotEmpty,
                  onTap: shopState.bulkShipments.isEmpty
                      ? null
                      : () => context.read<ShopCubit>().clearAllBulksFlow(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
