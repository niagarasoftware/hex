import 'package:flutter/material.dart';

import '../../../../view_models/base_header_view_model.dart';

class MainMenu extends StatelessWidget {
  final Axis direction;
  final BaseHeaderViewModel viewModel;

  const MainMenu({
    super.key,
    this.direction = Axis.vertical,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(viewModel.menuTitles.length, (index) {
          final isSelected = viewModel.selectedIndex == index;
          final isHovered = viewModel.hoveredIndex == index;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => viewModel.onHoverChange(index),
              onExit: (_) => viewModel.onHoverChange(-1),
              child: InkWell(
                onTap: () => viewModel.onDestinationSelectingChange(index),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primaryContainer
                        : isHovered
                            ? colorScheme.onPrimary.withOpacity(0.12)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 7),
                  child: Row(
                    children: [
                      Icon(
                        index == 0
                            ? Icons.dashboard_outlined
                            : index == 1
                                ? Icons.inventory_2_outlined
                                : Icons.warehouse_outlined,
                        size: 18,
                        color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        viewModel.menuTitles[index],
                        style: TextStyle(
                          color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}