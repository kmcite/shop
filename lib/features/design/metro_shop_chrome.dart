import 'package:flutter/material.dart';
import 'package:metro_ui/metro_ui.dart' as metro;

/// Dialog action for [showMetroDialog] shop convenience wrapper.
class MetroDialogAction {
  const MetroDialogAction({
    required this.label,
    required this.onPressed,
    this.accent = false,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool accent;
  final bool destructive;
}

/// Shop convenience over package [metro.showMetroDialog] + [metro.MetroDialog].
Future<T?> showMetroDialog<T>({
  required BuildContext context,
  required String title,
  String? message,
  required List<MetroDialogAction> actions,
  bool barrierDismissible = true,
}) {
  return metro.showMetroDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierDismissible ? 'Dismiss' : null,
    builder: (ctx) {
      return metro.MetroDialog(
        title: Text(title),
        content: message == null ? null : Text(message),
        actions: [
          for (final action in actions)
            action.accent || action.destructive
                ? metro.MetroButton.accent(
                    onPressed: action.onPressed,
                    child: Text(action.label),
                  )
                : metro.MetroButton(
                    onPressed: action.onPressed,
                    child: Text(action.label),
                  ),
        ],
      );
    },
  );
}

/// Page title or section group header.
class MetroHeader extends StatelessWidget {
  const MetroHeader.page(
    this.text, {
    super.key,
    this.padding = const EdgeInsets.fromLTRB(
      metro.MetroSpacing.lg,
      metro.MetroSpacing.sm,
      metro.MetroSpacing.lg,
      metro.MetroSpacing.xs,
    ),
    this.panorama = false,
  }) : _kind = _MetroHeaderKind.page;

  const MetroHeader.section(
    this.text, {
    super.key,
    this.padding = const EdgeInsets.fromLTRB(
      metro.MetroSpacing.lg,
      metro.MetroSpacing.md,
      metro.MetroSpacing.lg,
      metro.MetroSpacing.xs,
    ),
  })  : panorama = false,
        _kind = _MetroHeaderKind.section;

  final String text;
  final EdgeInsetsGeometry padding;
  final bool panorama;
  final _MetroHeaderKind _kind;

  @override
  Widget build(BuildContext context) {
    final theme = metro.MetroTheme.of(context);
    final material = Theme.of(context);

    switch (_kind) {
      case _MetroHeaderKind.page:
        final style = panorama
            ? theme.typography.hero
            : theme.typography.header.copyWith(fontWeight: FontWeight.w200);
        return Padding(
          padding: padding,
          child: Text(
            text.toLowerCase(),
            maxLines: 1,
            softWrap: false,
            overflow: panorama ? TextOverflow.visible : TextOverflow.ellipsis,
            textAlign: TextAlign.left,
            style: style,
          ),
        );
      case _MetroHeaderKind.section:
        return Padding(
          padding: padding,
          child: Text(
            text.toLowerCase(),
            style: material.textTheme.headlineSmall?.copyWith(
                  color: theme.colors.mutedForeground,
                  fontWeight: FontWeight.w300,
                ) ??
                theme.typography.subheader.copyWith(
                  color: theme.colors.mutedForeground,
                ),
          ),
        );
    }
  }
}

enum _MetroHeaderKind { page, section }

/// Full-width list row — optional accent selection + check.
class MetroListRow extends StatelessWidget {
  const MetroListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.onTap,
    this.showDivider = true,
    this.selected = false,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool showDivider;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = metro.MetroTheme.of(context);
    final material = Theme.of(context);
    final muted = theme.colors.mutedForeground;
    final canTap = enabled && onTap != null;

    final Color bg;
    final Color titleColor;
    final Color subColor;
    if (!enabled) {
      bg = Colors.transparent;
      titleColor = muted.withValues(alpha: 0.45);
      subColor = muted.withValues(alpha: 0.35);
    } else if (selected) {
      bg = theme.colors.accent;
      titleColor = theme.colors.onAccent;
      subColor = theme.colors.onAccent.withValues(alpha: 0.85);
    } else {
      bg = Colors.transparent;
      titleColor = theme.colors.foreground;
      subColor = muted;
    }

