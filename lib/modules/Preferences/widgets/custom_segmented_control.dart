import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomSegmentedControl extends StatelessWidget {
  final Map<int, String> segmentTitles;
  final int groupValue;
  final ValueChanged<int?> onChanged;
  final Color selectedColor;
  final Color unselectedColor;
  final EdgeInsets padding;

  const CustomSegmentedControl({
    super.key,
    required this.segmentTitles,
    required this.groupValue,
    required this.onChanged,
    this.selectedColor = Colors.black,
    this.unselectedColor = const Color(0xFFFFFFFF),
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: CupertinoSlidingSegmentedControl<int>(
        padding: const EdgeInsets.all(2),
        children: segmentTitles.map((key, title) {
          final isSelected = groupValue == key;
          return MapEntry(
            key,
            Padding(
              padding: padding,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }),
        groupValue: groupValue,
        onValueChanged: onChanged,
        thumbColor: colorScheme.surface,
        backgroundColor: colorScheme.surface.withOpacity(0),
      ),
    );
  }
}
