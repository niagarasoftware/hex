import 'package:flutter/material.dart';
import '../model/constant_setting_type_Model.dart';

class CustomPopUpButton extends StatelessWidget {
  final List<PopUpItemModel> popUpItemModelList;
  final dynamic selectedItemSno;
  final void Function(dynamic) onSelected;
  const CustomPopUpButton({
    super.key,
    required this.popUpItemModelList,
    required this.selectedItemSno,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (popUpItemModelList.isEmpty) {
      return Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
          color: colorScheme.surfaceContainerLow,
        ),
        alignment: Alignment.center,
        child: Text(
          '$selectedItemSno',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    PopUpItemModel selectedPopUpItemModel = popUpItemModelList.firstWhere(
          (item) => item.sNo == selectedItemSno,
      orElse: () => popUpItemModelList.first,
    );

    return PopupMenuButton(
      tooltip: '',
      initialValue: selectedPopUpItemModel.sNo,
      onSelected: onSelected,
      itemBuilder: (context) {
        return popUpItemModelList.map((item) {
          return PopupMenuItem(
            value: item.sNo,
            child: Text(
              item.title,
              style: TextStyle(
                fontSize: 12,
                color: item.color,
                fontWeight: FontWeight.bold,
              ),
              softWrap: true,
              textAlign: TextAlign.center,
            ),
          );
        }).toList();
      },
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selectedPopUpItemModel.color),
          color: selectedPopUpItemModel.color.withOpacity(0.12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        alignment: Alignment.center,
        child: Text(
          selectedPopUpItemModel.title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: selectedPopUpItemModel.color,
          ),
          softWrap: true,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
