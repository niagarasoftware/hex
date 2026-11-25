import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hex/models/customer/site_model.dart';

class FertMainSourceCard extends StatefulWidget {
  final List<FertMainSource> sources;
  final void Function(PumpModel pump, bool value) onChanged;

  const FertMainSourceCard({
    super.key,
    required this.sources,
    required this.onChanged,
  });

  @override
  State<FertMainSourceCard> createState() => _FertMainSourceCardState();
}

class _FertMainSourceCardState extends State<FertMainSourceCard> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final withPumps = widget.sources.where((s) => s.pumps.isNotEmpty).toList();
    if (withPumps.isEmpty) return const SizedBox.shrink();

    int activeCount = 0;
    int totalPumps = 0;
    for (final s in withPumps) {
      for (final p in s.pumps) {
        totalPumps++;
        if (p.selected) activeCount++;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar
          InkWell(
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: isExpanded ? Radius.zero : const Radius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12),
                  bottom: isExpanded ? Radius.zero : const Radius.circular(12),
                ),
                border: isExpanded
                    ? Border(
                        bottom: BorderSide(
                          color: colorScheme.outlineVariant,
                          width: 0.5,
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Fertilizer Main Source Pump',
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "$activeCount/$totalPumps Active",
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // Content Grid
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final s in withPumps) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, top: 2),
                      child: Text(
                        s.source.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        const spacing = 8.0;
                        int columns = 1;
                        if (width >= 600) {
                          columns = 3;
                        } else if (width >= 320) {
                          columns = 2;
                        }

                        final itemWidth =
                            (width - (spacing * (columns - 1))) / columns;

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: s.pumps.map((pump) {
                            final isSelected = pump.selected;

                            return SizedBox(
                              width: itemWidth,
                              child: InkWell(
                                onTap: () => widget.onChanged(pump, !pump.selected),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.primaryContainer
                                            .withOpacity(0.45)
                                        : colorScheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? colorScheme.primary
                                          : colorScheme.outlineVariant,
                                      width: isSelected ? 1.2 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: Center(
                                          child: SvgPicture.asset(
                                            'assets/svg_images/pump.svg',
                                            width: 18,
                                            height: 18,
                                            colorFilter: ColorFilter.mode(
                                              isSelected
                                                  ? colorScheme.primary
                                                  : colorScheme
                                                      .onSurfaceVariant,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          pump.name,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? colorScheme.primary
                                                : colorScheme.onSurface,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Transform.scale(
                                        scale: 0.6,
                                        child: Switch(
                                          value: pump.selected,
                                          activeThumbColor: colorScheme.onPrimary,
                                          activeTrackColor: colorScheme.primary,
                                          inactiveTrackColor: colorScheme
                                              .surfaceContainerHighest,
                                          onChanged: (v) =>
                                              widget.onChanged(pump, v),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class FertTankValveCard extends StatefulWidget {
  final List<FertTank> tanks;
  final void Function(TankValveModel valve, bool value) onChanged;

  const FertTankValveCard({
    super.key,
    required this.tanks,
    required this.onChanged,
  });

  @override
  State<FertTankValveCard> createState() => _FertTankValveCardState();
}

class _FertTankValveCardState extends State<FertTankValveCard> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final visible = widget.tanks
        .where((t) => t.inletValves.isNotEmpty || t.outletValves.isNotEmpty)
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    int activeCount = 0;
    int totalValves = 0;
    for (final t in visible) {
      for (final v in t.inletValves) {
        totalValves++;
        if (v.selected) activeCount++;
      }
      for (final v in t.outletValves) {
        totalValves++;
        if (v.selected) activeCount++;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar
          InkWell(
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: isExpanded ? Radius.zero : const Radius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12),
                  bottom: isExpanded ? Radius.zero : const Radius.circular(12),
                ),
                border: isExpanded
                    ? Border(
                        bottom: BorderSide(
                          color: colorScheme.outlineVariant,
                          width: 0.5,
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Fertilizer Tank Valves',
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "$activeCount/$totalValves Active",
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // Content Grid
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final t in visible) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, top: 2),
                      child: Text(
                        t.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        const spacing = 8.0;
                        int columns = 1;
                        if (width >= 600) {
                          columns = 3;
                        } else if (width >= 320) {
                          columns = 2;
                        }

                        final itemWidth =
                            (width - (spacing * (columns - 1))) / columns;

                        final tankValves = <Map<String, dynamic>>[];
                        for (final v in t.inletValves) {
                          tankValves.add({'valve': v, 'kind': 'Inlet'});
                        }
                        for (final v in t.outletValves) {
                          tankValves.add({'valve': v, 'kind': 'Outlet'});
                        }

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: tankValves.map((map) {
                            final TankValveModel v = map['valve'];
                            final String kind = map['kind'];
                            final isSelected = v.selected;
                            final injectors = v.channelNames.isEmpty
                                ? ''
                                : ' • ${v.channelNames.join(', ')}';

                            return SizedBox(
                              width: itemWidth,
                              child: InkWell(
                                onTap: () => widget.onChanged(v, !v.selected),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.primaryContainer
                                            .withOpacity(0.45)
                                        : colorScheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? colorScheme.primary
                                          : colorScheme.outlineVariant,
                                      width: isSelected ? 1.2 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: Center(
                                          child: FaIcon(
                                            FontAwesomeIcons.faucetDrip,
                                            size: 14,
                                            color: isSelected
                                                ? colorScheme.primary
                                                : colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              v.name,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.w600,
                                                color: isSelected
                                                    ? colorScheme.primary
                                                    : colorScheme.onSurface,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '$kind$injectors',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Transform.scale(
                                        scale: 0.6,
                                        child: Switch(
                                          value: v.selected,
                                          activeThumbColor: colorScheme.onPrimary,
                                          activeTrackColor: colorScheme.primary,
                                          inactiveTrackColor: colorScheme
                                              .surfaceContainerHighest,
                                          onChanged: (val) =>
                                              widget.onChanged(v, val),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
