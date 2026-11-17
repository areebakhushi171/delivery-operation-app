import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Label with a small red asterisk ONLY when [isRequired] is true.
class RequiredFieldLabel extends StatelessWidget {
  const RequiredFieldLabel(this.text, {super.key, this.isRequired = true});
  final String text;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text,
        style: context.text.labelLarge,
        children: [
          if (isRequired)
            TextSpan(
              text: ' *',
              style: TextStyle(color: context.appColors.danger, fontWeight: FontWeight.w800),
            ),
        ],
      ),
    );
  }
}
