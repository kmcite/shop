import 'package:flutter/material.dart';
import 'package:metro_ui/metro_ui.dart';

/// Springs the panorama to the nearest (or flung) section stop.
class MetroPanoramaScrollPhysics extends ScrollPhysics {
  const MetroPanoramaScrollPhysics({
    required this.stops,
    super.parent,
  });

  /// Absolute scroll offsets for each section's leading edge.
  final List<double> stops;

  /// Fling past this speed advances to the next/previous section.
  static const double flingVelocity = 600;

  @override
  MetroPanoramaScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return MetroPanoramaScrollPhysics(
      stops: stops,
      parent: buildParent(ancestor),
    );
  }

  double _targetFor(ScrollMetrics position, double velocity) {
    if (stops.isEmpty) {
      return position.pixels.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
    }

    var nearest = 0;
    var best = double.infinity;
    for (var i = 0; i < stops.length; i++) {
      final d = (stops[i] - position.pixels).abs();
      if (d < best) {
        best = d;
        nearest = i;
      }
    }

    var targetIndex = nearest;
    if (velocity.abs() > flingVelocity) {
      if (velocity > 0 && nearest < stops.length - 1) {
        targetIndex = nearest + 1;
      } else if (velocity < 0 && nearest > 0) {
        targetIndex = nearest - 1;
      }
    }

    return stops[targetIndex].clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final tolerance = toleranceFor(position);
    final target = _targetFor(position, velocity);

    if ((target - position.pixels).abs() > tolerance.distance) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        target,
        velocity,
        tolerance: tolerance,
      );
    }

    return super.createBallisticSimulation(position, velocity);
  }
}

/// Drives a [MetroPanoramaView]: section index, animate/jump, scroll binding.
class MetroPanoramaController extends ChangeNotifier {
  ScrollController? _scroll;
  List<double> _widths = const [];
  double _gap = 0;
  int _index = 0;
  bool _programmatic = false;

  int get index => _index;

  bool get hasClients => _scroll?.hasClients ?? false;

  void _bind({
    required ScrollController scroll,
    required List<double> widths,
    required double gap,
  }) {
    if (!identical(_scroll, scroll)) {
      _scroll?.removeListener(_onScroll);
      _scroll = scroll;
      _scroll!.addListener(_onScroll);
    }
    _widths = widths;
    _gap = gap;
  }

  double offsetForSection(int index) {
    if (_widths.isEmpty) return 0;
    final i = index.clamp(0, _widths.length - 1);
    var x = 0.0;
    for (var n = 0; n < i; n++) {
      x += _widths[n] + _gap;
    }
    return x;
  }

  Future<void> animateToSection(
    int index, {
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.easeOutCubic,
  }) async {
    final scroll = _scroll;
    if (scroll == null || !scroll.hasClients || _widths.isEmpty) return;
    final target = index.clamp(0, _widths.length - 1);
    _programmatic = true;
    _setIndex(target);
    await scroll.animateTo(
      offsetForSection(target),
      duration: duration,
      curve: curve,
    );
    _programmatic = false;
  }

  void jumpToSection(int index) {
    final scroll = _scroll;
    if (scroll == null || !scroll.hasClients || _widths.isEmpty) return;
    final target = index.clamp(0, _widths.length - 1);
    _programmatic = true;
    _setIndex(target);
    scroll.jumpTo(offsetForSection(target));
    _programmatic = false;
  }

  void _onScroll() {
    if (_programmatic || _scroll == null || !_scroll!.hasClients) return;
    if (_widths.isEmpty) return;
    final next = _indexForOffset(_scroll!.offset);
    _setIndex(next);
  }

  int _indexForOffset(double offset) {
    var best = 0;
    var bestDist = double.infinity;
    var x = 0.0;
    for (var i = 0; i < _widths.length; i++) {
      final dist = (offset - x).abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = i;
      }
      x += _widths[i] + _gap;
    }
    return best;
  }

  void _setIndex(int value) {
    if (_index == value) return;
    _index = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _scroll?.removeListener(_onScroll);
    _scroll = null;
    super.dispose();
  }
}

/// One vertical column inside a [MetroPanoramaView].
class MetroPanoramaSection extends StatelessWidget {
  const MetroPanoramaSection({
    super.key,
    required this.title,
    required this.child,
    this.width,
    this.titleStyle,
    this.showTitle = true,
    this.wrapInScroll = true,
  });

  final String title;
  final Widget child;

  /// Column width. When null, [MetroPanoramaView] assigns a viewport-based width.
  final double? width;
  final TextStyle? titleStyle;
  final bool showTitle;

  /// When true, wraps [child] in a vertical [SingleChildScrollView].
  /// Set false when [child] already scrolls (e.g. [CustomScrollView] screens).
  final bool wrapInScroll;

  @override
  Widget build(BuildContext context) {
    final metro = MetroTheme.of(context);
    final style =
        titleStyle ?? metro.typography.header;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle)
          Padding(
            padding: const EdgeInsets.only(
              left: MetroSpacing.lg,
              right: MetroSpacing.sm,
              bottom: MetroSpacing.sm,
            ),
            child: Text(
              title.toLowerCase(),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.left,
              style: style,
            ),
          ),
        Expanded(
          child: wrapInScroll
              ? SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.only(bottom: MetroSpacing.lg),
                  child: child,
                )
              : child,
        ),
      ],
    );
  }
}

