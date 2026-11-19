/// App shell: static bottom navigation across main shop screens.
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shop/business/bulk_order_draft_cubit.dart';
import 'package:shop/business/shop_cubit.dart';

import '../customers/customer_editor_sheet.dart';
import '../customers/customers_screen.dart';
import '../design/metro.dart';
import '../sales/sales_screen.dart';
import '../sell/sell_screen.dart';
import '../settings/settings_screen.dart';
import '../stock/stock_screen.dart';

enum ShopHomeTab { buyBulk, sell, sales, customers, settings }

class ShopHomeScreen extends StatefulWidget {
  const ShopHomeScreen({super.key});

  @override
  State<ShopHomeScreen> createState() => _ShopHomeScreenState();
}

class _ShopHomeScreenState extends State<ShopHomeScreen> {
  ShopHomeTab _tab = ShopHomeTab.buyBulk;

  static const _titles = {
    ShopHomeTab.buyBulk: 'buy bulk',
    ShopHomeTab.sell: 'sell',
    ShopHomeTab.sales: 'sales',
    ShopHomeTab.customers: 'customers',
    ShopHomeTab.settings: 'settings',
  };

  void _goTo(ShopHomeTab tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final metro = MetroTheme.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MetroSpacing.lg,
                MetroSpacing.sm,
                MetroSpacing.lg,
                MetroSpacing.xs,
              ),
              child: Text(
                _titles[_tab]!,
                style: metro.typography.header.copyWith(
                  fontWeight: FontWeight.w200,
                ),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _tab.index,
                children: [
                  const StockScreen(),
                  SellScreen(
                    embedded: true,
                    onGoToStock: () => _goTo(ShopHomeTab.buyBulk),
                  ),
                  const SalesScreen(),
                  const CustomersScreen(),
                  const SettingsScreen(embedded: true),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: switch (_tab) {
        ShopHomeTab.buyBulk => FloatingActionButton(
            onPressed: () {
              context.read<ShopCubit>().startBulkFlow(
                    context.read<BulkOrderDraftCubit>(),
                  );
            },
            tooltip: 'New bulk',
            child: const Icon(MetroIcons.addBulk),
          ),
        ShopHomeTab.customers => FloatingActionButton(
            onPressed: () => openCustomerEditor(context),
            tooltip: 'Add customer',
            child: const Icon(MetroIcons.addCustomer),
          ),
        _ => null,
      },
      bottomNavigationBar: MetroStaticBottomBar(
        selectedIndex: _tab.index,
        items: [
          MetroBottomItem(
            icon: MetroIcons.stock,
            label: 'buy bulk',
            onTap: () => _goTo(ShopHomeTab.buyBulk),
          ),
          MetroBottomItem(
            icon: MetroIcons.sell,
            label: 'sell',
            onTap: () => _goTo(ShopHomeTab.sell),
          ),
          MetroBottomItem(
            icon: MetroIcons.sales,
            label: 'sales',
            onTap: () => _goTo(ShopHomeTab.sales),
          ),
          MetroBottomItem(
            icon: MetroIcons.customers,
            label: 'customers',
            onTap: () => _goTo(ShopHomeTab.customers),
          ),
          MetroBottomItem(
            icon: MetroIcons.settings,
            label: 'settings',
            onTap: () => _goTo(ShopHomeTab.settings),
          ),
        ],
      ),
    );
  }
}
