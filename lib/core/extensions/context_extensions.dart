import 'package:flutter/material.dart';

import '../theme/theme.dart';

extension SnackBarContext on BuildContext {
  void showMessage(String message, {bool isError = false, bool isSuccess = false}) {
    final c = appColors;
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? c.danger : (isSuccess ? c.success : null),
        ),
      );
  }
}
