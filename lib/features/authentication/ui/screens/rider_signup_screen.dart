import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../../providers/auth_provider.dart';

class RiderSignUpScreen extends StatefulWidget {
  const RiderSignUpScreen({super.key});

  @override
  State<RiderSignUpScreen> createState() => _RiderSignUpScreenState();
}

class _RiderSignUpScreenState extends State<RiderSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _vehicleTypeCtrl = TextEditingController(text: 'Bike - CG125');
  final _vehicleRegCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _regFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmPassFocus = FocusNode();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _vehicleTypeCtrl.dispose();
    _vehicleRegCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();

    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _regFocus.dispose();
    _passFocus.dispose();
    _confirmPassFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    KeyboardUtils.dismiss(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_passCtrl.text != _confirmPassCtrl.text) {
      context.showMessage('Passwords do not match.', isError: true);
      return;
    }

    final ok = await context.read<AuthProvider>().signUpRider(
          name: _nameCtrl.text,
          email: _emailCtrl.text,
          phone: _phoneCtrl.text,
          password: _passCtrl.text,
          vehicleType: _vehicleTypeCtrl.text,
          vehicleReg: _vehicleRegCtrl.text,
        );

    if (ok && mounted) {
      context.showMessage('Account created successfully!', isSuccess: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return KeyboardDismissOnTap(
      child: Scaffold(
        appBar: const CommonAppBar(title: 'Rider Registration'),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Join Fleet Operations', style: context.text.titleLarge),
                SizedBox(height: 4.h),
                Text('Register as a courier to receive dispatches and route assignments.', style: context.text.bodySmall),
                SizedBox(height: AppSpacing.md),
                CommonCard(
                  child: Column(
                    children: [
                      CommonTextField(
                        label: 'Full Name',
                        isRequired: true,
                        controller: _nameCtrl,
                        focusNode: _nameFocus,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => Validators.required(v, 'Full Name'),
                        onSubmitted: (_) => _emailFocus.requestFocus(),
                      ),
                      SizedBox(height: AppSpacing.md),
                      CommonTextField(
                        label: 'Email Address',
                        isRequired: true,
                        controller: _emailCtrl,
                        focusNode: _emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                        onSubmitted: (_) => _phoneFocus.requestFocus(),
                      ),
                      SizedBox(height: AppSpacing.md),
                      CommonTextField(
                        label: 'Phone Number',
                        isRequired: true,
                        controller: _phoneCtrl,
                        focusNode: _phoneFocus,
                        keyboardType: TextInputType.phone,
                        validator: Validators.phone,
                        onSubmitted: (_) => _regFocus.requestFocus(),
                      ),
                      SizedBox(height: AppSpacing.md),
                      CommonTextField(
                        label: 'Vehicle Registration No.',
                        isRequired: true,
                        controller: _vehicleRegCtrl,
                        focusNode: _regFocus,
                        hint: 'e.g. ICT-4082',
                        validator: (v) => Validators.required(v, 'Vehicle Reg'),
                        onSubmitted: (_) => _passFocus.requestFocus(),
                      ),
                      SizedBox(height: AppSpacing.md),
                      CommonPasswordField(
                        controller: _passCtrl,
                        focusNode: _passFocus,
                        validator: Validators.password,
                        onSubmitted: (_) => _confirmPassFocus.requestFocus(),
                      ),
                      SizedBox(height: AppSpacing.md),
                      CommonPasswordField(
                        label: 'Confirm Password',
                        controller: _confirmPassCtrl,
                        focusNode: _confirmPassFocus,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please confirm password';
                          if (v != _passCtrl.text) return 'Passwords do not match';
                          return null;
                        },
                        onSubmitted: (_) => _submit(),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                if (auth.error != null)
                  Container(
                    margin: EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: EdgeInsets.all(AppSpacing.sm + 4),
                    decoration: BoxDecoration(
                      color: context.appColors.danger.withAlpha(30),
                      borderRadius: BorderRadius.circular(AppRadius.input),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: context.appColors.danger, size: 20.w),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(auth.error!, style: context.text.bodySmall)),
                      ],
                    ),
                  ),
                CommonButton(
                  label: 'Register Rider Account',
                  icon: Icons.check_circle_rounded,
                  isLoading: auth.isBusy,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
