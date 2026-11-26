import 'package:flutter/material.dart';

import '../../../view_models/customer/customer_screen_controller_view_model.dart';

class MasterSelectorWidget extends StatelessWidget {
  final CustomerScreenControllerViewModel vm;
  final int sIndex;
  final int mIndex;

  const MasterSelectorWidget({
    super.key,
    required this.vm,
    required this.sIndex,
    required this.mIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final masterList = vm.mySiteList.data[sIndex].master;
    if (masterList.length <= 1) return const SizedBox();
    return PopupMenuButton<int>(
      color: colorScheme.surface,
      tooltip: 'master controller',
      child: MaterialButton(
        onPressed: null,
        textColor: colorScheme.onPrimary,
        child: Row(
          children: [
            Text(masterList[mIndex].categoryName, style: TextStyle(color: colorScheme.onPrimary)),
            const SizedBox(width: 3),
            Icon(Icons.arrow_drop_down, color: colorScheme.onPrimary),
          ],
        ),
      ),
      itemBuilder: (context) {
        return List.generate(masterList.length, (index) {
          final master = masterList[index];
          return PopupMenuItem<int>(
            value: index,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  master.categoryName,
                  style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
                Text(
                  master.modelName,
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        });
      },
      onSelected: (index) {
        vm.masterOnChanged(index);
      },
    );
  }
}