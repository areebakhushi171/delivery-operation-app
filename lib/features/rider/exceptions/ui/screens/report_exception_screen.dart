import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/core.dart';
import '../../../deliveries/providers/rider_orders_provider.dart';
import '../../../profile/providers/rider_profile_provider.dart';
import '../../../update_status/providers/rider_actions_provider.dart';
import '../../../../authentication/providers/auth_provider.dart';

class ReportExceptionScreen extends StatefulWidget {
  const ReportExceptionScreen({super.key, required this.orderId});
  final String orderId;

  @override
  State<ReportExceptionScreen> createState() => _ReportExceptionScreenState();
}

class _ReportExceptionScreenState extends State<ReportExceptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  // Stable id for this report => safe retries / offline replays (idempotent).
  final String _exceptionId = 'EX-${const Uuid().v4().substring(0, 8)}';
  ExceptionReason _reason = ExceptionReason.customerNotAvailable;
  String? _photo;
  bool _reschedule = false;
  DateTime? _rescheduleAt;
  ActionOutcome? _outcome;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 14)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 2))));
    if (t == null) return;
    setState(() => _rescheduleAt = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _submit(DeliveryOrder o) async {
    KeyboardUtils.dismiss(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_reschedule && _rescheduleAt == null) {
      context.showMessage('Pick a reschedule date and time.', isError: true);
      return;
    }
    final ok = await CommonConfirmationDialog.show(
      context,
      title: 'Submit exception report?',
      message: 'Order #${o.id} will be marked Failed and sent to dispatch for triage.',
      confirmLabel: 'Submit',
    );
    if (!ok || !mounted) return;
    final rider = context.read<RiderProfileProvider>().rider;
    final user = context.read<AuthProvider>().user;
    final actions = context.read<RiderActionsProvider>();
    final res = await actions.reportException(
      DeliveryException(
        id: _exceptionId,
        orderId: o.id,
        customerName: o.customerName,
        riderId: user?.uid ?? '',
        riderName: rider?.name ?? user?.name ?? '',
        riderStaffId: rider?.staffId ?? user?.staffId ?? '',
        reason: _reason,
        description: _descCtrl.text.trim(),
        codAmount: o.isCod ? o.codAmount : 0,
        reportedAt: DateTime.now(),
        photoPath: _photo,
        rescheduleRequestedAt: _reschedule ? _rescheduleAt : null,
      ),
    );
    if (!mounted) return;
    if (res == null) {
      context.showMessage(actions.error ?? 'Could not submit report', isError: true);
    } else {
      setState(() => _outcome = res);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = context.watch<RiderOrdersProvider>().byId(widget.orderId);
    final busy = context.watch<RiderActionsProvider>().isBusy;
    if (o == null && _outcome == null) {
      return const Scaffold(appBar: CommonAppBar(title: 'Report Exception'), body: CommonErrorState(message: 'Delivery not found.'));
    }
    final c = context.appColors;
    if (_outcome != null) {
      final done = _outcome == ActionOutcome.done;
      return Scaffold(
        appBar: const CommonAppBar(title: 'Report Exception'),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(done ? Icons.check_circle : Icons.cloud_upload_outlined, size: 80, color: done ? c.success : c.warning),
                SizedBox(height: AppSpacing.md),
                Text(done ? 'Report sent to dispatch' : 'Saved offline', style: context.text.headlineSmall),
                SizedBox(height: AppSpacing.sm),
                Text(done ? 'Dispatch will triage this and update you.' : AppStrings.offlineQueued,
                    textAlign: TextAlign.center, style: context.text.bodyMedium),
                SizedBox(height: AppSpacing.xl),
                CommonButton(label: 'Back to deliveries', onPressed: () => context.go(AppRoutes.riderDeliveries)),
              ],
            ),
          ),
        ),
      );
    }
    final order = o!;
    return KeyboardDismissOnTap(
      child: Scaffold(
        appBar: CommonAppBar(title: 'Report Exception', subtitle: '#${order.id}'),
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, KeyboardUtils.bottomInset(context, 96)),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RequiredFieldLabel('Select reason'),
                SizedBox(height: AppSpacing.sm),
                for (final r in ExceptionReason.values)
                  Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.xs),
                    child: CommonCard(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      onTap: busy ? null : () => setState(() => _reason = r),
                      child: Row(
                        children: [
                          Icon(AppIcons.forReason(r), color: context.scheme.primary),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(child: Text(r.label, style: context.text.bodyMedium)),
                          Icon(_reason == r ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              color: _reason == r ? context.scheme.primary : c.mutedText),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: AppSpacing.md),
                CommonTextField(
                  label: _reason == ExceptionReason.other ? 'Description' : 'Description (optional)',
                  isRequired: _reason == ExceptionReason.other,
                  controller: _descCtrl,
                  hint: 'Please provide details...',
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                  validator: (v) => _reason == ExceptionReason.other ? Validators.required(v, 'Description') : null,
                ),
                SizedBox(height: AppSpacing.md),
                const RequiredFieldLabel('Attach photo (optional)', isRequired: false),
                SizedBox(height: AppSpacing.sm),
                CommonImagePicker(path: _photo, label: 'Attach Photo', enabled: !busy, onChanged: (p) => setState(() => _photo = p)),
                SizedBox(height: AppSpacing.sm),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _reschedule,
                  onChanged: busy ? null : (v) => setState(() => _reschedule = v ?? false),
                  title: const Text('Request reschedule'),
                  subtitle: _reschedule
                      ? Text(_rescheduleAt == null ? 'No date chosen' : DateTimeUtils.dateTime(_rescheduleAt!))
                      : null,
                ),
                if (_reschedule)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : _pickDateTime,
                      icon: const Icon(Icons.event),
                      label: const Text('Choose date & time'),
                    ),
                  ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: CommonButton(label: 'Submit Report', isLoading: busy, onPressed: () => _submit(order)),
          ),
        ),
      ),
    );
  }
}
