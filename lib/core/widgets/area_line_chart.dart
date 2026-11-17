import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/theme.dart';

/// Curved gradient area chart with a vertical marker, dot and tooltip bubble.
/// Pass real values (one per x position). Tap / drag to move the marker.
class AreaLineChart extends StatefulWidget {
  const AreaLineChart({
    super.key,
    required this.values,
    this.xLabels,
    this.color,
    this.height = 190,
    this.format,
    this.axisFormat,
  });

  final List<double> values;

  /// Optional label for each value (same length). Defaults to 1..n.
  final List<String>? xLabels;
  final Color? color;
  final double height;

  /// Tooltip text, e.g. (v) => '12 orders'.
  final String Function(double)? format;

  /// Left axis text.
  final String Function(double)? axisFormat;

  @override
  State<AreaLineChart> createState() => _AreaLineChartState();
}

class _AreaLineChartState extends State<AreaLineChart> with SingleTickerProviderStateMixin {
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  int? _selected;

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  static String _compact(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}k';
    return v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final vals = widget.values;
    final color = widget.color ?? context.appColors.success;
    final muted = context.appColors.mutedText;
    if (vals.isEmpty) {
      return SizedBox(
        height: widget.height.h,
        child: Center(child: Text('No data yet', style: context.text.bodySmall)),
      );
    }
    final maxV = vals.fold<double>(0, math.max);
    final maxY = maxV <= 0 ? 4.0 : maxV * 1.25;
    final sel = (_selected ?? vals.length - 1).clamp(0, vals.length - 1);
    final fmt = widget.format ?? _compact;
    final axisFmt = widget.axisFormat ?? _compact;
    final labelStep = math.max(1, (vals.length / 6).ceil());

    return SizedBox(
      height: widget.height.h,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          final t = Curves.easeOutCubic.transform(_anim.value);
          final spots = [
            for (var i = 0; i < vals.length; i++) FlSpot(i.toDouble(), vals[i] * t),
          ];
          final bar = LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            color: color,
            barWidth: 2.4,
            showingIndicators: [sel],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withAlpha(110), color.withAlpha(0)],
              ),
            ),
          );
          return LineChart(
            duration: Duration.zero,
            LineChartData(
              minX: 0,
              maxX: math.max(1, vals.length - 1).toDouble(),
              minY: 0,
              maxY: maxY,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: muted.withAlpha(50),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 38.w,
                    interval: maxY / 4,
                    getTitlesWidget: (v, meta) => Text(
                      axisFmt(v),
                      style: TextStyle(fontSize: 10.sp, color: muted),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26.h,
                    interval: 1,
                    getTitlesWidget: (v, meta) {
                      final i = v.toInt();
                      if (v != i.toDouble() || i < 0 || i >= vals.length) return const SizedBox.shrink();
                      final isEdge = i == vals.length - 1;
                      if (i % labelStep != 0 && !(isEdge && (vals.length - 1) % labelStep == 0)) {
                        return const SizedBox.shrink();
                      }
                      final label = (widget.xLabels != null && i < widget.xLabels!.length)
                          ? widget.xLabels![i]
                          : '${i + 1}';
                      return Padding(
                        padding: EdgeInsets.only(top: 6.h),
                        child: Text(label, style: TextStyle(fontSize: 10.sp, color: muted)),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [bar],
              showingTooltipIndicators: [
                ShowingTooltipIndicators([LineBarSpot(bar, 0, spots[sel])]),
              ],
              lineTouchData: LineTouchData(
                handleBuiltInTouches: false,
                touchCallback: (event, resp) {
                  final hit = resp?.lineBarSpots;
                  if (hit == null || hit.isEmpty) return;
                  if (event is FlTapUpEvent || event is FlPanUpdateEvent || event is FlTapDownEvent) {
                    final i = hit.first.spotIndex;
                    if (i != _selected) setState(() => _selected = i);
                  }
                },
                getTouchedSpotIndicator: (barData, indexes) => [
                  for (final _ in indexes)
                    TouchedSpotIndicatorData(
                      FlLine(color: color, strokeWidth: 1.6),
                      FlDotData(
                        show: true,
                        getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                          radius: 4.5,
                          color: Colors.white,
                          strokeWidth: 2.4,
                          strokeColor: color,
                        ),
                      ),
                    ),
                ],
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => Colors.white,
                  tooltipRoundedRadius: 12,
                  tooltipBorder: BorderSide(color: color, width: 1.2),
                  tooltipPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  fitInsideHorizontally: true,
                  getTooltipItems: (spots) => [
                    for (final s in spots)
                      LineTooltipItem(
                        fmt(vals[s.spotIndex]),
                        TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12.sp),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
