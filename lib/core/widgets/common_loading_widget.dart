import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/theme.dart';

/// Spinner, or shimmering glass skeleton cards when [skeleton] is true.
class CommonLoadingWidget extends StatelessWidget {
  const CommonLoadingWidget({super.key, this.skeleton = false, this.message});
  final bool skeleton;
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (!skeleton) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              SizedBox(height: AppSpacing.md),
              Text(message!, style: context.text.bodySmall),
            ],
          ],
        ),
      );
    }
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: dark ? const Color(0x33FFFFFF) : const Color(0x99FFFFFF),
      highlightColor: dark ? const Color(0x55FFFFFF) : const Color(0xE6FFFFFF),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(AppSpacing.screen),
        itemCount: 4,
        separatorBuilder: (_, __) => SizedBox(height: AppSpacing.gap),
        itemBuilder: (_, __) => Container(
          height: 96.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
        ),
      ),
    );
  }
}
