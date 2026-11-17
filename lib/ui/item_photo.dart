import 'dart:io';

import 'package:flutter/material.dart';

import '../models/shop_item_model.dart';

/// Shows an item's photo when [imagePath] points to a readable file,
/// otherwise renders [fallback] (or a plain surface when none is given).
class const ItemPhoto({
  super.key,
  required final String? imagePath,
  final double? width,
  final double? height,
  final double borderRadius = 16,
  final BoxFit fit = BoxFit.cover,
  final Widget? fallback,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    final fallback = this.fallback;

    Widget placeholder() =>
        fallback ??
        Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        );

    if (path == null) return placeholder();

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.file(
        File(path),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => placeholder(),
      ),
    );
  }
}

/// Small rounded photo preview with the item's initial letter as fallback —
/// used on grid tiles and sheet headers.
class ItemPhotoBadge extends StatelessWidget {
  const ItemPhotoBadge({
    super.key,
    required this.item,
    this.size = 44,
  });

  final ShopItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = item.name;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return ItemPhoto(
      imagePath: item.imagePath,
      width: size,
      height: size,
      borderRadius: size * 0.28,
      fallback: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.28),
          color: scheme.primary.withValues(alpha: 0.12),
        ),
        child: Center(
          child: Text(
            initial,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
