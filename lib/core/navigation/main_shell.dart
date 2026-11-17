import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme.dart';
import '../utils/responsive_utils.dart';
import '../utils/scroll_reset.dart';
import '../widgets/common_bottom_navigation.dart';
import '../widgets/common_offline_banner.dart';

/// Shared shell for Rider and Admin.
/// Resets tab scroll offset to top (0) whenever a tab is selected or re-entered.
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

  void _select(int i) {
    shell.goBranch(i, initialLocation: i == shell.currentIndex);
    ScrollResetRegistry.resetTab(i);
  }

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
        if (!didPop) {
          shell.goBranch(0);
          ScrollResetRegistry.resetTab(0);
        }
      },
      child: Scaffold(
        body: useRail
            ? Row(
                children: [
                  NavigationRail(
                    backgroundColor: context.appColors.card,
                    indicatorColor: context.scheme.primary.withAlpha(32),
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
