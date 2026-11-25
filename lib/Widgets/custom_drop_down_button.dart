import 'package:flutter/material.dart';
class CustomDropDownButton extends StatelessWidget {
  final String value;
  TextStyle? style;
  final List<String> list;
  final void Function(String?)? onChanged;
  CustomDropDownButton({
    super.key,
    required this.value,
    this.style,
    required this.list,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DropdownButton<String>(
      isExpanded: true,
      underline: Container(),
      value: value,
      dropdownColor: colorScheme.surface,
      iconEnabledColor: colorScheme.onSurface,
      style: style ?? TextStyle(color: colorScheme.onSurface, fontSize: 13),
      items: list.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item, style: TextStyle(color: colorScheme.onSurface)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
