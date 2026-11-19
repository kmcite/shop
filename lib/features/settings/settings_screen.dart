import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shop/business/shop_cubit.dart';

import '../design/metro.dart';

Route<void> createSettingsRoute(BuildContext context) {
  return metroRoute(context: context, builder: (_) => const SettingsScreen());
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.embedded = false});

  /// When true, omit [Scaffold]/[AppBar] — used inside the home tab shell.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shopState = context.watch<ShopCubit>().state;
    final isDark = theme.brightness == Brightness.dark;

    final modeLabel = switch (shopState.themeMode) {
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
    };

    final body = ListView(
      children: [
        const MetroHeader.section('appearance'),
        MetroToggleTile(
          leading: Icon(
            isDark ? Icons.dark_mode : Icons.light_mode_outlined,
            color: MetroColors.cyan,
            size: 22,
          ),
          title: 'dark mode',
          subtitle: modeLabel,
          value: isDark,
          onChanged: (value) => context.read<ShopCubit>().setThemeMode(
                value ? ThemeMode.dark : ThemeMode.light,
              ),
        ),
        const MetroHeader.section('data'),
        ListTile(
          leading: Icon(
            Icons.receipt_long_outlined,
            color: scheme.error,
            size: 22,
          ),
          title: const Text('clear all sales'),
          subtitle: Text(
            shopState.sales.isEmpty
                ? 'no sales recorded'
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
            size: 22,
          ),
          title: const Text('clear all inventory'),
          subtitle: Text(
            shopState.items.isEmpty
                ? 'no products in stock'
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
            size: 22,
          ),
          title: const Text('clear all bulks'),
          subtitle: Text(
            shopState.bulkShipments.isEmpty
                ? 'no bulk records'
                : '${shopState.bulkShipments.length} bulk'
                    '${shopState.bulkShipments.length == 1 ? '' : 's'} on device',
          ),
          enabled: shopState.bulkShipments.isNotEmpty,
          onTap: shopState.bulkShipments.isEmpty
              ? null
              : () => context.read<ShopCubit>().clearAllBulksFlow(),
        ),
      ],
    );

    if (embedded) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('settings')),
      body: body,
    );
  }
}
