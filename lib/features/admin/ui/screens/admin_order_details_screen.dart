import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../../providers/admin_providers.dart';

class AdminOrderDetailsScreen extends StatelessWidget {
  const AdminOrderDetailsScreen({super.key, required this.orderId});

  final String orderId;

  Future<void> _cancelOrder(BuildContext context, String id) async {
    final confirmed = await CommonConfirmationDialog.show(
      context,
      title: 'Cancel Order',
      message: 'Are you sure you want to cancel Order #$id?',
      confirmLabel: 'Cancel Order',
      destructive: true,
    );

    if (confirmed && context.mounted) {
      try {
        await context.read<AdminOrdersProvider>().cancelOrder(id, 'admin-uid', 'Cancelled by Admin');
        if (context.mounted) {
          context.showMessage('Order #$id has been cancelled.', isSuccess: true);
        }
      } catch (e) {
        if (context.mounted) {
          context.showMessage('Failed to cancel order: $e', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminOrdersProvider>();
    final c = context.appColors;
    final primaryColor = context.scheme.primary;

    final orderList = prov.orders;
    final o = orderList.firstWhere(
      (order) => order.id == orderId,
      orElse: () => DeliveryOrder(
        id: orderId,
        customerName: 'Unknown',
        customerPhone: '',
        address: 'Not found',
        city: '',
        area: '',
        windowStart: DateTime.now(),
        windowEnd: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );

    final assignedRider = prov.riders.firstWhere(
      (r) => r.id == o.riderId,
      orElse: () => Rider(id: '', staffId: '', name: 'Unassigned', phone: '', email: ''),
    );

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Order Details',
        subtitle: '#${o.id}',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Card
            CommonCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order #${o.id}', style: context.text.titleMedium),
                      SizedBox(height: 4.h),
                      Text('Created ${DateTimeUtils.date(o.createdAt)}', style: context.text.bodySmall),
                    ],
                  ),
                  CommonStatusChip.order(o.status),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.md),

            // Customer Details Card
            const CommonSectionHeader('Customer Information'),
            SizedBox(height: AppSpacing.xs),
            CommonCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: primaryColor.withAlpha(30),
                        child: Icon(Icons.person, color: primaryColor),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.customerName, style: context.text.titleSmall),
                            Text(o.customerPhone, style: context.text.bodySmall),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.phone_rounded, color: context.appColors.success),
                        onPressed: () => LauncherService.call(o.customerPhone),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: c.mutedText, size: 20.w),
                      SizedBox(width: AppSpacing.xs),
                      Expanded(child: Text(o.address, style: context.text.bodyMedium)),
                    ],
                  ),
                  if (o.instructions.isNotEmpty) ...[
                    SizedBox(height: AppSpacing.xs),
                    Text('Notes: ${o.instructions}', style: context.text.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
            SizedBox(height: AppSpacing.md),

            // Assigned Rider Card
            const CommonSectionHeader('Rider Assignment'),
            SizedBox(height: AppSpacing.xs),
            CommonCard(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: assignedRider.id.isNotEmpty ? c.success.withAlpha(30) : c.mutedText.withAlpha(30),
                    child: Icon(Icons.two_wheeler, color: assignedRider.id.isNotEmpty ? c.success : c.mutedText),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(assignedRider.name, style: context.text.titleSmall),
                        Text(assignedRider.id.isNotEmpty ? 'Staff ID: ${assignedRider.staffId} • ${assignedRider.phone}' : 'No rider assigned',
                            style: context.text.bodySmall),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => _AssignRiderSheet(orderId: o.id, riders: prov.riders),
                      );
                    },
                    child: Text(o.riderId != null ? 'Reassign' : 'Assign'),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.md),

            // Payment Details
            const CommonSectionHeader('Payment Summary'),
            SizedBox(height: AppSpacing.xs),
            CommonCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Payment Type', style: context.text.bodyMedium),
                      Text(o.paymentType.name.toUpperCase(), style: context.text.titleSmall),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Amount', style: context.text.bodyMedium),
                      Text(CurrencyUtils.rs(o.amount), style: context.text.titleMedium?.copyWith(color: primaryColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.md),

            // Proof of Delivery Photo (If Delivered)
            if (o.proof != null) ...[
              const CommonSectionHeader('Proof of Delivery'),
              SizedBox(height: AppSpacing.xs),
              CommonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (o.proof!.photoPath.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.input),
                        child: ProofImage(path: o.proof!.photoPath),
                      ),
                      SizedBox(height: AppSpacing.sm),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Received By', style: context.text.bodySmall),
                        Text(o.proof!.recipientName, style: context.text.titleSmall),
                      ],
                    ),
                    if (o.proof!.notes != null && o.proof!.notes!.isNotEmpty) ...[
                      SizedBox(height: AppSpacing.xs),
                      Text('Notes: ${o.proof!.notes}', style: context.text.bodySmall),
                    ],
                    SizedBox(height: AppSpacing.xs),
                    Text('Delivered At: ${DateTimeUtils.date(o.proof!.submittedAt)} ${DateTimeUtils.time(o.proof!.submittedAt)}',
                        style: context.text.bodySmall?.copyWith(color: c.success)),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.md),
            ],

            // Delivery Timeline / Audit Log
            if (o.history.isNotEmpty) ...[
              const CommonSectionHeader('Delivery Timeline'),
              SizedBox(height: AppSpacing.xs),
              CommonCard(
                child: Column(
                  children: o.history.map((entry) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.check_circle_outline, color: c.success, size: 20.w),
                      title: Text(entry.status.label, style: context.text.titleSmall),
                      subtitle: Text('${DateTimeUtils.date(entry.at)} ${DateTimeUtils.time(entry.at)}${entry.note != null ? ' • ${entry.note}' : ''}'),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: AppSpacing.md),
            ],

            // Cancel Order Action Button
            if (o.status != OrderStatus.delivered && o.status != OrderStatus.failed) ...[
              CommonButton(
                label: 'Cancel Order',
                icon: Icons.cancel_outlined,
                variant: CommonButtonVariant.danger,
                onPressed: () => _cancelOrder(context, o.id),
              ),
              SizedBox(height: AppSpacing.md),
            ],
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
