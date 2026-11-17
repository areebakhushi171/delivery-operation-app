import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/theme.dart';
import 'glass_button.dart';

/// Transparent app bar on the sky background, glass back button.
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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 12);

  @override
  Widget build(BuildContext context) {
    final canPop = showBack && (ModalRoute.of(context)?.canPop ?? false);
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      toolbarHeight: kToolbarHeight + 12,
      leadingWidth: canPop ? 64.w : 0,
      leading: canPop
          ? Padding(
              padding: EdgeInsets.only(left: AppSpacing.screen - 4.w),
              child: Center(
                child: GlassCircleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  size: 40,
                  tooltip: 'Back',
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            )
          : null,
      titleSpacing: canPop ? 4.w : AppSpacing.screen,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.titleLarge),
          if (subtitle != null) Text(subtitle!, style: context.text.bodySmall),
        ],
      ),
      actions: [
        ...?actions,
        SizedBox(width: AppSpacing.sm),
      ],
    );
  }
}
