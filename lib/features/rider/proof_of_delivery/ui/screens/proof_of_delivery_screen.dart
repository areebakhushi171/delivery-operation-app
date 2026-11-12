import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../authentication/providers/auth_provider.dart';
import '../../../../../core/core.dart';
import '../../../deliveries/providers/rider_orders_provider.dart';
import '../../../update_status/providers/rider_actions_provider.dart';

/// Photo-only proof of delivery (camera/gallery). No OTP, no signature, no scanner.
class ProofOfDeliveryScreen extends StatefulWidget {
  const ProofOfDeliveryScreen({super.key, required this.orderId});
  final String orderId;

  @override
  State<ProofOfDeliveryScreen> createState() => _ProofOfDeliveryScreenState();
}

class _ProofOfDeliveryScreenState extends State<ProofOfDeliveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  final _notesFocus = FocusNode();
  String? _photo;
  String? _photoError;
  bool _codAck = false;
  bool _nameSeeded = false;
  ActionOutcome? _outcome;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    _nameFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  Future<void> _submit(DeliveryOrder o) async {
    KeyboardUtils.dismiss(context);
    final formOk = _formKey.currentState?.validate() ?? false;
    setState(() => _photoError = _photo == null ? 'A delivery photo is required' : null);
    if (!formOk || _photo == null) return;
    if (o.isCod && !_codAck) {
      context.showMessage('Please confirm the COD amount was collected.', isError: true);
      return;
    }
    final actions = context.read<RiderActionsProvider>();
    final uid = context.read<AuthProvider>().user?.uid;
    final res = await actions.submitProof(
      DeliveryProof(
        orderId: o.id,
        photoPath: _photo!,
        recipientName: _nameCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        codAcknowledged: _codAck,
        submittedAt: DateTime.now(),
        submittedBy: uid,
      ),
    );
    if (!mounted) return;
    if (res == null) {
      context.showMessage(actions.error ?? 'Submission failed. Please retry.', isError: true);
    } else {
      setState(() => _outcome = res);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = context.watch<RiderOrdersProvider>().byId(widget.orderId);
    final busy = context.watch<RiderActionsProvider>().isBusy;
    if (o == null) {
      return const Scaffold(appBar: CommonAppBar(title: 'Proof of Delivery'), body: CommonErrorState(message: 'Delivery not found.'));
    }
    if (!_nameSeeded) {
      _nameCtrl.text = o.customerName;
      _nameSeeded = true;
    }
    final c = context.appColors;

    if (_outcome != null) {
      final done = _outcome == ActionOutcome.done;
      return Scaffold(
        appBar: const CommonAppBar(title: 'Proof of Delivery'),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(done ? Icons.check_circle : Icons.cloud_upload_outlined,
                    size: 80.w, color: done ? c.success : c.warning),
                SizedBox(height: AppSpacing.md),
                Text(done ? 'Delivery completed' : 'Saved offline',
                    style: context.text.headlineSmall, textAlign: TextAlign.center),
                SizedBox(height: AppSpacing.sm),
                Text(
                  done ? 'Proof for #${o.id} was submitted.' : AppStrings.offlineQueued,
                  style: context.text.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.xl),
                CommonButton(label: 'Back to deliveries', onPressed: () => context.go(AppRoutes.riderDeliveries)),
              ],
            ),
          ),
        ),
      );
    }

    return KeyboardDismissOnTap(
      child: Scaffold(
        appBar: CommonAppBar(title: 'Proof of Delivery', subtitle: '#${o.id}'),
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, KeyboardUtils.bottomInset(context, 96)),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RequiredFieldLabel('Delivery photo'),
                SizedBox(height: AppSpacing.sm),
                CommonImagePicker(
                  path: _photo,
                  errorText: _photoError,
                  enabled: !busy,
                  onChanged: (p) => setState(() {
                    _photo = p;
                    _photoError = null;
                  }),
                ),
                SizedBox(height: AppSpacing.md),
                CommonTextField(
                  label: 'Recipient name',
                  isRequired: true,
                  controller: _nameCtrl,
                  focusNode: _nameFocus,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => Validators.required(v, 'Recipient name'),
                  onSubmitted: (_) => _notesFocus.requestFocus(),
                ),
                SizedBox(height: AppSpacing.md),
                CommonTextField(
                  label: 'Additional notes (optional)',
                  controller: _notesCtrl,
                  focusNode: _notesFocus,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                ),
                if (o.isCod) ...[
                  SizedBox(height: AppSpacing.md),
                  CommonCard(
                    onTap: busy ? null : () => setState(() => _codAck = !_codAck),
                    child: Row(
                      children: [
                        Checkbox(value: _codAck, onChanged: busy ? null : (v) => setState(() => _codAck = v ?? false)),
                        Expanded(
                          child: Text(
                            'I collected ${CurrencyUtils.rs(o.codAmount)} in cash from the customer.',
                            style: context.text.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (busy) ...[
                  SizedBox(height: AppSpacing.md),
                  const LinearProgressIndicator(),
                  SizedBox(height: AppSpacing.xs),
                  Text('Uploading proof...', style: context.text.bodySmall),
                ],
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: CommonButton(label: 'Submit Delivery', isLoading: busy, onPressed: () => _submit(o)),
          ),
        ),
      ),
    );
  }
}
