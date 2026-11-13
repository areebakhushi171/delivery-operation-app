import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<void> _showPhotoOptions(BuildContext context, AppUser? user) async {
    final hasPhoto = user?.photoUrl != null && user!.photoUrl!.isNotEmpty;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile Picture', style: context.text.titleMedium),
              SizedBox(height: AppSpacing.sm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.photo_library_outlined, color: context.scheme.primary),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndCropImage(context, ImageSource.gallery);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.photo_camera_outlined, color: context.scheme.primary),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndCropImage(context, ImageSource.camera);
                },
              ),
              if (hasPhoto)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  title: const Text('Remove Profile Picture', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmRemovePhoto(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndCropImage(BuildContext context, ImageSource source) async {
    final primaryColor = Theme.of(context).colorScheme.primary;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, maxWidth: 1600, imageQuality: 95);
      if (picked == null || !context.mounted) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
          ),
        ],
      );

      if (cropped == null || !context.mounted) return;

      if (!context.mounted) return;
      await _showPreviewAndUpload(context, File(cropped.path));
    } catch (e) {
      if (!context.mounted) return;
      context.showMessage('Failed to process image: $e', isError: true);
    }
  }

  Future<void> _showPreviewAndUpload(BuildContext context, File imageFile) async {
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Preview Profile Picture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: Image.file(
                imageFile,
                width: 140.w,
                height: 140.w,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            const Text('Would you like to upload this picture as your new profile photo?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Upload'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            SizedBox(width: AppSpacing.md),
            const Expanded(child: Text('Uploading profile picture...')),
          ],
        ),
      ),
    );

    final authProv = context.read<AuthProvider>();
    final success = await authProv.updateProfilePhoto(imageFile);

    if (!context.mounted) return;
    Navigator.pop(context); // Dismiss loading dialog

    if (success) {
      context.showMessage('Profile picture updated successfully!', isSuccess: true);
    } else {
      context.showMessage(authProv.error ?? 'Failed to upload profile picture.', isError: true);
    }
  }

  Future<void> _confirmRemovePhoto(BuildContext context) async {
    if (!context.mounted) return;
    final ok = await CommonConfirmationDialog.show(
      context,
      title: 'Remove Profile Picture?',
      message: 'Your profile picture will be removed and replaced with your initials.',
      confirmLabel: 'Remove',
      destructive: true,
    );

    if (!ok || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            SizedBox(width: AppSpacing.md),
            const Expanded(child: Text('Removing profile picture...')),
          ],
        ),
      ),
    );

    final authProv = context.read<AuthProvider>();
    final success = await authProv.removeProfilePhoto();

    if (!context.mounted) return;
    Navigator.pop(context); // Dismiss loading dialog

    if (success) {
      context.showMessage('Profile picture removed.', isSuccess: true);
    } else {
      context.showMessage(authProv.error ?? 'Failed to remove profile picture.', isError: true);
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
                CommonProfileAvatar(
                  name: user?.name ?? 'Dispatcher Admin',
                  photoUrl: user?.photoUrl,
                  size: 72,
                  showEditBadge: true,
                  onTap: () => _showPhotoOptions(context, user),
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
