import 'package:flutter/material.dart';

/// One circular action shown behind a swiped card.
class SwipeAction {
  const SwipeAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

/// Reusable swipe card (no extra package needed).
///
/// - Swipe RIGHT  -> reveals [startActions] on the left side (e.g. View)
/// - Swipe LEFT   -> reveals [endActions] on the right side (e.g. Assign, Cancel)
/// Only one card stays open at a time.
class SwipeActionCard extends StatefulWidget {
  const SwipeActionCard({
    super.key,
    required this.child,
    this.startActions = const [],
    this.endActions = const [],
  });

  final Widget child;
  final List<SwipeAction> startActions;
  final List<SwipeAction> endActions;

  @override
  State<SwipeActionCard> createState() => _SwipeActionCardState();
}

class _SwipeActionCardState extends State<SwipeActionCard> with SingleTickerProviderStateMixin {
  static _SwipeActionCardState? _open;
  static const double _slot = 78;

  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 240));
  double _dx = 0;
  double _from = 0;
  double _to = 0;

  double get _maxStart => widget.startActions.length * _slot;
  double get _maxEnd => widget.endActions.length * _slot;

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      setState(() => _dx = _from + (_to - _from) * Curves.easeOutCubic.transform(_c.value));
    });
  }

  @override
  void dispose() {
    if (_open == this) _open = null;
    _c.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _from = _dx;
    _to = target;
    _c.forward(from: 0);
  }

  void close() {
    if (_open == this) _open = null;
    _animateTo(0);
  }

  void _onStart(DragStartDetails d) {
    if (_open != null && _open != this) _open!.close();
    _c.stop();
  }

  void _onUpdate(DragUpdateDetails d) {
    setState(() => _dx = (_dx + d.delta.dx).clamp(-_maxEnd, _maxStart));
  }

  void _onEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    double target = 0;
    if (_dx > 0 && _maxStart > 0) {
      final open = v > 300 || (_dx > _maxStart * 0.4 && v > -300);
      target = open ? _maxStart : 0;
    } else if (_dx < 0 && _maxEnd > 0) {
      final open = v < -300 || (-_dx > _maxEnd * 0.4 && v < 300);
      target = open ? -_maxEnd : 0;
    }
    _open = target == 0 ? (_open == this ? null : _open) : this;
    _animateTo(target);
  }

  Widget _actionButton(SwipeAction a, double progress) {
    return SizedBox(
      width: _slot,
      child: Transform.scale(
        scale: (0.6 + 0.4 * progress).clamp(0.6, 1.0),
        child: Opacity(
          opacity: progress.clamp(0.0, 1.0),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              close();
              a.onTap();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [a.color.withOpacity(0.95), a.color.withOpacity(0.75)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: a.color.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(a.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  a.label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: a.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startProgress = _maxStart == 0 ? 0.0 : (_dx / _maxStart).clamp(0.0, 1.0);
    final endProgress = _maxEnd == 0 ? 0.0 : (-_dx / _maxEnd).clamp(0.0, 1.0);

    return Stack(
      children: [
        // Left side actions (visible on swipe right)
        if (_dx > 0)
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [for (final a in widget.startActions) _actionButton(a, startProgress)],
              ),
            ),
          ),
        // Right side actions (visible on swipe left)
        if (_dx < 0)
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [for (final a in widget.endActions) _actionButton(a, endProgress)],
              ),
            ),
          ),
        // The card itself
        Transform.translate(
          offset: Offset(_dx, 0),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: _onStart,
            onHorizontalDragUpdate: _onUpdate,
            onHorizontalDragEnd: _onEnd,
            onTap: _dx.abs() > 1 ? close : null,
            child: IgnorePointer(
              ignoring: _dx.abs() > 1, // card taps are disabled while open
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}
