import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/theme.dart';

/// Rounded progress bar with a percent bubble above the fill end.
/// [value] is 0..1. The fill animates on first build and on change.
class ProgressBarBubble extends StatelessWidget {
  const ProgressBarBubble({
    super.key,
    required this.value,
    required this.color,
    this.startLabel,
    this.endLabel,
    this.height = 8,
  });

  final double value;
  final Color color;
  final String? startLabel;
  final String? endLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    final track = context.appColors.mutedText.withAlpha(40);
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: v),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (_, t, __) => LayoutBuilder(
            builder: (_, box) {
              final w = box.maxWidth;
              final bubbleW = 54.w;
              final left = (w * t - bubbleW / 2).clamp(0.0, w - bubbleW);
              return SizedBox(
                height: 30.h + height.h,
                child: Stack(
                  children: [
                    Positioned(
                      left: left,
                      top: 0,
                      child: Container(
                        width: bubbleW,
                        padding: EdgeInsets.symmetric(vertical: 3.h),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14.r)),
                        child: Text(
                          '${(t * 100).toStringAsFixed(t * 100 >= 100 || t == 0 ? 0 : 1)}%',
                          style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: height.h,
                        decoration: BoxDecoration(color: track, borderRadius: BorderRadius.circular(8.r)),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: t,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.r),
                              gradient: LinearGradient(colors: [color.withAlpha(150), color]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (startLabel != null || endLabel != null) ...[
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(startLabel ?? '', style: context.text.bodySmall),
              Text(endLabel ?? '', style: context.text.bodySmall),
            ],
          ),
        ],
      ],
    );
  }
}
