import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import 'common_empty_state.dart';

class CommonErrorState extends StatelessWidget {
  const CommonErrorState({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => CommonEmptyState(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        message: message,
        actionLabel: onRetry == null ? null : AppStrings.retry,
        onAction: onRetry,
      );
}
