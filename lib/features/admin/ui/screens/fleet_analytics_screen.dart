import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../../providers/admin_providers.dart';
import '../widgets/admin_stats.dart';

class FleetAnalyticsScreen extends StatefulWidget {
  const FleetAnalyticsScreen({super.key});

  @override
  State<FleetAnalyticsScreen> createState() => _FleetAnalyticsScreenState();
}

class _FleetAnalyticsScreenState extends State<FleetAnalyticsScreen> {
  int _days = 30; // chart range (display only)

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<AdminDashboardProvider>();
    final c = context.appColors;
    final primary = context.scheme.primary;
    final stats = AdminStats(dash);

    final inTransitCount = stats.inTransit;
    final totalCompleted = dash.completedOrders;
    final totalFailed = dash.failedOrders;
    final totalPending = dash.pendingOrders;
    final deliverySuccessRate = (totalCompleted + totalFailed == 0)
        ? 0.0
        : (totalCompleted / (totalCompleted + totalFailed)) * 100.0;

    if (dash.isLoading) {
      return const Scaffold(
        appBar: CommonAppBar(title: 'Fleet Analytics & Reports', showBack: false),
        body: CommonLoadingWidget(skeleton: true),
      );
    }

    final delivered = stats.deliveredPerDay(_days);
    final created = stats.createdPerDay(_days);
    final revenue = stats.revenuePerDay(_days);
    final periodRevenue = revenue.fold<double>(0, (s, v) => s + v);
    final top = stats.topRider;
    final busiest = stats.busiestDay;
    final fastest = stats.fastestMinutes;
    final palette = [primary, AppColors.orange, AppColors.pink, AppColors.lightGreen, AppColors.yellow, AppColors.sky];
    final exSlices = stats.exceptionSlices(dash.exceptions, palette);

    // Riders ranked by delivered orders (real data)
    final perRider = <String, int>{};
    for (final o in stats.delivered) {
      final id = o.riderId;
      if (id == null || id.isEmpty) continue;
      perRider[id] = (perRider[id] ?? 0) + 1;
    }
    final ranked = perRider.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxRider = ranked.isEmpty ? 1 : ranked.first.value;

    final sections = <Widget>[
      // ---- Range chips ----
      Row(
        children: [
          for (final d in const [7, 14, 30]) ...[
            ChoiceChip(
              label: Text('$d days'),
              selected: _days == d,
              onSelected: (_) => setState(() => _days = d),
            ),
            SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
      SizedBox(height: AppSpacing.gap),

      // ---- Revenue hero ----
      SummaryCard(
        label: 'Delivered value - last $_days days',
        value: CurrencyUtils.rs(periodRevenue),
        badge: '${delivered.fold<double>(0, (s, v) => s + v).round()} deliveries',
        child: AreaLineChart(
          values: revenue,
          xLabels: AdminStats.dayLabels(_days),
          color: c.success,
          height: 170,
          format: (v) => CurrencyUtils.rs(v),
        ),
      ),

      // ---- KPI grid (same 8 tiles) ----
      const CommonSectionHeader('Operational KPI Summary'),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: AppSpacing.sm + 4,
        mainAxisSpacing: AppSpacing.sm + 4,
        childAspectRatio: 1.5,
        children: [
          CommonStatTile(icon: Icons.local_shipping_rounded, value: '${dash.totalOrders}', label: 'Total Orders', tone: StatusTone.info),
          CommonStatTile(icon: Icons.check_circle_rounded, value: '$totalCompleted', label: 'Delivered', tone: StatusTone.success),
          CommonStatTile(icon: Icons.directions_bike_rounded, value: '$inTransitCount', label: 'In Transit', tone: StatusTone.info),
          CommonStatTile(icon: Icons.cancel_rounded, value: '$totalFailed', label: 'Failed Deliveries', tone: StatusTone.danger),
          CommonStatTile(icon: Icons.two_wheeler_rounded, value: '${dash.riders.length}', label: 'Total Riders', tone: StatusTone.info),
          CommonStatTile(icon: Icons.verified_user_rounded, value: '${dash.activeFleet}', label: 'Active On Duty', tone: StatusTone.success),
          CommonStatTile(icon: Icons.payments_rounded, value: CurrencyUtils.rs(dash.codCollected), label: 'COD Realized', tone: StatusTone.warning),
          CommonStatTile(icon: Icons.thumb_up_rounded, value: '${deliverySuccessRate.toStringAsFixed(1)}%', label: 'Success Rate', tone: StatusTone.success),
        ],
      ),

      // ---- Created vs delivered ----
      CommonSectionHeader('Orders Created - last ${_days > 14 ? 14 : _days} days'),
      GlassCard(
        child: CommonBarChart(
          bars: AdminStats.bars(created.sublist(created.length - (_days > 14 ? 14 : _days))),
          color: primary,
          height: 150,
          format: (v) => '${v.round()} created',
        ),
      ),
      SizedBox(height: AppSpacing.gap),
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivered per day', style: context.text.labelMedium),
            SizedBox(height: 6.h),
            AreaLineChart(
              values: delivered,
              xLabels: AdminStats.dayLabels(_days),
              color: AppColors.lightGreen,
              height: 150,
              format: (v) => '${v.round()} delivered',
            ),
          ],
        ),
      ),

