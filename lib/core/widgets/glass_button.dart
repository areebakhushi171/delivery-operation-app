import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/theme.dart';

/// Round glass icon button (bell, back, arrow). [filled] = solid primary.
class GlassCircleButton extends StatefulWidget {
  const GlassCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.badge = 0,
    this.filled = false,
    this.tooltip,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final int badge;
  final bool filled;
  final String? tooltip;
  final Color? iconColor;

  @override
  State<GlassCircleButton> createState() => _GlassCircleButtonState();
}

class _GlassCircleButtonState extends State<GlassCircleButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final primary = context.scheme.primary;
    final d = widget.size.w;
    Widget icon = Icon(
      widget.icon,
      size: d * 0.46,
      color: widget.iconColor ?? (widget.filled ? Colors.white : primary),
    );
    if (widget.badge > 0) {
      icon = Badge(label: Text('${widget.badge > 99 ? '99+' : widget.badge}'), child: icon);
    }
    Widget btn = ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: d,
          height: d,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.filled ? primary : c.card,
            border: Border.all(color: c.glassBorder),
          ),
          child: icon,
        ),
      ),
    );
    btn = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: widget.filled ? primary.withAlpha(80) : c.shadow,
            blurRadius: 14.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: btn,
    );
    btn = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.92 : 1,
        duration: const Duration(milliseconds: 110),
        child: btn,
      ),
    );
    return widget.tooltip == null ? btn : Tooltip(message: widget.tooltip!, child: btn);
  }
}

/// Pill shaped glass button (icon + label), e.g. "Profile", quick actions.
class GlassPillButton extends StatefulWidget {
  const GlassPillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.filled = false,
    this.height = 48,
    this.color,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool filled;
  final double height;
  final Color? color;

  @override
  State<GlassPillButton> createState() => _GlassPillButtonState();
}

class _GlassPillButtonState extends State<GlassPillButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final accent = widget.color ?? context.scheme.primary;
    final fg = widget.filled ? Colors.white : accent;
    final h = widget.height.h;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 110),
        child: Container(
          height: h,
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(h),
            color: widget.filled ? accent : c.card,
            border: Border.all(color: c.glassBorder),
            boxShadow: [
              BoxShadow(
                color: widget.filled ? accent.withAlpha(70) : c.shadow,
                blurRadius: 14.r,
                offset: Offset(0, 6.h),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18.w, color: fg),
                SizedBox(width: 8.w),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelLarge?.copyWith(color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
