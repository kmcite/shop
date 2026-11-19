import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shop/business/shop_cubit.dart';

import '../../models/customer_model.dart';
import '../../ui/format.dart';
import '../../ui/spacing.dart';
import '../design/metro.dart';
import '../widgets/search_field.dart';
import 'customer_detail_screen.dart';
import 'customer_editor_sheet.dart';

/// Customers hub: people who buy on credit, with remaining balances.
class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _query = '';
  _CustomersFilter _filter = _CustomersFilter.owing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metro = MetroTheme.of(context);
    final state = context.watch<ShopCubit>().state;
    final accounts = _filtered(state.customerAccounts);
    final receivables = state.totalCustomerReceivables;

    return MetroRefresh(
      onRefresh: () => context.read<ShopCubit>().reloadData(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MetroPanel(
                    margin: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'still owed',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: metro.colors.mutedForeground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          formatMoney(receivables),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w300,
                            color: receivables > 0
                                ? metro.colors.accent
                                : metro.colors.foreground,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          state.customers.isEmpty
                              ? 'Add a customer to track credit sales & payments'
                              : '${state.customersWithBalance.length} owing · '
                                  '${state.customers.length} total',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: metro.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SearchField(
                    query: _query,
                    onChanged: (value) =>
                        setState(() => _query = value.trim()),
                    hintText: 'search customers\u2026',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  MetroPivotBar<_CustomersFilter>(
                    selected: _filter,
                    onSelected: (value) => setState(() => _filter = value),
                    options: const [
                      MetroPivotOption(
                        value: _CustomersFilter.owing,
                        label: 'owing',
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                      MetroPivotOption(
                        value: _CustomersFilter.all,
                        label: 'all',
                        icon: Icons.people_outline,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (state.customers.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _CustomersEmptyState(),
            )
          else if (accounts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: MetroEmptyState(
                message: _filter == _CustomersFilter.owing
                    ? 'Nobody owes you right now.'
                    : 'No customers match “$_query”.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final account = accounts[index];
                    return MetroListRow(
                      title: account.customer.name,
                      subtitle: _subtitle(account),
                      leading: MetroBadge.letter(
                        account.customer.name,
                        size: 40,
                      ),
                      trailing: Text(
                        formatMoney(account.remaining),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: account.remaining > 0.005
                              ? metro.colors.accent
                              : account.remaining < -0.005
                                  ? metro.colors.success
                                  : metro.colors.mutedForeground,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          CustomerDetailScreen.route(
                            context,
                            account.customer.id,
                          ),
                        );
                      },
                    );
                  },
                  childCount: accounts.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }

  List<CustomerAccount> _filtered(List<CustomerAccount> all) {
    var list = switch (_filter) {
      _CustomersFilter.owing =>
        all.where((a) => a.remaining > 0.005).toList(),
      _CustomersFilter.all => List<CustomerAccount>.from(all),
    };
    final q = _query.toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((a) => a.customer.name.toLowerCase().contains(q))
          .toList();
    }
    list.sort((a, b) {
      final byRemaining = b.remaining.compareTo(a.remaining);
      if (byRemaining != 0) return byRemaining;
      return a.customer.name.toLowerCase().compareTo(
            b.customer.name.toLowerCase(),
          );
    });
    return list;
  }

  String _subtitle(CustomerAccount account) {
    final parts = <String>[];
    if (account.saleCount > 0) {
      parts.add(
        '${account.saleCount} sale${account.saleCount == 1 ? '' : 's'}',
      );
    }
    if (account.paymentCount > 0) {
      parts.add(
        '${account.paymentCount} payment${account.paymentCount == 1 ? '' : 's'}',
      );
    }
    if (account.lastActivity != null) {
      parts.add(formatBulkDate(account.lastActivity));
    }
    if (parts.isEmpty) return 'no activity yet';
    return parts.join(' · ');
  }
}

enum _CustomersFilter { owing, all }

class _CustomersEmptyState extends StatelessWidget {
  const _CustomersEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metro = MetroTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MetroBadge(
              icon: Icons.people_outline,
              size: 88,
              filled: false,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'customers',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Track who bought on credit, what they took, '
              'what they paid, and what remains.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: metro.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: MetroButton.accent(
                onPressed: () => openCustomerEditor(context),
                style: const MetroButtonStyle(minimumSize: Size(0, 44)),
                child: const Text('Add first customer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
