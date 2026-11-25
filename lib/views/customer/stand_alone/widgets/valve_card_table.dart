import 'package:flutter/material.dart';

class ValveTileItem {
  final String iconPath;
  final String name;
  final bool isOn;
  final ValueChanged<bool> onToggle;

  const ValveTileItem({
    required this.iconPath,
    required this.name,
    required this.isOn,
    required this.onToggle,
  });
}

class ValveCardTable extends StatefulWidget {
  final String title;
  final bool showSwitch;
  final bool switchValue;
  final ValueChanged<bool>? onSwitchChanged;
  final List<ValveTileItem>? valveItems;
  final List<ValveTileItem>? rows;

  const ValveCardTable({
    super.key,
    required this.title,
    required this.showSwitch,
    required this.switchValue,
    required this.onSwitchChanged,
    this.valveItems,
    this.rows,
  });

  @override
  State<ValveCardTable> createState() => _ValveCardTableState();
}

class _ValveCardTableState extends State<ValveCardTable> {
  bool isExpanded = true;

  List<ValveTileItem> get _items =>
      widget.valveItems ?? widget.rows ?? const [];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final activeCount = _items.where((v) => v.isOn).length;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
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
              top: const Radius.circular(14),
              bottom: isExpanded ? Radius.zero : const Radius.circular(14),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(14),
                  bottom: isExpanded ? Radius.zero : const Radius.circular(14),
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
                      widget.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "$activeCount/${_items.length} Active",
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  if (widget.showSwitch) ...[
                    const SizedBox(width: 8),
                    Transform.scale(
                      scale: 0.75,
                      child: Switch(
                        value: widget.switchValue,
                        activeThumbColor: colorScheme.onPrimary,
                        activeTrackColor: colorScheme.primary,
                        inactiveTrackColor: colorScheme.surfaceContainerHighest,
                        onChanged: widget.onSwitchChanged,
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // Responsive Tile Grid
          if (isExpanded && _items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  const spacing = 10.0;
                  int columns = 2; // Mobile default
                  if (width >= 900) {
                    columns = 6;
                  } else if (width >= 600) {
                    columns = 4;
                  } else if (width >= 400) {
                    columns = 3;
                  }

                  final itemWidth =
                      (width - (spacing * (columns - 1))) / columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: _items.map((item) {
                      final isSelected = item.isOn;

                      return SizedBox(
                        width: itemWidth,
                        child: InkWell(
                          onTap: () => item.onToggle(!item.isOn),
                          borderRadius: BorderRadius.circular(8),
                          child: Tooltip(
                            message: item.name,
                            waitDuration: const Duration(milliseconds: 500),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 40),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
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
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    item.iconPath,
                                    width: 22,
                                    height: 22,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.tune_rounded,
                                      size: 16,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      maxLines: 2,
                                      softWrap: true,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? colorScheme.primary
                                            : colorScheme.onSurface,
                                        height: 1.15,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Transform.scale(
                                    scale: 0.65,
                                    child: Switch(
                                      value: item.isOn,
                                      activeThumbColor: colorScheme.onPrimary,
                                      activeTrackColor: colorScheme.primary,
                                      inactiveTrackColor: colorScheme
                                          .surfaceContainerHighest,
                                      onChanged: item.onToggle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
