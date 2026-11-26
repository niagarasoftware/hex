import 'package:flutter/material.dart';

import '../../../view_models/customer/customer_screen_controller_view_model.dart';

class SiteSelectorWidget extends StatelessWidget {
  final CustomerScreenControllerViewModel vm;
  final BuildContext context;

  const SiteSelectorWidget({
    super.key,
    required this.vm,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final siteList = vm.mySiteList.data;
    if (siteList.length <= 1) return const SizedBox();

    return DropdownButton(
      isExpanded: false,
      underline: Container(),
      items: (vm.mySiteList.data).map((site) {
        return DropdownMenuItem(
          value: site.groupName,
          child: Text(
            site.groupName,
            style: TextStyle(color: colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
      selectedItemBuilder: (context) {
        return (vm.mySiteList.data).map((site) {
          return Center(
            child: Text(
              site.groupName,
              style: TextStyle(color: colorScheme.onPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          );
        }).toList();
      },
      onChanged: (siteName) => vm.siteOnChanged(siteName!),
      value: vm.myCurrentSite,
      dropdownColor: colorScheme.surface,
      iconEnabledColor: colorScheme.onPrimary,
      iconDisabledColor: colorScheme.onPrimary.withOpacity(0.5),
      focusColor: Colors.transparent,
    );
  }
}