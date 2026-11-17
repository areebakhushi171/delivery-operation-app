import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/theme.dart';
import 'common_button.dart';

class CommonEmptyState extends StatelessWidget {
  const CommonEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84.w,
              height: 84.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.scheme.primary.withAlpha(24),
                border: Border.all(color: context.appColors.glassBorder),
              ),
              child: Icon(icon, size: 38.w, color: context.scheme.primary),
            ),
            SizedBox(height: AppSpacing.md),
            Text(title, style: context.text.titleMedium, textAlign: TextAlign.center),
            if (message != null) ...[
              SizedBox(height: AppSpacing.xs),
              Text(message!, style: context.text.bodySmall, textAlign: TextAlign.center),
            ],
            if (actionLabel != null) ...[
              SizedBox(height: AppSpacing.md),
              CommonButton(label: actionLabel!, onPressed: onAction, expanded: false),
            ],
          ],
        ),
      ),
    );
  }
}
