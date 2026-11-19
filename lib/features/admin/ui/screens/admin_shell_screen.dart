import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../../core/navigation/main_shell.dart';
import '../../../../core/widgets/common_bottom_navigation.dart';

class AdminShellScreen extends StatelessWidget {
  const AdminShellScreen({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _items = [
    AppNavItem(label: 'Home', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard_rounded),
    AppNavItem(label: 'Orders', icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long_rounded),
    AppNavItem(label: 'Riders', icon: Icons.two_wheeler_outlined, selectedIcon: Icons.two_wheeler_rounded),
    AppNavItem(label: 'Exceptions', icon: Icons.warning_amber_rounded, selectedIcon: Icons.warning_rounded),
    AppNavItem(label: 'Analytics', icon: Icons.analytics_outlined, selectedIcon: Icons.analytics_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Sirf phone (narrow screen) par bottom navigation
    if (screenWidth < 700) {
      return MainShell(shell: shell, items: _items);
    }

    // Baqi sab (web/tablet/desktop): hamesha full wide sidebar
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            items: _items,
            currentIndex: shell.currentIndex,
            expanded: true,
            onSelect: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
          ),
          Expanded(child: shell),
        ],
      ),
    );
  }
}

// ───────────────────────── Sidebar ─────────────────────────

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.items,
    required this.currentIndex,
    required this.expanded,
    required this.onSelect,
  });

  final List<AppNavItem> items;
  final int currentIndex;
  final bool expanded;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final width = expanded ? 300.0 : 84.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: BoxDecoration(
        color: context.appColors.card,
        border: Border(right: BorderSide(color: context.appColors.glassBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        right: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(expanded ? 20 : 12, 24, expanded ? 20 : 12, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Brand(expanded: expanded),
              const SizedBox(height: 32),
              if (expanded)
                Padding(
                  padding: const EdgeInsets.only(left: 14, bottom: 12),
                  child: Text(
                    'MENU',
                    style: context.text.labelSmall?.copyWith(
                      color: context.scheme.onSurfaceVariant,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              for (var i = 0; i < items.length; i++)
                _NavTile(
                  item: items[i],
                  selected: i == currentIndex,
                  expanded: expanded,
                  onTap: () => onSelect(i),
                ),
              const Spacer(),
              const Divider(height: 24),
              _ProfileTile(expanded: expanded),
            ],
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.expanded});
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final logo = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: context.appColors.heroGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 24),
    );

    if (!expanded) return Center(child: logo);

    return Row(
      children: [
        logo,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery Ops',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                'Admin Console',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(color: context.scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final AppNavItem item;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = context.scheme.primary;
    final fg = selected ? primary : context.scheme.onSurfaceVariant;

    final tile = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        hoverColor: primary.withAlpha(15),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 52,
          padding: EdgeInsets.symmetric(horizontal: expanded ? 14 : 0),
          decoration: BoxDecoration(
            color: selected ? primary.withAlpha(28) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(selected ? item.selectedIcon : item.icon, color: fg, size: 24),
              if (expanded) ...[
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall?.copyWith(
                      color: fg,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                  ),
              ],
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: expanded ? tile : Tooltip(message: item.label, child: tile),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.expanded});
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final fg = context.scheme.onSurfaceVariant;

    final tile = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(AppRoutes.adminProfile),
        child: Container(
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: expanded ? 14 : 0),
          child: Row(
            mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline_rounded, color: fg, size: 22),
              if (expanded) ...[
                const SizedBox(width: 14),
                Text(
                  'Profile & Settings',
                  style: context.text.titleSmall?.copyWith(color: fg, fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return expanded ? tile : Tooltip(message: 'Profile & Settings', child: tile);
  }
}