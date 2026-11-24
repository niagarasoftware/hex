import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hex/modules/constant/model/constant_setting_model.dart';
import 'package:hex/modules/constant/state_management/constant_provider.dart';
import 'package:hex/modules/constant/widget/find_suitable_widget.dart';
import 'package:provider/provider.dart';
import '../../../StateManagement/overall_use.dart';
import '../../../Widgets/custom_buttons.dart';
import '../../../Widgets/status_box.dart';
import '../../../services/communication_service.dart';
import '../../../services/mqtt_service.dart';
import '../../../utils/constants.dart';
import '../../config_maker/view/config_web_view.dart';
import '../model/constant_setting_type_Model.dart';
import '../repository/constant_repository.dart';

class GlobalAlarmInConstant extends StatefulWidget {
  final ConstantProvider constPvd;
  final OverAllUse overAllPvd;
  final Map<String, dynamic> userData;
  const GlobalAlarmInConstant(
      {super.key,
        required this.constPvd,
        required this.overAllPvd,
        required this.userData});

  @override
  State<GlobalAlarmInConstant> createState() => _GlobalAlarmInConstantState();
}

class _GlobalAlarmInConstantState extends State<GlobalAlarmInConstant> {
  HardwareAcknowledgementState payloadState =
      HardwareAcknowledgementState.notSent;
  MqttService mqttService = MqttService();

