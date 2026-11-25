import 'package:flutter/material.dart';

class CustomTab extends StatelessWidget {
  final dynamic content;
  final String? label;
  final int tabIndex;
  final int selectedTabIndex;
  final double? radius;
  final double? height;

  const CustomTab({
    super.key,
    required this.content,
    this.label,
    required this.tabIndex,
    required this.selectedTabIndex,
    this.radius,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isSelected = tabIndex == selectedTabIndex;

    Color avatarColor = isSelected ? colorScheme.primary : colorScheme.surface;
    Color contentColor = isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant;

    return Tab(
      height: height,
      child: Column(
        children: [
          const SizedBox(height: 5),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            elevation: isSelected ? 2 : 0,
            child: CircleAvatar(
              radius: radius,
              backgroundColor: avatarColor,
              child: content is IconData
                  ? Icon(content, color: contentColor)
                  : Text(
                      content.toString(),
                      style: TextStyle(
                        color: contentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(
              label!,
              style: TextStyle(
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
