import 'package:flutter/material.dart';
import 'package:metro_ui/metro_ui.dart';

/// One entry on the Metro application bar (pivot icon and/or peeled text row).
class MetroBottomItem {
  const MetroBottomItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.semanticLabel,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? semanticLabel;
}

/// Always-visible equal-width destination bar (no peel / overflow).
class MetroStaticBottomBar extends StatelessWidget {
  const MetroStaticBottomBar({
    super.key,
    required this.items,
    this.selectedIndex = 0,
  });

  final List<MetroBottomItem> items;
  final int selectedIndex;

  static const height = 64.0;

  @override
  Widget build(BuildContext context) {
    final metro = MetroTheme.of(context);

    return Material(
      color: metro.colors.surface,
      child: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: metro.colors.border.withValues(alpha: 0.45)),
            ),
          ),
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _StaticBarSlot(
                      item: items[i],
                      selected: i == selectedIndex,
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

class _StaticBarSlot extends StatelessWidget {
  const _StaticBarSlot({
    required this.item,
    required this.selected,
  });

  final MetroBottomItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metro = MetroTheme.of(context);
    final color =
        selected ? metro.colors.accent : metro.colors.mutedForeground;

    return Semantics(
      button: true,
      selected: selected,
      label: item.semanticLabel ?? item.label,
      child: InkWell(
        onTap: item.onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              item.label.toLowerCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                height: 1.0,
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Windows Phone 8–style application bar: first [maxPrimaryItems] as outlined
/// square icons; further [items] peel up as lines with a left icon.
class MetroBottomApplicationBar extends StatefulWidget {
  const MetroBottomApplicationBar({
    super.key,
    required this.items,
    this.selectedIndex = -1,
  });

  final List<MetroBottomItem> items;
  final int selectedIndex;

  static const maxPrimaryItems = 4;

  static const contentVerticalPad = MetroSpacing.xs;

  static const collapsedHeight = 60.0;
  static const extraLineHeight = 44.0;

  static double peelHeightFor(int overflowCount) {
    if (overflowCount <= 0) return collapsedHeight;
    return collapsedHeight +
        contentVerticalPad * 2 +
        overflowCount * extraLineHeight;
  }

  @override
  State<MetroBottomApplicationBar> createState() =>
      _MetroBottomApplicationBarState();
}

class _MetroBottomApplicationBarState extends State<MetroBottomApplicationBar>
    with TickerProviderStateMixin {
  late final AnimationController _expandController;
  late final AnimationController _itemsController;
  double _dragExpansion = 0;
  int _lastItemCount = 0;

  List<MetroBottomItem> get _items => widget.items;

  int get _primaryCount =>
      _items.length.clamp(0, MetroBottomApplicationBar.maxPrimaryItems);

  List<MetroBottomItem> get _overflowItems =>
      _items.length > MetroBottomApplicationBar.maxPrimaryItems
          ? _items.sublist(MetroBottomApplicationBar.maxPrimaryItems)
          : const [];

  @override
  void initState() {
    super.initState();
    _lastItemCount = widget.items.length;
    _expandController = AnimationController(
      vsync: this,
      value: 0,
      duration: const Duration(milliseconds: 250),
    );
    _itemsController = AnimationController(
      vsync: this,
      value: 1,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(covariant MetroBottomApplicationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextCount = widget.items.length;
    if (nextCount != _lastItemCount) {
      _lastItemCount = nextCount;
      _itemsController
        ..value = 0
        ..forward();
      if (_overflowItems.isEmpty && _expandController.value > 0) {
        _expandController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    _itemsController.dispose();
    super.dispose();
  }

  double get _expansion =>
      (_expandController.value + _dragExpansion).clamp(0.0, 1.0);

  double get _peelRange =>
      MetroBottomApplicationBar.peelHeightFor(_overflowItems.length) -
      MetroBottomApplicationBar.collapsedHeight;

  void _applyDragDelta(double deltaDy) {
    if (_peelRange <= 0) return;
    final delta = -deltaDy / _peelRange;
    setState(() {
      _dragExpansion =
          (_expandController.value + _dragExpansion + delta).clamp(0.0, 1.0) -
              _expandController.value;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final merged = (_expandController.value + _dragExpansion).clamp(0.0, 1.0);
    _expandController.value = merged;
    setState(() => _dragExpansion = 0);
    final vy = details.velocity.pixelsPerSecond.dy;
    final snapOpen = merged > 0.35 || vy < -120;
    final snapClose = merged < 0.65 && vy > 120;
    if (snapOpen && !snapClose) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  void _togglePeel() {
    if (_expandController.value > 0.6) {
      _expandController.reverse();
    } else {
      _expandController.forward();
    }
  }

  void _onOverflowTap(MetroBottomItem item) {
    item.onTap();
    _expandController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final metro = MetroTheme.of(context);
    final chrome = metro.colors.surface;
    final border = metro.colors.border;
    final hasOverflow = _overflowItems.isNotEmpty;
    final motion = metro.motion;

    return Material(
      color: chrome,
      child: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: Listenable.merge([_expandController, _itemsController]),
          builder: (context, child) {
            final t = _expansion;
            final height =
                MetroBottomApplicationBar.collapsedHeight + _peelRange * t;
            final showOverflow = hasOverflow && t > 0.12;
            final overflowOpacity =
                showOverflow ? ((t - 0.12) / 0.88).clamp(0.0, 1.0) : 0.0;
            final itemsT =
                Curves.easeOutCubic.transform(_itemsController.value);

            return AnimatedSize(
              duration: motion.normal,
              curve: motion.standardCurve,
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: height,
                child: Column(
                  children: [
                    SizedBox(
                      height: MetroBottomApplicationBar.collapsedHeight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical:
                              MetroBottomApplicationBar.contentVerticalPad,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  for (var i = 0; i < _primaryCount; i++)
                                    Expanded(
                                      child: _SlideInBarSlot(
                                        index: i,
                                        progress: itemsT,
                                        child: _MetroBarIcon(
                                          item: _items[i],
                                          selected: widget.selectedIndex == i,
                                          labelOpacity: t,
                                          onTap: _items[i].onTap,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            AnimatedSize(
                              duration: motion.normal,
                              curve: motion.standardCurve,
                              child: hasOverflow
                                  ? FadeTransition(
                                      opacity: _itemsController,
                                      child: _PeelDotsButton(
                                        active: t > 0.6,
                                        onTap: _togglePeel,
                                        onVerticalDragUpdate: (d) =>
                                            _applyDragDelta(d.delta.dy),
                                        onVerticalDragEnd: _onVerticalDragEnd,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (hasOverflow)
                      ClipRect(
                        child: Align(
                          alignment: Alignment.topCenter,
                          heightFactor: t.clamp(0.0, 1.0),
                          child: Opacity(
                            opacity: overflowOpacity,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: MetroBottomApplicationBar
                                    .contentVerticalPad,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (var i = 0;
                                      i < _overflowItems.length;
                                      i++)
                                    _MetroOverflowRow(
                                      item: _overflowItems[i],
                                      borderColor: border,
                                      isFirst: i == 0,
                                      isLast: i == _overflowItems.length - 1,
                                      onTap: () =>
                                          _onOverflowTap(_overflowItems[i]),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SlideInBarSlot extends StatelessWidget {
  const _SlideInBarSlot({
    required this.index,
    required this.progress,
    required this.child,
  });

  final int index;
  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final delayed = ((progress - index * 0.08) / 0.7).clamp(0.0, 1.0);
    return Opacity(
      opacity: delayed,
      child: Transform.translate(
        offset: Offset(0, (1 - delayed) * 10),
        child: child,
      ),
    );
  }
}

class _MetroBarIcon extends StatelessWidget {
  const _MetroBarIcon({
    required this.item,
    required this.selected,
    required this.labelOpacity,
    required this.onTap,
  });

  final MetroBottomItem item;
  final bool selected;
  final double labelOpacity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metro = MetroTheme.of(context);
    final color =
        selected ? metro.colors.accent : metro.colors.mutedForeground;
    final showCaption = labelOpacity > 0.35;
    final iconSize = showCaption ? 18.0 : 20.0;

    return Semantics(
      label: item.semanticLabel ?? item.label,
      button: true,
      selected: selected,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          MetroIconButton(
            icon: Icon(item.icon, size: iconSize),
            onPressed: onTap,
            semanticLabel: item.semanticLabel ?? item.label,
            variant: selected
                ? MetroButtonVariant.accent
                : MetroButtonVariant.standard,
            style: MetroButtonStyle(
              minimumSize: Size.square(showCaption ? 28 : 32),
              padding: EdgeInsets.zero,
            ),
          ),
          if (showCaption) ...[
            const SizedBox(height: 2),
            Opacity(
              opacity: labelOpacity.clamp(0.0, 1.0),
              child: Text(
                item.label.toLowerCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  height: 1.0,
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetroOverflowRow extends StatefulWidget {
  const _MetroOverflowRow({
    required this.item,
    required this.borderColor,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final MetroBottomItem item;
  final Color borderColor;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  State<_MetroOverflowRow> createState() => _MetroOverflowRowState();
}

class _MetroOverflowRowState extends State<_MetroOverflowRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metro = MetroTheme.of(context);
    final color =
        _pressed ? metro.colors.accent : metro.colors.foreground;
    final iconColor =
        _pressed ? metro.colors.accent : metro.colors.mutedForeground;

    return Semantics(
      button: true,
      label: widget.item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: metro.motion.fast,
          curve: metro.motion.standardCurve,
          height: MetroBottomApplicationBar.extraLineHeight,
          decoration: BoxDecoration(
            border: Border(
              top: widget.isFirst
                  ? BorderSide(color: widget.borderColor)
                  : BorderSide.none,
              bottom: widget.isLast
                  ? BorderSide.none
                  : BorderSide(color: widget.borderColor),
            ),
            color: _pressed
                ? metro.colors.accent.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
          padding: const EdgeInsets.symmetric(horizontal: MetroSpacing.lg),
          child: Row(
            children: [
              Icon(widget.item.icon, size: 22, color: iconColor),
              const SizedBox(width: MetroSpacing.sm),
              Expanded(
                child: Text(
                  widget.item.label.toLowerCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeelDotsButton extends StatefulWidget {
  const _PeelDotsButton({
    required this.active,
    this.onTap,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
  });

  final bool active;
  final VoidCallback? onTap;
  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;

  @override
  State<_PeelDotsButton> createState() => _PeelDotsButtonState();
}

class _PeelDotsButtonState extends State<_PeelDotsButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final metro = MetroTheme.of(context);
    final subtle = metro.colors.mutedForeground;
    final gripColor =
        widget.active || _pressed ? metro.colors.accent : subtle;

    return ExcludeFocus(
      child: Semantics(
        button: false,
        focusable: false,
        container: true,
        label: 'more actions',
        hint: 'drag up to show',
        child: SizedBox(
          width: 56,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: widget.onTap,
            onVerticalDragUpdate: widget.onVerticalDragUpdate,
            onVerticalDragEnd: widget.onVerticalDragEnd,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: MetroSpacing.sm),
                child: _SquareGrip(color: gripColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SquareGrip extends StatelessWidget {
  const _SquareGrip({required this.color});

  final Color color;

  static const _dot = 4.0;
  static const _gap = 3.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: _gap),
          Container(
            width: _dot,
            height: _dot,
            color: color,
          ),
        ],
      ],
    );
  }
}

/// Standard outline icon set for main pivots (always outlined — WP app bar).
abstract final class MetroIcons {
  static const stock = Icons.inventory_2_outlined;
  static const sell = Icons.point_of_sale_outlined;
  static const sales = Icons.receipt_long_outlined;
  static const settings = Icons.settings_outlined;
  static const addBulk = Icons.add_shopping_cart_outlined;
  static const customers = Icons.people_outline;
  static const addCustomer = Icons.person_add_alt_1_outlined;
}
