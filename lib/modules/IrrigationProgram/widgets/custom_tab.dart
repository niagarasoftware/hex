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
    const primaryPurple = Color(0xFF5B21B6);
    final bool isSelected = tabIndex == selectedTabIndex;

    Color avatarColor = isSelected ? primaryPurple : Colors.white;
    Color contentColor = isSelected ? Colors.white : const Color(0xFF64748B);

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
                color: isSelected ? primaryPurple : const Color(0xFF64748B),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
