import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/core.dart';

/// One delivery row, reused by Home, Deliveries and History.
class DeliveryCard extends StatelessWidget {
  const DeliveryCard({super.key, required this.order});
  final DeliveryOrder order;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final tone = CommonStatusChip.orderTone(order.status).of(context);
    return CommonCard(
      onTap: () => context.push(AppRoutes.riderDelivery(order.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(color: tone.withAlpha(34), shape: BoxShape.circle),
                child: Icon(Icons.inventory_2_outlined, size: 20.w, color: tone),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('#${order.id}', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                    Text(order.customerName,
                        style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              CommonStatusChip.order(order.status),
            ],
          ),
          SizedBox(height: AppSpacing.sm + 2),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16.w, color: context.appColors.mutedText),
              SizedBox(width: 4.w),
              Expanded(
                child: Text('${order.area}, ${order.city}',
                    style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _Meta(Icons.schedule, DateTimeUtils.window(order.windowStart, order.windowEnd)),
              if (order.distanceKm > 0) _Meta(Icons.route_outlined, '${order.distanceKm.toStringAsFixed(1)} km'),
              if (order.status.isActive && order.etaMinutes != null)
                _Meta(Icons.timer_outlined, 'ETA ${order.etaMinutes} min'),
            ],
          ),
          SizedBox(height: AppSpacing.sm + 2),
          Row(
            children: [
              CommonStatusChip(
                label: order.isCod ? 'COD ${CurrencyUtils.rs(order.codAmount)}' : 'Prepaid',
                tone: order.isCod ? StatusTone.warning : StatusTone.neutral,
                icon: order.isCod ? Icons.payments_outlined : Icons.credit_score_outlined,
              ),
              if (order.stopNumber != null) ...[
                SizedBox(width: AppSpacing.sm),
                CommonStatusChip(label: 'Stop #${order.stopNumber}', tone: StatusTone.info),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.w, color: context.appColors.mutedText),
          SizedBox(width: 4.w),
          Text(text, style: context.text.bodySmall),
        ],
      );
}
