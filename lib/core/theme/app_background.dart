import 'package:flutter/material.dart';

import 'app_theme_extensions.dart';

/// Full-screen sky-blue gradient. Used by the app root and by every page
/// transition, so all screens (Admin + Rider) share the same background.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>();
    return DecoratedBox(
      decoration: BoxDecoration(gradient: colors?.backgroundGradient),
      child: child,
    );
  }
}

/// Fade + slight slide-up page transition on an opaque gradient, so the
/// previous page never shows through the (transparent) scaffolds.
class GlassPageTransitionsBuilder extends PageTransitionsBuilder {
  const GlassPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(curved),
        child: AppBackground(child: child),
      ),
    );
  }
}
