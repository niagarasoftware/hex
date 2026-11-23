import 'package:flutter/material.dart';
import '../../../../models/customer/site_model.dart';
import 'custom_card_table.dart';
import 'custom_switch_row.dart';

class SourcePumpCard extends StatelessWidget {
  final List<PumpModel> pumps;
  final void Function(PumpModel, bool) onChanged;

  const SourcePumpCard({
    super.key,
    required this.pumps,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (pumps.isEmpty) return const SizedBox.shrink();

    final activeCount = pumps.where((p) => p.selected).length;

    return CustomCardTable(
      title: "Source Pump",
      activeCountText: "$activeCount/${pumps.length} Active",
      rows: pumps.map((pump) {
        return CustomSwitchRow(
          iconPath: 'assets/png/dp_pump.png',
          label: pump.name,
          value: pump.selected,
          onChanged: (val) => onChanged(pump, val),
        );
      }).toList(),
    );
  }
}
