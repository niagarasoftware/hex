import 'package:flutter/material.dart';

class CustomSwitch extends StatelessWidget {
  final bool value;
  final void Function(bool?)? onChanged;
  const CustomSwitch({super.key, required this.value,required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Switch(
      activeThumbColor: colorScheme.onPrimary,
      value: value,
      onChanged: onChanged,
      activeTrackColor: colorScheme.primary,
      thumbIcon: WidgetStateProperty.all(Icon(
        Icons.circle,
        color: value ? colorScheme.onPrimary : colorScheme.outline,
        size: 25,
      )),
      trackOutlineWidth: WidgetStateProperty.all(0.0),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
