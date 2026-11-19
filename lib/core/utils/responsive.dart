// lib/core/utils/responsive.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Breakpoints {
  const Breakpoints._();
  static const double tablet = 600;
  static const double desktop = 1100;
}

enum ScreenType { mobile, tablet, desktop }

class Responsive {
  const Responsive._();

  static ScreenType typeOfWidth(double w) {
    if (w >= Breakpoints.desktop) return ScreenType.desktop;
    if (w >= Breakpoints.tablet) return ScreenType.tablet;
    return ScreenType.mobile;
  }

  static ScreenType type(BuildContext c) => typeOfWidth(MediaQuery.sizeOf(c).width);
  static bool isMobile(BuildContext c) => type(c) == ScreenType.mobile;
  static bool isTablet(BuildContext c) => type(c) == ScreenType.tablet;
  static bool isDesktop(BuildContext c) => type(c) == ScreenType.desktop;

  /// Tablet ya desktop (yani phone nahi)
  static bool isWide(BuildContext c) => !isMobile(c);

  static T value<T>(BuildContext c, {required T mobile, T? tablet, T? desktop}) {
    switch (type(c)) {
      case ScreenType.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenType.tablet:
        return tablet ?? mobile;
      case ScreenType.mobile:
        return mobile;
    }
  }

  /// Bottom sheets / dialogs web par poori width na lein.
  static BoxConstraints sheetConstraints([double maxWidth = 560]) => BoxConstraints(maxWidth: maxWidth);
}

/// Content ko center karta hai aur max width tak limit karta hai.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 1100});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
    );
  }
}

/// Phone par horizontal scroll list, tablet/desktop par barabar width ki row.
class AdaptiveHList extends StatelessWidget {
  const AdaptiveHList({super.key, required this.height, required this.children, this.gap = 12});

  final double height;
  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return SizedBox(
        height: height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: children.length,
          separatorBuilder: (_, __) => SizedBox(width: gap.w),
          itemBuilder: (_, i) => children[i],
        ),
      );
    }
    return SizedBox(
      height: height,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: gap.w),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}

/// ScreenUtilInit ki jagah use karein (main.dart mein).
/// Web/tablet par UI 3-4x bada hone se bachata hai.
class ResponsiveScreenUtilInit extends StatelessWidget {
  const ResponsiveScreenUtilInit({super.key, required this.builder});

  final Widget Function(BuildContext context, Widget? child) builder;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.maybeSizeOf(context)?.width ?? 375;
    final type = Responsive.typeOfWidth(w);
    final Size design;
    switch (type) {
      case ScreenType.desktop:
        design = const Size(1280, 800);
        break;
      case ScreenType.tablet:
        design = const Size(768, 1024);
        break;
      case ScreenType.mobile:
        design = const Size(375, 812);
        break;
    }
    return ScreenUtilInit(
      key: ValueKey(type),
      designSize: design,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: builder,
    );
  }
}

/// Centers content on wide screens WITHOUT constraining the scroll view itself.
/// The scroll view stays full width (so the scrollbar sits at the window's right
/// edge) and the side space is added as horizontal padding instead.
///
/// Usage: builder gives `pad` - add it to your ListView / SingleChildScrollView padding
/// (`pad + EdgeInsets...`) or pass slivers through [padSlivers].
class ResponsivePad extends StatelessWidget {
  const ResponsivePad({super.key, required this.builder, this.maxWidth = 1200});

  final Widget Function(BuildContext context, EdgeInsets pad) builder;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.max(0.0, (constraints.maxWidth - maxWidth) / 2);
        return builder(context, EdgeInsets.symmetric(horizontal: side));
      },
    );
  }
}

/// Wraps every sliver with the same horizontal padding (for CustomScrollView).
List<Widget> padSlivers(EdgeInsets pad, List<Widget> slivers) => [
  for (final s in slivers) SliverPadding(padding: pad, sliver: s),
];