import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/core.dart';
import '../../../deliveries/providers/rider_orders_provider.dart';

class DeliveryDetailsScreen extends StatelessWidget {
  const DeliveryDetailsScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<RiderOrdersProvider>();
    final o = orders.byId(orderId);
    if (orders.isLoadingInitial) {
      return const Scaffold(appBar: CommonAppBar(title: 'Delivery Details'), body: CommonLoadingWidget());
    }
    if (o == null) {
      return const Scaffold(
        appBar: CommonAppBar(title: 'Delivery Details'),
        body: CommonErrorState(message: 'This delivery was not found or is no longer assigned to you.'),
      );
    }
    final t = context.text;
    return Scaffold(
      appBar: CommonAppBar(title: 'Delivery Details', subtitle: '#${o.id}'),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          CommonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CommonProfileAvatar(name: o.customerName, size: 52),
                    SizedBox(width: AppSpacing.sm + 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.customerName, style: t.titleLarge),
                          Text(o.customerPhone, style: t.bodySmall),
                        ],
                      ),
                    ),
                    CommonStatusChip.order(o.status),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: CommonButton(
                        label: 'Call',
                        icon: Icons.call,
                        onPressed: () async {
                          if (!await LauncherService.call(o.customerPhone) && context.mounted) {
                            context.showMessage('Cannot open the phone app.', isError: true);
                          }
                        },
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: CommonButton(
                        label: 'Message',
                        icon: Icons.sms_outlined,
                        variant: CommonButtonVariant.secondary,
                        onPressed: () async {
                          if (!await LauncherService.sms(o.customerPhone) && context.mounted) {
                            context.showMessage('Cannot open messages.', isError: true);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          CommonCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined, color: context.scheme.primary),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Delivery address', style: t.labelMedium),
                      Text(o.fullAddress, style: t.bodyMedium),
                      SizedBox(height: AppSpacing.xs),
                      Text('Window: ${DateTimeUtils.window(o.windowStart, o.windowEnd)}', style: t.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          CommonSectionHeader('Order Items'),
          CommonCard(
            child: Column(
              children: [
                for (final it in o.items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.shopping_bag_outlined),
                    title: Text(it.name),
                    trailing: Text('x${it.quantity}', style: t.titleSmall),
                  ),
              ],
            ),
          ),
          if (o.instructions.isNotEmpty) ...[
            CommonSectionHeader('Delivery Notes'),
            CommonCard(child: Text('"${o.instructions}"', style: t.bodyMedium)),
          ],
          CommonSectionHeader('Payment'),
          CommonCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payment type', style: t.labelMedium),
                      Text(o.paymentType.label, style: t.titleMedium),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(o.isCod ? 'Amount to collect' : 'Amount paid', style: t.labelMedium),
                    Text(CurrencyUtils.rs(o.amount), style: t.titleMedium),
                    if (o.isCod && o.codCollected)
                      CommonStatusChip(label: 'Collected', tone: StatusTone.success),
                  ],
                ),
              ],
            ),
          ),
          CommonSectionHeader('Delivery Timeline'),
          CommonCard(child: _Timeline(order: o)),
        ],
      ),
      bottomNavigationBar: !o.status.isActive
          ? null
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: CommonButton(
                        label: 'Update Status',
                        onPressed: () => context.push(AppRoutes.riderStatus(o.id)),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: CommonButton(
                        label: 'Report Exception',
                        variant: CommonButtonVariant.secondary,
                        onPressed: () => context.push(AppRoutes.riderException(o.id)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.order});
  final DeliveryOrder order;

  static const _steps = [
    OrderStatus.assigned,
    OrderStatus.pickedUp,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      children: [
        for (final s in _steps)
          Builder(builder: (_) {
            final at = order.timeOf(s);
            final done = at != null;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: done ? c.success : c.mutedText),
              title: Text(s.label, style: context.text.titleSmall),
              trailing: Text(done ? DateTimeUtils.time(at) : '-', style: context.text.bodySmall),
            );
          }),
        if (order.status == OrderStatus.failed)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.cancel, color: c.danger),
            title: Text('Failed', style: context.text.titleSmall?.copyWith(color: c.danger)),
            subtitle: Text(order.history.isNotEmpty ? (order.history.last.note ?? '') : ''),
            trailing: Text(order.failedAt == null ? '-' : DateTimeUtils.time(order.failedAt!),
                style: context.text.bodySmall),
          ),
      ],
    );
  }
}
