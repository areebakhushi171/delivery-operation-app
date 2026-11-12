import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Shows a local file or an https URL (uploaded proof / exception photo).
class ProofImage extends StatelessWidget {
  const ProofImage({super.key, required this.path, this.height, this.fit = BoxFit.cover});
  final String path;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final broken = Container(
      height: height,
      color: context.appColors.surfaceSecondary,
      alignment: Alignment.center,
      child: Icon(Icons.broken_image_outlined, color: context.appColors.mutedText),
    );
    final image = path.startsWith('http')
        ? Image.network(path, height: height, width: double.infinity, fit: fit,
            errorBuilder: (_, __, ___) => broken)
        : Image.file(File(path), height: height, width: double.infinity, fit: fit,
            errorBuilder: (_, __, ___) => broken);
    return image;
  }
}
