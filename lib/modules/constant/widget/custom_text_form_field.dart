import 'package:flutter/material.dart';

class CustomTextFormField extends StatefulWidget {
  final String value;
  final String dataType;
  final void Function(String)? onChanged;
  const CustomTextFormField({
    super.key,
    required this.value,
    required this.dataType,
    required this.onChanged,
  });

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  bool isEditing = false;
  FocusNode myFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        myFocus.addListener(() {
          if (!myFocus.hasFocus) {
            toggleEditing();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    myFocus.dispose();
    super.dispose();
  }

  void toggleEditing() {
    setState(() {
      isEditing = !isEditing;
      if (isEditing) {
        myFocus.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: toggleEditing,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEditing
                ? colorScheme.primary
                : colorScheme.outlineVariant.withOpacity(0.5),
            width: isEditing ? 1.5 : 1.0,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        child: isEditing
            ? TextFormField(
          focusNode: myFocus,
          initialValue: widget.value,
          onChanged: widget.onChanged,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
          ),
        )
            : Text(
          widget.value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
