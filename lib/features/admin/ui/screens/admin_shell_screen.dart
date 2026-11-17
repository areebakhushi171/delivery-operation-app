import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../../core/navigation/main_shell.dart';
import '../../../../core/widgets/common_bottom_navigation.dart';

class AdminShellScreen extends StatelessWidget {
  const AdminShellScreen({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return MainShell(
      shell: shell,
      items: const [
        AppNavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard_rounded),
        AppNavItem(label: 'Orders', icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long_rounded),
        AppNavItem(label: 'Fleet', icon: Icons.radar_outlined, selectedIcon: Icons.radar_rounded),
        AppNavItem(label: 'Exceptions', icon: Icons.warning_amber_rounded, selectedIcon: Icons.warning_rounded),
        AppNavItem(label: 'Analytics', icon: Icons.analytics_outlined, selectedIcon: Icons.analytics_rounded),
      ],
    );
  }
}
