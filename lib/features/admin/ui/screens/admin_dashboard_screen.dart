
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../../../../core/providers/notifications_provider.dart';
import '../../providers/admin_providers.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<AdminDashboardProvider>();

    final unreadCount = context.select<NotificationsProvider, int>(
          (provider) => provider.unreadCount,
    );

    final c = context.appColors;

    final openExceptions =
    dash.exceptions.where((e) => e.status.isOpen).toList();

    if (dash.isLoading) {
      return const Scaffold(
        appBar: CommonAppBar(title: 'Admin Command Center'),
        body: CommonLoadingWidget(),
      );
    }

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Command Center',
        actions: [
          // Notifications
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {
              context.push(AppRoutes.adminNotifications);
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined),
                if (unreadCount > 0)
                  Positioned(
                    right: -7,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      constraints: const BoxConstraints(
                        minWidth: 17,
                        minHeight: 17,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Admin Profile
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () {
              context.push(AppRoutes.adminProfile);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
        await Future.delayed(const Duration(milliseconds: 500)),
        child: ListView(
          padding: EdgeInsets.all(AppSpacing.md),
          children: [
            // Greeting
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()} 👋',
                  style: context.text.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 2.h),
                Text(
                  DateFormat('EEEE, d MMMM').format(DateTime.now()),
                  style: context.text.bodySmall
                      ?.copyWith(color: context.scheme.onSurfaceVariant),
                ),
              ],
            ).animate().fadeIn(duration: 300.ms),

            SizedBox(height: AppSpacing.md),

            // Hero card (real data)
            _HeroCard(dash: dash)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.08, end: 0),

            SizedBox(height: AppSpacing.md),

            // Quick actions
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('New Order'),
                    onPressed: () => context.push(AppRoutes.adminCreateOrder),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.two_wheeler),
                    label: const Text('Manage Riders'),
                    onPressed: () => context.go(AppRoutes.adminRiders),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 500.ms),

            SizedBox(height: AppSpacing.md),

            // Key metrics
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.5,
              children: [
                CommonStatTile(
                  icon: Icons.receipt_long_rounded,
                  value: '${dash.totalOrders}',
                  label: 'Total Orders',
                  tone: StatusTone.info,
                  onTap: () => context.go(AppRoutes.adminOrders),
                ),
                CommonStatTile(
                  icon: Icons.two_wheeler_rounded,
                  value: '${dash.activeFleet}',
                  label: 'Active Fleet',
                  tone: StatusTone.success,
                  onTap: () => context.go(AppRoutes.adminRiders),
                ),
                CommonStatTile(
                  icon: Icons.verified_rounded,
                  value: '${dash.slaSuccessRate.toStringAsFixed(1)}%',
                  label: 'SLA Success Rate',
                  tone: StatusTone.success,
                  onTap: () => context.go(AppRoutes.adminAnalytics),
                ),
                CommonStatTile(
                  icon: Icons.payments_rounded,
                  value: CurrencyUtils.rs(dash.codCollected),
                  label: 'COD Collected',
                  tone: StatusTone.warning,
                  onTap: () => context.go(AppRoutes.adminAnalytics),
                ),
              ],
            ).animate().fadeIn(duration: 600.ms),

            SizedBox(height: AppSpacing.md),

            // Delivery trend (real data, last 7 days)
            const CommonSectionHeader('Delivery Volume & Trend'),
            SizedBox(height: AppSpacing.xs),
            CommonCard(
              child: _TrendCard(
                points: dash.weeklyTrend,
                changePercent: dash.weekChangePercent,
              ),
            ).animate().fadeIn(duration: 700.ms),

            SizedBox(height: AppSpacing.md),

            // Pipeline
            const CommonSectionHeader('Order Pipeline Status'),
            SizedBox(height: AppSpacing.xs),
            CommonCard(
              onTap: () => context.go(AppRoutes.adminOrders),
              child: _PipelineCard(
                pending: dash.pendingOrders,
                completed: dash.completedOrders,
                failed: dash.failedOrders,
              ),
            ),

            SizedBox(height: AppSpacing.md),

            // Exceptions
            if (openExceptions.isNotEmpty) ...[
              CommonSectionHeader(
                'Active Exceptions (${openExceptions.length})',
              ),
              SizedBox(height: AppSpacing.xs),
              ...openExceptions.map(
                    (ex) => Container(
                  margin: EdgeInsets.only(bottom: AppSpacing.xs),
                  child: CommonCard(
                    onTap: () =>
                        context.push(AppRoutes.adminOrder(ex.orderId)),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: c.danger.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: c.danger,
                            size: 20.w,
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order #${ex.orderId} • ${ex.reason.name.toUpperCase()}',
                                style: context.text.titleSmall,
                              ),
                              Text(
                                ex.description,
                                style: context.text.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.push(AppRoutes.adminOrder(ex.orderId)),
                          child: const Text('Details'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Hero card ─────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.dash});

  final AdminDashboardProvider dash;

  @override
  Widget build(BuildContext context) {
    final primary = context.scheme.primary;
    final change = dash.weekChangePercent;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, primary.withAlpha(190)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card + 4),
        boxShadow: [
          BoxShadow(
            color: primary.withAlpha(80),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -30.w,
            top: -30.h,
            child: Container(
              width: 130.w,
              height: 130.w,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 40.w,
            bottom: -40.h,
            child: Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Realized Volume',
                      style: context.text.bodyMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.circle,
                            color: Colors.greenAccent,
                            size: 8,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'LIVE',
                            style: context.text.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  CurrencyUtils.rs(dash.realizedVolume),
                  style: context.text.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 32.sp,
                  ),
                ),
                SizedBox(height: 14.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 6.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _ChangeChip(percent: change, onDark: true),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'SLA ${dash.slaSuccessRate.toStringAsFixed(1)}%',
                        style: context.text.labelSmall
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangeChip extends StatelessWidget {
  const _ChangeChip({required this.percent, this.onDark = false});

  final double? percent;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final p = percent;

    if (p == null) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: onDark
              ? Colors.white.withAlpha(50)
              : context.scheme.outline.withAlpha(30),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Text(
          'No previous week data',
          style: context.text.labelSmall?.copyWith(
            color: onDark ? Colors.white : context.scheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final up = p >= 0;
    final tone = up ? c.success : c.danger;
    final fg = onDark ? Colors.white : tone;
    final arrowColor =
    onDark ? (up ? Colors.greenAccent : Colors.orangeAccent) : tone;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withAlpha(50) : tone.withAlpha(28),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.arrow_upward : Icons.arrow_downward,
            color: arrowColor,
            size: 14,
          ),
          SizedBox(width: 4.w),
          Text(
            '${up ? '+' : ''}${p.toStringAsFixed(1)}% vs last week',
            style: context.text.labelSmall
                ?.copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Trend chart ─────────────────────────

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.points,
    required this.changePercent,
  });

  final List<DailyTrendPoint> points;
  final double? changePercent;

  @override
  Widget build(BuildContext context) {
    final primary = context.scheme.primary;
    final success = context.appColors.success;
    final muted = context.scheme.onSurfaceVariant;

    final createdSpots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].created.toDouble()),
    ];

    final deliveredSpots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].delivered.toDouble()),
    ];

    final maxVal = points.fold<int>(
      0,
          (m, p) => math.max(m, math.max(p.created, p.delivered)),
    );

    final maxY = math.max(4, maxVal).toDouble() * 1.25;
    final total = points.fold<int>(0, (s, p) => s + p.created);
    final isEmpty = maxVal == 0;

    final range =
        '${DateFormat('d MMM').format(points.first.date)} – ${DateFormat('d MMM').format(points.last.date)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$total',
                  style: context.text.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  'orders • $range',
                  style: context.text.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
            const Spacer(),
            _ChangeChip(percent: changePercent),
          ],
        ),
        SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _LegendDot(color: primary, label: 'Orders'),
            SizedBox(width: AppSpacing.md),
            _LegendDot(color: success, label: 'Delivered'),
          ],
        ),
        SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 190.h,
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: (points.length - 1).toDouble(),
                    minY: 0,
                    maxY: maxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY / 4,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: context.scheme.outline.withAlpha(35),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: 42.h,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();

                            if (value != i.toDouble() ||
                                i < 0 ||
                                i >= points.length) {
                              return const SizedBox.shrink();
                            }

                            final d = points[i].date;
                            final isToday = i == points.length - 1;

                            return Padding(
                              padding: EdgeInsets.only(top: 8.h),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    DateFormat('d').format(d),
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w800,
                                      color: isToday
                                          ? primary
                                          : context.scheme.onSurface,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    DateFormat('E').format(d),
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: isToday ? primary : muted,
                                      fontWeight: isToday
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => context.scheme.inverseSurface,
                        getTooltipItems: (spots) => spots.map((s) {
                          final style = TextStyle(
                            color: context.scheme.onInverseSurface,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          );

                          if (s.barIndex == 0) {
                            final d = DateFormat('EEE, d MMM')
                                .format(points[s.x.toInt()].date);

                            return LineTooltipItem(
                              '$d\nOrders: ${s.y.toInt()}',
                              style,
                            );
                          }

                          return LineTooltipItem(
                            'Delivered: ${s.y.toInt()}',
                            style,
                          );
                        }).toList(),
                      ),
                    ),
                    lineBarsData: [
                      _line(createdSpots, primary, context, fill: true),
                      _line(deliveredSpots, success, context),
                    ],
                  ),
                ),
              ),
              if (isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 40.h),
                    child: Text(
                      'No orders in the last 7 days',
                      style: context.text.bodySmall?.copyWith(color: muted),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  LineChartBarData _line(
      List<FlSpot> spots,
      Color color,
      BuildContext context, {
        bool fill = false,
      }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.25,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 3.5,
          color: Theme.of(context).colorScheme.surface,
          strokeWidth: 2.5,
          strokeColor: color,
        ),
      ),
      belowBarData: BarAreaData(
        show: fill,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withAlpha(80), color.withAlpha(0)],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 6.w),
        Text(label, style: context.text.labelSmall),
      ],
    );
  }
}

