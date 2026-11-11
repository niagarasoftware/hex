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
    this.unselectedColor = Colors.white,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(4),
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
                  color: isSelected ? Colors.black87 : primaryColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }),
        groupValue: groupValue,
        onValueChanged: onChanged,
        thumbColor: Colors.white,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
