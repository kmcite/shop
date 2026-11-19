import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shop/business/item_form_cubit.dart';

import '../../models/shop_item_model.dart';
import '../../ui/spacing.dart';
import '../design/metro.dart';
import 'item_form_sheet_fields.dart';

/// Opens the edit screen for a single existing item. Returns the edited draft,
/// or null when cancelled.
Future<ShopItem?> openItemFormSheet(
  BuildContext context, {
  required ShopItem existing,
}) async {
  context.read<ItemFormCubit>().begin(existing);
  if (!context.mounted) return null;

  return Navigator.of(context).push<ShopItem>(
    metroRoute(context: context, builder: (_) => ItemFormScreen(existing: existing)),
  );
}

class ItemFormScreen extends StatelessWidget {
  const ItemFormScreen({super.key, required this.existing});

  final ShopItem existing;

  Future<void> _submit(BuildContext context) async {
    final formCubit = context.read<ItemFormCubit>();
    formCubit.validateForSubmit();
    if (!context.mounted) return;

    final form = context.read<ItemFormCubit>().state;
    if (form.isValid) Navigator.pop(context, form.draft(existing));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('edit item')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        children: [
          Text(
            'Update the details or correct the stock count.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const ItemFormSheetFields(isEdit: true),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          child: SizedBox(
            width: double.infinity,
            child: MetroButton.accent(
              onPressed: () => _submit(context),
              style: const MetroButtonStyle(minimumSize: Size(0, 44)),
              child: const Text('Save changes'),
            ),
          ),
        ),
      ),
    );
  }
}