// ───────────────────────── Pipeline ─────────────────────────

class _PipelineCard extends StatelessWidget {
  const _PipelineCard({
    required this.pending,
    required this.completed,
    required this.failed,
  });

  final int pending;
  final int completed;
  final int failed;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final total = pending + completed + failed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: SizedBox(
            height: 10.h,
            child: total == 0
                ? ColoredBox(color: context.scheme.outline.withAlpha(40))
                : Row(
              children: [
                if (pending > 0)
                  Expanded(
                    flex: pending,
                    child: ColoredBox(color: c.warning),
                  ),
                if (completed > 0)
                  Expanded(
                    flex: completed,
                    child: ColoredBox(color: c.success),
                  ),
                if (failed > 0)
                  Expanded(
                    flex: failed,
                    child: ColoredBox(color: c.danger),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _PipelineItem(
                label: 'Pending',
                count: pending,
                total: total,
                color: c.warning,
              ),
            ),
            Expanded(
              child: _PipelineItem(
                label: 'Completed',
                count: completed,
                total: total,
                color: c.success,
              ),
            ),
            Expanded(
              child: _PipelineItem(
                label: 'Failed',
                count: failed,
                total: total,
                color: c.danger,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PipelineItem extends StatelessWidget {
  const _PipelineItem({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (count / total * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8.w,
              height: 8.w,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 6.w),
            Text(label, style: context.text.bodySmall),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          '$count',
          style: context.text.headlineSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w800),
        ),
        Text(
          '$pct%',
          style: context.text.labelSmall
              ?.copyWith(color: context.scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
