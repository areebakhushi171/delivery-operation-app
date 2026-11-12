import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/theme.dart';

class ChartBar {
  const ChartBar(this.label, this.value);
  final String label;
  final double value;
}

/// Interactive bar chart: tap a bar to read its exact value.
class CommonBarChart extends StatefulWidget {
  const CommonBarChart({
    super.key,
    required this.bars,
    required this.color,
    this.height = 140,
    this.format,
  });

  final List<ChartBar> bars;
  final Color color;
  final double height;
  final String Function(double)? format;

  @override
  State<CommonBarChart> createState() => _CommonBarChartState();
}

class _CommonBarChartState extends State<CommonBarChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final maxV = widget.bars.fold<double>(0, (m, b) => math.max(m, b.value));
    final barArea = widget.height.h - 22.h;
    final fmt = widget.format ?? (v) => v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);
    final sel = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 20.h,
          child: Text(
            sel != null && sel < widget.bars.length
                ? '${widget.bars[sel].label.isEmpty ? 'Bar ${sel + 1}' : widget.bars[sel].label}: ${fmt(widget.bars[sel].value)}'
                : 'Tap a bar for details',
            style: context.text.labelSmall,
          ),
        ),
        SizedBox(
          height: widget.height.h,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < widget.bars.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _selected = i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: EdgeInsets.symmetric(horizontal: 2.w),
                          height: maxV == 0 ? 3.h : math.max(3.h, widget.bars[i].value / maxV * barArea),
                          decoration: BoxDecoration(
                            color: i == sel ? widget.color : widget.color.withAlpha(150),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(4.r)),
                          ),
                        ),
                        SizedBox(
                          height: 18.h,
                          child: FittedBox(
                            child: Text(widget.bars[i].label, style: context.text.labelSmall),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
