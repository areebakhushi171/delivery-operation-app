import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/theme.dart';
import 'common_status_chip.dart';

/// Pastel KPI tile (icon + big number + label) as in the reference UI.
class CommonStatTile extends StatelessWidget {
  const CommonStatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.tone = StatusTone.info,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final String? subtitle;
  final StatusTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = tone.of(context);
    final radius = BorderRadius.circular(AppRadius.card);
    return Material(
      color: color.withAlpha(26),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(color: color.withAlpha(40), shape: BoxShape.circle),
                  child: Icon(icon, size: 16.w, color: color),
                ),
                SizedBox(height: 4.h),
                Text(value, style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text(label, style: context.text.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (subtitle != null)
                  Text(subtitle!, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
