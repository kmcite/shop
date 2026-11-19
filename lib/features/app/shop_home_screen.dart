/// App shell: three-tab view — Buy bulk, Sell, and Sales — switched with
/// a bottom navigation bar. The buy-bulk FAB only shows on the stock screen.
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shop/business/bulk_order_draft_cubit.dart';
import 'package:shop/business/shop_cubit.dart';
import '../../ui/spacing.dart';
import '../sales/sales_screen.dart';
import '../sell/sell_screen.dart';
import '../settings/settings_screen.dart';
import '../stock/stock_screen.dart';

class ShopHomeScreen extends StatefulWidget {
  const ShopHomeScreen({super.key});

  @override
  State<ShopHomeScreen> createState() => _ShopHomeScreenState();
}

class _ShopHomeScreenState extends State<ShopHomeScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _titles = ['Buy bulk', 'Sell', 'Sales'];

  void _goToScreen(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_index],
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(createSettingsRoute());
            },
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: PageView(
        controller: _controller,
        onPageChanged: (index) => setState(() => _index = index),
        children: [
          const StockScreen(),
          SellScreen(onGoToStock: () => _goToScreen(0)),
          const SalesScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goToScreen,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Buy bulk',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'Sell',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Sales',
          ),
        ],
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.read<ShopCubit>().startBulkFlow(
                    context.read<BulkOrderDraftCubit>(),
                  ),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Buy bulk'),
            )
          : null,
    );
  }
}