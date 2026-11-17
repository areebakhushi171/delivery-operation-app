import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/theme.dart';

/// Reusable frosted-glass card with clean glass fill and 0.97 scale press animation.
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.color,
    this.gradient,
    this.radius,
    this.blur = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Gradient? gradient;
  final double? radius;
  final bool blur;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _pressed = false;

  void _set(bool v) {
    if (widget.onTap == null || _pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final r = BorderRadius.circular(widget.radius ?? AppRadius.card);

    Widget body = Container(
      padding: widget.padding ?? EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: widget.gradient == null ? (widget.color ?? c.card) : null,
        gradient: widget.gradient,
        borderRadius: r,
        border: Border.all(color: c.glassBorder),
      ),
      child: widget.child,
    );

    body = ClipRRect(
      borderRadius: r,
      child: widget.blur
          ? BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: body)
          : body,
    );

    body = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: body,
    );

    if (widget.onTap == null) return body;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: body,
      ),
    );
  }
}
