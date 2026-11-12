import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../data/models/enums.dart';
import '../theme/theme.dart';

enum StatusTone { success, warning, danger, info, neutral }

extension StatusToneColor on StatusTone {
  Color of(BuildContext context) {
    final c = context.appColors;
    switch (this) {
      case StatusTone.success:
        return c.success;
      case StatusTone.warning:
        return c.warning;
      case StatusTone.danger:
        return c.danger;
      case StatusTone.info:
        return c.info;
      case StatusTone.neutral:
        return c.mutedText;
    }
  }
}

/// Colour semantics: green = delivered, amber = pending, red = failed, blue = in progress.
class CommonStatusChip extends StatelessWidget {
  const CommonStatusChip({super.key, required this.label, required this.tone, this.icon});

  factory CommonStatusChip.order(OrderStatus s, {Key? key}) =>
      CommonStatusChip(key: key, label: s.label, tone: orderTone(s));

  final String label;
  final StatusTone tone;
  final IconData? icon;

  static StatusTone orderTone(OrderStatus s) {
    switch (s) {
      case OrderStatus.delivered:
        return StatusTone.success;
      case OrderStatus.failed:
        return StatusTone.danger;
      case OrderStatus.unassigned:
      case OrderStatus.assigned:
        return StatusTone.warning;
      case OrderStatus.pickedUp:
      case OrderStatus.outForDelivery:
        return StatusTone.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = tone.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withAlpha(32),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14.w, color: color), SizedBox(width: 4.w)],
          Text(label, style: context.text.labelMedium?.copyWith(color: color)),
        ],
      ),
    );
  }
}