      // ---- Pipeline donut ----
      const CommonSectionHeader('Order Pipeline Distribution'),
      GlassCard(
        child: dash.totalOrders == 0
            ? SizedBox(height: 80.h, child: const Center(child: Text('No orders recorded yet.')))
            : DonutChart(
          centerValue: '${dash.totalOrders}',
          centerLabel: 'orders',
          slices: [
            DonutSlice('Delivered', totalCompleted.toDouble(), AppColors.lightGreen),
            DonutSlice('In transit', inTransitCount.toDouble(), primary),
            DonutSlice('Pending', totalPending.toDouble(), AppColors.orange),
            DonutSlice('Failed', totalFailed.toDouble(), AppColors.pink),
          ],
        ),
      ),

      // ---- Payment mix ----
      const CommonSectionHeader('Payment Mix'),
      GlassCard(
        child: DonutChart(
          centerValue: '${dash.totalOrders}',
          centerLabel: 'orders',
          slices: [
            DonutSlice('COD', stats.codCount.toDouble(), AppColors.orange),
            DonutSlice('Prepaid', stats.prepaidCount.toDouble(), primary),
          ],
        ),
      ),

      // ---- Exceptions by reason ----
      if (exSlices.isNotEmpty) ...[
        const CommonSectionHeader('Exceptions by Reason'),
        GlassCard(
          child: DonutChart(
            centerValue: '${dash.exceptions.length}',
            centerLabel: 'reported',
            slices: exSlices,
          ),
        ),
      ],

      // ---- SLA ----
      const CommonSectionHeader('SLA Performance Overview'),
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProgressBarBubble(
              value: dash.slaSuccessRate / 100.0,
              color: c.success,
              startLabel: 'On-Time Delivery SLA Rate',
              endLabel: '${dash.slaSuccessRate.toStringAsFixed(1)}%',
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Calculated from eligible completed orders delivered within promised window deadline.',
              style: context.text.bodySmall,
            ),
          ],
        ),
      ),

      // ---- Highlights ----
      if (top != null || busiest != null || fastest != null) ...[
        const CommonSectionHeader('Highlights'),
        SizedBox(
          height: 128.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              if (top != null) ...[
                HighlightCard(
                  icon: Icons.emoji_events_outlined,
                  label: 'Top Rider',
                  value: top.name.split(' ').first,
                  caption: '${top.count} deliveries',
                  color: AppColors.orange,
                ),
                SizedBox(width: 12.w),
              ],
              if (busiest != null) ...[
                HighlightCard(
                  icon: Icons.calendar_month_outlined,
                  label: 'Busiest Day',
                  value: busiest.day,
                  caption: '${busiest.count} orders created',
                  color: primary,
                ),
                SizedBox(width: 12.w),
              ],
              if (fastest != null)
                HighlightCard(
                  icon: Icons.bolt_rounded,
                  label: 'Fastest Delivery',
                  value: fastest >= 60 ? '${fastest ~/ 60}h ${fastest % 60}m' : '$fastest min',
                  caption: 'Best time on record',
                  color: c.success,
                ),
            ],
          ),
        ),
      ],

      // ---- Rider leaderboard ----
      if (ranked.isNotEmpty) ...[
        const CommonSectionHeader('Rider Leaderboard'),
        GlassCard(
          child: Column(
            children: [
              for (final e in ranked.take(5))
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.h),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 92.w,
                        child: Text(
                          dash.riders.where((r) => r.id == e.key).map((r) => r.name).firstOrNull ?? 'Rider',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.labelMedium?.copyWith(color: context.scheme.onSurface),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: LinearProgressIndicator(
                            value: e.value / maxRider,
                            minHeight: 8.h,
                            color: primary,
                            backgroundColor: c.mutedText.withAlpha(40),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text('${e.value}', style: context.text.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    ];

    return Scaffold(
      appBar: const CommonAppBar(title: 'Fleet Analytics & Reports', showBack: false),
      body: RefreshIndicator(
        onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
        child: ListView(
          key: const PageStorageKey('admin_analytics_scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.xl),
          children: [
            for (var i = 0; i < sections.length; i++)
              sections[i].animate().fadeIn(delay: (40 * i).ms, duration: 300.ms),
          ],
        ),
      ),
    );
  }
}
