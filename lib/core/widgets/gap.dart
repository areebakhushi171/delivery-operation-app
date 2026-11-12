import 'package:flutter/widgets.dart';

/// Vertical gap by default; `Gap.h` for horizontal.
class Gap extends StatelessWidget {
  const Gap(this.size, {super.key}) : horizontal = false;
  const Gap.h(this.size, {super.key}) : horizontal = true;
  final double size;
  final bool horizontal;

  @override
  Widget build(BuildContext context) =>
      horizontal ? SizedBox(width: size) : SizedBox(height: size);
}
