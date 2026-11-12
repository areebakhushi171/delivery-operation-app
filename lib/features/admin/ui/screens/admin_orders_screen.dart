import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../../providers/admin_providers.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminOrdersProvider>();

    if (prov.isLoading) {
      return const Scaffold(appBar: CommonAppBar(title: 'Orders Management'), body: CommonLoadingWidget());
    }

    return Scaffold(
      appBar: const CommonAppBar(
        title: 'Orders Management',
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: CommonSearchField(
              hint: 'Search by Order ID, customer, address...',
              onChanged: prov.setSearch,
            ),
          ),
          SizedBox(
            height: 40.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
          Expanded(
            child: prov.orders.isEmpty
                ? const CommonEmptyState(title: 'No Orders', message: 'No orders found matching criteria.')
                : ListView.builder(
                    padding: EdgeInsets.all(AppSpacing.md),
                    itemCount: prov.orders.length,
                    itemBuilder: (context, index) {
                      final o = prov.orders[index];
                      final assignedRider = prov.riders.firstWhere(
                        (r) => r.id == o.riderId,
                        orElse: () => Rider(id: '', staffId: '', name: 'Unassigned', phone: '', email: ''),
                      );
                      return Slidable(
                        key: ValueKey(o.id),
                        startActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) => context.push(AppRoutes.adminOrder(o.id)),
                              backgroundColor: context.scheme.primary,
                              foregroundColor: Colors.white,
                              icon: Icons.visibility_outlined,
                              label: 'View',
                            ),
                          ],
                        ),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (_) => _AssignRiderSheet(orderId: o.id, riders: prov.riders),
                                );
                              },
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              icon: Icons.two_wheeler,
                              label: 'Assign',
                            ),
                            SlidableAction(
                              onPressed: (_) async {
                                await context.read<AdminOrdersProvider>().cancelOrder(o.id, 'admin-uid', 'Cancelled by Admin');
                              },
                              backgroundColor: context.appColors.danger,
                              foregroundColor: Colors.white,
                              icon: Icons.cancel_outlined,
                              label: 'Cancel',
                            ),
                          ],
                        ),
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
                  ),
          ),
        ],
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
