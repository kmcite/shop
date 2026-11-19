import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shop/business/shop_cubit.dart';

import '../../models/customer_model.dart';
import '../../ui/format.dart';
import '../../ui/spacing.dart';
import '../design/metro.dart';
import '../widgets/search_field.dart';
import 'customer_editor_sheet.dart';

Future<ShopCustomer?> openPickCustomer(BuildContext context) {
  return Navigator.of(context).push<ShopCustomer>(
    metroRoute(
      context: context,
      builder: (_) => const PickCustomerScreen(),
    ),
  );
}

class PickCustomerScreen extends StatefulWidget {
  const PickCustomerScreen({super.key});

  @override
  State<PickCustomerScreen> createState() => _PickCustomerScreenState();
}

class _PickCustomerScreenState extends State<PickCustomerScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metro = MetroTheme.of(context);
    final accounts = context.watch<ShopCubit>().state.customerAccounts;
    final q = _query.toLowerCase();
    final filtered = q.isEmpty
        ? accounts
        : accounts
            .where((a) => a.customer.name.toLowerCase().contains(q))
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('who is buying?')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: SearchField(
              query: _query,
              onChanged: (v) => setState(() => _query = v.trim()),
              hintText: 'search customers\u2026',
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              children: [
                MetroListRow(
                  title: 'New customer',
                  subtitle: 'Create someone, then assign this sale',
                  leading: Icon(
                    Icons.person_add_alt_1_outlined,
                    color: metro.colors.accent,
                  ),
                  onTap: () async {
                    final created = await openCustomerEditor(context);
                    if (created != null && context.mounted) {
                      Navigator.of(context).pop(created);
                    }
                  },
                ),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      accounts.isEmpty
                          ? 'No customers yet — add one above.'
                          : 'No matches for “$_query”.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: metro.colors.mutedForeground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  for (final account in filtered)
                    MetroListRow(
                      title: account.customer.name,
                      subtitle: account.remaining > 0.005
                          ? 'Owes ${formatMoney(account.remaining)}'
                          : account.remaining < -0.005
                              ? 'Credit ${formatMoney(-account.remaining)}'
                              : 'Settled',
                      leading: MetroBadge.letter(
                        account.customer.name,
                        size: 40,
                      ),
                      onTap: () =>
                          Navigator.of(context).pop(account.customer),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
