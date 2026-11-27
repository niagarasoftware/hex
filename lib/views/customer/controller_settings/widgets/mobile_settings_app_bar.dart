import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

PreferredSizeWidget buildMobileSettingsAppBar(
  BuildContext context, {
  required String title,
  List<Widget>? actions,
  Widget? leading,
  PreferredSizeWidget? bottom,
}) {
  final colorScheme = Theme.of(context).colorScheme;

  return AppBar(
    title: Text(
      title,
      style: TextStyle(
        color: colorScheme.onPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    ),
    centerTitle: false,
    backgroundColor: colorScheme.primary,
    foregroundColor: colorScheme.onPrimary,
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: colorScheme.onPrimary),
    actionsIconTheme: IconThemeData(color: colorScheme.onPrimary),
    elevation: 0,
    systemOverlayStyle: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
    leading: leading,
    actions: actions,
    bottom: bottom,
  );
}
