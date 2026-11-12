import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/theme.dart';

/// Spinner, or pulsing skeleton cards when [skeleton] is true.
class CommonLoadingWidget extends StatefulWidget {
  const CommonLoadingWidget({super.key, this.skeleton = false, this.message});
  final bool skeleton;
  final String? message;

  @override
  State<CommonLoadingWidget> createState() => _CommonLoadingWidgetState();
}

class _CommonLoadingWidgetState extends State<CommonLoadingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.skeleton) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (widget.message != null) ...[
              SizedBox(height: AppSpacing.md),
              Text(widget.message!, style: context.text.bodySmall),
            ],
          ],
        ),
      );
    }
    final c = context.appColors;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_c),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(AppSpacing.md),
        itemCount: 4,
        separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, __) => Container(
          height: 96.h,
          decoration: BoxDecoration(
            color: c.surfaceSecondary,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
        ),
      ),
    );
  }
}
