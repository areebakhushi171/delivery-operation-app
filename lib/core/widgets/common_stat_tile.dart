import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/theme.dart';
import 'common_status_chip.dart';
import 'glass_card.dart';

/// KPI tile (round tinted icon + big number + label) on glass.
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
    return GlassCard(
      blur: false,
      onTap: onTap,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(5.w),
              decoration: BoxDecoration(color: color.withAlpha(36), shape: BoxShape.circle),
              child: Icon(icon, size: 16.w, color: color),
            ),
            SizedBox(height: 4.h),
            Text(value, style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text(label, style: context.text.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (subtitle != null)
              Text(subtitle!, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
