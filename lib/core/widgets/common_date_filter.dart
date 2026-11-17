import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../utils/date_time_utils.dart';

class CommonDateFilter extends StatelessWidget {
  const CommonDateFilter({
    super.key,
    required this.value,
    required this.onChanged,
    this.options = DateRangeOption.values,
  });

  final DateRangeOption value;
  final ValueChanged<DateRangeOption> onChanged;
  final List<DateRangeOption> options;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: c.glassBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DateRangeOption>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(AppRadius.input),
          icon: Icon(Icons.calendar_today_outlined, size: 18, color: context.scheme.primary),
          style: context.text.bodyMedium,
          items: [
            for (final o in options) DropdownMenuItem(value: o, child: Text(o.label)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
