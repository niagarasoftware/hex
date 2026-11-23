import 'package:flutter/material.dart';
import 'package:hex/modules/constant/model/constant_setting_model.dart';
import 'package:hex/modules/constant/model/constant_setting_type_Model.dart';
import 'package:hex/modules/constant/state_management/constant_provider.dart';
import 'package:hex/modules/constant/widget/find_suitable_widget.dart';
import 'package:hex/utils/constants.dart';

import '../../../StateManagement/overall_use.dart';

class GeneralInConstant extends StatefulWidget {
  final ConstantProvider constPvd;
  final OverAllUse overAllPvd;
  const GeneralInConstant(
      {super.key, required this.constPvd, required this.overAllPvd});

  @override
  State<GeneralInConstant> createState() => _GeneralInConstantState();
}

class _GeneralInConstantState extends State<GeneralInConstant> {
  int? _getModelId() {
    var uData = widget.constPvd.userData;
    var rawModelId = uData['modelId'] ??
        uData['modelid'] ??
        (uData['masterData'] is Map
            ? (uData['masterData']['modelId'] ?? uData['masterData']['modelid'])
            : null);
    return rawModelId is int
        ? rawModelId
        : int.tryParse(rawModelId?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final modelId = _getModelId();
    final isGem = modelId != null && AppConstants.gemModelList.contains(modelId);

    final visibleSettings = widget.constPvd.general.where((setting) {
      if (modelId == null) {
        return true;
      }
      return isGem ? setting.gemDisplay : setting.ecoGemDisplay;
    }).toList();

    if (visibleSettings.isEmpty && widget.constPvd.general.isNotEmpty) {
      visibleSettings.addAll(widget.constPvd.general);
    }

    final dosingSettings = <ConstantSettingModel>[];
    final timingSettings = <ConstantSettingModel>[];
    final loraSettings = <ConstantSettingModel>[];
    final otherSettings = <ConstantSettingModel>[];

    for (final setting in visibleSettings) {
      final t = setting.title.toLowerCase();
      if (t.contains('dosing') ||
          t.contains('fertilizer') ||
          t.contains('leakage') ||
          t.contains('water pulse') ||
          t.contains('valve')) {
        dosingSettings.add(setting);
      } else if (t.contains('time') ||
          t.contains('delay') ||
          t.contains('reset')) {
        timingSettings.add(setting);
      } else if (t.contains('lora') ||
          t.contains('key') ||
          t.contains('channel')) {
        loraSettings.add(setting);
      } else {
        otherSettings.add(setting);
      }
    }

    final groupCards = <Widget>[];

    if (dosingSettings.isNotEmpty) {
      groupCards.add(_buildSettingGroupCard(
        context: context,
        title: 'Dosing',
        icon: Icons.water_drop_outlined,
        settings: dosingSettings,
      ));
    }

    if (timingSettings.isNotEmpty) {
      groupCards.add(_buildSettingGroupCard(
        context: context,
        title: 'Timing',
        icon: Icons.access_time_outlined,
        settings: timingSettings,
      ));
    }

    if (loraSettings.isNotEmpty) {
      groupCards.add(_buildSettingGroupCard(
        context: context,
        title: 'LoRa & Communication',
        icon: Icons.sensors_outlined,
        settings: loraSettings,
      ));
    }

    if (otherSettings.isNotEmpty) {
      groupCards.add(_buildSettingGroupCard(
        context: context,
        title: 'General Controls',
        icon: Icons.tune_rounded,
        settings: otherSettings,
      ));
    }

    if (groupCards.isEmpty) {
      return const Center(child: Text("No general settings available."));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final isMobile = constraints.maxWidth < 650;

        if (isMobile || groupCards.length <= 1) {
          return SingleChildScrollView(
            child: Column(
              children: [
                for (final card in groupCards) ...[
                  card,
                  const SizedBox(height: spacing),
                ],
              ],
            ),
          );
        }

        final leftColumn = <Widget>[];
        final rightColumn = <Widget>[];

        for (int i = 0; i < groupCards.length; i++) {
          if (i % 2 == 0) {
            leftColumn.add(groupCards[i]);
          } else {
            rightColumn.add(groupCards[i]);
          }
        }

        final colWidth = (constraints.maxWidth - spacing) / 2;

        return SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: colWidth,
                child: Column(
                  children: [
                    for (int i = 0; i < leftColumn.length; i++) ...[
                      leftColumn[i],
                      if (i < leftColumn.length - 1)
                        const SizedBox(height: spacing),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: spacing),
              SizedBox(
                width: colWidth,
                child: Column(
                  children: [
                    for (int i = 0; i < rightColumn.length; i++) ...[
                      rightColumn[i],
                      if (i < rightColumn.length - 1)
                        const SizedBox(height: spacing),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingGroupCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<ConstantSettingModel> settings,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.4),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: colorScheme.primary,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 0.5,
            color: colorScheme.outlineVariant.withOpacity(0.3),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < settings.length; i++) ...[
                _buildSettingRow(context, settings[i]),
                if (i < settings.length - 1)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: colorScheme.outlineVariant.withOpacity(0.3),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(BuildContext context, ConstantSettingModel setting) {
    final colorScheme = Theme.of(context).colorScheme;
    final description = _getSettingDescription(setting.title);

    List<PopUpItemModel> popUpList = const [];
    if (setting.widgetTypeId == 6) {
      if (setting.title.toLowerCase().contains('status')) {
        popUpList = widget.constPvd.alarmOnStatus;
      } else if (setting.title.toLowerCase().contains('reset')) {
        popUpList = widget.constPvd.alarmResetAfterIrrigation;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  setting.title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          IntrinsicWidth(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 80, maxWidth: 160),
              child: AnimatedBuilder(
                animation: setting.value,
                builder: (context, child) {
                  return FindSuitableWidget(
                    constantSettingModel: setting,
                    onUpdate: (value) {
                      setting.value.value = value;
                    },
                    onOk: () {
                      setState(() {
                        setting.value.value = widget.overAllPvd.getTime();
                      });
                      Navigator.pop(context);
                    },
                    popUpItemModelList: popUpList,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _getSettingDescription(String title) {
    final t = title.toLowerCase();
    if (t.contains('water pulse')) return 'Short flush before fertilizer starts';
    if (t.contains('pump on')) return 'Delay pump start until the valve opens';
    if (t.contains('reset time')) return 'HH:MM:SS';
    if (t.contains('no pressure delay')) return 'HH:MM:SS';
    return null;
  }
}
