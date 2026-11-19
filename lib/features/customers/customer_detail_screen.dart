import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shop/business/shop_cubit.dart';

import '../../models/customer_model.dart';
import '../../ui/format.dart';
import '../../ui/spacing.dart';
import '../design/metro.dart';
import 'customer_editor_sheet.dart';
import 'record_credit_sale_screen.dart';
import 'record_payment_sheet.dart';

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final String customerId;

  static Route<void> route(BuildContext context, String customerId) {
    return metroRoute(
      context: context,
      builder: (_) => CustomerDetailScreen(customerId: customerId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metro = MetroTheme.of(context);
    final account = context.watch<ShopCubit>().state.accountFor(customerId);

    if (account == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const MetroEmptyState(message: 'Customer not found'),
      );
    }

    final remaining = account.remaining;

    return Scaffold(
      appBar: AppBar(
        title: Text(account.customer.name.toLowerCase()),
        actions: [
          MetroIconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => openCustomerEditor(
              context,
              existing: account.customer,
            ),
            semanticLabel: 'Edit customer',
          ),
          MetroIconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => _confirmDelete(context, account),
            semanticLabel: 'Delete customer',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          MetroPanel(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  remaining > 0.005
                      ? 'still owes'
                      : remaining < -0.005
                          ? 'credit on account'
                          : 'settled',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: metro.colors.mutedForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  formatMoney(remaining.abs()),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w200,
                    color: remaining > 0.005
                        ? metro.colors.accent
                        : remaining < -0.005
                            ? metro.colors.success
                            : metro.colors.foreground,
                  ),
                ),
                if (account.customer.note.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    account.customer.note,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: metro.colors.mutedForeground,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: _StatChip(
                        label: 'sold',
                        value: formatMoney(account.totalSold),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _StatChip(
                        label: 'paid',
                        value: formatMoney(account.totalPaid),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: MetroButton.accent(
                  onPressed: () => openRecordCreditSale(
                    context,
                    customer: account.customer,
                  ),
                  style: const MetroButtonStyle(minimumSize: Size(0, 44)),
                  child: const Text('Credit sale'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: MetroButton(
                  onPressed: () => openRecordPayment(
                    context,
                    account: account,
                  ),
                  style: const MetroButtonStyle(minimumSize: Size(0, 44)),
                  child: const Text('Payment'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'ledger',
            style: theme.textTheme.labelLarge?.copyWith(
              color: metro.colors.mutedForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (account.entries.isEmpty)
            MetroEmptyState(
              message: 'No sales or payments yet. Record a credit sale to start.',
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            )
          else
            for (final entry in account.entries) ...[
              _LedgerTile(entry: entry),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CustomerAccount account,
  ) async {
    final yes = await showMetroDialog<bool>(
      context: context,
      title: 'Remove ${account.customer.name}?',
      message: account.entries.isEmpty
          ? 'This customer has no ledger history.'
          : 'This deletes ${account.entries.length} ledger '
              'entries. Inventory sales history stays.',
      actions: [
        MetroDialogAction(
          label: 'Keep',
          onPressed: () => Navigator.pop(context, false),
        ),
        MetroDialogAction(
          label: 'Delete',
          accent: true,
          destructive: true,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
    if (yes != true || !context.mounted) return;
    await context.read<ShopCubit>().deleteCustomer(account.customer.id);
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metro = MetroTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      color: metro.colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: metro.colors.mutedForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({required this.entry});

  final CustomerLedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metro = MetroTheme.of(context);
    final isSale = entry.isSale;
    final amount = isSale ? entry.saleTotal : entry.amount;

    return MetroPanel(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MetroBadge(
                icon: isSale
                    ? Icons.shopping_bag_outlined
                    : Icons.payments_outlined,
                size: 36,
                filled: false,
                color: isSale ? metro.colors.accent : metro.colors.success,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.headline,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatBulkDate(entry.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: metro.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isSale ? '+' : '−'}${formatMoney(amount)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isSale ? metro.colors.accent : metro.colors.success,
                ),
              ),
            ],
          ),
          if (isSale && entry.lines.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            for (final line in entry.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${line.quantity}× ${line.itemName}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      formatMoney(line.total),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: metro.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (entry.note.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              entry.note,
              style: theme.textTheme.bodySmall?.copyWith(
                color: metro.colors.mutedForeground,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
