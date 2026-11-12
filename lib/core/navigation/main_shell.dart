import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/responsive_utils.dart';
import '../widgets/common_bottom_navigation.dart';
import '../widgets/common_offline_banner.dart';

/// Shared shell for Rider and Admin. Branch navigators are kept alive
/// (IndexedStack) so each tab keeps its scroll position.
///
/// Back button: Home -> exits app, any other tab -> Home, nested -> previous screen.
class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required this.shell,
    required this.items,
    this.badges = const {},
  });

  final StatefulNavigationShell shell;
  final List<AppNavItem> items;
  final Map<int, int> badges;

  void _select(int i) => shell.goBranch(i, initialLocation: i == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final useRail = ResponsiveUtils.useNavigationRail(context);
    final body = Column(
      children: [
        const CommonOfflineBanner(),
        Expanded(child: shell),
      ],
    );
    return PopScope(
      canPop: shell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) shell.goBranch(0);
      },
      child: Scaffold(
        body: useRail
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: shell.currentIndex,
                    onDestinationSelected: _select,
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (var i = 0; i < items.length; i++)
                        NavigationRailDestination(
                          icon: navIcon(items[i].icon, badges[i] ?? 0),
                          selectedIcon: navIcon(items[i].selectedIcon, badges[i] ?? 0),
                          label: Text(items[i].label),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: body),
                ],
              )
            : body,
        bottomNavigationBar: useRail
            ? null
            : CommonBottomNavigation(
                items: items,
                currentIndex: shell.currentIndex,
                onSelected: _select,
                badges: badges,
              ),
      ),
    );
  }
}
