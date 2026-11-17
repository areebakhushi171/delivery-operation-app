import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/core.dart';
import '../../../../authentication/providers/auth_provider.dart';
import '../../../deliveries/providers/rider_orders_provider.dart';
import '../../../deliveries/ui/widgets/delivery_card.dart';
import '../../../deliveries/ui/widgets/rider_stats.dart';
import '../../../profile/providers/rider_profile_provider.dart';
import '../../../../../core/utils/scroll_reset.dart';
import '../../../../../widgets/greeting_header.dart';
class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    ScrollResetRegistry.register(0, _scrollController);
  }

  @override
  void dispose() {
    ScrollResetRegistry.unregister(0);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final orders = context.watch<RiderOrdersProvider>();
    final profile = context.watch<RiderProfileProvider>();
    final unread = context.select<NotificationsProvider, int>((p) => p.unreadCount);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            GreetingHeader(
              userName: user?.name ?? 'Rider',
              unread: unread,
              onNotifications: () => context.push(AppRoutes.riderNotifications),
              onProfile: () => context.go(AppRoutes.riderProfile),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.lg),
              child: _Body(orders: orders, profile: profile),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.orders, required this.profile});
  final RiderOrdersProvider orders;
  final RiderProfileProvider profile;

  static String _status(int n, String none, String some) => n == 0 ? none : some;

  @override
  Widget build(BuildContext context) {
    if (orders.isLoadingInitial) {
      return SizedBox(height: 300.h, child: const CommonLoadingWidget(skeleton: true));
    }
    if (orders.error != null) {
      return SizedBox(height: 300.h, child: CommonErrorState(message: orders.error!, onRetry: orders.refresh));
    }
    final c = context.appColors;
    final stats = RiderStats(orders);
    final onDuty = profile.rider?.isOnDuty ?? false;
    final issue = profile.locationIssue;
    final pendingN = stats.pendingToday;
    final transitN = stats.inTransitToday;
    final week = RiderStats.weekBars(stats.delivered);
    final onTime = orders.onTimeRate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- Hero: today's progress ----
        SummaryCard(
          label: "Today's Deliveries",
          value: '${orders.completed} / ${orders.total}',
          badge: '${(orders.progress * 100).round()}% completed',
          onArrow: () => context.go(AppRoutes.riderDeliveries),
          child: ProgressBarBubble(
            value: orders.progress,
            color: c.success,
            startLabel: '${orders.completed} delivered',
            endLabel: '${orders.total} total',
          ),
        ),
        SizedBox(height: AppSpacing.gap),

        // ---- Duty switch (existing setDuty logic) ----
        GlassCard(
          blur: false,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          child: Row(
            children: [
              Icon(Icons.circle, size: 12.w, color: onDuty ? c.success : c.mutedText),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(onDuty ? 'On Duty' : 'Off Duty', style: context.text.titleSmall)),
              Switch(
                value: onDuty,
                onChanged: profile.isBusy
                    ? null
                    : (v) async {
                  final ok = await profile.setDuty(v);
                  if (!ok && context.mounted) {
                    context.showMessage(profile.error ?? 'Could not change duty status', isError: true);
                  }
                },
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.gap),

        if (issue != null) ...[
          GlassCard(
            blur: false,
            color: c.warning.withAlpha(40),
            padding: EdgeInsets.all(AppSpacing.sm + 4),
            child: Row(
              children: [
                const Icon(Icons.location_off_outlined),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('Location is unavailable, so dispatch cannot see you live.',
                      style: context.text.bodySmall),
                ),
                TextButton(onPressed: profile.openLocationSettings, child: const Text('Settings')),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.gap),
        ],

        // ---- Status cards with waveform ----
        CommonSectionHeader('Delivery Status',
            actionLabel: 'More Details', onAction: () => context.go(AppRoutes.riderDeliveries)),
        SizedBox(
          height: 196.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              WaveformCard(
                title: 'Pending',
                value: pendingN,
                status: _status(pendingN, 'Clear', 'Waiting'),
                color: AppColors.orange,
                series: RiderStats.hourBuckets(orders.today.where((o) =>
                o.status == OrderStatus.assigned || o.status == OrderStatus.unassigned)),
              ),
              SizedBox(width: 12.w),
              WaveformCard(
                title: 'On the Way',
                value: transitN,
                status: _status(transitN, 'Idle', 'Moving'),
                color: context.scheme.primary,
                series: RiderStats.hourBuckets(orders.today.where((o) =>
                o.status == OrderStatus.pickedUp || o.status == OrderStatus.outForDelivery)),
              ),
              SizedBox(width: 12.w),
              WaveformCard(
                title: 'Delivered',
                value: orders.completed,
                status: orders.total > 0 && orders.progress >= 0.8 ? 'On track' : 'Keep going',
                color: AppColors.lightGreen,
                series: RiderStats.dailyCounts(stats.delivered, 7),
              ),
              SizedBox(width: 12.w),
              WaveformCard(
                title: 'Failed',
                value: orders.failed,
                status: _status(orders.failed, 'None', 'Review'),
                color: AppColors.pink,
                series: RiderStats.dailyCounts(stats.failed, 7),
              ),
            ],
          ),
        ),

        // ---- Weekly bars ----
        const CommonSectionHeader('Last 7 Days'),
        GlassCard(
          child: CommonBarChart(
            bars: week,
            color: context.scheme.primary,
            height: 150,
            format: (v) => '${v.round()} deliveries',
          ),
        ),

        // ---- Highlights (from real delivery times) ----
        if (stats.fastest != null || onTime != null) ...[
          const CommonSectionHeader('Highlights - 30 days'),
          SizedBox(
            height: 128.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                if (stats.fastest != null) ...[
                  HighlightCard(
                    icon: Icons.bolt_rounded,
                    label: 'Fastest Delivery',
                    value: RiderStats.minutesText(stats.fastest!),
                    caption: 'Your best time',
                    color: c.success,
                  ),
                  SizedBox(width: 12.w),
                  HighlightCard(
                    icon: Icons.hourglass_bottom_rounded,
                    label: 'Longest Delivery',
                    value: RiderStats.minutesText(stats.longest!),
                    caption: 'Your slowest time',
                    color: AppColors.orange,
                  ),
                  SizedBox(width: 12.w),
                ],
                if (onTime != null)
                  HighlightCard(
                    icon: Icons.timer_outlined,
                    label: 'On-time Rate',
                    value: '${(onTime * 100).round()}%',
                    caption: 'Delivered inside window',
                    color: context.scheme.primary,
                  ),
              ],
            ),
          ),
        ],

        // ---- COD ----
        SizedBox(height: AppSpacing.gap),
        GlassCard(
          child: Row(
            children: [
              Expanded(child: _Cod('COD collected', CurrencyUtils.rs(orders.codCollectedToday), c.success)),
              Container(width: 1, height: 40.h, color: context.scheme.primary.withAlpha(80)),
              Expanded(child: _Cod('COD to collect', CurrencyUtils.rs(orders.codToCollect), AppColors.orange)),
            ],
          ),
        ),

        // ---- Upcoming ----
        CommonSectionHeader('Upcoming Deliveries',
            actionLabel: 'See All', onAction: () => context.go(AppRoutes.riderDeliveries)),
        if (orders.upcoming.isEmpty)
          const CommonCard(
            child: CommonEmptyState(
              icon: Icons.task_alt,
              title: 'All caught up',
              message: 'No pending deliveries right now.',
            ),
          )
        else
          for (final o in orders.upcoming)
            Padding(padding: EdgeInsets.only(bottom: AppSpacing.sm + 2), child: DeliveryCard(order: o)),
      ],
    );
  }
}

class _Cod extends StatelessWidget {
  const _Cod(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: context.text.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w800)),
      Text(label, style: context.text.bodySmall),
    ],
  );
}