    final row = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: canTap ? onTap : null,
      child: AnimatedContainer(
        duration: theme.motion.fast,
        color: bg,
        padding: const EdgeInsets.fromLTRB(
          metro.MetroSpacing.lg,
          metro.MetroSpacing.xs,
          metro.MetroSpacing.lg,
          metro.MetroSpacing.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: metro.MetroSpacing.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: material.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: material.textTheme.bodySmall?.copyWith(
                        color: subColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ?trailing,
            if (selected) ...[
              const SizedBox(width: metro.MetroSpacing.xs),
              Icon(Icons.check, size: 18, color: titleColor),
            ],
          ],
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row,
        if (showDivider && !selected) const Divider(height: 1),
      ],
    );
  }
}

/// Flat Metro panel — solid fill only (no border, shadow, or radius).
class MetroPanel extends StatelessWidget {
  const MetroPanel({
    super.key,
    required this.child,
    this.margin =
        const EdgeInsets.symmetric(horizontal: metro.MetroSpacing.lg),
    this.padding = const EdgeInsets.all(metro.MetroSpacing.sm),
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = metro.MetroTheme.of(context);
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.zero,
        color: color ?? theme.colors.surfaceVariant,
      ),
      child: child,
    );
  }
}

/// Empty list / empty cart placeholder.
class MetroEmptyState extends StatelessWidget {
  const MetroEmptyState({
    super.key,
    required this.message,
    this.padding = const EdgeInsets.symmetric(
      horizontal: metro.MetroSpacing.lg,
      vertical: metro.MetroSpacing.xl,
    ),
  });

  final String message;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = metro.MetroTheme.of(context);
    return Padding(
      padding: padding,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: theme.colors.mutedForeground,
              ),
        ),
      ),
    );
  }
}

/// Square Metro badge / avatar substitute (letter, index, or icon).
class MetroBadge extends StatelessWidget {
  const MetroBadge({
    super.key,
    this.label,
    this.icon,
    this.size = 36,
    this.filled = true,
    this.color,
    this.foregroundColor,
  }) : assert(label != null || icon != null);

  final String? label;
  final IconData? icon;
  final double size;
  final bool filled;
  final Color? color;
  final Color? foregroundColor;

  factory MetroBadge.letter(
    String text, {
    Key? key,
    double size = 36,
    bool filled = true,
  }) {
    final trimmed = text.trim();
    final letter = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
    return MetroBadge(
      key: key,
      label: letter,
      size: size,
      filled: filled,
    );
  }

  factory MetroBadge.index(
    int index, {
    Key? key,
    double size = 28,
  }) {
    return MetroBadge(
      key: key,
      label: '$index',
      size: size,
      filled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = metro.MetroTheme.of(context);
    final accent = color ?? theme.colors.accent;
    final fg = foregroundColor ??
        (filled ? theme.colors.onAccent : accent);

    return AnimatedContainer(
      duration: theme.motion.fast,
      curve: theme.motion.standardCurve,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? accent : Colors.transparent,
        border: filled ? null : Border.all(color: accent, width: 1.5),
        borderRadius: BorderRadius.zero,
      ),
      alignment: Alignment.center,
      child: icon != null
          ? Icon(icon, size: size * 0.5, color: fg)
          : Text(
              label!,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                    fontSize: size * 0.38,
                    height: 1,
                  ),
            ),
    );
  }
}

/// Status label — filled chip or quiet inline text (+ optional icon).
class MetroTag extends StatelessWidget {
  const MetroTag({
    super.key,
    required this.label,
    this.color,
    this.foregroundColor,
    this.icon,
  })  : accent = false,
        danger = false,
        inline = false;

  const MetroTag.inline({
    super.key,
    required this.label,
    this.icon,
    this.accent = false,
    this.danger = false,
  })  : color = null,
        foregroundColor = null,
        inline = true;

  final String label;
  final Color? color;
  final Color? foregroundColor;
  final IconData? icon;
  final bool accent;
  final bool danger;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final theme = metro.MetroTheme.of(context);

