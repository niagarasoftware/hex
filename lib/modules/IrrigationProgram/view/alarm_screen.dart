import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:hex/modules/IrrigationProgram/model/sequence_model.dart';
import 'package:hex/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/svg.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

import '../state_management/irrigation_program_provider.dart';

class AlarmScreen extends StatefulWidget {
  final int modelId;
  const AlarmScreen({super.key, required this.modelId});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  late IrrigationProgramMainProvider irrigationProgramMainProvider;
  late List<AlarmData> alarmList;
  final iconList = [
    MdiIcons.gaugeLow,
    MdiIcons.gaugeFull,
    MdiIcons.gaugeEmpty,
    'assets/SVGPicture/ec high.svg',
    'assets/SVGPicture/ph low.svg',
    'assets/SVGPicture/ph high.svg',
    MdiIcons.speedometerSlow,
    MdiIcons.speedometer,
    MdiIcons.powerPlugOff,
    'assets/SVGPicture/no communication.svg',
    'assets/SVGPicture/wrong feedback1.svg',
    'assets/SVGPicture/sump empty.svg',
    'assets/SVGPicture/tank full.svg',
    MdiIcons.batteryLow,
    'assets/SVGPicture/ec diff.svg',
    'assets/SVGPicture/ph-differencef.svg',
    'assets/SVGPicture/pumpoff1.svg',
    'assets/SVGPicture/pressure switch.svg',
    'assets/SVGPicture/pressure switch.svg',
  ];

  @override
  void initState() {
    super.initState();
    irrigationProgramMainProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: false);
    if (AppConstants.gemModelList.contains(widget.modelId)) {
      alarmList = irrigationProgramMainProvider.newAlarmList!.alarmList.where((e) => e.gemDisplay).toList();
    } else {
      alarmList = irrigationProgramMainProvider.newAlarmList!.alarmList.where((e) => e.ecoGemDisplay).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    irrigationProgramMainProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: true);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 12),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () {
                setState(() {
                  for (var i = 0; i < alarmList.length; i++) {
                    alarmList[i].value = irrigationProgramMainProvider.newAlarmList!.defaultAlarm[i].value;
                  }
                });
              },
              icon: const Icon(Icons.sync_outlined, size: 16, color: Colors.white),
              label: Text("Use global alarm".toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
          Expanded(
            child: ResponsiveGridList(
              horizontalGridMargin: 8,
              verticalGridMargin: 8,
              minItemWidth: 320,
              children: [
                for (var index = 0; index < alarmList.length; index++)
                  if (AppConstants.omsGemList.contains(widget.modelId) && [1, 3].contains(alarmList[index].sNo))
                    _buildAlarmListTile(index)
                  else if (!AppConstants.omsGemList.contains(widget.modelId))
                    _buildAlarmListTile(index),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmListTile(int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconIndex = alarmList.indexOf(alarmList[index]);
    final icon = iconIndex < iconList.length ? iconList[iconIndex] : Icons.warning_amber_outlined;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        horizontalTitleGap: 16,
        title: Text(
          alarmList[index].name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface),
        ),
        subtitle: Text(
          "Trigger system alert when condition occurs",
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
        ),
        trailing: Switch(
          value: alarmList[index].value,
          activeThumbColor: colorScheme.onPrimary,
          activeTrackColor: colorScheme.primary,
          onChanged: (newValue) {
            setState(() {
              final newIndex = irrigationProgramMainProvider.newAlarmList!.alarmList.indexWhere((e) => e.sNo == alarmList[index].sNo);
              irrigationProgramMainProvider.newAlarmList!.alarmList[newIndex].value = newValue;
            });
          },
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: icon is IconData
                ? Icon(icon, color: colorScheme.primary, size: 22)
                : SvgPicture.asset(
                    icon as String,
                    width: 22,
                    height: 22,
                    colorFilter: ColorFilter.mode(colorScheme.primary, BlendMode.srcIn),
                  ),
          ),
        ),
      ),
    );
  }
}
