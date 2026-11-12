import 'package:flutter/material.dart';

class KeyboardUtils {
  KeyboardUtils._();

  static void dismiss(BuildContext context) => FocusManager.instance.primaryFocus?.unfocus();

  /// Bottom padding for scroll views so the last field is never hidden by the keyboard.
  static double bottomInset(BuildContext context, [double extra = 24]) =>
      MediaQuery.viewInsetsOf(context).bottom + extra;
}

/// Dismisses the keyboard when tapping outside of any input.
class KeyboardDismissOnTap extends StatelessWidget {
  const KeyboardDismissOnTap({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => KeyboardUtils.dismiss(context),
        child: child,
      );
}