    if (inline) {
      final fg = danger
          ? theme.colors.error
          : accent
              ? theme.colors.accent
              : theme.colors.mutedForeground;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: metro.MetroSpacing.xxs),
          ],
          Text(
            label.toLowerCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      );
    }

    final bg = color ?? theme.colors.accent;
    final fg = foregroundColor ?? theme.colors.onAccent;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: metro.MetroSpacing.xs,
        vertical: metro.MetroSpacing.xxs,
      ),
      color: bg,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: metro.MetroSpacing.xxs),
          ],
          Text(
            label.toLowerCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

/// List row with a [metro.MetroToggleSwitch] trailing control.
class MetroToggleTile extends StatelessWidget {
  const MetroToggleTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.leading,
    this.enabled = true,
    this.showDivider = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = metro.MetroTheme.of(context);
    final muted = theme.colors.mutedForeground;
    final canTap = enabled && onChanged != null;

    final row = InkWell(
      onTap: canTap ? () => onChanged!(!value) : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          metro.MetroSpacing.lg,
          metro.MetroSpacing.xs,
          metro.MetroSpacing.lg,
          metro.MetroSpacing.xs,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: metro.MetroSpacing.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toLowerCase(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: enabled ? null : muted,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!.toLowerCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: metro.MetroSpacing.sm),
            metro.MetroToggleSwitch(
              value: value,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row,
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

/// App shell with Metro title + optional accent FAB.
class MetroShell extends StatelessWidget {
  const MetroShell({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title.toLowerCase()),
        actions: actions,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// Pivot header style for [MetroPivotBar].
enum MetroPivotStyle { headers, strip }

/// One option in a [MetroPivotBar].
class MetroPivotOption<T> {
  const MetroPivotOption({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

/// Flat pivot strip — filter headers or compact underline strip.
class MetroPivotBar<T> extends StatelessWidget {
  const MetroPivotBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.style = MetroPivotStyle.strip,
    this.subtitle,
  });

  final List<MetroPivotOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final MetroPivotStyle style;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    if (style == MetroPivotStyle.headers) {
      return _MetroPivotHeaders(
        options: options,
        selected: selected,
        onSelected: onSelected,
        subtitle: subtitle,
      );
    }

    final theme = metro.MetroTheme.of(context);
    final material = Theme.of(context);

    return SizedBox(
      height: 40,
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: _MetroPivotCell(
                label: option.label,
                icon: option.icon,
                selected: option.value == selected,
                accent: theme.colors.accent,
                subtle: theme.colors.mutedForeground,
                textStyle: material.textTheme.labelLarge,
                onTap: () => onSelected(option.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetroPivotHeaders<T> extends StatelessWidget {
  const _MetroPivotHeaders({
    required this.options,
    required this.selected,
    required this.onSelected,
    this.subtitle,
  });

  final List<MetroPivotOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = metro.MetroTheme.of(context);
    final material = Theme.of(context);
    final muted = theme.colors.mutedForeground;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: metro.MetroSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                for (var i = 0; i < options.length; i++) ...[
                  if (i > 0) const SizedBox(width: metro.MetroSpacing.md),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelected(options[i].value),
                    child: Text(
                      options[i].label.toUpperCase(),
                      style: options[i].value == selected
                          ? material.textTheme.headlineMedium?.copyWith(
                              color: theme.colors.foreground,
                              fontWeight: FontWeight.w300,
                            )
                          : material.textTheme.titleMedium?.copyWith(
                              color: muted,
                              fontWeight: FontWeight.w300,
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: metro.MetroSpacing.xs),
            Text(
              subtitle!,
              style: material.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetroPivotCell extends StatelessWidget {
  const _MetroPivotCell({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.subtle,
    required this.textStyle,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final Color accent;
  final Color subtle;
  final TextStyle? textStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = metro.MetroTheme.of(context);
    final color = selected ? accent : subtle;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? accent : theme.colors.border,
              width: selected ? 3 : 1,
            ),
          ),
        ),
        child: Center(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: metro.MetroSpacing.xxs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label.toLowerCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle?.copyWith(
                      color: color,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w300,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
