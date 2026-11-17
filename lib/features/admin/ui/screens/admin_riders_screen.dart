import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../../providers/admin_providers.dart';

class AdminRidersScreen extends StatefulWidget {
  const AdminRidersScreen({super.key});

  @override
  State<AdminRidersScreen> createState() => _AdminRidersScreenState();
}

class _AdminRidersScreenState extends State<AdminRidersScreen> {
  String _searchQuery = '';
  DutyStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<AdminDashboardProvider>();
    final ordersProv = context.watch<AdminOrdersProvider>();
    final c = context.appColors;

    if (dash.isLoading) {
      return const Scaffold(
        appBar: CommonAppBar(title: 'Riders Management'),
        body: CommonLoadingWidget(),
      );
    }

    final allRiders = dash.riders;
    final allOrders = ordersProv.orders;

    final filteredRiders = allRiders.where((r) {
      final matchesSearch = _searchQuery.isEmpty ||
          r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.phone.contains(_searchQuery) ||
          r.staffId.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _statusFilter == null || r.dutyStatus == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Riders Management',
        subtitle: '${allRiders.length} Registered Couriers',
      ),
      body: RefreshIndicator(
        onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Fleet overview from the same rider list
                  Padding(
                    padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 0),
                    child: GlassCard(
                      blur: false,
                      padding: EdgeInsets.all(14.w),
                      child: DonutChart(
                        size: 96,
                        centerValue: '${allRiders.length}',
                        centerLabel: 'riders',
                        slices: [
                          DonutSlice('On duty', dash.activeFleet.toDouble(), AppColors.lightGreen),
                          DonutSlice('Off duty', (allRiders.length - dash.activeFleet).toDouble(), AppColors.orange),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(AppSpacing.screen),
                    child: CommonSearchField(
                      hint: 'Search riders by name, email, phone, staff ID...',
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                  SizedBox(
                    height: 38.h,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                      children: [
                        ChoiceChip(
                          label: const Text('All Riders'),
                          selected: _statusFilter == null,
                          onSelected: (_) => setState(() => _statusFilter = null),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        ChoiceChip(
                          label: const Text('On Duty'),
                          selected: _statusFilter == DutyStatus.onDuty,
                          onSelected: (_) => setState(() => _statusFilter = DutyStatus.onDuty),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        ChoiceChip(
                          label: const Text('Off Duty'),
                          selected: _statusFilter == DutyStatus.offDuty,
                          onSelected: (_) => setState(() => _statusFilter = DutyStatus.offDuty),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
            if (filteredRiders.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.only(top: 40, bottom: 60),
                  child: CommonEmptyState(
                    title: 'No Registered Riders',
                    message: 'No riders found matching your filter criteria.',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.screen),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final r = filteredRiders[index];
                      final assignedOrders = allOrders.where((o) => o.riderId == r.id).toList();
                      final activeOrders = assignedOrders.where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.failed).toList();
                      final completedOrders = assignedOrders.where((o) => o.status == OrderStatus.delivered).toList();

                      final statusColor = r.dutyStatus == DutyStatus.onDuty ? c.success : c.warning;

                      return Container(
                        margin: EdgeInsets.only(bottom: AppSpacing.sm),
                        child: CommonCard(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => _RiderDetailSheet(
                                rider: r,
                                assignedOrders: assignedOrders,
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24.r,
                                    backgroundColor: statusColor.withAlpha(30),
                                    child: Icon(Icons.two_wheeler, color: statusColor, size: 24.w),
                                  ),
                                  SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(r.name, style: context.text.titleSmall),
                                            SizedBox(width: 6.w),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                              decoration: BoxDecoration(
                                                color: c.mutedText.withAlpha(30),
                                                borderRadius: BorderRadius.circular(4.r),
                                              ),
                                              child: Text('#${r.staffId}', style: context.text.labelSmall),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 2.h),
                                        Text(r.email, style: context.text.bodySmall),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color: statusColor.withAlpha(30),
                                      borderRadius: BorderRadius.circular(AppRadius.chip),
                                    ),
                                    child: Text(
                                      r.dutyStatus.name.toUpperCase(),
                                      style: context.text.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.phone_outlined, size: 16.w, color: c.mutedText),
                                      SizedBox(width: 4.w),
                                      Text(r.phone, style: context.text.bodySmall),
                                    ],
                                  ),
                                  if (r.vehicleType.isNotEmpty)
                                    Row(
                                      children: [
                                        Icon(Icons.directions_bike, size: 16.w, color: c.mutedText),
                                        SizedBox(width: 4.w),
                                        Text('${r.vehicleType} (${r.vehicleReg})', style: context.text.bodySmall),
                                      ],
                                    ),
                                ],
                              ),
                              SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.all(8.w),
                                      decoration: BoxDecoration(
                                        color: c.info.withAlpha(20),
                                        borderRadius: BorderRadius.circular(AppRadius.chip),
                                      ),
                                      child: Column(
                                        children: [
                                          Text('${activeOrders.length}', style: context.text.titleSmall?.copyWith(color: c.info)),
                                          Text('Active Orders', style: context.text.labelSmall),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.all(8.w),
                                      decoration: BoxDecoration(
                                        color: c.success.withAlpha(20),
                                        borderRadius: BorderRadius.circular(AppRadius.chip),
                                      ),
                                      child: Column(
                                        children: [
                                          Text('${completedOrders.length}', style: context.text.titleSmall?.copyWith(color: c.success)),
                                          Text('Completed', style: context.text.labelSmall),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: (index * 50).ms);
                    },
                    childCount: filteredRiders.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RiderDetailSheet extends StatelessWidget {
  const _RiderDetailSheet({required this.rider, required this.assignedOrders});
  final Rider rider;
  final List<DeliveryOrder> assignedOrders;

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.scheme.primary;

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Rider Details', style: context.text.titleLarge),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            SizedBox(height: AppSpacing.md),

            // Profile Header
            Row(
              children: [
                CircleAvatar(
                  radius: 32.r,
                  backgroundColor: primaryColor.withAlpha(30),
                  child: Text(
                    rider.name.isNotEmpty ? rider.name[0].toUpperCase() : 'R',
                    style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rider.name, style: context.text.titleMedium),
                      Text('Staff ID: #${rider.staffId}', style: context.text.bodySmall),
                      Text(rider.email, style: context.text.bodySmall),
                      Text(rider.phone, style: context.text.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.phone_rounded, color: context.appColors.success),
                  onPressed: () => LauncherService.call(rider.phone),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),

            // Vehicle & Duty
            CommonCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Duty Availability', style: context.text.bodyMedium),
                      Text(rider.dutyStatus.name.toUpperCase(), style: context.text.titleSmall),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Vehicle', style: context.text.bodyMedium),
                      Text('${rider.vehicleType} (${rider.vehicleReg})', style: context.text.titleSmall),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.md),

            // Assigned Orders History
            Text('Assigned Orders History (${assignedOrders.length})', style: context.text.titleSmall),
            SizedBox(height: AppSpacing.xs),
            if (assignedOrders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No orders assigned to this rider yet.'),
              )
            else
              ...assignedOrders.map((o) => Container(
                margin: EdgeInsets.only(bottom: AppSpacing.xs),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.inventory_2_outlined, color: primaryColor),
                  title: Text('Order #${o.id} • ${o.customerName}'),
                  subtitle: Text(o.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: CommonStatusChip.order(o.status),
                  onTap: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.adminOrder(o.id));
                  },
                ),
              )),
          ],
        ),
      ),
    );
  }
}
