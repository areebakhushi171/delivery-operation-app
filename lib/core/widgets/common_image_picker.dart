import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../extensions/context_extensions.dart';
import '../theme/theme.dart';
import 'proof_image.dart';

/// Camera / gallery picker with preview, replace and remove.
class CommonImagePicker extends StatelessWidget {
  const CommonImagePicker({
    super.key,
    required this.path,
    required this.onChanged,
    this.label = 'Add Photo',
    this.errorText,
    this.enabled = true,
  });

  final String? path;
  final ValueChanged<String?> onChanged;
  final String label;
  final String? errorText;
  final bool enabled;

  Future<void> _pick(BuildContext context, ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 80);
      if (file != null) onChanged(file.path);
    } on PlatformException {
      if (context.mounted) {
        context.showMessage('Permission denied. Enable camera/photos access in Settings.', isError: true);
      }
    }
  }

  void _chooseSource(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(context, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final hasImage = path != null && path!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hasImage)
          Semantics(
            button: true,
            label: label,
            child: InkWell(
              onTap: enabled ? () => _chooseSource(context) : null,
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Container(
                height: 150.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: c.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: errorText == null ? c.border : c.danger, width: 1.4),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_camera_outlined, size: 40.w, color: context.scheme.primary),
                    SizedBox(height: AppSpacing.xs),
                    Text(label, style: context.text.titleSmall),
                    Text('Camera or Gallery', style: context.text.bodySmall),
                  ],
                ),
              ),
            ),
          )
        else ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: ProofImage(path: path!, height: 200.h),
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: enabled ? () => _chooseSource(context) : null,
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Replace'),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: enabled ? () => onChanged(null) : null,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove'),
                ),
              ),
            ],
          ),
        ],
        if (errorText != null)
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.xs),
            child: Text(errorText!, style: context.text.bodySmall?.copyWith(color: c.danger)),
          ),
      ],
    );
  }
}
