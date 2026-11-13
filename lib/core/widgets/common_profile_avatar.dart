import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/theme.dart';

class CommonProfileAvatar extends StatelessWidget {
  const CommonProfileAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 48,
    this.onDark = false,
    this.showEditBadge = false,
    this.onTap,
  });
  final String name;
  final String? photoUrl;
  final double size;
  final bool onDark;
  final bool showEditBadge;
  final VoidCallback? onTap;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.length == 1
        ? parts.first[0].toUpperCase()
        : (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bg = onDark ? Colors.white24 : context.scheme.primary.withAlpha(32);
    final fg = onDark ? Colors.white : context.scheme.primary;

    final avatar = Stack(
      children: [
        CircleAvatar(
          radius: size.w / 2,
          backgroundColor: bg,
          backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
              ? CachedNetworkImageProvider(photoUrl!)
              : null,
          child: (photoUrl == null || photoUrl!.isEmpty)
              ? Text(_initials, style: context.text.titleSmall?.copyWith(color: fg, fontSize: (size * 0.36).sp))
              : null,
        ),
        if (showEditBadge)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(5.w),
              decoration: BoxDecoration(
                color: context.scheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: context.scheme.surface, width: 2.w),
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: (size * 0.24).clamp(12.0, 16.0).w,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );

    return Semantics(
      label: 'Avatar for $name',
      child: onTap != null
          ? GestureDetector(
              onTap: onTap,
              child: avatar,
            )
          : avatar,
    );
  }
}
