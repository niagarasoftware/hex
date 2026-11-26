import 'package:flutter/material.dart';

class CustomCheckBox extends StatelessWidget {
  final bool value;
  final void Function(bool?)? onChanged;
  const CustomCheckBox({super.key, required this.value,required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Checkbox(
          activeColor: colorScheme.primary,
          checkColor: colorScheme.onPrimary,
          value: value,
          onChanged: onChanged
      ),
    );
  }
}
