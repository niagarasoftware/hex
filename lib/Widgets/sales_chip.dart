import 'package:flutter/material.dart';
import '../../models/sales_data_model.dart';


class SalesChip extends StatelessWidget {
  final int index;
  final Category item;
  const SalesChip({super.key, required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Chip(
      avatar: CircleAvatar(backgroundColor: item.color),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant, width: 0.1),
      ),
      color: WidgetStateProperty.resolveWith<Color>((states) => colorScheme.surfaceContainerLow),
      label: Text('${index + 1} - ${item.categoryName}', style: TextStyle(fontSize: 11, color: colorScheme.onSurface)),
      visualDensity: VisualDensity.compact,
    );
  }
}