import 'package:flutter/material.dart';

import '../../../models/bulk_shipment_model.dart';
import '../../../ui/spacing.dart';
import '../../bulk/bulk_step_access.dart';
import '../../design/metro.dart';

/// Shared page chrome for bulk flow screens.
class BulkFlowScaffold extends StatelessWidget {
  const BulkFlowScaffold({
    super.key,
    required this.title,
    required this.children,
    this.bottom,
    this.embedded = false,
  });

  final String title;
  final List<Widget> children;
  final Widget? bottom;

  /// When true, only the scrollable body is built (for panorama / hub steps).
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final body = ListView(
      padding: EdgeInsets.fromLTRB(
        embedded ? MetroSpacing.lg : AppSpacing.lg,
        embedded ? MetroSpacing.xs : AppSpacing.lg,
        embedded ? MetroSpacing.sm : AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: children,
    );

    if (embedded) return body;

    return Scaffold(
      appBar: AppBar(title: Text(title.toLowerCase())),
      body: body,
      bottomNavigationBar: bottom == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: bottom,
              ),
            ),
    );
  }
}

class BulkIntroText extends StatelessWidget {
  const BulkIntroText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final metro = MetroTheme.of(context);
    return Text(
      text,
      textAlign: TextAlign.left,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: metro.colors.mutedForeground,
            height: 1.25,
            fontWeight: FontWeight.w300,
          ),
    );
  }
}

class BulkSection extends StatelessWidget {
  const BulkSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metro = MetroTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toLowerCase(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w300,
                      color: metro.colors.mutedForeground,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle!.toLowerCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: metro.colors.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

/// Flat Metro panel — solid chrome fill, zero radius, no decorative chrome.
class BulkOutlineGroup extends StatelessWidget {
  const BulkOutlineGroup({
    super.key,
    required this.child,
    this.padding,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final metro = MetroTheme.of(context);

    return ColoredBox(
      color: color ?? metro.colors.surface,
      child: Padding(
        padding: padding ?? AppSpacing.card,
        child: child,
      ),
    );
  }
}

class BulkListTileRow extends StatelessWidget {
  const BulkListTileRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final metro = MetroTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: metro.colors.mutedForeground,
                        ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Sharp index badge (replaces circular avatars in Metro lists).
class BulkIndexBadge extends StatelessWidget {
  const BulkIndexBadge(this.index, {super.key});

  final int index;

  @override
  Widget build(BuildContext context) => MetroBadge.index(index);
}

class BulkErrorText extends StatelessWidget {
  const BulkErrorText(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Text(
        message!,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
      ),
    );
  }
}

/// Banner and/or intro for a bulk timeline step from [BulkStepAccess].
class BulkStepContextHeader extends StatelessWidget {
  const BulkStepContextHeader({
    super.key,
    required this.status,
    required this.stepIndex,
  });

  final BulkShipmentStatus status;
  final int stepIndex;

  @override
  Widget build(BuildContext context) {
    final banner = BulkStepAccess.stepBannerMessage(status, stepIndex);
    if (banner != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: BulkReadOnlyBanner(message: banner),
      );
    }

    final intro = BulkStepAccess.stepIntroMessage(status, stepIndex);
    if (intro != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: BulkIntroText(intro),
      );
    }

    return const SizedBox.shrink();
  }
}

class BulkReadOnlyBanner extends StatelessWidget {
  const BulkReadOnlyBanner({
    super.key,
    this.message = 'This step is complete — view only.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final metro = MetroTheme.of(context);
    return BulkOutlineGroup(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      color: metro.colors.accent.withValues(alpha: 0.12),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 20, color: metro.colors.accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message.toLowerCase(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class BulkStickyPrimaryButton extends StatelessWidget {
  const BulkStickyPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: MetroButton.accent(
        onPressed: onPressed,
        style: const MetroButtonStyle(minimumSize: Size(0, 44)),
        child: Text(label.toLowerCase()),
      ),
    );
  }
}
