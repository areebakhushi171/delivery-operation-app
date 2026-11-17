import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/theme.dart';

class DonutSlice {
  const DonutSlice(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;
}

/// Donut chart with centre text and a legend (label + count).
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.slices,
    this.centerValue,
    this.centerLabel,
    this.size = 150,
  });

  final List<DonutSlice> slices;
  final String? centerValue;
  final String? centerLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (s, e) => s + e.value);
    final shown = total <= 0
        ? [PieChartSectionData(value: 1, color: context.appColors.border, radius: 16, showTitle: false)]
        : [
            for (final s in slices.where((e) => e.value > 0))
              PieChartSectionData(value: s.value, color: s.color, radius: 16, showTitle: false),
          ];
    return Row(
      children: [
        SizedBox(
          width: size.w,
          height: size.w,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (_, t, __) => Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  duration: Duration.zero,
                  PieChartData(
                    sections: [
                      for (final s in shown)
                        PieChartSectionData(
                          value: s.value,
                          color: s.color,
                          radius: 16 * t,
                          showTitle: false,
                        ),
                    ],
                    centerSpaceRadius: size.w * 0.30,
                    sectionsSpace: shown.length > 1 ? 3 : 0,
                    startDegreeOffset: -90,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(centerValue ?? total.toStringAsFixed(0),
                        style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    if (centerLabel != null) Text(centerLabel!, style: context.text.labelSmall),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final s in slices)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Row(
                    children: [
                      Container(
                        width: 10.w,
                        height: 10.w,
                        decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(s.label,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
                      ),
                      Text(s.value.toStringAsFixed(0),
                          style: context.text.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
