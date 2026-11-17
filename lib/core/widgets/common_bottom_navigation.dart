import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme_extensions.dart';

class AppNavItem {
  const AppNavItem({required this.label, required this.icon, required this.selectedIcon});
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

Widget navIcon(IconData icon, int badge) => badge > 0
    ? Badge(label: Text('$badge'), child: Icon(icon))
    : Icon(icon);

/// Floating glass bottom bar. Active tab = blue icon + label on a soft pill.
class CommonBottomNavigation extends StatelessWidget {
  const CommonBottomNavigation({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
    this.badges = const {},
  });

  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;
  final Map<int, int> badges;

  @override
  Widget build(BuildContext context) {
    final primary = context.scheme.primary;
    final c = context.appColors;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 10.h),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32.r),
            boxShadow: [BoxShadow(color: c.shadow, blurRadius: 24.r, offset: Offset(0, 10.h))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                height: 68.h,
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(32.r),
                  border: Border.all(color: c.glassBorder),
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _NavButton(
                          item: items[i],
                          selected: i == currentIndex,
                          badge: badges[i] ?? 0,
                          primary: primary,
                          muted: c.mutedText,
                          onTap: () => onSelected(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.badge,
    required this.primary,
    required this.muted,
    required this.onTap,
  });

  final AppNavItem item;
  final bool selected;
  final int badge;
  final Color primary;
  final Color muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? primary : muted;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: selected ? primary.withAlpha(30) : Colors.transparent,
              borderRadius: BorderRadius.circular(22.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconTheme(
                  data: IconThemeData(color: color, size: selected ? 24.w : 22.w),
                  child: navIcon(selected ? item.selectedIcon : item.icon, badge),
                ),
                SizedBox(height: 2.h),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 10.sp,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
