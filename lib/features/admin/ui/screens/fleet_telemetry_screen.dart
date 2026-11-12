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

    return Scaffold(
      appBar: const CommonAppBar(title: 'Live Fleet Telemetry'),
      body: dash.riders.isEmpty
          ? const CommonEmptyState(title: 'No Fleet', message: 'No riders found.')
          : ListView.builder(
              padding: EdgeInsets.all(AppSpacing.md),
              itemCount: dash.riders.length,
              itemBuilder: (context, index) {
                final r = dash.riders[index];
                return Container(
                  margin: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: CommonCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: r.isOnDuty ? c.success : c.mutedText,
                          child: const Icon(Icons.two_wheeler, color: Colors.white),
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
                                style: context.text.labelSmall?.copyWith(
                                  color: r.isOnDuty ? c.success : c.mutedText,
                                  fontWeight: FontWeight.bold,
                                ),
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
    );
  }
}
