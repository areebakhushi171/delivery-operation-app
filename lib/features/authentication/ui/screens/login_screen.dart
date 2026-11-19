import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/data/mock/mock_auth_repository.dart';
import '../../../../core/data/models/enums.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/widgets/widgets.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _idFocus = FocusNode();
  final _passFocus = FocusNode();
  late UserRole _role;
  bool _remember = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _role = auth.rememberedRole;
    // Keep login fields empty by default on sign out / load
    _idCtrl.text = '';
    _passCtrl.text = '';
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _passCtrl.dispose();
    _idFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    KeyboardUtils.dismiss(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await context.read<AuthProvider>().signIn(
      identifier: _idCtrl.text,
      password: _passCtrl.text,
      role: _role,
      remember: _remember,
    );
  }

  void _fillDemo(UserRole role) {
    setState(() => _role = role);
    _idCtrl.text = role == UserRole.admin ? MockCredentials.adminEmail : MockCredentials.riderEmail;
    _passCtrl.text = MockCredentials.password;
    context.read<AuthProvider>().clearError();
  }

  Future<void> _forgot() async {
    final auth = context.read<AuthProvider>();
    final email = await showDialog<String>(
      context: context,
      builder: (_) => _ResetDialog(initial: _idCtrl.text.contains('@') ? _idCtrl.text : ''),
    );
    if (email == null || !mounted) return;
    final ok = await auth.sendPasswordReset(email);
    if (!mounted) return;
    context.showMessage(
      ok ? 'If an account exists for that email, a reset link has been sent.' : (auth.error ?? 'Failed'),
      isError: !ok,
      isSuccess: ok,
    );
  }

  /// Phone / tablet: form ko scroll + center + max width ke saath wrap karta hai.
  Widget _scrollable(BuildContext context, Widget form) {
    final mobile = Responsive.isMobile(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              KeyboardUtils.bottomInset(context),
            ),
            child: Align(
              alignment: mobile ? Alignment.topCenter : Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: form,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Desktop/web: form ek bade card mein, center mein.
  Widget _desktopFormPanel(BuildContext context, Widget form) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(40, 40, 40, 32),
                  decoration: BoxDecoration(
                    color: context.appColors.card,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: context.appColors.glassBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(18),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: form,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final desktop = Responsive.isDesktop(context);
    final form = _buildForm(context, auth, showHeader: !desktop, desktop: desktop);

    return KeyboardDismissOnTap(
      child: Scaffold(
        body: desktop
            ? Row(
          children: [
            const Expanded(flex: 1, child: _LoginHero()),
            Expanded(
              flex: 1,
              child: SafeArea(child: _desktopFormPanel(context, form)),
            ),
          ],
        )
        // Phone / tablet: unchanged
            : SafeArea(child: _scrollable(context, form)),
      ),
    );
  }

  Widget _buildForm(
      BuildContext context,
      AuthProvider auth, {
        required bool showHeader,
        bool desktop = false,
      }) {
    // Desktop par thoda bada spacing aur text; phone par pehle jaisa.
    final gapLg = desktop ? 28.0 : AppSpacing.lg;
    final gapMd = desktop ? 20.0 : AppSpacing.md;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader) ...[
            Center(
              child: Container(
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: context.appColors.heroGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_shipping_rounded, size: 44.w, color: Colors.white),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text('Delivery Operations\nCompanion',
                textAlign: TextAlign.center, style: context.text.headlineMedium),
            SizedBox(height: AppSpacing.sm),
          ],
          Text(
            'Welcome Back!',
            textAlign: desktop ? TextAlign.left : TextAlign.center,
            style: desktop
                ? context.text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)
                : context.text.titleMedium,
          ),
          if (desktop) const SizedBox(height: 6),
          Text(
            'Sign in to continue',
            textAlign: desktop ? TextAlign.left : TextAlign.center,
            style: desktop
                ? context.text.bodyLarge?.copyWith(color: context.scheme.onSurfaceVariant)
                : context.text.bodySmall,
          ),
          SizedBox(height: gapLg),
          SegmentedButton<UserRole>(
            segments: const [
              ButtonSegment(
                value: UserRole.rider,
                icon: Icon(Icons.two_wheeler),
                label: Text('Rider'),
              ),
              ButtonSegment(
                value: UserRole.admin,
                icon: Icon(Icons.dashboard_outlined),
                label: Text('Admin'),
              ),
            ],
            selected: {_role},
            onSelectionChanged: (s) {
              setState(() => _role = s.first);
              auth.clearError();
            },
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            _role == UserRole.rider ? AppStrings.rider : AppStrings.admin,
            textAlign: TextAlign.center,
            style: context.text.bodySmall,
          ),
          SizedBox(height: gapMd),
          CommonTextField(
            label: 'Staff ID / Email',
            isRequired: true,
            controller: _idCtrl,
            focusNode: _idFocus,
            hint: 'Enter your Staff ID or Email',
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.identifier,
            onSubmitted: (_) => _passFocus.requestFocus(),
          ),
          SizedBox(height: gapMd),
          CommonPasswordField(
            controller: _passCtrl,
            focusNode: _passFocus,
            validator: Validators.password,
            onSubmitted: (_) => _submit(),
          ),
          SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Checkbox(value: _remember, onChanged: (v) => setState(() => _remember = v ?? false)),
              Expanded(child: Text(AppStrings.rememberMe, style: context.text.bodySmall)),
              TextButton(onPressed: _forgot, child: const Text(AppStrings.forgotPassword)),
            ],
          ),
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
            label: AppStrings.signIn,
            icon: Icons.arrow_forward,
            isLoading: auth.isBusy,
            onPressed: _submit,
          ),
          if (_role == UserRole.rider) ...[
            SizedBox(height: AppSpacing.xs),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text("Don't have a courier account? ", style: context.text.bodySmall),
                TextButton(
                  onPressed: () => context.push(AppRoutes.riderSignUp),
                  child: const Text('Sign Up'),
                ),
              ],
            ),
          ],
          if (AppConfig.isMock) ...[
            SizedBox(height: gapMd),
            Text('Development mode - demo accounts',
                textAlign: TextAlign.center, style: context.text.labelSmall),
            SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _fillDemo(UserRole.rider),
                    child: const Text('Demo Rider'),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _fillDemo(UserRole.admin),
                    child: const Text('Demo Admin'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Desktop/web par login ke left side ka branding panel.
class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: context.appColors.heroGradient),
      padding: const EdgeInsets.all(48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_shipping_rounded, size: 56, color: Colors.white),
              ),
              const SizedBox(height: 28),
              Text(
                'Delivery Operations\nCompanion',
                style: context.text.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Manage orders, riders, and exceptions all in one place.',
                style: context.text.titleMedium?.copyWith(color: Colors.white.withAlpha(220)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResetDialog extends StatefulWidget {
  const _ResetDialog({required this.initial});
  final String initial;

  @override
  State<_ResetDialog> createState() => _ResetDialogState();
}

class _ResetDialogState extends State<_ResetDialog> {
  late final _ctrl = TextEditingController(text: widget.initial);
  final _key = GlobalKey<FormState>();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset password'),
      content: SizedBox(
        width: 400, // web par dialog ki width stable rahe
        child: Form(
          key: _key,
          child: CommonTextField(
            label: 'Email',
            isRequired: true,
            controller: _ctrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: Validators.email,
            onSubmitted: (_) => _send(),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text(AppStrings.cancel)),
        FilledButton(onPressed: _send, child: const Text('Send link')),
      ],
    );
  }

  void _send() {
    if (_key.currentState?.validate() ?? false) Navigator.pop(context, _ctrl.text.trim());
  }
}