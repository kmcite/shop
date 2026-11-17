import 'package:any/any.dart';
import 'package:flutter/material.dart';

import '../../commands/item_form_commands.dart';
import '../../models/shop_item_model.dart';
import '../../states/item_form_state.dart';
import '../../ui/spacing.dart';
import 'item_form_sheet_fields.dart';

/// Opens the edit sheet for a single existing item. Returns the edited draft,
/// or null when cancelled.
Future<ShopItem?> openItemFormSheet(
  BuildContext context, {
  required ShopItem existing,
}) async {
  await context(BeginItemFormCommand(existing));
  if (!context.mounted) return null;

  return showModalBottomSheet<ShopItem>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ItemFormSheet(existing: existing),
  );
}

class _ItemFormSheet extends StatelessWidget {
  const _ItemFormSheet({required this.existing});

  final ShopItem existing;

  Future<void> _submit(BuildContext context) async {
    await context(const SubmitItemFormCommand());
    if (!context.mounted) return;

    final form = context.of<ItemFormState>();
    if (form.isValid) Navigator.pop(context, form.draft(existing));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.lg + bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit item', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Update the details or correct the stock count.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const ItemFormSheetFields(isEdit: true),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () => _submit(context),
              child: const Text('Save changes'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}