import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/theme.dart';
import 'glass_card.dart';

/// Small status card: title, coloured waveform bars (built from real series
/// values), big number and a status label. Used in horizontal scrollers.
class WaveformCard extends StatelessWidget {
  const WaveformCard({
    super.key,
    required this.title,
    required this.value,
    required this.status,
    required this.color,
    this.series = const [],
    this.onTap,
    this.width = 128,
    this.valueText,
  });

  final String title;
  final num value;
  final String? valueText;
  final String status;
  final Color color;

  /// Real values over time (e.g. count per day). Empty = flat bars.
  final List<double> series;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width.w,
      child: GlassCard(
        blur: false,
        onTap: onTap,
        padding: EdgeInsets.fromLTRB(12.w, 14.h, 12.w, 12.h),
        child: Column(
          children: [
            Text(title, style: context.text.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 10.h),
            Expanded(child: WaveformBars(series: series, color: color)),
            SizedBox(height: 10.h),
            Text(
              valueText ?? '$value',
              style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2.h),
            Text(
              status.toUpperCase(),
              style: context.text.labelSmall?.copyWith(letterSpacing: 0.6, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dense vertical bars that fade downward, smoothly interpolating [series].
class WaveformBars extends StatelessWidget {
  const WaveformBars({super.key, required this.series, required this.color, this.bars = 22});
  final List<double> series;
  final Color color;
  final int bars;

  List<double> _levels() {
    if (series.isEmpty) return List.filled(bars, 0.12);
    final maxV = series.fold<double>(0, math.max);
    if (maxV <= 0) return List.filled(bars, 0.12);
    return List.generate(bars, (i) {
      final pos = series.length == 1 ? 0.0 : i / (bars - 1) * (series.length - 1);
      final lo = pos.floor();
      final hi = math.min(series.length - 1, lo + 1);
      final v = series[lo] + (series[hi] - series[lo]) * (pos - lo);
      // tiny deterministic ripple so the bars look like a waveform
      final ripple = 0.88 + 0.12 * math.sin(i * 1.7);
      return (math.max(v / maxV, 0.08) * ripple).clamp(0.08, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final levels = _levels();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, t, __) => LayoutBuilder(
        builder: (_, box) => Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final l in levels)
              Container(
                width: 2.2.w,
                height: box.maxHeight * l * t,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2.r),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color, color.withAlpha(60)],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
