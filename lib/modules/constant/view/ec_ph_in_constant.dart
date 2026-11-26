import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:hex/modules/constant/model/ec_ph_in_constant_model.dart';

import '../../../StateManagement/overall_use.dart';
import '../state_management/constant_provider.dart';
import '../widget/find_suitable_widget.dart';

class EcPhInConstant extends StatefulWidget {
  final ConstantProvider constPvd;
  final OverAllUse overAllPvd;
  const EcPhInConstant({super.key, required this.constPvd, required this.overAllPvd});

  @override
  State<EcPhInConstant> createState() => _EcPhInConstantState();
}

class _EcPhInConstantState extends State<EcPhInConstant> {
  double cellWidth = 150;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    double screenWidth = MediaQuery.of(context).size.width;
    double minWidth = (cellWidth * 2) + (widget.constPvd.defaultEcPhSetting.length * cellWidth) + 50;

    return DataTable2(
      dataRowHeight: 88.0,
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
        DataColumn2(
            headingRowAlignment: MainAxisAlignment.center,
            fixedWidth: cellWidth,
            label: Text(
              'Sensor',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              softWrap: true,
            )
        ),
        ...widget.constPvd.defaultEcPhSetting.map((defaultSetting) {
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
      rows: List.generate(widget.constPvd.ecPhSensor.length, (row){
        EcPhInConstantModel fertilizerSite = widget.constPvd.ecPhSensor[row];
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
              DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if(fertilizerSite.ecPopup.isNotEmpty)
                        Center(child: Text('Ec Sensor', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant))),
                      if(fertilizerSite.phPopup.isNotEmpty)
                        Center(child: Text('Ph Sensor', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant))),
                    ],
                  )
              ),
              ...List.generate(widget.constPvd.defaultEcPhSetting.length, (index){
                return DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // AnimatedBuilder(
                        //     animation: fertilizerSite.setting[0][index].value,
                        //     builder: (context, child){
                        //       return SizedBox(
                        //         height: 40,
                        //         width: cellWidth,
                        //         child: FindSuitableWidget(
                        //           constantSettingModel: fertilizerSite.setting[0][index],
                        //           onUpdate: (value){
                        //             fertilizerSite.setting[0][index].value.value = value;
                        //           },
                        //           onOk: (){
                        //             fertilizerSite.setting[0][index].value.value = widget.overAllPvd.getTime();
                        //             Navigator.pop(context);
                        //           },
                        //           popUpItemModelList: fertilizerSite.ecPopup,
                        //         ),
                        //       );
                        //     }
                        // ),
                        if(fertilizerSite.ecSetting.isNotEmpty)
                          AnimatedBuilder(
                            animation: fertilizerSite.ecSetting[index].value,
                            builder: (context, child){
                              return SizedBox(
                                height: 40,
                                width: cellWidth,
                                child: FindSuitableWidget(
                                  constantSettingModel: fertilizerSite.ecSetting[index],
                                  onUpdate: (value){
                                    fertilizerSite.ecSetting[index].value.value = value;
                                  },
                                  onOk: (){
                                    fertilizerSite.ecSetting[index].value.value = widget.overAllPvd.getTime();
                                    Navigator.pop(context);
                                  },
                                  popUpItemModelList: fertilizerSite.ecPopup,
                                ),
                              );
                            }
                        ),

                        if(fertilizerSite.phSetting.isNotEmpty)
                        // if(fertilizerSite.setting.length > 1)
                          // AnimatedBuilder(
                          //     animation: fertilizerSite.setting[1][index].value,
                          //     builder: (context, child){
                          //       return SizedBox(
                          //         width: cellWidth,
                          //         height: 40,
                          //         child: FindSuitableWidget(
                          //           constantSettingModel: fertilizerSite.setting[1][index],
                          //           onUpdate: (value){
                          //             fertilizerSite.setting[1][index].value.value = value;
                          //           },
                          //           onOk: (){
                          //             fertilizerSite.setting[1][index].value.value = widget.overAllPvd.getTime();
                          //             Navigator.pop(context);
                          //           },
                          //           popUpItemModelList: fertilizerSite.phPopup,
                          //         ),
                          //       );
                          //     }
                          // )
                          AnimatedBuilder(
                              animation: fertilizerSite.phSetting[index].value,
                              builder: (context, child){
                                return SizedBox(
                                  width: cellWidth,
                                  height: 40,
                                  child: FindSuitableWidget(
                                    constantSettingModel: fertilizerSite.phSetting[index],
                                    onUpdate: (value){
                                      fertilizerSite.phSetting[index].value.value = value;
                                    },
                                    onOk: (){
                                      fertilizerSite.phSetting[index].value.value = widget.overAllPvd.getTime();
                                      Navigator.pop(context);
                                    },
                                    popUpItemModelList: fertilizerSite.phPopup,
                                  ),
                                );
                              }
                          )
                      ],
                    )
                );
              })
            ]
        );
      }),
    );
  }
}