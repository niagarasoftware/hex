import 'package:flutter/material.dart';

import '../../../../models/customer/site_model.dart';
import 'custom_card_table.dart';
import 'custom_switch_row.dart';

class FertilizerSiteCard extends StatelessWidget {
  final List<FertilizerSiteModel> sites;
  final void Function(FertilizerItem, bool) onChanged;

  const FertilizerSiteCard({
    super.key,
    required this.sites,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (sites.isEmpty) return const SizedBox.shrink();

    return Column(
      children: sites.map((site) {
        final cardItems = <Widget>[];
        int activeCount = 0;
        int totalCount = 0;

        for (final c in site.channel) {
          totalCount++;
          if (c.selected) activeCount++;
          cardItems.add(CustomSwitchRow(
            iconPath: 'assets/png/fert_chanel.png',
            label: c.name,
            value: c.selected,
            onChanged: (val) => onChanged(c, val),
          ));
        }

        for (final bp in site.boosterPump) {
          totalCount++;
          if (bp.selected) activeCount++;
          cardItems.add(CustomSwitchRow(
            iconPath: 'assets/png/booster_pump.png',
            label: bp.name,
            value: bp.selected,
            onChanged: (val) => onChanged(bp, val),
          ));
        }

        for (final a in site.agitator) {
          totalCount++;
          if (a.selected) activeCount++;
          cardItems.add(CustomSwitchRow(
            iconPath: 'assets/png/agitator_gray.png',
            label: a.name,
            value: a.selected,
            onChanged: (val) => onChanged(a, val),
          ));
        }

        for (final s in site.selector) {
          totalCount++;
          if (s.selected) activeCount++;
          cardItems.add(CustomSwitchRow(
            iconPath: 'assets/png/selector.png',
            label: s.name,
            value: s.selected,
            onChanged: (val) => onChanged(s, val),
          ));
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CustomCardTable(
            title: site.name,
            activeCountText: "$activeCount/$totalCount Active",
            rows: cardItems,
          ),
        );
      }).toList(),
    );
  }
}