  @override
  void initState() {
    super.initState();
    mqttService.initializeMQTTClient(state: null);
    mqttService.connect();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isGem =
    AppConstants.gemModelList.contains(widget.constPvd.userData['modelId']);

    final visibleSettings = widget.constPvd.globalAlarm.where((defaultSetting) {
      return isGem ? defaultSetting.gemDisplay : defaultSetting.ecoGemDisplay;
    }).toList();

    final systemAlarms = <ConstantSettingModel>[];
    final sensorAlarms = <ConstantSettingModel>[];
    final otherAlarms = <ConstantSettingModel>[];

    for (final setting in visibleSettings) {
      final t = setting.title.toLowerCase();
      if (t.contains('comm') ||
          t.contains('power') ||
          t.contains('line') ||
          t.contains('system')) {
        systemAlarms.add(setting);
      } else if (t.contains('pressure') ||
          t.contains('flow') ||
          t.contains('level') ||
          t.contains('moisture') ||
          t.contains('ec') ||
          t.contains('ph')) {
        sensorAlarms.add(setting);
      } else {
        otherAlarms.add(setting);
      }
    }

    final groupCards = <Widget>[];

    if (systemAlarms.isNotEmpty) {
      groupCards.add(_buildSettingGroupCard(
        context: context,
        title: 'System & Power Alarms',
        icon: Icons.power_settings_new_rounded,
        settings: systemAlarms,
      ));
    }

    if (sensorAlarms.isNotEmpty) {
      groupCards.add(_buildSettingGroupCard(
        context: context,
        title: 'Sensor & Flow Alarms',
        icon: Icons.sensors_outlined,
        settings: sensorAlarms,
      ));
    }

    if (otherAlarms.isNotEmpty) {
      groupCards.add(_buildSettingGroupCard(
        context: context,
        title: 'General Alarm Triggers',
        icon: Icons.warning_amber_rounded,
        settings: otherAlarms,
      ));
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 16.0;
              final isMobile = constraints.maxWidth < 650;

              if (isMobile || groupCards.length <= 1) {
                return Column(
                  children: [
                    for (final card in groupCards) ...[
                      card,
                      const SizedBox(height: spacing),
                    ],
                  ],
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

              return Row(
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
              );
            },
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text(
                'Send Global Alarm Payload',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                setState(() {
                  payloadState = HardwareAcknowledgementState.notSent;
                  mqttService.acknowledgementPayload = null;
                });
                showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: (context) {
                      return StatefulBuilder(builder: (context, stateSetter) {
                        return AlertDialog(
                          title: Text(
                            'Send Payload',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          content:
                          getHardwareAcknowledgementWidget(payloadState),
                          actions: [
                            if (payloadState !=
                                HardwareAcknowledgementState.sending &&
                                payloadState !=
                                    HardwareAcknowledgementState.notSent)
                              CustomMaterialButton(),
                            if (payloadState ==
                                HardwareAcknowledgementState.notSent)
                              CustomMaterialButton(
                                title: 'Cancel',
                                outlined: true,
                              ),
                            if (payloadState ==
                                HardwareAcknowledgementState.notSent)
                              CustomMaterialButton(
                                onPressed: () async {
                                  sendToHttp();
                                  var payload =
                                  jsonEncode(getConstantHardwarePayload());
                                  int delayDuration = 50;
                                  for (var delay = 0;
                                  delay < delayDuration;
                                  delay++) {
                                    if (delay == 0) {
                                      stateSetter(() {
                                        setState(() {
                                          context
                                              .read<CommunicationService>()
                                              .sendCommand(
                                            serverMsg: '',
                                            payload: payload,
                                          );
                                          payloadState =
                                              HardwareAcknowledgementState
                                                  .sending;
                                        });
                                      });
                                    }
                                    stateSetter(() {
                                      setState(() {
                                        if (mqttService
                                            .acknowledgementPayload !=
                                            null) {
                                          if (validatePayloadFromHardware(
                                              mqttService
                                                  .acknowledgementPayload,
                                              ['cC'],
                                              widget
                                                  .userData['deviceId']) &&
                                              validatePayloadFromHardware(
                                                  mqttService
                                                      .acknowledgementPayload!,
                                                  ['cM', '4201', 'PayloadCode'],
                                                  '300')) {
                                            if (mqttService
                                                .acknowledgementPayload![
                                            'cM']['4201']['Code'] ==
                                                '200') {
                                              payloadState =
                                                  HardwareAcknowledgementState
                                                      .success;
                                            } else if (mqttService
                                                .acknowledgementPayload![
                                            'cM']['4201']['Code'] ==
                                                '90') {
                                              payloadState =
                                                  HardwareAcknowledgementState
                                                      .programRunning;
                                            } else if (mqttService
                                                .acknowledgementPayload![
                                            'cM']['4201']['Code'] ==
                                                '1') {
                                              payloadState =
                                                  HardwareAcknowledgementState
                                                      .hardwareUnknownError;
                                            } else {
                                              payloadState =
                                                  HardwareAcknowledgementState
                                                      .errorOnPayload;
                                            }
                                            mqttService.acknowledgementPayload =
                                            null;
                                          }
                                        }
                                      });
                                    });
                                    await Future.delayed(
                                        const Duration(seconds: 1));
                                    if (delay == delayDuration - 1) {
                                      stateSetter(() {
                                        setState(() {
                                          payloadState =
                                              HardwareAcknowledgementState
                                                  .failed;
                                        });
                                      });
                                    }
                                    if (payloadState !=
                                        HardwareAcknowledgementState.sending) {
                                      break;
                                    }
                                  }
                                },
                                title: 'Send',
                              ),
                          ],
                        );
                      });
                    });
              },
            ),
          ),
        ],
      ),
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

  Widget _buildSettingRow(
      BuildContext context, ConstantSettingModel setting) {
    final colorScheme = Theme.of(context).colorScheme;

    List<PopUpItemModel> popUpList = const [];
    if (setting.widgetTypeId == 6) {
      if (setting.title.toLowerCase().contains('status')) {
        popUpList = widget.constPvd.alarmOnStatus;
      } else {
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
              ],
            ),
          ),
          const SizedBox(width: 12),
          IntrinsicWidth(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 80, maxWidth: 140),
              child: AnimatedBuilder(
                animation: setting.value,
                builder: (context, child) {
                  return FindSuitableWidget(
                    constantSettingModel: setting,
                    onUpdate: (value) {
                      setState(() {
                        setting.value.value = value;
                      });
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

  Map<String, dynamic> getConstantHardwarePayload() {
    return widget.constPvd.getConstantHardwarePayload();
  }

  Widget getHardwareAcknowledgementWidget(HardwareAcknowledgementState state) {
    if (state == HardwareAcknowledgementState.notSent) {
      return const StatusBox(
        color: Colors.black87,
        child: Text('Do you want to send payload..'),
      );
    } else if (state == HardwareAcknowledgementState.success) {
      return const StatusBox(
        color: Colors.green,
        child: Text('Success..'),
      );
    } else if (state == HardwareAcknowledgementState.failed) {
      return const StatusBox(
        color: Colors.red,
        child: Text('Failed..'),
      );
    } else if (state == HardwareAcknowledgementState.errorOnPayload) {
      return const StatusBox(
        color: Colors.red,
        child: Text('Payload error..'),
      );
    } else {
      return const SizedBox(
          width: double.infinity, height: 5, child: LinearProgressIndicator());
    }
  }

  void sendToHttp() async {
    var body = {
      "userId": widget.userData['customerId'],
      "controllerId": widget.userData['controllerId'],
      "general":
      widget.constPvd.general.map((setting) => setting.toJson()).toList(),
      "waterSource": [],
      "levelSensor":
      widget.constPvd.level.map((setting) => setting.toJson()).toList(),
      "pump": widget.constPvd.pump.map((setting) => setting.toJson()).toList(),
      "filterSite": widget.constPvd.filterSite
          .map((setting) => setting.toJson())
          .toList(),
      "filter":
      widget.constPvd.filter.map((setting) => setting.toJson()).toList(),
      "fertilizerSite": widget.constPvd.fertilizerSite
          .map((setting) => setting.toJson())
          .toList(),
      "fertilizerChannel":
      widget.constPvd.channel.map((setting) => setting.toJson()).toList(),
      "ecPhSensor": widget.constPvd.ecPhSensor
          .map((setting) => setting.toJson())
          .toList(),
      "waterMeter": widget.constPvd.waterMeter
          .map((setting) => setting.toJson())
          .toList(),
      "pressureSensor": [],
      "mainValve":
      widget.constPvd.mainValve.map((setting) => setting.toJson()).toList(),
      "valve":
      widget.constPvd.valve.map((setting) => setting.toJson()).toList(),
      "moistureSensor":
      widget.constPvd.moisture.map((setting) => setting.toJson()).toList(),
      "analogSensor": [],
      "normalCriticalAlarm": widget.constPvd.normalCriticalAlarm
          .map((setting) => setting.toJson())
          .toList(),
      "commonAlarm": widget.constPvd.commonAlarm
          .map((setting) => setting.toJson())
          .toList(),
      "globalAlarm": widget.constPvd.globalAlarm
          .map((setting) => setting.toJson())
          .toList(),
      "hardware": getConstantHardwarePayload(),
      "controllerReadStatus": "0",
      "createUser": widget.userData['userId']
    };
    var response = await ConstantRepository().createUserConstant(body);
    debugPrint('code : ${response.body}');
  }
}