/// Horizontal panorama scroller with optional parallax background and
/// bleeding hub title that hints at off-screen content.
class MetroPanoramaView extends StatefulWidget {
  const MetroPanoramaView({
    super.key,
    required this.title,
    required this.sections,
    this.background,
    this.parallaxFactor = 0.4,
    this.controller,
    this.scrollController,
    this.titleStyle,
    this.sectionGap = MetroSpacing.lg,
    this.sectionPeek = MetroSpacing.lg,
    this.showHubTitle = true,
    this.onSectionChanged,
    this.initialSection = 0,
  });

  final String title;
  final List<MetroPanoramaSection> sections;
  final Widget? background;

  /// Background scrolls at this fraction of foreground offset (`0.3`–`0.5`).
  final double parallaxFactor;

  final MetroPanoramaController? controller;
  final ScrollController? scrollController;
  final TextStyle? titleStyle;
  final double sectionGap;

  /// How much of the next column peeks into the viewport (reduces section width).
  final double sectionPeek;

  final bool showHubTitle;
  final ValueChanged<int>? onSectionChanged;
  final int initialSection;

  @override
  State<MetroPanoramaView> createState() => _MetroPanoramaViewState();
}

class _MetroPanoramaViewState extends State<MetroPanoramaView> {
  ScrollController? _ownedScroll;
  MetroPanoramaController? _ownedPanorama;
  late ScrollController _scroll;
  late MetroPanoramaController _panorama;
  int _lastNotified = -1;
  bool _didJumpInitial = false;

  @override
  void initState() {
    super.initState();
    _ownedScroll =
        widget.scrollController == null ? ScrollController() : null;
    _scroll = widget.scrollController ?? _ownedScroll!;
    _ownedPanorama =
        widget.controller == null ? MetroPanoramaController() : null;
    _panorama = widget.controller ?? _ownedPanorama!;
    _panorama.addListener(_onPanoramaIndex);
    _lastNotified = _panorama.index;
  }

  @override
  void didUpdateWidget(covariant MetroPanoramaView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      if (widget.scrollController != null) {
        _scroll = widget.scrollController!;
      } else {
        _ownedScroll ??= ScrollController();
        _scroll = _ownedScroll!;
      }
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onPanoramaIndex);
      _ownedPanorama?.removeListener(_onPanoramaIndex);
      if (widget.controller != null) {
        _panorama = widget.controller!;
      } else {
        _ownedPanorama ??= MetroPanoramaController();
        _panorama = _ownedPanorama!;
      }
      _panorama.addListener(_onPanoramaIndex);
    }
  }

  @override
  void dispose() {
    _panorama.removeListener(_onPanoramaIndex);
    _ownedPanorama?.dispose();
    _ownedScroll?.dispose();
    super.dispose();
  }

  void _onPanoramaIndex() {
    if (widget.background != null) setState(() {});
    final i = _panorama.index;
    if (i != _lastNotified) {
      _lastNotified = i;
      widget.onSectionChanged?.call(i);
    }
  }

  List<double> _resolveWidths(double viewportWidth) {
    final fallback = (viewportWidth - widget.sectionPeek).clamp(240.0, 720.0);
    return [
      for (final s in widget.sections) s.width ?? fallback,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final metro = MetroTheme.of(context);
    final titleStyle = widget.titleStyle ??
        metro.typography.hero;
    final titleHeight =
        (titleStyle.fontSize ?? 72) * (titleStyle.height ?? 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final widths = _resolveWidths(constraints.maxWidth);
        _panorama._bind(
          scroll: _scroll,
          widths: widths,
          gap: widget.sectionGap,
        );

        if (!_didJumpInitial && widget.initialSection > 0) {
          _didJumpInitial = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _panorama.jumpToSection(widget.initialSection);
          });
        }

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            if (widget.background != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: ListenableBuilder(
                    listenable: _scroll,
                    builder: (context, child) {
                      final offset =
                          _scroll.hasClients ? _scroll.offset : 0.0;
                      return Transform.translate(
                        offset: Offset(-offset * widget.parallaxFactor, 0),
                        child: child,
                      );
                    },
                    child: widget.background,
                  ),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showHubTitle)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      MetroSpacing.lg,
                      MetroSpacing.sm,
                      0,
                      MetroSpacing.xs,
                    ),
                    // Fixed height so bleed text can't expand the Column;
                    // TextOverflow.visible paints past the right edge.
                    child: SizedBox(
                      height: titleHeight,
                      width: double.infinity,
                      child: Text(
                        widget.title.toLowerCase(),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                        textAlign: TextAlign.left,
                        style: titleStyle,
                      ),
                    ),
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, bodyConstraints) {
                      final stops = <double>[];
                      var x = 0.0;
                      for (var i = 0; i < widths.length; i++) {
                        stops.add(x);
                        x += widths[i] + widget.sectionGap;
                      }

                      return SingleChildScrollView(
                        controller: _scroll,
                        scrollDirection: Axis.horizontal,
                        physics: MetroPanoramaScrollPhysics(
                          stops: stops,
                          parent: const BouncingScrollPhysics(
                            decelerationRate: ScrollDecelerationRate.fast,
                          ),
                        ),
                        child: SizedBox(
                          height: bodyConstraints.maxHeight,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0;
                                  i < widget.sections.length;
                                  i++) ...[
                                if (i > 0) SizedBox(width: widget.sectionGap),
                                SizedBox(
                                  width: widths[i],
                                  child: widget.sections[i],
                                ),
                              ],
                              const SizedBox(width: MetroSpacing.lg),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
