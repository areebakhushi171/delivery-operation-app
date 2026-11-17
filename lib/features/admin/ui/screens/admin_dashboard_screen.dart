import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../../../../core/providers/notifications_provider.dart';
import '../../../../core/utils/scroll_reset.dart';
import '../../../../widgets/greeting_header.dart';
import '../../../authentication/providers/auth_provider.dart';
import '../../providers/admin_providers.dart';
import '../widgets/admin_stats.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with ScrollResetMixin {
  @override
  void initState() {
    super.initState();
    ScrollResetRegistry.register(0, scrollController);
  }

  @override
  void dispose() {
    ScrollResetRegistry.unregister(0);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<AdminDashboardProvider>();
    final user = context.watch<AuthProvider>().user;
    final unread = context.select<NotificationsProvider, int>((p) => p.unreadCount);

    if (dash.isLoading) {
      return const Scaffold(
        appBar: CommonAppBar(title: 'Admin Command Center', showBack: false),
        body: CommonLoadingWidget(skeleton: true),
      );
    }

    final sections = _sections(context, dash);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
        child: ListView(
          controller: scrollController, // scroll reset controller (PageStorageKey removed)
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            GreetingHeader(
              userName: user?.name ?? 'Admin',
              unread: unread,
              onNotifications: () => context.push(AppRoutes.adminNotifications),
              onProfile: () => context.push(AppRoutes.adminProfile),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < sections.length; i++)
                    sections[i].animate().fadeIn(delay: (50 * i).ms, duration: 350.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _sections(BuildContext context, AdminDashboardProvider dash) {
    final c = context.appColors;
    final primary = context.scheme.primary;
    final stats = AdminStats(dash);
    final change = dash.weekChangePercent;
    final openExceptions = dash.exceptions.where((e) => e.status.isOpen).toList();
    final riderCount = dash.riders.length;
    final onDutyRatio = riderCount == 0 ? 0.0 : dash.activeFleet / riderCount;
    final top = stats.topRider;
    final busiest = stats.busiestDay;
    final fastest = stats.fastestMinutes;

    return [
      // ---- Hero summary ----
      SummaryCard(
        label: 'Realized Volume',
        value: CurrencyUtils.rs(dash.realizedVolume),
        badge: change == null
            ? '${dash.weekOrders} orders this week'
            : '${change >= 0 ? '▲' : '▼'} ${change.abs().toStringAsFixed(1)}% vs last week',
        badgeColor: (change ?? 0) >= 0 ? c.success : c.danger,
        onArrow: () => context.go(AppRoutes.adminAnalytics),
        child: AreaLineChart(
          values: stats.deliveredPerDay(30),
          xLabels: AdminStats.dayLabels(30),
          color: c.success,
          height: 150,
          format: (v) => '${v.round()} delivered',
        ),
      ),
      SizedBox(height: AppSpacing.gap),

      // ---- Status waveform cards ----
      CommonSectionHeader('Order Pipeline',
          actionLabel: 'More Details', onAction: () => context.go(AppRoutes.adminOrders)),
      SizedBox(
        height: 196.h,
        child: ListView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          children: [
            WaveformCard(
              title: 'Pending',
              value: dash.pendingOrders,
              status: dash.unassignedOrders > 0 ? '${dash.unassignedOrders} unassigned' : 'Assigned',
              color: AppColors.orange,
              series: AdminStats.hourBuckets(stats.byStatus(
                      (s) => s == OrderStatus.assigned || s == OrderStatus.unassigned)),
              onTap: () => context.go(AppRoutes.adminOrders),
            ),
            SizedBox(width: 12.w),
            WaveformCard(
              title: 'On the Way',
              value: stats.inTransit,
              status: stats.inTransit == 0 ? 'Idle' : 'Moving',
              color: primary,
              series: AdminStats.hourBuckets(stats.byStatus(
                      (s) => s == OrderStatus.pickedUp || s == OrderStatus.outForDelivery)),
              onTap: () => context.go(AppRoutes.adminOrders),
            ),
            SizedBox(width: 12.w),
            WaveformCard(
              title: 'Delivered',
              value: dash.completedOrders,
              status: dash.slaSuccessRate >= 80 ? 'On track' : 'Watch SLA',
              color: AppColors.lightGreen,
              series: stats.deliveredPerDay(7),
              onTap: () => context.go(AppRoutes.adminOrders),
            ),
            SizedBox(width: 12.w),
            WaveformCard(
              title: 'Failed',
              value: dash.failedOrders,
              status: dash.failedOrders == 0 ? 'None' : 'Review',
              color: AppColors.pink,
              series: AdminStats.hourBuckets(stats.byStatus((s) => s == OrderStatus.failed)),
              onTap: () => context.go(AppRoutes.adminExceptions),
            ),
          ],
        ),
      ),

      // ---- SLA + fleet progress ----
      const CommonSectionHeader('Performance'),
      GlassCard(
        child: Column(
          children: [
            ProgressBarBubble(
              value: dash.slaSuccessRate / 100,
              color: c.success,
              startLabel: 'On-time SLA rate',
              endLabel: 'Delivered inside window',
            ),
            SizedBox(height: AppSpacing.sm),
            ProgressBarBubble(
              value: onDutyRatio,
              color: AppColors.orange,
              startLabel: 'Fleet on duty',
              endLabel: '${dash.activeFleet} of $riderCount riders',
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

      // ---- Open exceptions (same actions) ----
      if (openExceptions.isNotEmpty) ...[
        CommonSectionHeader('Active Exceptions (${openExceptions.length})',
            actionLabel: 'Desk', onAction: () => context.go(AppRoutes.adminExceptions)),
        for (final ex in openExceptions)
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: CommonCard(
              onTap: () => context.push(AppRoutes.adminOrder(ex.orderId)),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(color: c.danger.withAlpha(30), shape: BoxShape.circle),
                    child: Icon(Icons.warning_amber_rounded, color: c.danger, size: 20.w),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order #${ex.orderId} • ${ex.reason.name.toUpperCase()}',
                            style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(ex.description,
                            style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.adminOrder(ex.orderId)),
                    child: const Text('Details'),
                  ),
                ],
              ),
            ),
          ),
      ],
    ];
  }
}