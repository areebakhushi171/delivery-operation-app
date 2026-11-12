import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../../../authentication/providers/auth_provider.dart';
import '../../providers/admin_providers.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await CommonConfirmationDialog.show(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out from the Admin Command Center?',
      confirmLabel: 'Sign Out',
      destructive: true,
    );

    if (confirmed && context.mounted) {
      await context.read<AuthProvider>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProv = context.watch<ThemeProvider>();
    final dash = context.watch<AdminDashboardProvider>();
    final c = context.appColors;
    final primaryColor = context.scheme.primary;
    final user = auth.user;

    return Scaffold(
      appBar: const CommonAppBar(title: 'Admin Profile & Settings'),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          // Profile Header Card
          CommonCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36.r,
                  backgroundColor: primaryColor,
                  child: Text(
                    (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'A',
                    style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(user?.name ?? 'Dispatcher Admin', style: context.text.titleLarge),
                SizedBox(height: 2.h),
                Text(user?.email ?? 'admin@company.com', style: context.text.bodySmall),
                SizedBox(height: AppSpacing.xs),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text('FLEET DISPATCHER / ADMIN', style: context.text.labelSmall?.copyWith(color: primaryColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),

          // Operational Performance Overview
          const CommonSectionHeader('Operational System Overview'),
          SizedBox(height: AppSpacing.xs),
          CommonCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Managed Dispatches', style: context.text.bodyMedium),
                    Text('${dash.totalOrders}', style: context.text.titleSmall),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Active Fleet Size', style: context.text.bodyMedium),
                    Text('${dash.riders.length} Riders', style: context.text.titleSmall),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('SLA Success Rate', style: context.text.bodyMedium),
                    Text('${dash.slaSuccessRate.toStringAsFixed(1)}%', style: context.text.titleSmall?.copyWith(color: c.success)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),

          // App Accent Color Palette Picker
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
          SizedBox(height: AppSpacing.md),

          // Settings Section
          const CommonSectionHeader('System Settings'),
          SizedBox(height: AppSpacing.xs),
          CommonCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Dark Mode Theme'),
                  trailing: Switch(
                    value: themeProv.isDark(context),
                    onChanged: (val) => themeProv.setDark(val),
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.sync_rounded),
                  title: const Text('Real-Time Cloud Sync'),
                  subtitle: const Text('Firebase Firestore live telemetry connected'),
                  trailing: Icon(Icons.check_circle_rounded, color: c.success),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.lg),

          // Logout Button
          CommonButton(
            label: 'Sign Out Admin',
            icon: Icons.logout_rounded,
            variant: CommonButtonVariant.secondary,
            onPressed: () => _confirmSignOut(context),
          ),
        ],
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
