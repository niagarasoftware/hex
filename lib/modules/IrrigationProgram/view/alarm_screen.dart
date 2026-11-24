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
    final primaryPurple = const Color(0xFF5B21B6);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 12),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: primaryPurple,
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
    final primaryPurple = const Color(0xFF5B21B6);
    final iconIndex = alarmList.indexOf(alarmList[index]);
    final icon = iconIndex < iconList.length ? iconList[iconIndex] : Icons.warning_amber_outlined;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
        ),
        subtitle: const Text(
          "Trigger system alert when condition occurs",
          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        trailing: Switch(
          value: alarmList[index].value,
          activeColor: primaryPurple,
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
            color: const Color(0xFFF5F3FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: icon is IconData
                ? Icon(icon, color: primaryPurple, size: 22)
                : SvgPicture.asset(
                    icon as String,
                    width: 22,
                    height: 22,
                    colorFilter: ColorFilter.mode(primaryPurple, BlendMode.srcIn),
                  ),
          ),
        ),
      ),
    );
  }
}
