import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../../core/core.dart';
import '../../../../authentication/providers/auth_provider.dart';
import '../../../deliveries/providers/rider_orders_provider.dart';
import '../../providers/rider_profile_provider.dart';

class RiderProfileScreen extends StatefulWidget {
  const RiderProfileScreen({super.key});

  @override
  State<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends State<RiderProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_seeded) {
      final profile = context.read<RiderProfileProvider>();
      final user = context.read<AuthProvider>().user;
      final displayRider = profile.rider ??
          (user != null
              ? Rider(
                  id: user.uid,
                  staffId: user.staffId,
                  name: user.name,
                  phone: '+92 300 1234567',
                  email: user.email,
                  dutyStatus: DutyStatus.onDuty,
                  vehicleType: 'Bike - CG125',
                  vehicleReg: 'ICT-408',
                  rating: 4.8,
                )
              : null);
      if (displayRider != null) {
        _nameCtrl.text = displayRider.name;
        _phoneCtrl.text = displayRider.phone;
        _seeded = true;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    KeyboardUtils.dismiss(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final p = context.read<RiderProfileProvider>();
    final ok = await p.updateProfile(name: _nameCtrl.text, phone: _phoneCtrl.text);
    if (!mounted) return;
    context.showMessage(ok ? 'Profile updated' : (p.error ?? 'Update failed'), isError: !ok, isSuccess: ok);
  }

  Future<void> _logout() async {
    final ok = await CommonConfirmationDialog.show(
      context,
      title: 'Log out?',
      message: 'You will need to sign in again.',
      confirmLabel: 'Log out',
      destructive: true,
    );
    if (ok && mounted) await context.read<AuthProvider>().signOut();
  }

  void _showQueue() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _QueueSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<RiderProfileProvider>();
    final orders = context.watch<RiderOrdersProvider>();
    final prefs = context.watch<PreferencesProvider>();
    final theme = context.watch<ThemeProvider>();
    final sync = context.watch<SyncProvider>();
    final user = context.watch<AuthProvider>().user;

    final displayRider = profile.rider ??
        (user != null
            ? Rider(
                id: user.uid,
                staffId: user.staffId,
                name: user.name,
                phone: '+92 300 1234567',
                email: user.email,
                dutyStatus: DutyStatus.onDuty,
                vehicleType: 'Bike - CG125',
                vehicleReg: 'ICT-408',
                rating: 4.8,
              )
            : null);

    final onTime = orders.onTimeRate;

    return KeyboardDismissOnTap(
      child: Scaffold(
        appBar: const CommonAppBar(title: 'Profile & Settings', showBack: false),
        body: displayRider == null
            ? const CommonLoadingWidget()
            : ListView(
                key: const PageStorageKey('rider_profile_scroll'),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, KeyboardUtils.bottomInset(context)),
                children: [
                  Center(child: CommonProfileAvatar(name: displayRider.name, size: 84)),
                  SizedBox(height: AppSpacing.sm),
                  Center(child: Text(displayRider.name, style: context.text.titleLarge)),
                  Center(child: Text('Rider ID: #${displayRider.staffId}', style: context.text.bodySmall)),
                  SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: CommonStatTile(
                          icon: Icons.star_rounded,
                          value: displayRider.rating.toStringAsFixed(1),
                          label: 'Rating',
                          tone: StatusTone.warning,
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: CommonStatTile(
                          icon: Icons.timer_outlined,
                          value: onTime == null ? '98%' : '${(onTime * 100).round()}%',
                          label: 'On-time rate',
                          tone: StatusTone.success,
                        ),
                      ),
                    ],
                  ),
                  const CommonSectionHeader('Personal details'),
                  CommonCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CommonTextField(
                            label: 'Full Name',
                            isRequired: true,
                            controller: _nameCtrl,
                            focusNode: _nameFocus,
                            textCapitalization: TextCapitalization.words,
                            validator: (v) => Validators.required(v, 'Full name'),
                            onSubmitted: (_) => _phoneFocus.requestFocus(),
                          ),
                          SizedBox(height: AppSpacing.md),
                          CommonTextField(
                            label: 'Staff ID',
                            isRequired: true,
                            initialValue: displayRider.staffId,
                            readOnly: true,
                            enabled: false,
                          ),
                          SizedBox(height: AppSpacing.md),
                          CommonTextField(
                            label: 'Phone Number',
                            isRequired: true,
                            controller: _phoneCtrl,
                            focusNode: _phoneFocus,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            validator: Validators.phone,
                            onSubmitted: (_) => _save(),
                          ),
                          SizedBox(height: AppSpacing.md),
                          CommonTextField(
                            label: 'Email',
                            isRequired: true,
                            initialValue: user?.email ?? displayRider.email,
                            readOnly: true,
                            enabled: false,
                          ),
                          SizedBox(height: AppSpacing.md),
                          CommonTextField(
                            label: 'Vehicle (optional)',
                            initialValue: displayRider.vehicleType,
                            readOnly: true,
                            enabled: false,
                          ),
                          SizedBox(height: AppSpacing.md),
                          CommonTextField(
                            label: 'Vehicle registration (optional)',
                            initialValue: displayRider.vehicleReg,
                            readOnly: true,
                            enabled: false,
                          ),
                          SizedBox(height: AppSpacing.md),
                          CommonButton(label: 'Save changes', isLoading: profile.isBusy, onPressed: _save),
                        ],
                      ),
                    ),
                  ),
                  const CommonSectionHeader('App Accent Color Theme'),
                  SizedBox(height: AppSpacing.xs),
                  CommonCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: const [
                        _ColorOption(Color(0xFF1565C0), 'Cobalt'),
                        _ColorOption(Color(0xFF0F766E), 'Teal'),
                        _ColorOption(Color(0xFF10B981), 'Emerald'),
                        _ColorOption(Color(0xFF7C3AED), 'Purple'),
                        _ColorOption(Color(0xFFF59E0B), 'Amber'),
                      ],
                    ),
                  ),
                  const CommonSectionHeader('Settings'),
                  SizedBox(height: AppSpacing.xs),
                  CommonCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        SwitchListTile(
                          secondary: const Icon(Icons.notifications_outlined),
                          title: const Text('Notifications'),
                          value: prefs.notificationsEnabled,
                          onChanged: prefs.setNotifications,
                        ),
                        ListTile(
                          leading: const Icon(Icons.language),
                          title: const Text('Language'),
                          subtitle: const Text('Preference saved.'),
                          trailing: DropdownButton<String>(
                            value: prefs.language,
                            underline: const SizedBox.shrink(),
                            items: const [
                              DropdownMenuItem(value: 'English', child: Text('English')),
                              DropdownMenuItem(value: 'Urdu', child: Text('اردو')),
                            ],
                            onChanged: (v) {
                              if (v != null) prefs.setLanguage(v);
                            },
                          ),
                        ),
                        SwitchListTile(
                          secondary: const Icon(Icons.dark_mode_outlined),
                          title: const Text('Dark Mode'),
                          value: theme.isDark(context),
                          onChanged: theme.setDark,
                        ),
                        ListTile(
                          leading: Icon(sync.isOnline ? Icons.cloud_done_outlined : Icons.cloud_off),
                          title: const Text('Offline Sync'),
                          subtitle: Text(
                            sync.lastSync == null
                                ? '${sync.pendingCount} queued - never synced'
                                : '${sync.pendingCount} queued - last synced ${DateTimeUtils.relative(sync.lastSync!)}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _showQueue,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  CommonButton(
                    label: 'Logout',
                    icon: Icons.logout,
                    variant: CommonButtonVariant.danger,
                    onPressed: _logout,
                  ),
                ],
              ),
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  const _ColorOption(this.color, this.label);
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final isSelected = theme.accentColor.toARGB32() == color.toARGB32();
    return GestureDetector(
      onTap: () => theme.setAccentColor(color),
      child: Column(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 3),
              boxShadow: [
                if (isSelected)
                  BoxShadow(color: color.withAlpha(120), blurRadius: 8, spreadRadius: 2),
              ],
            ),
            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
          ),
          SizedBox(height: 4.h),
          Text(label, style: context.text.labelSmall),
        ],
      ),
    );
  }
}

class _QueueSheet extends StatelessWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncProvider>();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Offline queue', style: context.text.titleMedium),
            Text(sync.isOnline ? 'Online' : 'Offline - actions will sync automatically', style: context.text.bodySmall),
            SizedBox(height: AppSpacing.sm),
            if (sync.queue.isEmpty)
              const Padding(padding: EdgeInsets.all(16), child: Text('Nothing waiting to sync.'))
            else
              ...sync.queue.map(
                (a) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${a.type} - ${a.payload['orderId'] ?? ''}'),
                  subtitle: Text('${a.state.name}${a.error == null ? '' : ' - ${a.error}'}'),
                  trailing: a.state == SyncState.failed
                      ? IconButton(
                          tooltip: 'Discard',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => sync.discard(a.id),
                        )
                      : null,
                ),
              ),
            SizedBox(height: AppSpacing.sm),
            CommonButton(
              label: 'Sync now',
              icon: Icons.sync,
              isLoading: sync.isSyncing,
              onPressed: sync.isOnline && sync.pendingCount > 0 ? sync.syncNow : null,
            ),
          ],
        ),
      ),
    );
  }
}
