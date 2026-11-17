import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/theme.dart';

enum CommonButtonVariant { primary, secondary, danger }

/// Pill buttons: primary = blue filled, secondary = glass outlined, danger = red.
class CommonButton extends StatelessWidget {
  const CommonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = CommonButtonVariant.primary,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final CommonButtonVariant variant;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final enabled = onPressed != null && !isLoading;
    final isFilled = variant != CommonButtonVariant.secondary;
    final fg = isFilled ? scheme.onPrimary : scheme.primary;
    const shape = StadiumBorder();
    final size = Size(0, 54.h);

    final content = isLoading
        ? SizedBox(
            width: 20.w,
            height: 20.w,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 20.w), SizedBox(width: 8.w)],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final Widget button = isFilled
        ? FilledButton(
            onPressed: enabled ? onPressed : null,
            style: FilledButton.styleFrom(
              minimumSize: size,
              shape: shape,
              backgroundColor: variant == CommonButtonVariant.danger ? context.appColors.danger : null,
              textStyle: context.text.labelLarge,
            ),
            child: content,
          )
        : OutlinedButton(
            onPressed: enabled ? onPressed : null,
            style: OutlinedButton.styleFrom(
              minimumSize: size,
              shape: shape,
              backgroundColor: context.appColors.card,
              side: BorderSide(color: context.appColors.glassBorder),
              textStyle: context.text.labelLarge,
            ),
            child: content,
          );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
