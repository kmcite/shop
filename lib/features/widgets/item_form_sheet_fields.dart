import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shop/business/item_form_cubit.dart';

import '../../repositories/item_photo_store.dart';
import '../../ui/item_photo.dart';
import '../../ui/spacing.dart';

/// Shared name / price / cost / qty / photo fields for item add & edit screens.
class ItemFormSheetFields extends StatelessWidget {
  const ItemFormSheetFields({super.key, required this.isEdit});

  final bool isEdit;

  Future<void> _pickPhoto(BuildContext context) async {
    final path = await ItemPhotoStore.pickAndStore(context);
    if (path != null && context.mounted) {
      context.read<ItemFormCubit>().setPhoto(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = context.watch<ItemFormCubit>().state;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ItemPhoto(
              imagePath: form.imagePath,
              width: 64,
              height: 64,
              borderRadius: 0,
              fallback: _PhotoFallback(name: form.name),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _pickPhoto(context),
                    icon: Icon(
                      form.imagePath == null
                          ? Icons.photo_camera_outlined
                          : Icons.photo_camera,
                    ),
                    label: Text(
                      form.imagePath == null ? 'Take photo' : 'Retake',
                    ),
                  ),
                  if (form.imagePath != null)
                    TextButton(
                      onPressed: () =>
                          context.read<ItemFormCubit>().setPhoto(null),
                      child: const Text('Remove'),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          initialValue: form.name,
          onChanged: (value) => context.read<ItemFormCubit>().setName(value),
          decoration: InputDecoration(
            labelText: 'Item name',
            prefixIcon: const Icon(Icons.label_outline),
            errorText: form.nameError,
          ),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofocus: !isEdit,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          initialValue: form.price,
          onChanged: (value) => context.read<ItemFormCubit>().setPrice(value),
          decoration: InputDecoration(
            labelText: 'Sell price',
            helperText: 'What you expect to charge per unit',
            prefixIcon: const Icon(Icons.sell_outlined),
            errorText: form.priceError,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          initialValue: form.costPrice,
          onChanged: (value) =>
              context.read<ItemFormCubit>().setCostPrice(value),
          decoration: InputDecoration(
            labelText: 'Cost per unit',
            helperText: 'What you paid per unit in the bulk',
            prefixIcon: const Icon(Icons.shopping_bag_outlined),
            errorText: form.costPriceError,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          initialValue: form.quantity,
          onChanged: (value) =>
              context.read<ItemFormCubit>().setQuantity(value),
          decoration: InputDecoration(
            labelText: isEdit ? 'Stock on hand' : 'Units received',
            helperText: isEdit
                ? 'Total units currently on hand'
                : 'How many units this type added',
            prefixIcon: const Icon(Icons.inventory_2_outlined),
            errorText: form.quantityError,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.zero,
        color: scheme.primary.withValues(alpha: 0.12),
        border: Border.all(color: scheme.primary, width: 1.5),
      ),
      child: Center(
        child: Text(
          initial,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.primary,
          ),
        ),
      ),
    );
  }
}