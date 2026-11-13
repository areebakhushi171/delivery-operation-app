import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/core.dart';
import '../../../../authentication/providers/auth_provider.dart';
import '../../../deliveries/providers/rider_orders_provider.dart';
import '../../../deliveries/ui/widgets/delivery_card.dart';
import '../../../profile/providers/rider_profile_provider.dart';

class RiderHomeScreen extends StatelessWidget {
  const RiderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final orders = context.watch<RiderOrdersProvider>();
    final profile = context.watch<RiderProfileProvider>();
    final unread = context.select<NotificationsProvider, int>((p) => p.unreadCount);
    final onDuty = profile.rider?.isOnDuty ?? false;

    return Scaffold(
      body: ListView(
        key: const PageStorageKey('rider_home_scroll'),
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: BoxDecoration(gradient: context.appColors.heroGradient),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md, MediaQuery.paddingOf(context).top + AppSpacing.md, AppSpacing.md, AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CommonProfileAvatar(
                      name: user?.name ?? '',
                      photoUrl: profile.rider?.photoUrl ?? user?.photoUrl,
                      size: 40,
                      onDark: true,
                    ),
                    SizedBox(width: AppSpacing.sm + 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hello, ${user?.firstName ?? 'Rider'}! 👋',
                              style: context.text.titleLarge?.copyWith(color: Colors.white)),
                          Text('${DateTimeUtils.greeting()} - have a great delivery day!',
                              style: context.text.bodySmall?.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Notifications',
                      onPressed: () => context.push(AppRoutes.riderNotifications),
                      icon: Badge(
                        isLabelVisible: unread > 0,
                        label: Text('$unread'),
                        child: const Icon(Icons.notifications_outlined, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                Container(
                  padding: EdgeInsets.all(AppSpacing.sm + 4),
                  decoration: BoxDecoration(
                    color: context.appColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 18.w),
                          SizedBox(width: AppSpacing.sm),
                          Text(DateTimeUtils.date(DateTime.now()), style: context.text.labelLarge),
                        ],
                      ),
                      const Divider(),
                      Row(
                        children: [
                          Icon(Icons.circle, size: 12.w,
                              color: onDuty ? context.appColors.success : context.appColors.mutedText),
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
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: _Body(orders: orders, profile: profile),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.orders, required this.profile});
  final RiderOrdersProvider orders;
  final RiderProfileProvider profile;

  @override
  Widget build(BuildContext context) {
    if (orders.isLoadingInitial) {
      return SizedBox(height: 300.h, child: const CommonLoadingWidget(skeleton: true));
    }
    if (orders.error != null) {
      return SizedBox(height: 300.h, child: CommonErrorState(message: orders.error!, onRetry: orders.refresh));
    }
    final issue = profile.locationIssue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (issue != null)
          Container(
            margin: EdgeInsets.only(bottom: AppSpacing.md),
            padding: EdgeInsets.all(AppSpacing.sm + 4),
            decoration: BoxDecoration(
              color: context.appColors.warning.withAlpha(36),
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
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
        GridView.count(
          crossAxisCount: ResponsiveUtils.gridColumns(context, compact: 2, wide: 4),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.45,
          children: [
            CommonStatTile(icon: Icons.inventory_2_outlined, value: '${orders.total}', label: 'Total', tone: StatusTone.info),
            CommonStatTile(icon: Icons.check_circle_outline, value: '${orders.completed}', label: 'Completed', tone: StatusTone.success),
            CommonStatTile(icon: Icons.schedule, value: '${orders.pending}', label: 'Pending', tone: StatusTone.warning),
            CommonStatTile(icon: Icons.error_outline, value: '${orders.failed}', label: 'Failed', tone: StatusTone.danger),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: Text("Today's Progress", style: context.text.titleMedium)),
            Text('${(orders.progress * 100).round()}%', style: context.text.titleMedium),
          ],
        ),
        SizedBox(height: AppSpacing.sm),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: orders.progress),
          duration: const Duration(milliseconds: 600),
          builder: (_, v, __) => ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 10.h,
              color: context.appColors.success,
              backgroundColor: context.appColors.surfaceSecondary,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text('${orders.completed} of ${orders.total} deliveries', style: context.text.bodySmall),
        SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _QuickAction(Icons.map_outlined, 'View Map', () => context.go(AppRoutes.riderMap)),
            _QuickAction(Icons.list_alt, 'Deliveries', () => context.go(AppRoutes.riderDeliveries)),
            _QuickAction(Icons.report_problem_outlined, 'Report Issue', () {
              final cur = orders.nextStop;
              if (cur == null) {
                context.showMessage('No active delivery to report.');
              } else {
                context.push(AppRoutes.riderException(cur.id));
              }
            }),
            _QuickAction(Icons.history, 'History', () => context.go(AppRoutes.riderHistory)),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        CommonCard(
          child: Row(
            children: [
              Expanded(
                child: _Cod('COD collected', CurrencyUtils.rs(orders.codCollectedToday), context.appColors.success),
              ),
              Container(width: 1, height: 40.h, color: context.appColors.border),
              Expanded(
                child: _Cod('COD to collect', CurrencyUtils.rs(orders.codToCollect), context.appColors.warning),
              ),
            ],
          ),
        ),
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
            Padding(padding: EdgeInsets.only(bottom: AppSpacing.sm), child: DeliveryCard(order: o)),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.input),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: context.scheme.primary.withAlpha(28),
                    borderRadius: BorderRadius.circular(AppRadius.input),
                  ),
                  child: Icon(icon, color: context.scheme.primary),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(label, style: context.text.labelSmall, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
}

class _Cod extends StatelessWidget {
  const _Cod(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value, style: context.text.titleMedium?.copyWith(color: color)),
          Text(label, style: context.text.bodySmall),
        ],
      );
}
