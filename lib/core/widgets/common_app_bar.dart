import 'package:flutter/material.dart';

import '../theme/theme.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBack = true,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: showBack,
      foregroundColor: Colors.white,
      toolbarHeight: kToolbarHeight + 8,
      flexibleSpace: DecoratedBox(decoration: BoxDecoration(gradient: context.appColors.heroGradient)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.titleLarge?.copyWith(color: Colors.white)),
          if (subtitle != null)
            Text(subtitle!, style: context.text.bodySmall?.copyWith(color: Colors.white70)),
        ],
      ),
      actions: actions,
    );
  }
}
