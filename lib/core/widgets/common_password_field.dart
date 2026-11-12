import 'package:flutter/material.dart';

import 'common_text_field.dart';

class CommonPasswordField extends StatefulWidget {
  const CommonPasswordField({
    super.key,
    this.label = 'Password',
    this.controller,
    this.validator,
    this.focusNode,
    this.onSubmitted,
    this.textInputAction = TextInputAction.done,
  });

  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction textInputAction;

  @override
  State<CommonPasswordField> createState() => _CommonPasswordFieldState();
}

class _CommonPasswordFieldState extends State<CommonPasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return CommonTextField(
      label: widget.label,
      isRequired: true,
      controller: widget.controller,
      validator: widget.validator,
      focusNode: widget.focusNode,
      onSubmitted: widget.onSubmitted,
      textInputAction: widget.textInputAction,
      obscureText: _hidden,
      prefixIcon: Icons.lock_outline,
      hint: 'Enter your password',
      suffix: IconButton(
        tooltip: _hidden ? 'Show password' : 'Hide password',
        icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
        onPressed: () => setState(() => _hidden = !_hidden),
      ),
    );
  }
}
