import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:hex/modules/constant/model/object_in_constant_model.dart';

import '../../../StateManagement/overall_use.dart';
import '../../../utils/constants.dart';
import '../state_management/constant_provider.dart';
import '../widget/find_suitable_widget.dart';

class FertilizerSiteInConstant extends StatefulWidget {
  final ConstantProvider constPvd;
  final OverAllUse overAllPvd;
  const FertilizerSiteInConstant({super.key, required this.constPvd, required this.overAllPvd});

  @override
  State<FertilizerSiteInConstant> createState() => _FertilizerSiteInConstantState();
}

class _FertilizerSiteInConstantState extends State<FertilizerSiteInConstant> {
  double cellWidth = 180;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    double screenWidth = MediaQuery.of(context).size.width;
    int settingLength = widget.constPvd.defaultFertilizerSiteSetting.where((setting) {
      if(AppConstants.gemModelList.contains(widget.constPvd.userData['modelId'])){
        return setting.gemDisplay;
      }else{
        return setting.ecoGemDisplay;
      }
    }).length;
    double minWidth = (cellWidth * 2) + (settingLength * cellWidth) + 50;

    return DataTable2(
      dataRowHeight: 56.0,
      headingRowHeight: 44.0,
      headingRowColor: WidgetStatePropertyAll(colorScheme.surfaceContainerLow),
      border: TableBorder.all(
        color: colorScheme.outlineVariant,
        width: 1,
      ),
      minWidth: minWidth,
      fixedLeftColumns: minWidth < screenWidth ? 0 : 1,
      columns: [
        DataColumn2(
            headingRowAlignment: MainAxisAlignment.center,
            fixedWidth: cellWidth,
            label: Text(
              'Fertilizer Site',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              softWrap: true,
            )
        ),
        ...widget.constPvd.defaultFertilizerSiteSetting
            .where((defaultSetting) => AppConstants.gemModelList.contains(widget.constPvd.userData['modelId']) ? defaultSetting.gemDisplay : defaultSetting.ecoGemDisplay)
            .map((defaultSetting) {
          return DataColumn2(
              headingRowAlignment: MainAxisAlignment.center,
              fixedWidth: cellWidth,
              label: Text(
                defaultSetting.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                softWrap: true,
              )
          );
        }),
      ],
      rows: List.generate(widget.constPvd.fertilizerSite.length, (row){
        ObjectInConstantModel fertilizerSite = widget.constPvd.fertilizerSite[row];
        return DataRow2(
            color: WidgetStatePropertyAll(
              row.isOdd ? colorScheme.surface : colorScheme.surfaceContainerLow,
            ),
            cells: [
              DataCell(
                Center(
                  child: Text(
                    fertilizerSite.name.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              ...fertilizerSite.setting
                  .where((defaultSetting) => AppConstants.gemModelList.contains(widget.constPvd.userData['modelId']) ? defaultSetting.gemDisplay : defaultSetting.ecoGemDisplay)
                  .map((setting) {
                return DataCell(
                    AnimatedBuilder(
                      animation: setting.value,
                      builder: (context, child){
                        return FindSuitableWidget(
                          constantSettingModel: setting,
                          onUpdate: (value){
                            setting.value.value = value;
                          },
                          onOk: (){
                            setting.value.value = widget.overAllPvd.getTime();
                            Navigator.pop(context);
                          },
                          popUpItemModelList: widget.constPvd.fertilizerSiteControlFlag,
                        );
                      },
                    )

                );
              }),

            ]
        );
      }),

    );

  }
}
