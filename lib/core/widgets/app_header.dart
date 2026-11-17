import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/theme.dart';
import 'glass_button.dart';

/// Top header of main (tab) screens for both Rider and Admin:
/// Row 1: Greeting (Good morning 👋) on left, Notifications & Profile on right.
/// Row 2: User Name on its own dedicated bold line.
/// Row 3: Subtitle / Date.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.name = '',
    this.photoUrl,
    this.unread = 0,
    this.onNotifications,
    this.onProfile,
    this.profileLabel = 'Profile',
  });

  final String title;
  final String? subtitle;
  final String name;
  final String? photoUrl;
  final int unread;
  final VoidCallback? onNotifications;
  final VoidCallback? onProfile;
  final String profileLabel;

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        MediaQuery.paddingOf(context).top + 12.h,
        AppSpacing.screen,
        12.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Greeting title on left, Action buttons on right
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleMedium?.copyWith(
                    color: context.appColors.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onNotifications != null) ...[
                GlassCircleButton(
                  icon: Icons.notifications_none_rounded,
                  tooltip: 'Notifications',
                  badge: unread,
                  onTap: onNotifications,
                ),
                SizedBox(width: 8.w),
              ],
              if (onProfile != null)
                GlassPillButton(
                  label: profileLabel,
                  icon: Icons.person_outline_rounded,
                  height: 40,
                  onTap: onProfile,
                ),
            ],
          ),
          SizedBox(height: 4.h),
          // Row 2: Name on its own dedicated line!
          if (displayName.isNotEmpty) ...[
            Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 24.sp,
                height: 1.2,
              ),
            ),
            SizedBox(height: 2.h),
          ],
          // Subtitle / Date
          if (subtitle != null && subtitle!.isNotEmpty)
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(
                color: context.appColors.mutedText,
              ),
            ),
        ],
      ),
    );
  }
}
