import 'package:flutter/material.dart';

class CustomMaterialButton extends StatelessWidget {
  void Function()? onPressed;
  String? title;
  bool? outlined;
  Widget? child;
  Color? color;
  CustomMaterialButton({super.key, this.onPressed, this.title, this.outlined, this.child, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
      child: child ?? Text(
        title ?? "OK",
        style: TextStyle(color: outlined != null ? colorScheme.primary : colorScheme.onPrimary),
      ),
    );
  }
}

