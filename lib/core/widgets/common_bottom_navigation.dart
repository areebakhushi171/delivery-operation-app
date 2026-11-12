import 'package:flutter/material.dart';

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
    final primaryColor = context.scheme.primary;
    final colors = context.appColors;
    // Light mode mein safed card, dark mode mein dark card (theme se aata hai)
    final unselected = colors.mutedText;

    return NavigationBarTheme(
      data: NavigationBarThemeData(
        indicatorColor: primaryColor.withAlpha(35),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primaryColor, size: 24);
          }
          return IconThemeData(color: unselected, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12);
          }
          return TextStyle(color: unselected, fontWeight: FontWeight.normal, fontSize: 11);
        }),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onSelected,
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        shadowColor: colors.shadow,
        elevation: 8,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          for (var i = 0; i < items.length; i++)
            NavigationDestination(
              icon: navIcon(items[i].icon, badges[i] ?? 0),
              selectedIcon: navIcon(items[i].selectedIcon, badges[i] ?? 0),
              label: items[i].label,
            ),
        ],
      ),
    );
  }
}