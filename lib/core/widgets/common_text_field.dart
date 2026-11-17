import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';
import 'required_field_label.dart';

/// Single text field used by every form (consistent label, keyboard actions, errors).
class CommonTextField extends StatelessWidget {
  const CommonTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.validator,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.focusNode,
    this.onSubmitted,
    this.onChanged,
    this.onTap,
    this.isRequired = false,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.showLabel = true,
    this.initialValue,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool isRequired;
  final int maxLines;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool showLabel;
  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          RequiredFieldLabel(label, isRequired: isRequired),
          SizedBox(height: AppSpacing.xs + 2),
        ],
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          focusNode: focusNode,
          validator: validator,
          autovalidateMode: autovalidateMode,
          keyboardType: keyboardType ?? (maxLines > 1 ? TextInputType.multiline : null),
          textInputAction: textInputAction,
          onFieldSubmitted: (v) {
            if (textInputAction == TextInputAction.done) FocusScope.of(context).unfocus();
            onSubmitted?.call(v);
          },
          onChanged: onChanged,
          onTap: onTap,
          obscureText: obscureText,
          enabled: enabled,
          readOnly: readOnly,
          maxLines: obscureText ? 1 : maxLines,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          scrollPadding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom + 120),
          style: context.text.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}
