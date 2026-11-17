import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../../providers/admin_providers.dart';

class FleetTelemetryScreen extends StatelessWidget {
  const FleetTelemetryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<AdminDashboardProvider>();
    final c = context.appColors;
    final riders = dash.riders;
    final ratio = riders.isEmpty ? 0.0 : dash.activeFleet / riders.length;

    return Scaffold(
      appBar: const CommonAppBar(title: 'Live Fleet Telemetry'),
      body: RefreshIndicator(
        onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
        child: riders.isEmpty
            ? const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: CommonEmptyState(title: 'No Fleet', message: 'No riders found.'),
                ),
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(AppSpacing.screen),
                itemCount: riders.length + 1,
                itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.gap),
              child: SummaryCard(
                label: 'Riders on duty',
                value: '${dash.activeFleet} / ${riders.length}',
                badge: 'Live GPS tracking',
                child: ProgressBarBubble(value: ratio, color: AppColors.lightGreen),
              ),
            );
          }
          final r = riders[index - 1];
          final tone = r.isOnDuty ? c.success : c.mutedText;
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm + 4),
            child: CommonCard(
              child: Row(
                children: [
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(color: tone.withAlpha(34), shape: BoxShape.circle),
                    child: Icon(Icons.two_wheeler, color: tone, size: 22.w),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name, style: context.text.titleSmall),
                        Text('Vehicle: ${r.vehicleType} • Staff: ${r.staffId}', style: context.text.bodySmall),
                        SizedBox(height: 4.h),
                        Text(
                          r.isOnDuty ? 'On Duty (Active GPS Tracking)' : 'Off Duty',
                          style: context.text.labelSmall?.copyWith(color: tone, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (r.battery != null)
                        Row(
                          children: [
                            Icon(Icons.battery_full, size: 16.w, color: c.info),
                            SizedBox(width: 4.w),
                            Text('${r.battery}%', style: context.text.bodySmall),
                          ],
                        ),
                      if (r.speedKmh != null)
                        Text('${r.speedKmh!.toStringAsFixed(0)} km/h', style: context.text.labelSmall),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
  }
}
