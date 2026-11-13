import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<void> _showPhotoOptions(BuildContext context, Rider rider) async {
    final hasPhoto = rider.photoUrl != null && rider.photoUrl!.isNotEmpty;
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
                    _confirmRemovePhoto();
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
      if (picked == null || !mounted) return;

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

      if (cropped == null || !mounted) return;

      if (!mounted) return;
      await _showPreviewAndUpload(File(cropped.path));
    } catch (e) {
      if (!mounted) return;
      context.showMessage('Failed to process image: $e', isError: true);
    }
  }

  Future<void> _showPreviewAndUpload(File imageFile) async {
    if (!mounted) return;
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

    if (confirmed != true || !mounted) return;

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

    final profileProv = context.read<RiderProfileProvider>();
    final success = await profileProv.updateProfilePhoto(imageFile);

    if (!mounted) return;
    Navigator.pop(context); // Dismiss loading dialog

    if (success) {
      context.showMessage('Profile picture updated successfully!', isSuccess: true);
    } else {
      context.showMessage(profileProv.error ?? 'Failed to upload profile picture.', isError: true);
    }
  }

  Future<void> _confirmRemovePhoto() async {
    if (!mounted) return;
    final ok = await CommonConfirmationDialog.show(
      context,
      title: 'Remove Profile Picture?',
      message: 'Your profile picture will be removed and replaced with your initials.',
      confirmLabel: 'Remove',
      destructive: true,
    );

    if (!ok || !mounted) return;

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

    final profileProv = context.read<RiderProfileProvider>();
    final success = await profileProv.removeProfilePhoto();

    if (!mounted) return;
    Navigator.pop(context); // Dismiss loading dialog

    if (success) {
      context.showMessage('Profile picture removed.', isSuccess: true);
    } else {
      context.showMessage(profileProv.error ?? 'Failed to remove profile picture.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<RiderProfileProvider>();
    final orders = context.watch<RiderOrdersProvider>();
    final prefs = context.watch<PreferencesProvider>();
    final theme = context.watch<ThemeProvider>();
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
                  Center(
                    child: CommonProfileAvatar(
                      name: displayRider.name,
                      photoUrl: displayRider.photoUrl,
                      size: 84,
                      showEditBadge: true,
                      onTap: () => _showPhotoOptions(context, displayRider),
                    ),
                  ),
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
                          trailing: Text(
                            'English',
                            style: context.text.bodyMedium?.copyWith(
                              color: context.appColors.mutedText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SwitchListTile(
                          secondary: const Icon(Icons.dark_mode_outlined),
                          title: const Text('Dark Mode'),
                          value: theme.isDark(context),
                          onChanged: theme.setDark,
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
