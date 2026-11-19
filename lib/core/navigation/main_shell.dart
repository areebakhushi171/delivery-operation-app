import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme.dart';
import '../utils/responsive_utils.dart';
import '../utils/scroll_reset.dart';
import '../widgets/common_bottom_navigation.dart';
import '../widgets/common_offline_banner.dart';

/// Shared shell for Rider and Admin.
/// Resets tab scroll offset to top (0) whenever a tab is selected or re-entered.
///
/// - Phone: bottom navigation (unchanged).
/// - Tablet/Web: left sidebar menu (icon + label list).
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
    final useSidebar = ResponsiveUtils.useNavigationRail(context);

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
        body: useSidebar
            ? Row(
          children: [
            _SideMenu(
              items: items,
              badges: badges,
              currentIndex: shell.currentIndex,
              onSelect: _select,
            ),
            Expanded(child: body),
          ],
        )
            : body,
        bottomNavigationBar: useSidebar
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

// ───────────────────────── Side menu ─────────────────────────

class _SideMenu extends StatelessWidget {
  const _SideMenu({
    required this.items,
    required this.badges,
    required this.currentIndex,
    required this.onSelect,
  });

  final List<AppNavItem> items;
  final Map<int, int> badges;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // Chhoti tablet screen par thoda patla, baqi jagah 280.
    final menuWidth = width < 900 ? 220.0 : 280.0;

    return Container(
      width: menuWidth,
      decoration: BoxDecoration(
        color: context.appColors.card,
        border: Border(right: BorderSide(color: context.appColors.glassBorder)),
      ),
      child: SafeArea(
        right: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          children: [
            for (var i = 0; i < items.length; i++)
              _MenuTile(
                item: items[i],
                selected: currentIndex == i,
                badge: badges[i] ?? 0,
                onTap: () => onSelect(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.item,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final AppNavItem item;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = context.scheme.primary;
    final fg = selected ? primary : context.scheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          hoverColor: primary.withAlpha(15),
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: selected ? primary.withAlpha(24) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                navIcon(selected ? item.selectedIcon : item.icon, badge),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall?.copyWith(
                      color: fg,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
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