import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/theme.dart';

class CommonProfileAvatar extends StatelessWidget {
  const CommonProfileAvatar({super.key, required this.name, this.size = 48, this.onDark = false});
  final String name;
  final double size;
  final bool onDark;

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
    return Semantics(
      label: 'Avatar for $name',
      child: CircleAvatar(
        radius: size.w / 2,
        backgroundColor: bg,
        child: Text(_initials, style: context.text.titleSmall?.copyWith(color: fg, fontSize: (size * 0.36).sp)),
      ),
    );
  }
}
