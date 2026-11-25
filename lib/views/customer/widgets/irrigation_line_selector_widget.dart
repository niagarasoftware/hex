import 'package:flutter/material.dart';

import '../../../view_models/customer/customer_screen_controller_view_model.dart';

class IrrigationLineSelectorWidget extends StatelessWidget {
  final CustomerScreenControllerViewModel vm;

  const IrrigationLineSelectorWidget({
    super.key,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final master = vm.mySiteList.data[vm.sIndex].master[vm.mIndex];
    if (master.categoryId != 1 || master.irrigationLine.length <= 1) {
      return const SizedBox();
    }
    return DropdownButton<int>(
      underline: Container(),
      items: List.generate(master.irrigationLine.length, (index) {
        final line = master.irrigationLine[index];
        return DropdownMenuItem<int>(
          value: index,
          child: Text(
            line.name,
            style: TextStyle(color: colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        );
      }),
      selectedItemBuilder: (context) {
        return List.generate(master.irrigationLine.length, (index) {
          final line = master.irrigationLine[index];
          return Center(
            child: Text(
              line.name,
              style: TextStyle(color: colorScheme.onPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          );
        });
      },
      onChanged: (selectedIndex) {
        if (selectedIndex != null) {
          vm.lineOnChanged(selectedIndex);
        }
      },
      value: vm.lIndex,
      dropdownColor: colorScheme.surface,
      iconEnabledColor: colorScheme.onPrimary,
      iconDisabledColor: colorScheme.onPrimary.withOpacity(0.5),
      focusColor: Colors.transparent,
    );
  }
}