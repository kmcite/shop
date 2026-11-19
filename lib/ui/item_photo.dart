import 'dart:io';

import 'package:flutter/material.dart';

import '../features/design/metro.dart';
import '../models/shop_item_model.dart';

/// Shows an item's photo when [imagePath] points to a readable file,
/// otherwise renders [fallback] (or a plain surface when none is given).
class ItemPhoto extends StatelessWidget {
  const ItemPhoto({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.borderRadius = 0,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  final String? imagePath;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    final fallback = this.fallback;

    Widget placeholder() =>
        fallback ??
        Container(
          width: width,
          height: height,
          color: MetroTheme.of(context).surfaceColor,
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

/// Sharp Metro photo tile with letter badge fallback — used on list rows.
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
    final metro = MetroTheme.of(context);
    final name = item.name;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return ItemPhoto(
      imagePath: item.imagePath,
      width: size,
      height: size,
      borderRadius: 0,
      fallback: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.zero,
          color: metro.colors.accent.withValues(alpha: 0.12),
          border: Border.all(color: metro.colors.accent, width: 1.5),
        ),
        child: Center(
          child: Text(
            initial,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: metro.colors.accent,
                ),
          ),
        ),
      ),
    );
  }
}
