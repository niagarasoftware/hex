
import 'package:flutter/material.dart';

Widget buildValveStatusLegend(bool isAquaculture) {
  final statusItems = [
    (const Color(0xFF64748B), 'Default'),
    (const Color(0xFF16A34A), 'Running'),
    (const Color(0xFF2563EB), 'Completed'),
    (const Color(0xFFEAB308), 'Pending'),
    (const Color(0xFFEF861D), 'Not Open'),
    (const Color(0xFFB91C1C), 'Not Closed'),
    (const Color(0xFF7C3AED), 'On · Low Pressure'),
    (const Color(0xFFE81FAF), 'Off · High Pressure'),
    (const Color(0xFF7D50CA), 'On · Low Lateral Pressure'),
    (const Color(0xFF634610), 'Off · High Lateral Pressure'),
  ];

  return LayoutBuilder(
    builder: (context, constraints) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      final isNarrow = constraints.maxWidth < 600;

      Widget legendItem(Color color, String text) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                  width: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        );
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(color: colorScheme.outlineVariant),
            bottom: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAquaculture ? 'Aerator Status' : 'Valve Status',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: isNarrow ? 14 : 20,
              runSpacing: 10,
              children: statusItems.map((item) {
                return legendItem(item.$1, item.$2);
              }).toList(),
            ),
          ],
        ),
      );
    },
  );
}