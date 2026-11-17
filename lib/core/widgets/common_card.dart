import 'package:flutter/material.dart';

import 'glass_card.dart';

/// Existing card API, now rendered as a glass card.
/// (No backdrop blur here: CommonCard is used inside long lists.)
class CommonCard extends StatelessWidget {
  const CommonCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  @override
  Widget build(BuildContext context) => GlassCard(
        blur: false,
        onTap: onTap,
        padding: padding,
        margin: margin,
        color: color,
        child: child,
      );
}
