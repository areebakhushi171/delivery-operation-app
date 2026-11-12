import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/core.dart';
import '../../../deliveries/providers/rider_orders_provider.dart';
import '../../providers/rider_actions_provider.dart';

class UpdateStatusScreen extends StatefulWidget {
  const UpdateStatusScreen({super.key, required this.orderId});
  final String orderId;

  @override
  State<UpdateStatusScreen> createState() => _UpdateStatusScreenState();
}

class _UpdateStatusScreenState extends State<UpdateStatusScreen> {
  ActionOutcome? _outcome;
  OrderStatus? _appliedTo;

  Future<void> _confirm(DeliveryOrder o) async {
    final next = o.status.next!;
    final ok = await CommonConfirmationDialog.show(
      context,
      title: 'Mark as ${next.label}?',
      message: 'This will update the status for order #${o.id}.',
    );
    if (!ok || !mounted) return;
    final actions = context.read<RiderActionsProvider>();
    final res = await actions.advanceStatus(o);
    if (!mounted) return;
    if (res == null) {
      context.showMessage(actions.error ?? 'Could not update status', isError: true);
    } else {
      setState(() {
        _outcome = res;
        _appliedTo = next;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = context.watch<RiderOrdersProvider>().byId(widget.orderId);
    final busy = context.watch<RiderActionsProvider>().isBusy;
    if (o == null) {
      return const Scaffold(
        appBar: CommonAppBar(title: 'Update Status'),
        body: CommonErrorState(message: 'Delivery not found.'),
      );
    }
    final next = o.status.next;
    final c = context.appColors;

    Widget body;
    if (_outcome != null) {
      final done = _outcome == ActionOutcome.done;
      body = _Message(
        icon: done ? Icons.check_circle : Icons.cloud_upload_outlined,
        color: done ? c.success : c.warning,
        title: done ? 'Status Updated!' : 'Saved offline',
        message: done
            ? 'Order #${o.id} is now ${_appliedTo?.label ?? o.status.label}.'
            : AppStrings.offlineQueued,
        action: CommonButton(label: 'Done', onPressed: () => context.pop()),
      );
    } else if (next == null) {
      body = _Message(
        icon: Icons.info_outline,
        color: c.info,
        title: 'No further steps',
        message: 'Order #${o.id} is ${o.status.label}.',
        action: CommonButton(label: 'Back', onPressed: () => context.pop()),
      );
    } else if (next == OrderStatus.delivered) {
      body = _Message(
        icon: Icons.photo_camera_outlined,
        color: context.scheme.primary,
        title: 'Complete delivery',
        message: 'Delivering order #${o.id} needs a photo as proof of delivery.',
        action: Column(
          children: [
            CommonButton(
              label: 'Continue to Proof of Delivery',
              onPressed: () => context.pushReplacement(AppRoutes.riderProof(o.id)),
            ),
            SizedBox(height: AppSpacing.sm),
            CommonButton(label: 'Cancel', variant: CommonButtonVariant.secondary, onPressed: () => context.pop()),
          ],
        ),
      );
    } else {
      body = _Message(
        icon: Icons.local_shipping_outlined,
        color: context.scheme.primary,
        title: 'Mark as ${next.label}?',
        message: 'Current status: ${o.status.label}.\nThis will update the status for order #${o.id}.',
        action: Column(
          children: [
            CommonButton(label: 'Confirm', isLoading: busy, onPressed: () => _confirm(o)),
            SizedBox(height: AppSpacing.sm),
            CommonButton(
              label: 'Cancel',
              variant: CommonButtonVariant.secondary,
              onPressed: busy ? null : () => context.pop(),
            ),
          ],
        ),
      );
    }
    return Scaffold(appBar: const CommonAppBar(title: 'Update Status'), body: body);
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.action,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(color: color.withAlpha(30), shape: BoxShape.circle),
                child: Icon(icon, size: 56.w, color: color),
              ),
              SizedBox(height: AppSpacing.lg),
              Text(title, textAlign: TextAlign.center, style: context.text.headlineSmall),
              SizedBox(height: AppSpacing.sm),
              Text(message, textAlign: TextAlign.center, style: context.text.bodyMedium),
              SizedBox(height: AppSpacing.xl),
              action,
            ],
          ),
        ),
      );
}
