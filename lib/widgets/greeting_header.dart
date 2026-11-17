import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../core/core.dart';

/// Reusable GreetingHeader widget placed at the top row of Rider and Admin home screens.
class GreetingHeader extends StatelessWidget {
  const GreetingHeader({
    super.key,
    required this.userName,
    this.unread = 0,
    this.onNotifications,
    this.onProfile,
    this.profileLabel = 'Profile',
  });

  final String userName;
  final int unread;
  final VoidCallback? onNotifications;
  final VoidCallback? onProfile;
  final String profileLabel;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = DateTimeUtils.greeting();
    final formattedDate = DateFormat('EEE, MMM d, yyyy').format(now);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        MediaQuery.paddingOf(context).top + 12.h,
        AppSpacing.screen,
        12.h,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hello, $userName! 👋',
                    style: context.text.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 22.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '$greeting - $formattedDate',
                    style: context.text.bodySmall?.copyWith(
                      color: context.appColors.mutedText,
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8.w),
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
    );
  }
}
