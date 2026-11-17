import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/theme.dart';
import 'glass_card.dart';

/// "Highest / Lowest / Top rider" style card for horizontal highlight rows.
class HighlightCard extends StatelessWidget {
  const HighlightCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.delta,
    this.caption,
    this.width = 190,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? delta;
  final String? caption;
  final Color color;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width.w,
      child: GlassCard(
        blur: false,
        onTap: onTap,
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 16.w, color: color),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelMedium?.copyWith(color: color)),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(value, style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  if (delta != null) ...[
                    SizedBox(width: 6.w),
                    Text(delta!, style: context.text.labelSmall?.copyWith(color: color)),
                  ],
                ],
              ),
            ),
            if (caption != null) ...[
              SizedBox(height: 6.h),
              Text(caption!, style: context.text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }
}
