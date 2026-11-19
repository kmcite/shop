import 'package:flutter/material.dart';
import 'package:metro_ui/metro_ui.dart';

/// Metro pull-to-refresh — sharp accent strip that fills as you drag, then
/// runs an indeterminate bar while [onRefresh] completes.
class MetroRefresh extends StatefulWidget {
  const MetroRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.displacement = 56,
    this.triggerPull = 64,
    this.edgeOffset = 0,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final double displacement;
  final double triggerPull;
  final double edgeOffset;

  @override
  State<MetroRefresh> createState() => _MetroRefreshState();
}

class _MetroRefreshState extends State<MetroRefresh> {
  double _pull = 0;
  bool _refreshing = false;
  bool _armed = false;

  double get _progress => (_pull / widget.triggerPull).clamp(0.0, 1.0);

  Future<void> _runRefresh() async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      _armed = false;
      _pull = widget.triggerPull;
    });
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
          _pull = 0;
        });
      }
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (_refreshing) return false;

    if (notification is OverscrollNotification) {
      if (notification.metrics.pixels <= 0 && notification.overscroll < 0) {
        setState(() {
          _pull = (_pull - notification.overscroll).clamp(
            0.0,
            widget.triggerPull * 1.35,
          );
          _armed = _pull >= widget.triggerPull;
        });
      }
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      final pixels = notification.metrics.pixels;
      if (pixels < 0) {
        setState(() {
          _pull = (-pixels).clamp(0.0, widget.triggerPull * 1.35);
          _armed = _pull >= widget.triggerPull;
        });
      } else if (_pull > 0 && pixels >= 0 && notification.dragDetails == null) {
        if (!_armed) {
          setState(() {
            _pull = 0;
            _armed = false;
          });
        }
      }
      return false;
    }

    if (notification is ScrollEndNotification) {
      if (_armed) {
        _runRefresh();
      } else if (_pull > 0) {
        setState(() {
          _pull = 0;
          _armed = false;
        });
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final metro = MetroTheme.of(context);
    final show = _refreshing || _pull > 0;
    final height = _refreshing ? 3.0 : (3.0 + _progress * 3.0);

    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Stack(
        children: [
          widget.child,
          if (show)
            Positioned(
              top: widget.edgeOffset +
                  (_refreshing ? widget.displacement * 0.15 : 0),
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: _MetroRefreshStrip(
                  refreshing: _refreshing,
                  progress: _refreshing ? null : _progress,
                  armed: _armed,
                  height: height,
                  accent: metro.colors.accent,
                  track: metro.colors.surfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetroRefreshStrip extends StatelessWidget {
  const _MetroRefreshStrip({
    required this.refreshing,
    required this.progress,
    required this.armed,
    required this.height,
    required this.accent,
    required this.track,
  });

  final bool refreshing;
  final double? progress;
  final bool armed;
  final double height;
  final Color accent;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MetroSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: MetroSpacing.xs),
          if (refreshing)
            MetroProgressBar(height: height)
          else
            ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: (progress ?? 0).clamp(0.0, 1.0),
                  child: Container(
                    height: height,
                    color: armed ? accent : accent.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
          if (!refreshing && (progress ?? 0) > 0.05) ...[
            const SizedBox(height: MetroSpacing.xxs),
            Text(
              armed ? 'release to refresh' : 'pull to refresh',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: armed ? accent : track,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
