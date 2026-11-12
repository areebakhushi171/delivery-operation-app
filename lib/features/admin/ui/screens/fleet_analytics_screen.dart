import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../../providers/admin_providers.dart';

class FleetAnalyticsScreen extends StatelessWidget {
  const FleetAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<AdminDashboardProvider>();
    final c = context.appColors;

    final inTransitCount = dash.orders.where((o) => o.status == OrderStatus.outForDelivery || o.status == OrderStatus.pickedUp).length;
    final totalCompleted = dash.completedOrders;
    final totalFailed = dash.failedOrders;
    final totalPending = dash.pendingOrders;
    final deliverySuccessRate = (totalCompleted + totalFailed == 0)
        ? 0.0
        : (totalCompleted / (totalCompleted + totalFailed)) * 100.0;

    return Scaffold(
      appBar: const CommonAppBar(title: 'Fleet Analytics & Reports'),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          const CommonSectionHeader('Operational KPI Summary'),
          SizedBox(height: AppSpacing.xs),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.5,
            children: [
              CommonStatTile(
                icon: Icons.local_shipping_rounded,
                value: '${dash.totalOrders}',
                label: 'Total Orders',
                tone: StatusTone.info,
              ),
              CommonStatTile(
                icon: Icons.check_circle_rounded,
                value: '$totalCompleted',
                label: 'Delivered',
                tone: StatusTone.success,
              ),
              CommonStatTile(
                icon: Icons.directions_bike_rounded,
                value: '$inTransitCount',
                label: 'In Transit',
                tone: StatusTone.info,
              ),
              CommonStatTile(
                icon: Icons.cancel_rounded,
                value: '$totalFailed',
                label: 'Failed Deliveries',
                tone: StatusTone.danger,
              ),
              CommonStatTile(
                icon: Icons.two_wheeler_rounded,
                value: '${dash.riders.length}',
                label: 'Total Riders',
                tone: StatusTone.info,
              ),
              CommonStatTile(
                icon: Icons.verified_user_rounded,
                value: '${dash.activeFleet}',
                label: 'Active On Duty',
                tone: StatusTone.success,
              ),
              CommonStatTile(
                icon: Icons.payments_rounded,
                value: CurrencyUtils.rs(dash.codCollected),
                label: 'COD Realized',
                tone: StatusTone.warning,
              ),
              CommonStatTile(
                icon: Icons.thumb_up_rounded,
                value: '${deliverySuccessRate.toStringAsFixed(1)}%',
                label: 'Success Rate',
                tone: StatusTone.success,
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          SizedBox(height: AppSpacing.lg),

          // Order Pipeline Distribution Chart
          const CommonSectionHeader('Order Pipeline Distribution'),
          SizedBox(height: AppSpacing.xs),
          CommonCard(
            child: SizedBox(
              height: 220.h,
              child: dash.totalOrders == 0
                  ? const Center(child: Text('No orders recorded yet.'))
                  : PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 40.r,
                        sections: [
                          PieChartSectionData(
                            color: c.success,
                            value: totalCompleted.toDouble(),
                            title: '$totalCompleted',
                            radius: 50.r,
                            titleStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          PieChartSectionData(
                            color: c.info,
                            value: inTransitCount.toDouble(),
                            title: '$inTransitCount',
                            radius: 50.r,
                            titleStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          PieChartSectionData(
                            color: c.warning,
                            value: totalPending.toDouble(),
                            title: '$totalPending',
                            radius: 50.r,
                            titleStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          PieChartSectionData(
                            color: c.danger,
                            value: totalFailed.toDouble(),
                            title: '$totalFailed',
                            radius: 50.r,
                            titleStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
            ),
          ).animate().fadeIn(duration: 500.ms),
          SizedBox(height: AppSpacing.lg),

          const CommonSectionHeader('SLA Performance Overview'),
          SizedBox(height: AppSpacing.xs),
          CommonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('On-Time Delivery SLA Rate', style: context.text.titleSmall),
                    Text(
                      '${dash.slaSuccessRate.toStringAsFixed(1)}%',
                      style: context.text.titleMedium?.copyWith(color: c.success, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.sm),
                LinearProgressIndicator(
                  value: (dash.slaSuccessRate / 100.0).clamp(0.0, 1.0),
                  backgroundColor: c.border,
                  color: c.success,
                  minHeight: 8.h,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Calculated from eligible completed orders delivered within promised window deadline.',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 600.ms),
        ],
      ),
    );
  }
}
