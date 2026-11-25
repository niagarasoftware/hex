import 'package:flutter/material.dart';

class CustomDropdownWidget extends StatelessWidget {
  final List<String> dropdownItems;
  final String selectedValue;
  final Function(String?) onChanged;
  final bool includeNoneOption;

  const CustomDropdownWidget({
    super.key,
    required this.dropdownItems,
    required this.selectedValue,
    required this.onChanged,
    this.includeNoneOption = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    List<DropdownMenuItem<String>> items = [];

    if (includeNoneOption) {
      items.add(
        DropdownMenuItem<String>(
          value: 'None',
          child: Text('None', style: TextStyle(color: colorScheme.onSurface)),
        ),
      );
    }

    items.addAll(dropdownItems.where((name) => name != null).map((pumpName) {
        return DropdownMenuItem<String>(
          value: pumpName,
          child: Text(pumpName, style: TextStyle(color: colorScheme.onSurface)),
        );
      }).toList(),
    );

    return DropdownButton<String>(
      isExpanded: true,
      underline: Container(),
      value: selectedValue,
      dropdownColor: colorScheme.surface,
      iconEnabledColor: colorScheme.onSurface,
      style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
      items: items,
      onChanged: onChanged,
    );
  }
}
