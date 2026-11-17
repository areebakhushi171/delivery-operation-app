import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/theme.dart';
import 'glass_button.dart';
import 'glass_card.dart';

/// Hero card: small grey label, very large number, optional round arrow button
/// and optional [child] below (chart, breakdown row, etc.).
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    this.badge,
    this.badgeColor,
    this.onArrow,
    this.child,
    this.trailing,
  });

  final String label;
  final String value;

  /// Small pill under the number, e.g. "+12% vs last week".
  final String? badge;
  final Color? badgeColor;
  final VoidCallback? onArrow;
  final Widget? child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final bc = badgeColor ?? context.appColors.success;
    return GlassCard(
      padding: EdgeInsets.all(18.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: context.text.bodySmall),
                    SizedBox(height: 4.h),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(value, style: context.text.displayMedium),
                    ),
                    if (badge != null) ...[
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: bc.withAlpha(34),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(badge!, style: context.text.labelMedium?.copyWith(color: bc)),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (onArrow != null)
                GlassCircleButton(icon: Icons.arrow_forward_rounded, size: 38, onTap: onArrow),
            ],
          ),
          if (child != null) ...[SizedBox(height: 14.h), child!],
        ],
      ),
    );
  }
}
