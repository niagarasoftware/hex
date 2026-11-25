import 'package:flutter/material.dart';
import '../../../models/customer/site_model.dart';
import '../../../utils/constants.dart';
export 'hex_sidebar.dart';

class NavigationDestinationsBuilder {

  static List<NavigationRailDestination> build(
      BuildContext context, MasterControllerModel master) {
    final colorScheme = Theme.of(context).colorScheme;

    return [
      NavigationRailDestination(
        icon: const Tooltip(message: 'Home', child: Icon(Icons.home_outlined)),
        selectedIcon: Icon(Icons.home, color: colorScheme.onPrimaryContainer),
        label: const Text(''),
      ),
      NavigationRailDestination(
        icon: const Tooltip(message: 'All my devices', child: Icon(Icons.devices_other)),
        selectedIcon: Icon(Icons.devices_other, color: colorScheme.onPrimaryContainer),
        label: const Text(''),
      ),
      NavigationRailDestination(
        icon: const Tooltip(message: 'Sent & Received', child: Icon(Icons.question_answer_outlined)),
        selectedIcon: Icon(Icons.question_answer, color: colorScheme.onPrimaryContainer),
        label: const Text(''),
      ),
      if ([...AppConstants.gemModelList, ...AppConstants.ecoGemModelList, ...AppConstants.omsGemList].contains(master.modelId))
        NavigationRailDestination(
          icon: const Tooltip(message: 'Controller Logs', child: Icon(Icons.receipt_outlined)),
          selectedIcon: Icon(Icons.receipt, color: colorScheme.onPrimaryContainer),
          label: const Text(''),
        ),
      NavigationRailDestination(
        icon: const Tooltip(message: 'Settings', child: Icon(Icons.settings_outlined)),
        selectedIcon: Icon(Icons.settings, color: colorScheme.onPrimaryContainer),
        label: const Text(''),
      ),
      NavigationRailDestination(
        icon: const Tooltip(message: 'Configuration', child: Icon(Icons.confirmation_num_outlined)),
        selectedIcon: Icon(Icons.confirmation_num, color: colorScheme.onPrimaryContainer),
        label: const Text(''),
      ),
      NavigationRailDestination(
        icon: const Tooltip(message: 'Service Request', child: Icon(Icons.support_agent_sharp)),
        selectedIcon: Icon(Icons.support_agent_sharp, color: colorScheme.onPrimaryContainer),
        label: const Text(''),
      ),
      if ([...AppConstants.gemModelList].contains(master.modelId)
          && ![...AppConstants.aquacultureModelList].contains(master.modelId))
        NavigationRailDestination(
          icon: const Tooltip(message: 'Weather', child: Icon(Icons.sunny_snowing)),
          selectedIcon: Icon(Icons.wb_sunny_rounded, color: colorScheme.onPrimaryContainer),
          label: const Text(''),
        ),
      if ([...AppConstants.aquacultureModelList].contains(master.modelId) || [...AppConstants.gemModelList].contains(master.modelId))
        NavigationRailDestination(
          icon: const Tooltip(message: 'Geography', child: Icon(Icons.map_outlined)),
          selectedIcon: Icon(Icons.map_outlined, color: colorScheme.onPrimaryContainer),
          label: const Text(''),
        ),
    ];
  }
}