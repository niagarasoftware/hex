import 'package:flutter/material.dart';
import 'package:hex/views/customer/stand_alone/widgets/valve_card_table.dart';

import '../../../../models/customer/site_model.dart';

class IrrigationLineCard extends StatelessWidget {
  final IrrigationLineModel line;
  final bool showSwitch;

  final void Function(ValveModel valve, bool value) onToggleValve;
  final void Function(FoggerModel fogger, bool value) onToggleFogger;

  const IrrigationLineCard({
    super.key,
    required this.line,
    required this.showSwitch,
    required this.onToggleValve,
    required this.onToggleFogger,
  });

  @override
  Widget build(BuildContext context) {
    if (line.name == 'All irrigation line' ||
        line.name == 'All Aquaculture line') {
      return const SizedBox.shrink();
    }

    final valveItems = <ValveTileItem>[];

    for (final valve in line.valveObjects) {
      valveItems.add(ValveTileItem(
        iconPath: 'assets/png/m_valve_grey.png',
        name: valve.name,
        isOn: valve.isOn,
        onToggle: (val) => onToggleValve(valve, val),
      ));
    }

    for (final fogger in line.foggerObjects) {
      valveItems.add(ValveTileItem(
        iconPath: 'assets/png/mobile/m_fogger_grey.png',
        name: fogger.name,
        isOn: fogger.isOn,
        onToggle: (val) => onToggleFogger(fogger, val),
      ));
    }

    return ValveCardTable(
      title: line.name,
      showSwitch: showSwitch,
      switchValue: true,
      onSwitchChanged: (_) {},
      valveItems: valveItems,
    );
  }
}
