import 'package:flutter/material.dart';

class CustomMaterialButton extends StatelessWidget {
  void Function()? onPressed;
  String? title;
  bool? outlined;
  Widget? child;
  Color? color;
  IconData? icon;
  CustomMaterialButton({super.key, this.onPressed, this.title, this.outlined, this.child, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = outlined != null ? colorScheme.primary : colorScheme.onPrimary;

    Widget buttonChild;
    if (child != null) {
      buttonChild = child!;
    } else if (icon != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Text(
            title ?? "OK",
            style: TextStyle(color: textColor),
          ),
        ],
      );
    } else {
      buttonChild = Text(
        title ?? "OK",
        style: TextStyle(color: textColor),
      );
    }

    return MaterialButton(
      hoverColor: colorScheme.primaryContainer,
      color: color ?? (outlined != null ? colorScheme.surface : colorScheme.primary),
      shape: RoundedRectangleBorder(
        side: outlined != null ? BorderSide(color: colorScheme.primary) : BorderSide.none,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      onPressed: onPressed ?? () {
        Navigator.of(context).pop(); // Dismiss the alert
      },
      child: buttonChild,
    );
  }
}

