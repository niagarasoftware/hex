import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:hex/modules/constant/model/object_in_constant_model.dart';
import 'package:hex/utils/constants.dart';
import '../../../StateManagement/overall_use.dart';
import '../state_management/constant_provider.dart';
import '../widget/find_suitable_widget.dart';

class ChannelInConstant extends StatefulWidget {
  final ConstantProvider constPvd;
  final OverAllUse overAllPvd;
  const ChannelInConstant({super.key, required this.constPvd, required this.overAllPvd});

  @override
  State<ChannelInConstant> createState() => _ChannelInConstantState();
}

class _ChannelInConstantState extends State<ChannelInConstant> {
  double cellWidth = 180;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    double screenWidth = MediaQuery.of(context).size.width;
    int settingLength = widget.constPvd.defaultChannelSetting.where((setting) {
      if(AppConstants.gemModelList.contains(widget.constPvd.userData['modelId'])){
        return setting.gemDisplay;
      }else{
        return setting.ecoGemDisplay;
      }
    }).length;
    double minWidth = (cellWidth * 4) + (settingLength * cellWidth) + 50;

    return DataTable2(
      dataRowHeight: 64.0,
      headingRowHeight: 44.0,
      headingRowColor: WidgetStatePropertyAll(colorScheme.surfaceContainerLow),
      border: TableBorder.all(
        color: colorScheme.outlineVariant,
        width: 1,
      ),
      minWidth: minWidth,
      fixedLeftColumns: minWidth < screenWidth ? 0 : 1,
      columns: [
        ...['Channel', 'Location', 'Device', 'Connection No'].map((title) {
          return DataColumn2(
            headingRowAlignment: MainAxisAlignment.center,
            fixedWidth: cellWidth,
            label: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              softWrap: true,
            ),
          );
        }),
        ...widget.constPvd.defaultChannelSetting
            .where((defaultSetting) => AppConstants.gemModelList.contains(widget.constPvd.userData['modelId']) ? defaultSetting.gemDisplay : defaultSetting.ecoGemPayload)
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
            ),
          );
        }),
      ],
      rows: List.generate(widget.constPvd.channel.length, (row){
        ObjectInConstantModel channel = widget.constPvd.channel[row];
        final devName = widget.constPvd.getDeviceDetails(key: 'deviceName', controllerId: channel.controllerId);
        final devId = widget.constPvd.getDeviceDetails(key: 'deviceId', controllerId: channel.controllerId);

        return DataRow2(
            color: WidgetStatePropertyAll(
              row.isOdd ? colorScheme.surface : colorScheme.surfaceContainerLow,
            ),
            cells: [
              DataCell(
                Center(
                  child: Text(
                    channel.name.toString(),
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
                Center(
                  child: Text(
                    widget.constPvd.getName(channel.location),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              DataCell(
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        devName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        devId,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(
                Center(
                  child: Text(
                    '${channel.connectionNo}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface),
                    softWrap: true,
                  ),
                ),
              ),
              ...channel.setting
                  .where((defaultSetting) => AppConstants.gemModelList.contains(widget.constPvd.userData['modelId']) ? defaultSetting.gemDisplay : defaultSetting.ecoGemPayload)
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
                          popUpItemModelList: widget.constPvd.fertilizerChannelMode,
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
