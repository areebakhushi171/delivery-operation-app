import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../../../../core/utils/scroll_reset.dart';
import '../../../../widgets/swipe_action_card.dart';
import '../../providers/admin_providers.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> with ScrollResetMixin {
  @override
  void initState() {
    super.initState();
    ScrollResetRegistry.register(1, scrollController);
  }

  @override
  void dispose() {
    ScrollResetRegistry.unregister(1);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminOrdersProvider>();
    final dash = context.watch<AdminDashboardProvider>();

    if (prov.isLoading) {
      return const Scaffold(appBar: CommonAppBar(title: 'Orders Management'), body: CommonLoadingWidget());
    }

    return Scaffold(
      appBar: const CommonAppBar(
        title: 'Orders Management',
      ),
      body: RefreshIndicator(
        onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
        child: CustomScrollView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Status overview (counts come from the dashboard provider streams)
                  Padding(
                    padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 0),
                    child: GlassCard(
                      blur: false,
                      padding: EdgeInsets.all(14.w),
                      child: DonutChart(
                        size: 104,
                        centerValue: '${dash.totalOrders}',
                        centerLabel: 'orders',
                        slices: [
                          DonutSlice('Pending', dash.pendingOrders.toDouble(), AppColors.orange),
                          DonutSlice('In transit', dash.orders.where((o) => o.status == OrderStatus.pickedUp || o.status == OrderStatus.outForDelivery).length.toDouble(), context.scheme.primary),
                          DonutSlice('Delivered', dash.completedOrders.toDouble(), AppColors.lightGreen),
                          DonutSlice('Failed', dash.failedOrders.toDouble(), AppColors.pink),
                        ],
                      ),
                    ),
                  ),
                  // Search + Create Order button
                  Padding(
                    padding: EdgeInsets.all(AppSpacing.screen),
                    child: Row(
                      children: [
                        Expanded(
                          child: CommonSearchField(
                            hint: 'Search by Order ID, customer, address...',
                            onChanged: prov.setSearch,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        GlassCircleButton(
                          icon: Icons.add_rounded,
                          size: 52,
                          filled: true,
                          tooltip: 'Create Order',
                          onTap: () => context.push(AppRoutes.adminCreateOrder),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 40.h,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                      children: [
                        ChoiceChip(
                          label: const Text('All Status'),
                          selected: prov.statusFilter == null,
                          onSelected: (_) => prov.setStatusFilter(null),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        ChoiceChip(
                          label: const Text('Assigned'),
                          selected: prov.statusFilter == OrderStatus.assigned,
                          onSelected: (_) => prov.setStatusFilter(OrderStatus.assigned),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        ChoiceChip(
                          label: const Text('Delivered'),
                          selected: prov.statusFilter == OrderStatus.delivered,
                          onSelected: (_) => prov.setStatusFilter(OrderStatus.delivered),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        ChoiceChip(
                          label: const Text('Failed'),
                          selected: prov.statusFilter == OrderStatus.failed,
                          onSelected: (_) => prov.setStatusFilter(OrderStatus.failed),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
            if (prov.orders.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.only(top: 40, bottom: 60),
                  child: CommonEmptyState(title: 'No Orders', message: 'No orders found matching criteria.'),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.screen),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final o = prov.orders[index];
                      final assignedRider = prov.riders.firstWhere(
                        (r) => r.id == o.riderId,
                        orElse: () => Rider(id: '', staffId: '', name: 'Unassigned', phone: '', email: ''),
                      );

                      final canCancel = !o.status.isClosed;

                      final startActions = [
                        SwipeAction(
                          icon: Icons.visibility_rounded,
                          label: 'View',
                          color: const Color(0xFF3B82F6),
                          onTap: () => context.push(AppRoutes.adminOrder(o.id)),
                        ),
                      ];

                      final endActions = <SwipeAction>[];
                      if (canCancel) {
                        endActions.add(
                          SwipeAction(
                            icon: Icons.close_rounded,
                            label: 'Cancel',
                            color: const Color(0xFFEF4444),
                            onTap: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Cancel Order'),
                                  content: Text('Are you sure you want to cancel order #${o.id}?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, Cancel')),
                                  ],
                                ),
                              );
                              if (confirmed == true && context.mounted) {
                                await context.read<AdminOrdersProvider>().cancelOrder(o.id, 'admin-uid', 'Cancelled by Admin');
                                if (context.mounted) {
                                  context.showMessage('Order #${o.id} cancelled successfully.', isSuccess: true);
                                }
                              }
                            },
                          ),
                        );
                      }

                      return SwipeActionCard(
                        key: ValueKey(o.id),
                        startActions: startActions,
                        endActions: endActions,
                        child: Container(
                          margin: EdgeInsets.only(bottom: AppSpacing.sm),
                          child: CommonCard(
                            onTap: () => context.push(AppRoutes.adminOrder(o.id)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Order #${o.id}', style: context.text.titleSmall),
                                    CommonStatusChip.order(o.status),
                                  ],
                                ),
                                SizedBox(height: AppSpacing.xs),
                                Text(o.customerName, style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                                Text(o.address, style: context.text.bodySmall),
                                SizedBox(height: AppSpacing.sm),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${o.paymentType.name.toUpperCase()}: ${CurrencyUtils.rs(o.amount)}',
                                        style: context.text.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Flexible(
                                      child: TextButton(
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            builder: (_) => _AssignRiderSheet(orderId: o.id, riders: prov.riders),
                                          );
                                        },
                                        child: Text(
                                          o.riderId != null ? 'Reassign (${assignedRider.name})' : 'Assign Rider',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: prov.orders.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AssignRiderSheet extends StatelessWidget {
  const _AssignRiderSheet({required this.orderId, required this.riders});
  final String orderId;
  final List<Rider> riders;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Assign Rider to Order #$orderId', style: context.text.titleLarge),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: riders.length,
              itemBuilder: (context, index) {
                final r = riders[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.two_wheeler)),
                  title: Text(r.name),
                  subtitle: Text('ID: ${r.id} • ${r.vehicleType} • ${r.dutyStatus.name}'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      await context.read<AdminOrdersProvider>().assignRider(orderId, r.id, 'admin-uid');
                      if (context.mounted) {
                        Navigator.pop(context);
                        context.showMessage('Successfully assigned to ${r.name}', isSuccess: true);
                      }
                    },
                    child: const Text('Assign'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}