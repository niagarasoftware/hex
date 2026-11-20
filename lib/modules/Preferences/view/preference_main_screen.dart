import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:hex/modules/Preferences/view/view_config.dart';
import 'package:hex/services/communication_service.dart';
import 'package:hex/services/http_service.dart';
import 'package:hex/services/mqtt_service.dart';
import 'package:hex/utils/constants.dart';
import 'package:provider/provider.dart';
import '../../../Constants/constants.dart';
import '../../../Constants/properties.dart' show AppProperties;
import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../Widgets/custom_animated_switcher.dart';
import '../../IrrigationProgram/view/schedule_screen.dart';
import '../../IrrigationProgram/widgets/custom_native_time_picker.dart';
import '../model/preference_data_model.dart';
import '../repository/preferences_repo.dart';
import '../state_management/preference_provider.dart';
import '../../SystemDefinitions/widgets/custom_snack_bar.dart';
import '../../../utils/environment.dart';
import '../../IrrigationProgram/view/program_library.dart';
import '../widgets/custom_segmented_control.dart';
import '../widgets/progress_dialog.dart';

const Color kFieldBg = Color(0xFFF0F1F6);
const Color kCardBorder = Color(0xFFEDEEF3);
const Color kMuted = Color(0xFF6B7080);

final otherSettingsIcons = [
  MdiIcons.lightbulbMultipleOutline,
  MdiIcons.alphaRCircleOutline,
  MdiIcons.alphaYCircleOutline,
  MdiIcons.alphaBCircleOutline,
  MdiIcons.formatLineHeight,
  MdiIcons.windowMinimize,
  MdiIcons.windowMaximize,
  MdiIcons.restart,
  MdiIcons.lightbulbCfl,
  MdiIcons.lightbulbCfl,
  MdiIcons.lightbulbCflOff,
  MdiIcons.toggleSwitch,
  MdiIcons.timerSand,
  MdiIcons.lightbulbCflOff,
  MdiIcons.toggleSwitch,
  MdiIcons.timerSand,
  MdiIcons.motionSensor,
  MdiIcons.lightbulbCflOff,
  MdiIcons.toggleSwitch,
  MdiIcons.timerSand,
  MdiIcons.motionSensor,
  MdiIcons.carBrakeLowPressure,
  MdiIcons.clock,
  MdiIcons.windowMinimize,
  MdiIcons.windowMaximize,
  MdiIcons.carBrakeLowPressure,
  MdiIcons.clock,
];

final voltageSettingsIcons = [
  MdiIcons.speedometerSlow,
  MdiIcons.lightbulbGroup,
  MdiIcons.lightbulbGroup,
  MdiIcons.lightbulbMultiple,
  MdiIcons.lightbulbMultiple,
  MdiIcons.speedometer,
  MdiIcons.lightbulbGroup,
  MdiIcons.lightbulbGroup,
  MdiIcons.lightbulbMultiple,
  MdiIcons.lightbulbMultiple,
  MdiIcons.scaleUnbalanced,
  MdiIcons.flashTriangle,
  MdiIcons.stepBackward,
  MdiIcons.stepBackward,
  MdiIcons.lightbulbMultiple,
  MdiIcons.scaleUnbalanced,
  MdiIcons.flashTriangle,
  MdiIcons.stepBackward,
  MdiIcons.stepBackward,
];

final timerSettingsIcons = [
  MdiIcons.timerPlay,
  MdiIcons.starCog,
  MdiIcons.battery,
  MdiIcons.batteryClock,
  MdiIcons.messageAlert,
  MdiIcons.timerSettings,
  MdiIcons.radioactive,
  MdiIcons.fanClock,
  MdiIcons.timerSync,
  MdiIcons.timerPlay,
  MdiIcons.timerStop,
  MdiIcons.timerRefresh,
  MdiIcons.timerSand,
  MdiIcons.timerSand,
  MdiIcons.timerSand,
  MdiIcons.timerSand,
];

final currentSettingIcons = [
  MdiIcons.waterAlert,
  MdiIcons.timerSand,
  MdiIcons.lightbulbGroup,
  MdiIcons.lightbulbMultiple,
  MdiIcons.restart,
  MdiIcons.timer,
  MdiIcons.restartAlert,
  MdiIcons.timer,
  MdiIcons.counter,
  Icons.lock_reset,
  MdiIcons.stackOverflow,
  MdiIcons.timerSand,
  MdiIcons.lightbulbGroup,
  MdiIcons.lightbulbMultiple,
  MdiIcons.overscan,
  MdiIcons.overscan,
  MdiIcons.lightbulbMultiple,
  MdiIcons.lightbulbMultiple,
  MdiIcons.lightbulbMultiple,
  MdiIcons.overscan,
  MdiIcons.overscan,
  MdiIcons.lightbulbMultiple,
  MdiIcons.lightbulbMultiple,
  MdiIcons.lightbulbMultiple,
];

final additionalSettingsIcons = [
  MdiIcons.storageTank,
  MdiIcons.bucket,
  MdiIcons.calendar,
  Icons.directions_run,
  MdiIcons.skipNextOutline,
  MdiIcons.storageTank,
  MdiIcons.bucket,
  MdiIcons.calendar,
  Icons.directions_run,
  MdiIcons.skipNextOutline,
];

final levelSettingsIcons = [
  MdiIcons.storageTank,
  MdiIcons.bucket,
  MdiIcons.calendar,
  Icons.directions_run,
  MdiIcons.skipNextOutline,
  MdiIcons.skipNextOutline,
  MdiIcons.bucket,
  MdiIcons.calendar,
  Icons.directions_run,
  MdiIcons.skipNextOutline,
  MdiIcons.skipNextOutline,
];

final voltageCalibrationIcons = [
  MdiIcons.alphaRCircleOutline,
  MdiIcons.alphaYCircleOutline,
  MdiIcons.alphaBCircleOutline,
  MdiIcons.alphaRCircleOutline,
  MdiIcons.alphaYCircleOutline,
  MdiIcons.alphaBCircleOutline,
];

final otherCalibrationIcons = [
  MdiIcons.clipboardFlow,
  Icons.compress,
  MdiIcons.windowMaximize,
  MdiIcons.waterCheck,
  MdiIcons.storeSettings,
  MdiIcons.carCoolantLevel,
  Icons.compress,
  MdiIcons.windowMaximize,
  MdiIcons.waterCheck,
  MdiIcons.storeSettings,
  MdiIcons.carCoolantLevel,
];

class PreferenceMainScreen extends StatefulWidget {
  final int userId, customerId, selectedIndex;
  final Map<String, dynamic> masterData;
  const PreferenceMainScreen(
      {super.key,
        required this.userId,
        required this.customerId,
        required this.masterData,
        required this.selectedIndex});

  @override
  State<PreferenceMainScreen> createState() => _PreferenceMainScreenState();
}

class _PreferenceMainScreenState extends State<PreferenceMainScreen>
    with TickerProviderStateMixin {
  late PreferenceProvider preferenceProvider;
  late MqttPayloadProvider mqttPayloadProvider;
  bool shouldSendFailedPayloads = false;
  List oroPumpList = [];
  List selectedOroPumpList = [];
  bool breakLoop = false;
  bool viewConfig = false;
  final PreferenceRepository repository = PreferenceRepository(HttpService());
  TabController? commonPumpTabController;
  TabController? individualPumpTabController;
  int selectedSetting = 0;
  TextEditingController passwordController = TextEditingController();
  final MqttService mqttService = MqttService();
  late bool isToGem;
  late bool isPumpWithValveModel;
  late bool isPumpOnly;
  late bool isValveSetting;
  late bool isNova;
  late bool isWlc;

  @override
  void initState() {
    super.initState();
    preferenceProvider =
        Provider.of<PreferenceProvider>(context, listen: false);
    mqttPayloadProvider =
        Provider.of<MqttPayloadProvider>(context, listen: false);
    preferenceProvider
        .getUserPreference(
        userId: widget.customerId,
        controllerId: widget.masterData['controllerId'],
        modelId: widget.masterData['modelId'])
        .then((_) {
      if (!mounted) return;
      commonPumpTabController?.dispose();
      individualPumpTabController?.dispose();
      commonPumpTabController = TabController(
          length: preferenceProvider.commonPumpSettings?.length ?? 0,
          vsync: this);
      individualPumpTabController = TabController(
          length: preferenceProvider.individualPumpSetting?.length ?? 0,
          vsync: this);
      setState(() {
        if (preferenceProvider.commonPumpSettings?.isEmpty ?? true) {
          selectedSetting = 1;
        }
        if (isValveSetting) {
          selectedSetting = 3;
        }
      });
    });
    preferenceProvider.updateTabIndex(0);
    mqttPayloadProvider.viewSettingsList.clear();
    isToGem = [
      ...AppConstants.gemModelList,
      ...AppConstants.aquacultureModelList
    ].contains(widget.masterData['modelId']);
    isPumpWithValveModel = AppConstants.pumpWithValveModelList
        .contains(widget.masterData['modelId']);
    isPumpOnly =
        AppConstants.pumpModelList.contains(widget.masterData['modelId']);
    isNova = AppConstants.ecoGemAndPlusModelList
        .contains(widget.masterData['modelId']);
    isWlc = AppConstants.wlcModelList.contains(widget.masterData['modelId']);
    isValveSetting = [1, 2].contains(widget.selectedIndex);
  }

  @override
  void dispose() {
    commonPumpTabController?.dispose();
    individualPumpTabController?.dispose();
    passwordController.dispose();
    preferenceProvider.clearData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    preferenceProvider = Provider.of<PreferenceProvider>(context, listen: true);
    mqttPayloadProvider =
        Provider.of<MqttPayloadProvider>(context, listen: true);
    final colorScheme = Theme.of(context).colorScheme;

    if (preferenceProvider.commonPumpSettings != null &&
        preferenceProvider.commonPumpSettings!.isNotEmpty) {
      if (oroPumpList.isEmpty) {
        for (var i = 0;
        i < preferenceProvider.commonPumpSettings!.length;
        i++) {
          oroPumpList.add(preferenceProvider.commonPumpSettings![i].deviceId);
        }
        selectedOroPumpList = oroPumpList;
      }
    }
    if (preferenceProvider.generalData != null &&
        preferenceProvider.commonPumpSettings != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F5FA),
        appBar: (MediaQuery.of(context).size.width <= 500 && !isValveSetting)
            ? AppBar(
          title: const Text("Preference"),
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          actions: [
            if (selectedSetting == 0)
              FilledButton.tonal(
                  onPressed: () {
                    setState(() {
                      viewConfig = !viewConfig;
                    });
                  },
                  child: const Text('View')),
            const SizedBox(width: 10)
          ],
        )
            : PreferredSize(
            preferredSize: const Size(0, 0), child: Container()),
        body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    if (!isValveSetting) ...[
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: [
                            if (preferenceProvider.commonPumpSettings!.isNotEmpty)
                              if (!viewConfig)
                                Expanded(
                                  flex: 5,
                                  child: CustomSegmentedControl(
                                    segmentTitles: const {
                                      0: 'Common setting',
                                      1: 'Individual setting',
                                      2: 'Calibration'
                                    },
                                    groupValue: selectedSetting,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedSetting = value!;
                                        if (selectedSetting == 2) {
                                          showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return Consumer(builder:
                                                    (BuildContext context,
                                                    PreferenceProvider
                                                    preferenceProvider,
                                                    _) {
                                                  return AlertDialog(
                                                    title: const Text("Calibration Password"),
                                                    content: Column(
                                                      mainAxisSize:
                                                      MainAxisSize.min,
                                                      children: [
                                                        TextFormField(
                                                          controller:
                                                          passwordController,
                                                          autofocus: true,
                                                          obscureText: true,
                                                          decoration:
                                                          const InputDecoration(
                                                              hintText:
                                                              "Enter password",
                                                              isDense: true),
                                                        ),
                                                        const SizedBox(height: 10),
                                                        if (preferenceProvider
                                                            .passwordValidationCode ==
                                                            404)
                                                          Text(
                                                            'Invalid password',
                                                            style: TextStyle(
                                                                color: colorScheme.error),
                                                          )
                                                      ],
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                          onPressed: () {
                                                            passwordController
                                                                .text = "";
                                                            preferenceProvider
                                                                .updateValidationCode();
                                                            selectedSetting = 1;
                                                            Navigator.of(context)
                                                                .pop();
                                                          },
                                                          child:
                                                          const Text("CANCEL")),
                                                      FilledButton(
                                                          onPressed: () async {
                                                            if (isNova || isToGem) {
                                                              final pump = preferenceProvider
                                                                  .commonPumpSettings![
                                                              preferenceProvider
                                                                  .selectedTabIndex];
                                                              final payload =
                                                              jsonEncode({
                                                                "sentSms":
                                                                "viewconfig,4"
                                                              });
                                                              final payload2 =
                                                              jsonEncode({
                                                                "0": payload
                                                              });
                                                              final viewConfig = {
                                                                "5900": {
                                                                  "5901":
                                                                  "${pump.serialNumber}+${pump.referenceNumber}+${pump.deviceId}+${pump.interfaceTypeId}+$payload2+${4}"
                                                                }
                                                              };
                                                              mqttService.topicToPublishAndItsMessage(
                                                                  isToGem
                                                                      ? jsonEncode(
                                                                      viewConfig)
                                                                      : payload,
                                                                  "${Environment.mqttPublishTopic}/${preferenceProvider.generalData!.deviceId}");
                                                            }
                                                            await Future.delayed(
                                                                Duration.zero, () {
                                                              preferenceProvider
                                                                  .updateValidationCode();
                                                            });
                                                            await preferenceProvider
                                                                .checkPassword(
                                                                userId: widget
                                                                    .customerId,
                                                                password:
                                                                passwordController
                                                                    .text);
                                                            if (preferenceProvider
                                                                .passwordValidationCode ==
                                                                200) {
                                                              if (!mounted) return;
                                                              Navigator.of(context)
                                                                  .pop();
                                                              passwordController
                                                                  .text = "";
                                                            }
                                                          },
                                                          child: const Text("OK")),
                                                    ],
                                                  );
                                                });
                                              });
                                        } else {
                                          preferenceProvider.updateValidationCode();
                                        }
                                      });
                                    },
                                  ),
                                )
                              else
                                Expanded(child: Container()),
                            if (preferenceProvider.commonPumpSettings!.isNotEmpty &&
                                constraints.maxWidth >= 700)
                              const SizedBox(width: 16),
                            if (constraints.maxWidth >= 700)
                              Expanded(
                                flex: 7,
                                child: _getDefaultTabController(),
                              ),
                            if (selectedSetting == 0 &&
                                MediaQuery.of(context).size.width > 500 &&
                                preferenceProvider.commonPumpSettings!.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              FilledButton.tonalIcon(
                                  onPressed: () {
                                    setState(() {
                                      viewConfig = !viewConfig;
                                    });
                                  },
                                  icon: Icon(viewConfig ? Icons.edit : Icons.visibility_rounded, size: 18),
                                  label: Text(viewConfig ? 'Edit' : 'View'))
                            ]
                          ],
                        ),
                      ),
                    ],
                    if (constraints.maxWidth <= 700 && !isValveSetting)
                      _getDefaultTabController(),
                    if (!isValveSetting)
                      const SizedBox(height: 12),
                    if (selectedSetting != 2 &&
                        commonPumpTabController != null &&
                        individualPumpTabController != null)
                      Expanded(
                          child: TabBarView(
                            controller: selectedSetting != 1
                                ? commonPumpTabController
                                : individualPumpTabController,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              if (viewConfig)
                                for (int i = 0; i < (commonPumpTabController?.length ?? 0); i++)
                                  ViewConfig(
                                    userId: widget.userId,
                                    isLora: preferenceProvider
                                        .commonPumpSettings![
                                    (commonPumpTabController?.index ?? 0) < preferenceProvider.commonPumpSettings!.length
                                        ? (commonPumpTabController?.index ?? 0)
                                        : 0]
                                        .interfaceTypeId ==
                                        1,
                                    modelId: widget.masterData['modelId'],
                                  )
                              else if (selectedSetting == 0)
                                for (var commonSettingIndex = 0;
                                commonSettingIndex <
                                    preferenceProvider.commonPumpSettings!.length;
                                commonSettingIndex++)
                                  buildSettingsCategory(
                                      context: context,
                                      settingList: preferenceProvider
                                          .commonPumpSettings![commonSettingIndex]
                                          .settingList,
                                      constraints: constraints,
                                      pumpIndex: commonSettingIndex)
                              else if (selectedSetting == 1)
                                  for (var pumpSettingIndex = 0;
                                  pumpSettingIndex <
                                      preferenceProvider
                                          .individualPumpSetting!.length;
                                  pumpSettingIndex++)
                                    buildSettingsCategory(
                                        context: context,
                                        settingList: preferenceProvider
                                            .individualPumpSetting![pumpSettingIndex]
                                            .settingList,
                                        constraints: constraints,
                                        pumpIndex: pumpSettingIndex)
                            ],
                          )),
                    if (selectedSetting == 2 &&
                        (preferenceProvider.passwordValidationCode == 200) &&
                        commonPumpTabController != null &&
                        individualPumpTabController != null)
                      Expanded(
                          child: TabBarView(
                            controller: selectedSetting != 1
                                ? commonPumpTabController
                                : individualPumpTabController,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              for (var calibrationSettingIndex = 0;
                              calibrationSettingIndex <
                                  preferenceProvider.calibrationSetting!.length;
                              calibrationSettingIndex++)
                                buildSettingsCategory(
                                    context: context,
                                    settingList: preferenceProvider
                                        .calibrationSetting![calibrationSettingIndex]
                                        .settingList,
                                    constraints: constraints,
                                    pumpIndex: calibrationSettingIndex)
                            ],
                          )),
                  ],
                ),
              );
            }),
        bottomNavigationBar: !viewConfig
            ? Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.4)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!isValveSetting &&
                  (preferenceProvider.passwordValidationCode == 200 &&
                      preferenceProvider.calibrationSetting![0]
                          .settingList[1].controllerReadStatus ==
                          "0"
                      ? getCalibrationPayload(isToGem: isToGem)
                      .split(';')[0]
                      .isNotEmpty
                      : getFailedPayload(sendAll: false, isToGem: isToGem)
                      .split(';')[0]
                      .isNotEmpty))
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final failedPayload =
                    preferenceProvider.passwordValidationCode == 200
                        ? getCalibrationPayload(isToGem: isToGem)
                        .split(';')
                        : getFailedPayload(
                        sendAll: false, isToGem: isToGem)
                        .split(';');
                    List temp = List.from(selectedOroPumpList);
                    preferenceProvider.temp.clear();
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return StatefulBuilder(builder:
                            (BuildContext context,
                            StateSetter stateSetter) {
                          return AlertDialog(
                            content: SizedBox(
                              height: 450,
                              width: 300,
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    for (var i = 0;
                                    i <
                                        preferenceProvider
                                            .commonPumpSettings!
                                            .length;
                                    i++)
                                      CheckboxListTile(
                                          title: Text(preferenceProvider
                                              .commonPumpSettings![i]
                                              .deviceName),
                                          subtitle: Text(
                                              preferenceProvider
                                                  .commonPumpSettings![i]
                                                  .deviceId),
                                          value: temp.contains(
                                              preferenceProvider
                                                  .commonPumpSettings![i]
                                                  .deviceId),
                                          onChanged: (newValue) {
                                            stateSetter(() {
                                              if (!mounted) return;
                                              setState(() {
                                                if (temp.contains(
                                                    preferenceProvider
                                                        .commonPumpSettings![
                                                    i]
                                                        .deviceId)) {
                                                  temp.remove(
                                                      preferenceProvider
                                                          .commonPumpSettings![
                                                      i]
                                                          .deviceId);
                                                } else {
                                                  temp.add(preferenceProvider
                                                      .commonPumpSettings![
                                                  i]
                                                      .deviceId);
                                                }
                                              });
                                            });
                                          }),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                      const NeverScrollableScrollPhysics(),
                                      itemCount: failedPayload.length,
                                      itemBuilder:
                                          (BuildContext context, int i) {
                                        var payloadToDecode = isToGem
                                            ? failedPayload[i]
                                            .split('+')[4]
                                            : failedPayload[i];
                                        var decodedData =
                                        jsonDecode(payloadToDecode);
                                        var key = decodedData.keys.first;
                                        int oroPumpIndex = 0;
                                        if (isToGem) {
                                          oroPumpIndex =
                                              preferenceProvider
                                                  .commonPumpSettings!
                                                  .indexWhere((element) =>
                                              element.deviceId ==
                                                  failedPayload[i]
                                                      .split('+')[2]);
                                        }
                                        return temp.contains(
                                            preferenceProvider
                                                .commonPumpSettings![
                                            oroPumpIndex]
                                                .deviceId)
                                            ? ListTile(
                                          leading: Container(
                                            height: 30,
                                            width: 30,
                                            decoration:
                                            BoxDecoration(
                                              shape:
                                              BoxShape.circle,
                                              gradient: AppProperties
                                                  .linearGradientLeading,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${i + 1}',
                                                style:
                                                const TextStyle(
                                                    color: Colors
                                                        .white),
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            preferenceProvider
                                                .commonPumpSettings![
                                            oroPumpIndex]
                                                .deviceName,
                                            style: const TextStyle(
                                                fontWeight:
                                                FontWeight
                                                    .w400),
                                          ),
                                          subtitle: Text(
                                            statusMessages[key]!,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight:
                                                FontWeight
                                                    .bold),
                                          ),
                                        )
                                            : Container();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            actions: [
                              FilledButton(
                                  onPressed: temp.isNotEmpty
                                      ? () async {
                                    await Future.delayed(
                                        Duration.zero, () {
                                      if (!mounted) return;
                                      setState(() {
                                        shouldSendFailedPayloads =
                                        true;
                                        selectedOroPumpList =
                                            List.from(temp);
                                      });
                                    });
                                    if (!mounted) return;
                                    Navigator.pop(context);
                                    await sendFunction();
                                  }
                                      : null,
                                  child: const Text("Resend")),
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text("Cancel"))
                            ],
                          );
                        });
                      },
                    );
                  },
                  icon: const Icon(Icons.warning_amber_rounded, size: 18),
                  label: const Text("Failed"),
                )
              else
                const SizedBox(),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final rtcError = validateAllRtcSettings();
                  print("rtcError : ${rtcError}");
                  if (rtcError != null) {
                    _showRtcErrorDialog(rtcError);
                    return;
                  }
                  final onDelayError = validateAllOnDelaySettings();
                  if (onDelayError != null) {
                    _showOnDelayAlertMessage(onDelayError);
                    return;
                  }
                  await Future.delayed(Duration.zero, () {
                    if (!mounted) return;
                    setState(() {
                      shouldSendFailedPayloads = false;
                    });
                  });
                  preferenceProvider.temp.clear();
                  if (preferenceProvider.commonPumpSettings!.isEmpty ||
                      preferenceProvider.commonPumpSettings!.length <= 1) {
                    sendFunction();
                  } else {
                    if (preferenceProvider.passwordValidationCode == 200) {
                      if (preferenceProvider.calibrationSetting!.any(
                              (element) => element.settingList
                              .any((e) => e.changed == true))) {
                        selectedOroPumpList.clear();
                        if (selectedOroPumpList.isEmpty) {
                          selectedOroPumpList.addAll(preferenceProvider
                              .calibrationSetting!
                              .where((element) => element.settingList
                              .any((e) => e.changed == true))
                              .toList()
                              .map((e) => e.deviceId)
                              .toList());
                        }
                        sendFunction();
                      } else {
                        selectPumpToSend();
                      }
                    } else {
                      List common = preferenceProvider.commonPumpSettings!
                          .where((element) => element.settingList
                          .any((e) => e.changed == true))
                          .toList()
                          .map((e) => e.deviceId)
                          .toList();
                      List individual = preferenceProvider
                          .individualPumpSetting!
                          .where((element) => element.settingList
                          .any((e) => e.changed == true))
                          .toList()
                          .map((e) => e.deviceId)
                          .toList();
                      if (preferenceProvider.commonPumpSettings!.any(
                              (element) => element.settingList
                              .any((e) => e.changed == true)) ||
                          preferenceProvider.individualPumpSetting!.any(
                                  (element) => element.settingList
                                  .any((e) => e.changed == true))) {
                        selectedOroPumpList.clear();
                        if (selectedOroPumpList.isEmpty) {
                          selectedOroPumpList.addAll(
                              common.isNotEmpty ? common : individual);
                        }
                        sendFunction();
                      } else {
                        selectPumpToSend();
                      }
                    }
                  }
                },
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  preferenceProvider.passwordValidationCode == 200
                      ? "Send calibration"
                      : isValveSetting
                      ? "Send"
                      : "Send Preference",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        )
            : null,
      );
    } else {
      return Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        body:
        const Center(child: CircularProgressIndicator(semanticsLabel: "Loading")),
      );
    }
  }

  Widget _getDefaultTabController() {
    final colorScheme = Theme.of(context).colorScheme;
    final commonLength = preferenceProvider.commonPumpSettings?.length ?? 0;
    final individualLength = preferenceProvider.individualPumpSetting?.length ?? 0;
    final targetLength = selectedSetting != 1 ? commonLength : individualLength;
    if (targetLength == 0) return const SizedBox();

    final activeTabController = selectedSetting != 1
        ? commonPumpTabController
        : individualPumpTabController;

    if (activeTabController == null) return const SizedBox();

    return DefaultTabController(
      length: targetLength,
      child: Row(
        children: [
          Text("Pump unit", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
              ),
              child: TabBar(
                controller: activeTabController,
                labelPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4),
                indicator: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                tabAlignment: TabAlignment.start,
                labelColor: colorScheme.onPrimaryContainer,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                dividerColor: Colors.transparent,
                isScrollable: true,
                onTap: (value) async {
                  final curIdx = commonPumpTabController?.index ?? 0;
                  preferenceProvider.updateTabIndex(curIdx);
                  if (selectedSetting == 2 && isToGem && preferenceProvider.commonPumpSettings != null && curIdx < preferenceProvider.commonPumpSettings!.length) {
                    mqttPayloadProvider.viewSettingsList.clear();
                    final oroPumpSerialNumber = preferenceProvider
                        .commonPumpSettings![curIdx]
                        .serialNumber;
                    final referenceNumber = preferenceProvider
                        .commonPumpSettings![curIdx]
                        .referenceNumber;
                    final deviceId = preferenceProvider
                        .commonPumpSettings![curIdx]
                        .deviceId;
                    final interfaceType = preferenceProvider
                        .commonPumpSettings![curIdx]
                        .interfaceTypeId;
                    final categoryId = preferenceProvider
                        .commonPumpSettings![curIdx]
                        .categoryId;
                    final payload = jsonEncode({"sentSms": "viewconfig"});
                    final payload2 = jsonEncode({"0": payload});
                    final viewConfig = {
                      "5900": {
                        "5901":
                        "$oroPumpSerialNumber+$referenceNumber+$deviceId+$interfaceType+$payload2+$categoryId",
                      }
                    };
                    await context.read<CommunicationService>().sendCommand(
                      serverMsg: '',
                      payload: isWlc
                          ? Constants.sendPayloadWithCrc(payload)
                          : jsonEncode(viewConfig),
                    );
                  }
                },
                tabs: [
                  if (selectedSetting != 1)
                    ...preferenceProvider.commonPumpSettings!
                        .asMap()
                        .entries
                        .map((entry) {
                      final element = entry.value;
                      return preferenceProvider.commonPumpSettings!.length > 1
                          ? Tab(
                        text: "${element.deviceName} (${element.deviceId})",
                      )
                          : Container();
                    })
                  else
                    ...preferenceProvider.individualPumpSetting!
                        .asMap()
                        .entries
                        .map((entry) {
                      final element = entry.value;

                      CommonPumpSetting? matchingCommonPump;
                      try {
                        matchingCommonPump =
                            preferenceProvider.commonPumpSettings!.firstWhere(
                                    (common) => common.deviceId == element.deviceId);
                      } catch (e) {
                        matchingCommonPump = null;
                      }

                      return preferenceProvider.individualPumpSetting!.length > 1
                          ? Tab(
                        text: (preferenceProvider
                            .commonPumpSettings!.length >
                            1 &&
                            matchingCommonPump != null)
                            ? "${element.name} (${matchingCommonPump.deviceId})"
                            : element.name,
                      )
                          : Container();
                    })
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowCategory(SettingList settingCategory, int pumpIndex) {
    if (([...AppConstants.wlcModelList].contains(widget.masterData['modelId']) &&
        !AppConstants.threePhaseWireLessWlcModelList.contains(widget.masterData['modelId']) &&
        AppConstants.otherCalibration.contains(settingCategory.type))) {
      return false;
    }
    if (([
      ...AppConstants.singlePhaseWlcModelList,
      ...AppConstants.threePhaseWlcModelList,
    ].contains(widget.masterData['modelId']) &&
        !AppConstants.threePhaseWireLessWlcModelList.contains(widget.masterData['modelId']) &&
        AppConstants.otherSetting.contains(settingCategory.type))) {
      return false;
    }
    if ([...AppConstants.singleOrThreePhaseWlcModelList].contains(widget.masterData['modelId']) &&
        AppConstants.additionalSetting.contains(settingCategory.type)) {
      return false;
    }
    if (AppConstants.levelSetting.contains(settingCategory.type) && isToGem) {
      if (pumpIndex >= (preferenceProvider.individualPumpSetting?.length ?? 0) ||
          !preferenceProvider.individualPumpSetting![pumpIndex].controlGem) {
        return false;
      }
    }
    return true;
  }

  bool _isFullWidthCategory(SettingList settingCategory) {
    final type = settingCategory.type;
    final name = settingCategory.name.toLowerCase();
    if (AppConstants.additionalSetting.contains(type) ||
        name.contains('auxiliary') ||
        name.contains('2-phase') ||
        name.contains('2 phase') ||
        name.contains('schedule')) {
      return true;
    }
    return false;
  }

  Widget buildSettingsCategory(
      {required BuildContext context,
        required List<SettingList> settingList,
        required BoxConstraints constraints,
        required int pumpIndex})
  {
    try {
      return LayoutBuilder(
        builder: (context, bc) {
          const spacing = 16.0;
          final isMobile = bc.maxWidth < 700;

          final visible = <SettingList>[];
          for (var i = 0; i < settingList.length; i++) {
            if (_shouldShowCategory(settingList[i], pumpIndex)) {
              visible.add(settingList[i]);
            }
          }
          if (visible.isEmpty) return const SizedBox();

          final fullW = bc.maxWidth;
          final colW = isMobile ? fullW : (fullW - spacing) / 2;

          Widget card(SettingList cat, double w) => SizedBox(
            width: w,
            child: _buildCategoryCard(
              context: context,
              settingCategory: cat,
              width: w,
              pumpIndex: pumpIndex,
            ),
          );

          // Card height estimate - shorter column-ku next card poga
          double estHeight(SettingList cat) {
            double h = 80;
            for (final st in cat.setting) {
              if (st.display == false || st.hidden == true) continue;
              final t = st.title.toUpperCase();
              if (t == "RTC TIMER") {
                h += 320;
              } else if (t == "2 PHASE" ||
                  t == "AUTO RESTART 2 PHASE" ||
                  t.contains("LINEAR LEVEL SENSOR")) {
                h += 60 +
                    56.0 *
                        (preferenceProvider.individualPumpSetting?.length ?? 1);
              } else if (st.widgetTypeId == 2) {
                h += 64;
              } else {
                h += 44; // half-row (2 column grid)
              }
            }
            return h;
          }

          Widget columnOf(List<SettingList> list) => SizedBox(
            width: colW,
            child: Column(
              children: [
                for (int i = 0; i < list.length; i++) ...[
                  if (i > 0) const SizedBox(height: spacing),
                  card(list[i], colW),
                ],
              ],
            ),
          );

          final rows = <Widget>[];
          var segment = <SettingList>[];
          void flush() {
            if (segment.isEmpty) return;
            if (segment.length == 1) {
              // thaniya oru card irundha full width - empty space varadhu
              rows.add(card(segment[0], fullW));
            } else {
              final left = <SettingList>[];
              final right = <SettingList>[];
              double lh = 0, rh = 0;
              for (final c in segment) {
                if (lh <= rh) {
                  left.add(c);
                  lh += estHeight(c) + spacing;
                } else {
                  right.add(c);
                  rh += estHeight(c) + spacing;
                }
              }
              rows.add(Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  columnOf(left),
                  const SizedBox(width: spacing),
                  columnOf(right),
                ],
              ));
            }
            segment = <SettingList>[];
          }

          for (final cat in visible) {
            if (isMobile) {
              rows.add(card(cat, fullW));
            } else if (_isFullWidthCategory(cat)) {
              flush();
              rows.add(card(cat, fullW));
            } else {
              segment.add(cat);
            }
          }
          flush();

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final r in rows) ...[r, const SizedBox(height: spacing)],
              ],
            ),
          );
        },
      );
    } catch (error, stackTrace) {
      debugPrint("error ==> $error");
      debugPrint("stackTrace ==> $stackTrace");
      return const Center(child: Text("Unexpected error"));
    }
  }

  String? _categoryDescription(String name) {
    final n = name.toLowerCase();
    if (n.contains('voltage')) {
      return 'Under-voltage and over-voltage trip thresholds and differentials.';
    }
    if (n.contains('current')) return 'Dry run, overload and current trip settings.';
    if (n.contains('timer') || n.contains('delay')) {
      return 'On delay, cyclic, max run time and RTC timers.';
    }
    if (n.contains('level') || n.contains('tank')) {
      return 'Reservoir dimensions, level cutoffs, and linear level probes.';
    }
    if (n.contains('pressure') || n.contains('flow')) {
      return 'Line pressure scanning intervals, flow cutoffs, and pressure switch settings.';
    }
    if (n.contains('auxiliary') || n.contains('other')) {
      return 'Station lighting output and utility peak-hour tariff restrictions.';
    }
    if (n.contains('calibration')) return 'Sensor calibration values.';
    return null;
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required SettingList settingCategory,
    required double width,
    required int pumpIndex,
  })
  {
    final inner = width - 40; // card padding 20 + 20
    final half = (inner - 16) / 2; // 2-column grid
    final desc = _categoryDescription(settingCategory.name);

    final items = <Widget>[];
    for (var i = 0; i < settingCategory.setting.length; i++) {
      final title = settingCategory.setting[i].title.toUpperCase();
      if (title == "RTC TIMER") {
        items.add(SizedBox(
            width: inner,
            child: _buildRtcTimer(0, i, pumpIndex, [settingCategory])));
      } else if (title == "2 PHASE" ||
          title == "AUTO RESTART 2 PHASE" ||
          (title == "AUTO RESTART" &&
              settingCategory.setting[i].serialNumber == 8) ||
          (isNova &&
              (title == "UPPER TANK LINEAR LEVEL SENSOR" ||
                  title == "LOWER TANK LINEAR LEVEL SENSOR"))) {
        items.add(SizedBox(
            width: inner,
            child: _buildTwoPhaseCard(0, i, pumpIndex, [settingCategory])));
      } else {
        items.add(buildCustomListTileWidget(
          context: context,
          title: settingCategory.setting[i].title,
          widgetType: _getWidgetType(0, i, [settingCategory]),
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp('[^0-9.]')),
            LengthLimitingTextInputFormatter(6),
          ],
          dataList: title == "SENSOR HEIGHT"
              ? ["20", "35"]
              : title == 'CABLE SELECT'
              ? ['0', '1', '2', '3']
              : ["10", "12"],
          value: _getInitialValue(0, i, [settingCategory], pumpIndex),
          leading: _buildLeading(0, i, [settingCategory]), // OLD ICON
          onValueChange: (newValue) => onChangeValue(
              0, i, [settingCategory], newValue,
              pumpIndex: pumpIndex),
          conditionToShow: getConditionToShow(
            type: settingCategory.type,
            serialNumber: settingCategory.setting[i].serialNumber,
            value: settingCategory.setting[i].value,
          ),
          subTitle: _getSubTitle(0, i, [settingCategory], pumpIndex),
          display: settingCategory.setting[i].display,
          hidden: (settingCategory.setting[i].title == "Schedule by Days" ||
              (!isNova &&
                  AppConstants.otherCalibration
                      .contains(settingCategory.type) &&
                  [7, 8].contains(settingCategory.setting[i].serialNumber)))
              ? true
              : settingCategory.setting[i].hidden,
          enabled: true,
          modelId: widget.masterData['modelId'],
          fullWidth: inner,
          halfWidth: half,
        ));
      }
    }

    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(settingCategory.name,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
          if (desc != null) ...[
            const SizedBox(height: 4),
            Text(desc, style: const TextStyle(color: kMuted, fontSize: 13)),
          ],
          const SizedBox(height: 14),
          Wrap(spacing: 16, runSpacing: 0, children: items),
        ],
      ),
    );
  }

  // OLD design icon: white ring + cardColor circle + primary icon
  Widget _buildLeading(int categoryIndex, int settingIndex, List settingList) {
    return Container(
      decoration:
      const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: cardColor,
        child: _buildIcon(categoryIndex, settingIndex, settingList),
      ),
    );
  }

  int _rtcTimeToSeconds(String timeStr) {
    if (timeStr.isEmpty) return 0;
    final parts = timeStr.split(':');
    if (parts.length < 2) return 0;
    int hours = int.tryParse(parts[0]) ?? 0;
    int minutes = int.tryParse(parts[1]) ?? 0;
    int seconds = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;
    return hours * 3600 + minutes * 60 + seconds;
  }

  String? _validateSingleRtcList(List<RtcTimeSetting> rtcSettings,
      {String? pumpName, bool isLiveEdit = false}) {
    int? lastActiveOffTimeSeconds;
    int? lastActiveIndex;

    for (int i = 0; i < rtcSettings.length; i++) {
      final rtc = rtcSettings[i];
      final onSeconds = _rtcTimeToSeconds(rtc.onTime);
      final offSeconds = _rtcTimeToSeconds(rtc.offTime);

      if (onSeconds == 0 && offSeconds == 0) {
        continue;
      }

      final prefix =
      pumpName != null ? "$pumpName - RTC ${i + 1}" : "RTC ${i + 1}";

      if (offSeconds > 0 || !isLiveEdit) {
        if (offSeconds <= onSeconds) {
          return "$prefix: Off time must be greater than On time.";
        }
      }

      if (lastActiveOffTimeSeconds != null &&
          onSeconds < lastActiveOffTimeSeconds) {
        final prevPrefix = "RTC ${lastActiveIndex! + 1}";
        return "$prefix: On time must be greater than or equal to $prevPrefix Off time.";
      }

      if (offSeconds > 0) {
        lastActiveOffTimeSeconds = offSeconds;
        lastActiveIndex = i;
      }
    }
    return null;
  }

  void _showRtcErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text("Invalid RTC Setting"),
            ],
          ),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  String? validateAllRtcSettings() {
    if (preferenceProvider.individualPumpSetting != null) {
      for (var individualPump in preferenceProvider.individualPumpSetting!) {
        final pumpName = preferenceProvider.individualPumpSetting!.length > 1
            ? individualPump.name
            : null;
        for (var settingCategory in individualPump.settingList) {
          if (AppConstants.timerSetting.contains(settingCategory.type)) {
            bool isRtcEnabled = true;
            List<RtcTimeSetting>? rtcSettings;

            for (var setting in settingCategory.setting) {
              if (setting.title.toUpperCase() == "RTC") {
                isRtcEnabled = setting.value == true;
              }
              if (setting.title.toUpperCase() == "RTC TIMER" &&
                  setting.rtcSettings != null) {
                rtcSettings = setting.rtcSettings;
              }
            }

            if (isRtcEnabled && rtcSettings != null) {
              final error =
              _validateSingleRtcList(rtcSettings, pumpName: pumpName);
              if (error != null) {
                return error;
              }
            }
          }
        }
      }
    }

    if (preferenceProvider.commonPumpSettings != null) {
      for (var commonSetting in preferenceProvider.commonPumpSettings!) {
        for (var settingCategory in commonSetting.settingList) {
          if (AppConstants.timerSetting.contains(settingCategory.type)) {
            bool isRtcEnabled = true;
            List<RtcTimeSetting>? rtcSettings;

            for (var setting in settingCategory.setting) {
              if (setting.title.toUpperCase() == "RTC") {
                isRtcEnabled = setting.value == true;
              }
              if (setting.title.toUpperCase() == "RTC TIMER" &&
                  setting.rtcSettings != null) {
                rtcSettings = setting.rtcSettings;
              }
            }

            if (isRtcEnabled && rtcSettings != null) {
              final error = _validateSingleRtcList(rtcSettings);
              if (error != null) {
                return error;
              }
            }
          }
        }
      }
    }

    return null;
  }

  Widget _buildRtcTimer(
      int categoryIndex, int settingIndex, int pumpIndex, List settingList) {
    final rtcSettings = settingList[categoryIndex]
        .setting[settingIndex]
        .rtcSettings as List<RtcTimeSetting>?;
    final colorScheme = Theme.of(context).colorScheme;

    return CustomAnimatedSwitcher(
      condition: (conditions['rtc'] ?? false),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                  child: Center(
                      child: Text('RTC',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.onSurfaceVariant)))),
              Expanded(
                  child: Center(
                      child: Text('On Time',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.onSurfaceVariant)))),
              Expanded(
                  child: Center(
                      child: Text('Off Time',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.onSurfaceVariant)))),
              Expanded(
                  child: Center(
                      child: Text('Action',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.onSurfaceVariant)))),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              if (rtcSettings != null)
                ...rtcSettings.asMap().entries.map((entry) {
                  final int rtcIndex = entry.key;
                  final rtcSetting = entry.value;
                  final bool isClearingAllowed =
                      (rtcSetting.onTime.isNotEmpty &&
                          rtcSetting.onTime != "00:00:00") ||
                          (rtcSetting.offTime.isNotEmpty &&
                              rtcSetting.offTime != "00:00:00");

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                '${rtcIndex + 1}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: CustomNativeTimePicker(
                                initialValue: rtcSetting.onTime.isNotEmpty
                                    ? rtcSetting.onTime
                                    : "00:00:00",
                                onChanged: (newTime) {
                                  final oldTime = rtcSetting.onTime;
                                  rtcSetting.onTime = newTime;
                                  final error = _validateSingleRtcList(
                                      rtcSettings,
                                      isLiveEdit: true);
                                  if (error != null) {
                                    rtcSetting.onTime = oldTime;
                                    Future.delayed(
                                        const Duration(milliseconds: 100), () {
                                      if (mounted) _showRtcErrorDialog(error);
                                    });
                                    if (mounted) setState(() {});
                                  } else {
                                    if (mounted) {
                                      setState(() {
                                        settingList[categoryIndex]
                                            .setting[settingIndex]
                                            .isChanged = true;
                                        settingList[categoryIndex].changed = true;
                                      });
                                    }
                                  }
                                },
                                is24HourMode: true,
                                modelId: 1,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: CustomNativeTimePicker(
                                initialValue: rtcSetting.offTime.isNotEmpty
                                    ? rtcSetting.offTime
                                    : "00:00:00",
                                onChanged: (newTime) {
                                  final oldTime = rtcSetting.offTime;
                                  rtcSetting.offTime = newTime;
                                  final error = _validateSingleRtcList(
                                      rtcSettings,
                                      isLiveEdit: true);
                                  if (error != null) {
                                    rtcSetting.offTime = oldTime;
                                    Future.delayed(
                                        const Duration(milliseconds: 100), () {
                                      if (mounted) _showRtcErrorDialog(error);
                                    });
                                    if (mounted) setState(() {});
                                  } else {
                                    if (mounted) {
                                      setState(() {
                                        settingList[categoryIndex]
                                            .setting[settingIndex]
                                            .isChanged = true;
                                        settingList[categoryIndex].changed = true;
                                      });
                                    }
                                  }
                                },
                                is24HourMode: true,
                                modelId: 1,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: IconButton(
                                tooltip: 'Clear RTC ${rtcIndex + 1}',
                                icon: Icon(
                                  Icons.clear,
                                  color: isClearingAllowed
                                      ? colorScheme.error
                                      : colorScheme.onSurfaceVariant.withOpacity(0.4),
                                  size: 18,
                                ),
                                onPressed: isClearingAllowed
                                    ? () {
                                  final oldOnTime = rtcSetting.onTime;
                                  final oldOffTime = rtcSetting.offTime;
                                  rtcSetting.onTime = "00:00:00";
                                  rtcSetting.offTime = "00:00:00";
                                  final error = _validateSingleRtcList(
                                      rtcSettings,
                                      isLiveEdit: true);
                                  if (error != null) {
                                    rtcSetting.onTime = oldOnTime;
                                    rtcSetting.offTime = oldOffTime;
                                    if (mounted) {
                                      _showRtcErrorDialog(error);
                                    }
                                  } else {
                                    if (mounted) {
                                      setState(() {
                                        settingList[categoryIndex]
                                            .setting[settingIndex]
                                            .isChanged = true;
                                        settingList[categoryIndex].changed =
                                        true;
                                      });
                                    }
                                  }
                                }
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                }),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTwoPhaseCard(
      int categoryIndex, int settingIndex, int pumpIndex, List settingList) {
    bool singlePhaseModel = [
      ...AppConstants.singlePhasePumpModel,
      ...AppConstants.singlePhasePumpPlusModel,
      ...AppConstants.singlePhaseShineModel,
      ...AppConstants.singlePhaseElitePlusModel,
      ...AppConstants.singlePhaseEcoGemModel,
      ...AppConstants.singlePhaseEcoGemPlusModel
    ].contains(widget.masterData['modelId']);
    bool showTitle = true;
    bool showPumpList = true;
    if (singlePhaseModel) {
      if (settingList[categoryIndex]
          .setting[settingIndex]
          .title
          .contains("2 Phase")) {
        showTitle = false;
        showPumpList = false;
      }
    }
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        if (showTitle)
          ListTile(
            dense: true,
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  settingIndex < otherSettingsIcons.length
                      ? otherSettingsIcons[settingIndex]
                      : Icons.power_rounded,
                  color: colorScheme.primary,
                  size: 17,
                ),
              ),
            ),
            title: Text(
              settingList[categoryIndex].setting[settingIndex].title,
              style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
        if (showPumpList)
          Column(
            children: [
              for (int index = 0;
              index <
                  (isToGem
                      ? preferenceProvider.individualPumpSetting!
                      .where((e) =>
                  e.deviceId ==
                      preferenceProvider
                          .commonPumpSettings![pumpIndex].deviceId)
                      .length
                      : preferenceProvider.individualPumpSetting!.length);
              index++)
                SwitchListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    title: Text(
                      isToGem
                          ? preferenceProvider.individualPumpSetting!
                          .where((e) =>
                      e.deviceId ==
                          preferenceProvider
                              .commonPumpSettings![pumpIndex].deviceId)
                          .elementAt(index)
                          .name
                          : preferenceProvider
                          .individualPumpSetting![index].name,
                      style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
                    ),
                    value: settingList[categoryIndex]
                        .setting[settingIndex]
                        .value[index],
                    onChanged: (newValue) {
                      if (!mounted) return;
                      setState(() {
                        settingList[categoryIndex]
                            .setting[settingIndex]
                            .value[index] = newValue;
                        settingList[categoryIndex]
                            .setting[settingIndex]
                            .isChanged = true;
                        settingList[categoryIndex].changed = true;
                      });
                    }),
            ],
          )
      ],
    );
  }

  int _getWidgetType(int categoryIndex, int settingIndex, List settingList) {
    return (settingList[categoryIndex]
        .setting[settingIndex]
        .title
        .toUpperCase() ==
        "PRESSURE MAXIMUM VALUE")
        ? 7
        : settingList[categoryIndex].setting[settingIndex].widgetTypeId;
  }

  Widget _buildIcon(int categoryIndex, int settingIndex, List settingList) {
    final type = settingList[categoryIndex].type;
    IconData iconData = Icons.tune_rounded;

    if (AppConstants.otherSetting.contains(type) && settingIndex < otherSettingsIcons.length) {
      iconData = otherSettingsIcons[settingIndex];
    } else if (AppConstants.voltageSetting.contains(type) && settingIndex < voltageSettingsIcons.length) {
      iconData = voltageSettingsIcons[settingIndex];
    } else if (AppConstants.timerSetting.contains(type) && settingIndex < timerSettingsIcons.length) {
      iconData = timerSettingsIcons[settingIndex];
    } else if (AppConstants.currentSetting.contains(type) && settingIndex < currentSettingIcons.length) {
      iconData = currentSettingIcons[settingIndex];
    } else if (AppConstants.currentCalibration.contains(type) && settingIndex < voltageCalibrationIcons.length) {
      iconData = voltageCalibrationIcons[settingIndex];
    } else if (AppConstants.otherCalibration.contains(type) && settingIndex < otherCalibrationIcons.length) {
      iconData = otherCalibrationIcons[settingIndex];
    } else if (AppConstants.levelSetting.contains(type) && settingIndex < levelSettingsIcons.length) {
      iconData = levelSettingsIcons[settingIndex];
    } else if ([211, 611].contains(type)) {
      iconData = Icons.numbers;
    } else if (settingIndex < additionalSettingsIcons.length) {
      iconData = additionalSettingsIcons[settingIndex];
    }

    return Icon(iconData, size: 20, color: Theme.of(context).primaryColor);
  }

  dynamic _getSubTitle(
      int categoryIndex,
      int settingIndex,
      List settingList,
      int pumpIndex,
      ) {
    if (!(isNova || isToGem) ||
        ![
          ...AppConstants.voltageCalibration,
          ...AppConstants.currentCalibration,
          ...AppConstants.otherCalibration
        ].contains(settingList[categoryIndex].type)) {
      return null;
    }

    final value = _getValue(
      type: settingList[categoryIndex].type,
      categoryIndex: categoryIndex,
      pumpIndex: pumpIndex,
      settingIndex: settingIndex,
    );

    if (value.isEmpty) {
      return "Last setting: Loading...";
    }

    final parts = value.split(',');
    int index = 0;

    if (categoryIndex == 0 || categoryIndex == 1) {
      index = (settingIndex < 3) ? settingIndex : 0;
    } else {
      index = (settingIndex < parts.length) ? settingIndex : 0;
    }

    return "Last setting: ${parts[index]}";
  }

  String _secondsToTimeString(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showOnDelayAlert(int minSeconds) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text("Invalid Timer Setting"),
            ],
          ),
          content: Text(
              "On Delay Timer must be at least $minSeconds seconds.\nResetting time to ${_secondsToTimeString(minSeconds)}."),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showOnDelayAlertMessage(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text("Invalid Timer Setting"),
            ],
          ),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  String? validateAllOnDelaySettings() {
    if (preferenceProvider.individualPumpSetting != null) {
      for (var individualPump in preferenceProvider.individualPumpSetting!) {
        int minSeconds =
        (AppConstants.shineAndEliteModelList.contains(widget.masterData['modelId']) ||
            (AppConstants.ecoGemAndPlusModelList.contains(widget.masterData['modelId']) &&
                individualPump.pumpType == 2))
            ? 30
            : 5;
        for (var settingCategory in individualPump.settingList) {
          if (AppConstants.timerSetting.contains(settingCategory.type)) {
            for (var setting in settingCategory.setting) {
              final titleUpper = setting.title.toUpperCase();
              if (titleUpper.contains("ON DELAY") ||
                  setting.serialNumber == 1) {
                if (setting.value is String && setting.value.isNotEmpty) {
                  int curSec = _rtcTimeToSeconds(setting.value);
                  if (curSec < minSeconds) {
                    setting.value = _secondsToTimeString(minSeconds);
                    return "${individualPump.name} - ${setting.title}: Minimum value is $minSeconds seconds. Resetting time to ${_secondsToTimeString(minSeconds)}.";
                  }
                }
              }
            }
          }
        }
      }
    }
    return null;
  }

  dynamic _getInitialValue(
      int categoryIndex, int settingIndex, List settingList, int pumpIndex) {
    var val = settingList[categoryIndex].setting[settingIndex].value;
    final setting = settingList[categoryIndex].setting[settingIndex];
    final titleUpper = setting.title.toUpperCase();
    if (titleUpper.contains("ON DELAY") ||
        (AppConstants.timerSetting.contains(settingList[categoryIndex].type) &&
            setting.serialNumber == 1)) {
      int pumpType = 0;
      if (preferenceProvider.individualPumpSetting != null &&
          pumpIndex < preferenceProvider.individualPumpSetting!.length) {
        pumpType =
            preferenceProvider.individualPumpSetting![pumpIndex].pumpType;
      }
      int minSeconds =
      (AppConstants.shineAndEliteModelList.contains(widget.masterData['modelId']) ||
          (AppConstants.ecoGemAndPlusModelList.contains(widget.masterData['modelId']) &&
              pumpType == 2))
          ? 30
          : 5;
      if (val is String && val.isNotEmpty) {
        int curSeconds = _rtcTimeToSeconds(val);
        if (curSeconds < minSeconds) {
          val = _secondsToTimeString(minSeconds);
          setting.value = val;
        }
      }
    }
    return val;
  }

  void onChangeValue(
      int categoryIndex, int settingIndex, List settingList, newValue,
      {int? pumpIndex}) {
    if (!mounted) return;
    setState(() {
      var finalValue = newValue;
      final setting = settingList[categoryIndex].setting[settingIndex];
      final titleUpper = setting.title.toUpperCase();
      if (titleUpper.contains("ON DELAY") ||
          (AppConstants.timerSetting
              .contains(settingList[categoryIndex].type) &&
              setting.serialNumber == 1)) {
        int pumpType = 0;
        if (preferenceProvider.individualPumpSetting != null &&
            pumpIndex != null &&
            pumpIndex < preferenceProvider.individualPumpSetting!.length) {
          pumpType =
              preferenceProvider.individualPumpSetting![pumpIndex].pumpType;
        } else if (preferenceProvider.individualPumpSetting != null) {
          int idx = preferenceProvider.individualPumpSetting!
              .indexWhere((p) => p.settingList == settingList);
          if (idx != -1) {
            pumpType = preferenceProvider.individualPumpSetting![idx].pumpType;
          }
        }
        int minSeconds =
        (AppConstants.shineAndEliteModelList.contains(widget.masterData['modelId']) ||
            (AppConstants.ecoGemAndPlusModelList.contains(widget.masterData['modelId']) &&
                pumpType == 2))
            ? 30
            : 5;
        if (finalValue is String) {
          int selectedSec = _rtcTimeToSeconds(finalValue);
          if (selectedSec < minSeconds) {
            finalValue = _secondsToTimeString(minSeconds);
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) _showOnDelayAlert(minSeconds);
            });
          }
        }
      }

      settingList[categoryIndex].setting[settingIndex].isChanged = true;
      if (AppConstants.otherSetting.contains(settingList[categoryIndex].type)) {
        if (settingList[categoryIndex].setting[settingIndex].serialNumber ==
            15 ||
            settingList[categoryIndex].setting[settingIndex].serialNumber ==
                16) {
          if (settingList[categoryIndex].setting[settingIndex].serialNumber ==
              15) {
            settingList[categoryIndex].setting[settingIndex].value = true;
            settingList[categoryIndex]
                .setting
                .firstWhere((setting) => setting.serialNumber == 16)
                .value = false;
          } else if (settingList[categoryIndex]
              .setting[settingIndex]
              .serialNumber ==
              16) {
            settingList[categoryIndex].setting[settingIndex].value = true;
            settingList[categoryIndex]
                .setting
                .firstWhere((setting) => setting.serialNumber == 15)
                .value = false;
          }
        }
      }
      if (settingList[categoryIndex].type == 211 &&
          settingList[categoryIndex].setting[settingIndex].serialNumber == 5) {
        if (settingList[categoryIndex].setting[settingIndex].value) {
          preferenceProvider.mode == "Manual";
        } else {
          preferenceProvider.mode == "Duration";
        }
      }
      settingList[categoryIndex].changed = true;
      settingList[categoryIndex].setting[settingIndex].value = newValue;
    });
  }

  List<String> extractValues(int rtcIndex, List<String> valuesList) {
    int startIndex = rtcIndex * 2;
    return valuesList.sublist(startIndex, startIndex + 2);
  }

  String _getValue(
      {required int type,
        required int categoryIndex,
        required int pumpIndex,
        required int settingIndex}) {
    String valueToShow = "";

    for (var i = 0; i < mqttPayloadProvider.viewSettingsList.length; i++) {
      if (i == 0) {
        var decodedList = jsonDecode(mqttPayloadProvider.viewSettingsList[i]);
        for (var element in decodedList) {
          Map<String, dynamic> decode = element;
          decode.forEach((key, value) {
            if (AppConstants.voltageCalibration.contains(type)) {
              if (key == "calibration") {
                valueToShow = value;
              }
            } else if (AppConstants.currentCalibration.contains(type)) {
              if (key == "calibration") {
                valueToShow = value.split(',').skip(3).join(',');
              }
            } else if (AppConstants.otherCalibration.contains(type)) {
              if (key == "calibration") {
                valueToShow = value.split(',').skip(6).join(',');
              }
            }
          });
        }
      }
    }

    return valueToShow;
  }

  String getValueForRtc(
      {required int type,
        required int categoryIndex,
        required int pumpIndex,
        required int settingIndex}) {
    String valueToShow = "";

    for (var i = 0; i < mqttPayloadProvider.viewSettingsList.length; i++) {
      if (i - 1 == pumpIndex) {
        var rtcTimeTemp = "";
        var delayTimeTemp = "";
        var decodedList = jsonDecode(mqttPayloadProvider.viewSettingsList[i]);
        for (var element in decodedList) {
          Map<String, dynamic> decode = element;
          decode.forEach((key, value) {
            switch (type) {
              case 202:
                if (key == "rtcconfig") rtcTimeTemp = value;
                valueToShow = delayTimeTemp + rtcTimeTemp;
                break;
            }
          });
        }
      }
    }
    return valueToShow;
  }

  Map<String, bool> conditions = {
    'phaseValue': true,
    'lowVoltage': false,
    'highVoltage': false,
    'startingCapacitor': false,
    'starterFeedback': false,
    'maxTime': false,
    'cyclicTime': false,
    'rtc': false,
    'dryRun': false,
    'dryRunRestart': false,
    'dryRunOcc': false,
    'overLoad': false,
    'schedule': false,
    'light': false,
    'peakHour': false,
  };

  bool getConditionToShow(
      {required int type, required int serialNumber, required value}) {
    bool result = true;
    void setCondition(String key) {
      conditions[key] = value;
    }

    if (AppConstants.otherSetting.contains(type)) {
      if (serialNumber == 9) setCondition('light');
      if (serialNumber == 12) setCondition('peakHour');
      if ([10, 11].contains(serialNumber)) result = conditions['light']!;
      if ([13, 14].contains(serialNumber)) result = conditions['peakHour']!;
    } else if (AppConstants.voltageSetting.contains(type)) {
      if (serialNumber == 1) setCondition('lowVoltage');
      if (serialNumber == 6) setCondition('highVoltage');
      if ([2, 3].contains(serialNumber)) result = conditions['lowVoltage']!;
      if ([4, 5].contains(serialNumber)) {
        result = conditions['phaseValue']! && conditions['lowVoltage']!;
      }
      if ([7, 8].contains(serialNumber)) result = conditions['highVoltage']!;
      if ([9, 10].contains(serialNumber)) {
        result = conditions['phaseValue']! && conditions['highVoltage']!;
      }
    } else if (AppConstants.timerSetting.contains(type)) {
      if (serialNumber == 3) setCondition('startingCapacitor');
      if (serialNumber == 4) result = conditions['startingCapacitor']!;
      if (serialNumber == 5) setCondition('starterFeedback');
      if (serialNumber == 6) result = conditions['starterFeedback']!;
      if (serialNumber == 7) setCondition('maxTime');
      if (serialNumber == 8) result = conditions['maxTime']!;
      if (serialNumber == 9) setCondition('cyclicTime');
      if ([10, 11].contains(serialNumber)) result = conditions['cyclicTime']!;
      if (serialNumber == 12) setCondition('rtc');
      if (serialNumber == 13) result = conditions['rtc']!;
    } else if (AppConstants.currentSetting.contains(type)) {
      if (serialNumber == 1) setCondition('dryRun');
      if (serialNumber == 4) {
        result = conditions['phaseValue']! && conditions['dryRun']!;
      }
      if ([2, 3, 5, 6, 7, 8, 9, 10].contains(serialNumber)) {
        result = conditions['dryRun']!;
      }
      if (serialNumber == 5) setCondition('dryRunRestart');
      if (serialNumber == 6) {
        result = conditions['dryRun']! && conditions['dryRunRestart']!;
      }
      if (serialNumber == 7) setCondition('dryRunOcc');
      if ([8, 9].contains(serialNumber)) {
        result = conditions['dryRun']! && conditions['dryRunOcc']!;
      }
      if (serialNumber == 11) setCondition('overLoad');
      if (serialNumber == 14) {
        result = conditions['phaseValue']! && conditions['overLoad']!;
      }
      if ([12, 13, 15].contains(serialNumber)) result = conditions['overLoad']!;
    } else if (AppConstants.additionalSetting.contains(type)) {
      if (serialNumber == 3) setCondition('schedule');
      if ([4, 5].contains(serialNumber)) result = conditions['schedule']!;
    }

    return result;
  }

  Widget buildTabItem(
      {required int index,
        required String itemName,
        required int selectedIndex}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: index == selectedIndex
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerLow),
        child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                itemName,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: index == selectedIndex
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant),
              ),
            )));
  }

  void selectPumpToSend() {
    showAdaptiveDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter stateSetter) {
                return AlertDialog(
                  title: const Text("Select the pump"),
                  content: SizedBox(
                    height: 200,
                    child: Scrollbar(
                      thumbVisibility: true,
                      trackVisibility: true,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            for (var i = 0;
                            i < preferenceProvider.commonPumpSettings!.length;
                            i++)
                              CheckboxListTile(
                                  dense: false,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 0, horizontal: 10),
                                  title: Text(preferenceProvider
                                      .commonPumpSettings![i].deviceName),
                                  subtitle: Text(preferenceProvider
                                      .commonPumpSettings![i].deviceId),
                                  value: selectedOroPumpList.contains(
                                      preferenceProvider
                                          .commonPumpSettings![i].deviceId),
                                  onChanged: (newValue) {
                                    stateSetter(() {
                                      if (!mounted) return;
                                      setState(() {
                                        if (selectedOroPumpList.contains(
                                            preferenceProvider
                                                .commonPumpSettings![i].deviceId)) {
                                          selectedOroPumpList.remove(
                                              preferenceProvider
                                                  .commonPumpSettings![i].deviceId);
                                        } else {
                                          selectedOroPumpList.add(preferenceProvider
                                              .commonPumpSettings![i].deviceId);
                                        }
                                      });
                                    });
                                  })
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        "CANCEL",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    FilledButton(
                      onPressed: selectedOroPumpList.isNotEmpty
                          ? () async {
                        Navigator.of(context).pop();
                        await sendFunction();
                      }
                          : null,
                      child: const Text("SEND"),
                    ),
                  ],
                );
              });
        });
  }

  static const Map<String, String> statusMessages = {
    "100": "Other settings",
    "200": "Voltage settings",
    "400-1": "Current settings for pump 1",
    "300-1": "Delay settings for pump 1",
    "500-1": "RTC settings for pump 1",
    "600-1": "Schedule config for pump 1",
    "400-2": "Current settings for pump 2",
    "300-2": "Delay settings for pump 2",
    "500-2": "RTC settings for pump 2",
    "600-2": "Schedule config for pump 2",
    "400-3": "Current settings for pump 3",
    "300-3": "Delay settings for pump 3",
    "500-3": "RTC settings for pump 3",
    "600-3": "Schedule config for pump 3",
    "900": "Calibration settings",
  };

  Future<void> sendFunction() async {
    final rtcError = validateAllRtcSettings();
    debugPrint("rtcError : $rtcError");
    if (rtcError != null) {
      _showRtcErrorDialog(rtcError);
      return;
    }
    breakLoop = false;
    Map<String, dynamic> userData = {
      "userId": widget.customerId,
      "controllerId": widget.masterData['controllerId'],
      "createUser": widget.userId
    };

    Map<String, dynamic> payloadForSlave = {
      "400": {"401": onDelayTimer()}
    };

    final payload = shouldSendFailedPayloads
        ? getFailedPayload(isToGem: isToGem, sendAll: false)
        : getPayload(isToGem: isToGem, sendAll: false);
    final payloadParts = payload.split("?")[0].split(';');

    final payloadForGem = preferenceProvider.passwordValidationCode == 200
        ? getCalibrationPayload(isToGem: isToGem).split("?")[0].split(';')
        : payloadParts[0].isEmpty
        ? shouldSendFailedPayloads
        ? getFailedPayload(isToGem: isToGem, sendAll: true)
        .split("?")[0]
        .split(';')
        : getPayload(isToGem: isToGem, sendAll: true)
        .split("?")[0]
        .split(';')
        : payloadParts;
    try {
      bool isLevelSettingChanged = preferenceProvider.individualPumpSetting!
          .any((pump) => pump.settingList.any((setting) =>
      AppConstants.levelSetting.contains(setting.type) &&
          setting.changed));
      bool isAnyOtherChanged = preferenceProvider.commonPumpSettings!
          .any((pump) => pump.settingList.any((setting) => setting.changed));

      if (isToGem) {
        await validatePayloadSent(
            dialogContext: context,
            context: context,
            mqttPayloadProvider: mqttPayloadProvider,
            acknowledgedFunction: () async {
              if (!mounted) return;
              setState(() {
                preferenceProvider.generalData!.controllerReadStatus = "1";
              });
            },
            payload: payloadForSlave,
            payloadCode: "400",
            deviceId: widget.masterData['deviceId']);
      }
      print('start sendFunction');
      if (preferenceProvider.commonPumpSettings!.isNotEmpty &&
          !(isLevelSettingChanged && !isAnyOtherChanged)) {
        if ((isToGem
            ? preferenceProvider.generalData!.controllerReadStatus == "1"
            : true) &&
            payloadForGem.any((item) => item.trim().isNotEmpty)) {
          for (var i = 0; i < payloadForGem.length; i++) {
            var payloadToDecode =
            isToGem ? payloadForGem[i].split('+')[4] : payloadForGem[i];
            var decodedData = jsonDecode(payloadToDecode);
            var key = decodedData.keys.first;
            int oroPumpIndex = 0;
            if (isToGem) {
              oroPumpIndex = preferenceProvider.commonPumpSettings!.indexWhere(
                      (element) =>
                  element.deviceId == payloadForGem[i].split('+')[2]);
            }
            if (!mounted) return;
            setState(() {
              if (key.contains("100")) {
                preferenceProvider.commonPumpSettings![oroPumpIndex]
                    .settingList[0].controllerReadStatus = "0";
              }
              if (key.contains("200")) {
                preferenceProvider.commonPumpSettings![oroPumpIndex]
                    .settingList[1].controllerReadStatus = "0";
              }
              int pumpIndex = 0;
              for (var individualPump
              in preferenceProvider.individualPumpSetting ?? []) {
                if (preferenceProvider
                    .commonPumpSettings![oroPumpIndex].deviceId ==
                    individualPump.deviceId) {
                  if (individualPump.output != null) {
                    pumpIndex = individualPump.output;
                  } else {
                    pumpIndex++;
                  }
                  for (var individualPumpSetting
                  in individualPump.settingList) {
                    if (AppConstants.currentSetting
                        .contains(individualPumpSetting.type)) {
                      if (key.contains("400-$pumpIndex")) {
                        individualPumpSetting.controllerReadStatus = "0";
                      }
                    } else if (AppConstants.timerSetting
                        .contains(individualPumpSetting.type)) {
                      if (key.contains("300-$pumpIndex") ||
                          key.contains("500-$pumpIndex")) {
                        individualPumpSetting.controllerReadStatus = "0";
                      }
                    } else if (AppConstants.additionalSetting
                        .contains(individualPumpSetting.type)) {
                      if (key.contains("600-$pumpIndex")) {
                        individualPumpSetting.controllerReadStatus = "0";
                      }
                    }
                  }
                }
              }
              if (preferenceProvider.passwordValidationCode == 200 &&
                  preferenceProvider.calibrationSetting!.isNotEmpty) {
                if (key.contains("900")) {
                  preferenceProvider.calibrationSetting![oroPumpIndex]
                      .settingList[1].controllerReadStatus = "0";
                }
              }
            });
          }
          print('resultFromDialog');
          final dialogResult = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return PayloadProgressDialog(
                payloads: preferenceProvider.passwordValidationCode == 200
                    ? getCalibrationPayload(isToGem: isToGem).split(';')
                    : payloadForGem,
                deviceId: widget.masterData['deviceId'],
                isToGem: isToGem,
                mqttService: mqttService,
                shouldSendFailedPayloads: shouldSendFailedPayloads,
                isWlc: isWlc,
              );
            },
          );
          if (!mounted) return;
          final isSuccess = (dialogResult == true) ||
              getFailedPayload(sendAll: false, isToGem: isToGem)
                  .split(';')
                  .where((part) => part.isNotEmpty)
                  .toList()
                  .isEmpty;

          if (isSuccess) {
            preferenceProvider.generalData!.controllerReadStatus = "1";
            await Future.delayed(const Duration(milliseconds: 300));
            await showSnackBar(
              message: preferenceProvider.passwordValidationCode == 200
                  ? "Calibration settings sent successfully!"
                  : "Preferences sent successfully!",
              color: Colors.green.shade700,
            );
          } else {
            preferenceProvider.generalData!.controllerReadStatus = "0";
            await showSnackBar(
              message: "Failed to send some settings. Please check failed payloads and try again.",
              color: Colors.red.shade700,
            );
          }
        }
      }

      await Future.delayed(Duration.zero, () {
        userData.addAll({
          'general': preferenceProvider.generalData!.toJson(),
          'contacts': [],
          'settings': preferenceProvider.individualPumpSetting
              ?.map((item) => item.toJson())
              .toList(),
          'pumps': [],
          'calibrationSetting': preferenceProvider.calibrationSetting
              ?.map((item) => item.toJson())
              .toList(),
          'commonPumps': preferenceProvider.commonPumpSettings
              ?.map((item) => item.toJson())
              .toList(),
          'hardware': payloadForSlave,
          'changedPayload': generatePayloadMessageForChangedPayload(),
          'controllerReadStatus':
          preferenceProvider.generalData!.controllerReadStatus,
        });
      });
      if (!mounted) return;
      await Future.delayed(Duration.zero, () async {
        final createUserPreference =
        await repository.createUserPreference(userData);
        final message = jsonDecode(createUserPreference.body);
        if (!mounted) return;
        await showSnackBar(
          message: message['message'] ?? 'Preferences saved to server successfully',
          color: message['code'] == 200 ? Colors.green.shade700 : null,
        );
      });
    } catch (error, stackTrace) {
      if (!mounted) return;
      showSnackBar(
        message: "Failed to update due to: $error",
        color: Colors.red.shade700,
      );
      debugPrint("Error in preference sending: $error");
      debugPrint("Stack trace in preference sending: $stackTrace");
    }
  }

  Future<void> showSnackBar({required String message, Color? color}) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context)
        .showSnackBar(CustomSnackBar(message: message, color: color));
  }

  Map<String, dynamic> generatePayloadMessageForChangedPayload() {
    Map<String, dynamic> payload = {
      "commonPumpSettings": {},
      "individualPumpSetting": {}
    };
    if (preferenceProvider.commonPumpSettings != null) {
      for (var controller in preferenceProvider.commonPumpSettings!) {
        for (var settingCategory in controller.settingList) {
          for (var setting in settingCategory.setting) {
            if (setting.isChanged) {
              if (!payload["commonPumpSettings"]
                  .containsKey(controller.deviceId)) {
                payload["commonPumpSettings"][controller.deviceId] = {};
              }
              if (!payload["commonPumpSettings"][controller.deviceId]
                  .containsKey(settingCategory.name)) {
                payload["commonPumpSettings"][controller.deviceId]
                [settingCategory.name] = {};
              }
              payload["commonPumpSettings"][controller.deviceId]
              [settingCategory.name][setting.title] =
                  setting.value.toString();
            }
          }
        }
      }
    }
    if (preferenceProvider.individualPumpSetting != null) {
      for (var pump in preferenceProvider.individualPumpSetting!) {
        for (var settingCategory in pump.settingList) {
          for (var setting in settingCategory.setting) {
            if (setting.isChanged) {
              if (!payload["individualPumpSetting"].containsKey(pump.name)) {
                payload["individualPumpSetting"][pump.name] = {};
              }
              if (!payload["individualPumpSetting"][pump.name]
                  .containsKey(settingCategory.name)) {
                payload["individualPumpSetting"][pump.name]
                [settingCategory.name] = {};
              }
              payload["individualPumpSetting"][pump.name][settingCategory.name]
              [setting.title] = setting.value.toString();
            }
          }
        }
      }
    }
    return payload;
  }

  String onDelayTimer() {
    List<String> result = [];
    preferenceProvider.individualPumpSetting!.forEach((element) {
      String combinedResult = '${element.toGem()},${element.oDt()}';
      result.add(combinedResult);
    });

    return result.join(';');
  }

  String getPayload({required bool isToGem, required bool sendAll}) {
    List<String> result = [];
    for (var commonSetting in preferenceProvider.commonPumpSettings!) {
      List<String> temp = [];
      int oroPumpSerialNumber = commonSetting.serialNumber;
      String deviceId = commonSetting.deviceId;
      int categoryId = commonSetting.categoryId;
      int categoryId2 = 4;
      int interfaceType = commonSetting.interfaceTypeId;
      int referenceNumber = commonSetting.referenceNumber;
      int modelId = commonSetting.modelId;
      if (selectedOroPumpList.contains(deviceId)) {
        for (var settingCategory in commonSetting.settingList) {
          if (!sendAll
              ? (AppConstants.voltageSetting.contains(settingCategory.type) &&
              settingCategory.changed)
              : AppConstants.voltageSetting.contains(settingCategory.type)) {
            final payload = jsonEncode({
              "200": jsonEncode({
                "sentSms": 'voltageconfig,${getSettingValue(settingCategory)}'
              })
            });
            temp.add(isToGem
                ? "$oroPumpSerialNumber+$referenceNumber+$deviceId+$interfaceType+$payload+$categoryId2"
                : payload);
          } else if (!sendAll
              ? (AppConstants.otherSetting.contains(settingCategory.type) &&
              settingCategory.changed)
              : AppConstants.otherSetting.contains(settingCategory.type)) {
            final payload = jsonEncode({
              "100": jsonEncode(
                  {"sentSms": 'ctconfig,${getSettingValue(settingCategory)}'})
            });
            temp.add(isToGem
                ? "$oroPumpSerialNumber+$referenceNumber+$deviceId+$interfaceType+$payload+$categoryId2"
                : payload);
          }
        }

        int pumpIndex = 0;
        for (var individualPump
        in preferenceProvider.individualPumpSetting ?? []) {
          if ((isPumpWithValveModel || isPumpOnly || !isToGem)
              ? true
              : commonSetting.deviceId == individualPump.deviceId) {
            List<String> currentConfigList = [];
            List<String> delayConfigList = [];
            List<String> rtcConfigList = [];
            List<String> scheduleConfigList = [];
            if (individualPump.output != null) {
              pumpIndex = individualPump.output;
            } else {
              pumpIndex++;
            }
            for (var individualPumpSetting in individualPump.settingList) {
              final conditionToSend =
              (!sendAll ? individualPumpSetting.changed : true);
              if (AppConstants.currentSetting
                  .contains(individualPumpSetting.type)) {
                if (conditionToSend) {
                  final payload = jsonEncode({
                    "400-$pumpIndex": jsonEncode({
                      "sentSms":
                      'currentconfig,$pumpIndex,${getSettingValue(individualPumpSetting)}'
                    })
                  });
                  currentConfigList.add(isToGem
                      ? "$oroPumpSerialNumber+$referenceNumber+$deviceId+$interfaceType+$payload+$categoryId2"
                      : payload);
                }
              } else if (AppConstants.timerSetting
                  .contains(individualPumpSetting.type)) {
                if (conditionToSend) {
                  final payload = jsonEncode({
                    "300-$pumpIndex": jsonEncode({
                      "sentSms":
                      'delayconfig,$pumpIndex,${getSettingValue(individualPumpSetting)}'
                    })
                  });
                  delayConfigList.add(isToGem
                      ? "$oroPumpSerialNumber+$referenceNumber+$deviceId+$interfaceType+$payload+$categoryId2"
                      : payload);

                  final payload2 = jsonEncode({
                    "500-$pumpIndex": jsonEncode({
                      "sentSms":
                      'rtcconfig,$pumpIndex,${getRtcValue(individualPumpSetting)}'
                    })
                  });
                  rtcConfigList.add(isToGem
                      ? "$oroPumpSerialNumber+$referenceNumber+$deviceId+$interfaceType+$payload2+$categoryId2"
                      : payload2);
                }
              } else if (AppConstants.additionalSetting
                  .contains(individualPumpSetting.type)) {
                if (conditionToSend) {
                  int index = preferenceProvider.individualPumpSetting!
                      .indexWhere(
                          (e) => e.controllerId == commonSetting.controllerId);

                  final payload = jsonEncode({
                    "600-$pumpIndex": jsonEncode({
                      "sentSms":
                      'scheduleconfig,$pumpIndex,${getSettingValue(individualPumpSetting, controlToOroGem: (isPumpWithValveModel || !isToGem || isPumpOnly) ? false : preferenceProvider.individualPumpSetting![index].controlGem)}'
                    })
                  });

                  scheduleConfigList.add(isToGem
                      ? "$oroPumpSerialNumber+$referenceNumber+$deviceId+$interfaceType+$payload+$categoryId2"
                      : payload);
                }
              }
            }

            if (currentConfigList.isNotEmpty)
              temp.add(currentConfigList.join('_'));
            if (delayConfigList.isNotEmpty) temp.add(delayConfigList.join('_'));
            if (rtcConfigList.isNotEmpty) temp.add(rtcConfigList.join('_'));
            if (scheduleConfigList.isNotEmpty)
              temp.add(scheduleConfigList.join('_'));
          }
        }
      }
      result.addAll(temp);
    }

    return result.join(';');
  }

  String getFailedPayload({required bool isToGem, required bool sendAll}) {
    List<String> result = [];
    for (var commonSetting in preferenceProvider.commonPumpSettings!) {
      List<String> temp = [];
      int oroPumpSerialNumber = commonSetting.serialNumber;
      String deviceId = commonSetting.deviceId;
      int categoryId = commonSetting.categoryId;
      int categoryId2 = 4;
      int interfaceType = commonSetting.interfaceTypeId;
      int referenceNumber = commonSetting.referenceNumber;
      int modelId = commonSetting.modelId;
      if (selectedOroPumpList.contains(deviceId)) {
        for (var settingCategory in commonSetting.settingList) {
          if (!sendAll
              ? (AppConstants.voltageSetting.contains(settingCategory.type) &&
              settingCategory.controllerReadStatus == "0")
              : AppConstants.voltageSetting.contains(settingCategory.type)) {
            final payload = jsonEncode({
              "200": jsonEncode({
                "sentSms": 'voltageconfig,${getSettingValue(settingCategory)}'
              })
            });
            temp.add(isToGem
                ? "$oroPumpSerialNumber+$referenceNumber+$deviceId+$interfaceType+$payload+$categoryId2"
                : payload);
          } else if (!sendAll
              ? (AppConstants.otherSetting.contains(settingCategory.type) &&
              settingCategory.controllerReadStatus == "0")
              : AppConstants.otherSetting.contains(settingCategory.type)) {
            final payload = jsonEncode({
              "100": jsonEncode(
                  {"sentSms": 'ctconfig,${getSettingValue(settingCategory)}'})
            });
            temp.add(isToGem
                ? "$oroPumpSerialNumber+$referenceNumber+$deviceId+$interfaceType+$payload+$categoryId2"
                : payload);
          }
        }

        int pumpIndex = 0;
        for (var individualPump
        in preferenceProvider.individualPumpSetting ?? []) {
          if ((isPumpWithValveModel || !isToGem || isPumpOnly)
              ? true
              : commonSetting.deviceId == individualPump.deviceId) {
            List<String> currentConfigList = [];
            List<String> delayConfigList = [];
            List<String> rtcConfigList = [];
            List<String> scheduleConfigList = [];
            if (individualPump.output != null) {
              pumpIndex = individualPump.output;
            } else {
              pumpIndex++;
            }
            for (var individualPumpSetting in individualPump.settingList) {
              final conditionToSend = (!sendAll
                  ? individualPumpSetting.controllerReadStatus == "0"
                  : true);
              if (AppConstants.currentSetting
                  .contains(individualPumpSetting.type)) {
                if (conditionToSend) {
                  final payload = jsonEncode({
                    "400-$pumpIndex": jsonEncode({
                      "sentSms":
                      'currentconfig,$pumpIndex,${getSettingValue(individualPumpSetting)}'
                    })
                  });
                  currentConfigList.add(
                    isToGem
                        ? "$oroPumpSerialNumber+$referenceNumber+$deviceId+$interfaceType+$payload+$categoryId2"
                        : payload,
                  );
                }
              } else if (AppConstants.timerSetting
                  .contains(individualPumpSetting.type)) {
                if (conditionToSend) {
                  final payload = jsonEncode({
                    "300-$pumpIndex": jsonEncode({
                      "sentSms":
                      'delayconfig,$pumpIndex,${getSettingValue(individualPumpSetting)}'
                    })
                  });
                  delayConfigList.add(
                    isToGem
                        ? "$oroPumpSerialNumber+$referenceNumber+$deviceId+$interfaceType+$payload+$categoryId2"
                        : payload,
                  );

                  final payload2 = jsonEncode({
                    "500-$pumpIndex": jsonEncode({
                      "sentSms":
                      'rtcconfig,$pumpIndex,${getRtcValue(individualPumpSetting)}'
                    })
                  });
                  rtcConfigList.add(
                    isToGem
                        ? "$oroPumpSerialNumber+$referenceNumber+$deviceId+$interfaceType+$payload2+$categoryId2"
                        : payload2,
                  );
                }
              } else if (AppConstants.additionalSetting
                  .contains(individualPumpSetting.type)) {
                if (conditionToSend) {
                  int index = preferenceProvider.individualPumpSetting!
                      .indexWhere((e) => e.deviceId == commonSetting.deviceId);

                  final payload = jsonEncode({
                    "600-$pumpIndex": jsonEncode({
                      "sentSms":
                      'scheduleconfig,$pumpIndex,${getSettingValue(individualPumpSetting, controlToOroGem: (isPumpWithValveModel || !isToGem || isPumpOnly) ? false : preferenceProvider.individualPumpSetting![index].controlGem)}'
                    })
                  });

                  scheduleConfigList.add(
                    isToGem
                        ? "$oroPumpSerialNumber+$referenceNumber+$deviceId+$interfaceType+$payload+$categoryId2"
                        : payload,
                  );
                }
              }
            }

            if (currentConfigList.isNotEmpty)
              temp.add(currentConfigList.join('_'));
            if (delayConfigList.isNotEmpty) temp.add(delayConfigList.join('_'));
            if (rtcConfigList.isNotEmpty) temp.add(rtcConfigList.join('_'));
            if (scheduleConfigList.isNotEmpty)
              temp.add(scheduleConfigList.join('_'));
          }
        }
      }
      result.addAll(temp);
    }

    return result.join(';');
  }

  String getCalibrationPayload({required bool isToGem}) {
    List result = [];
    for (var commonSetting in preferenceProvider.calibrationSetting!) {
      List temp = [];
      List temp2 = [];
      int oroPumpSerialNumber = commonSetting.serialNumber;
      String deviceId = commonSetting.deviceId;
      int categoryId = 4;
      int interfaceType = commonSetting.interfaceTypeId;
      int referenceNumber = commonSetting.referenceNumber;

      CommonPumpSetting aeratorCalibrationSetting = CommonPumpSetting(
          controllerId: commonSetting.controllerId,
          categoryId: commonSetting.categoryId,
          modelId: commonSetting.modelId,
          deviceId: commonSetting.deviceId,
          deviceName: commonSetting.deviceName,
          serialNumber: commonSetting.serialNumber,
          referenceNumber: commonSetting.referenceNumber,
          interfaceTypeId: commonSetting.interfaceTypeId,
          settingList: [
            SettingList(
                type: 608,
                changed: true,
                controllerReadStatus: '0',
                name: 'Aerator',
                setting: [
                  for (var i in commonSetting.settingList) ...i.setting
                ])
          ]);
      List<SettingList> aeratorOrNormal = AppConstants.aquacultureModelList
          .contains(widget.masterData['modelId'])
          ? aeratorCalibrationSetting.settingList
          : commonSetting.settingList;
      if (selectedOroPumpList.contains(deviceId)) {
        for (var settingCategory in aeratorOrNormal) {
          if (AppConstants.voltageCalibration.contains(settingCategory.type)) {
            final payload = jsonEncode({
              "900": jsonEncode({
                "sentSms": 'calibration,${getSettingValue(settingCategory)}'
              })
            });
            temp.add(isToGem
                ? "$oroPumpSerialNumber+$referenceNumber+$deviceId+$interfaceType+$payload+$categoryId"
                : payload);
          } else if (AppConstants.currentCalibration
              .contains(settingCategory.type)) {
            var splitParts = [];
            if (isToGem) {
              splitParts = temp[0].split('+');
            }
            var tempMap = jsonDecode(
                jsonDecode(isToGem ? splitParts[4] : temp[0])['900']);
            temp2 = tempMap['sentSms'].toString().split(',');
            temp2.add('${getSettingValue(settingCategory)}');
            tempMap['sentSms'] = temp2.join(',');
            debugPrint("tempMap : $tempMap");
            if (isToGem) {
              splitParts[4] = jsonEncode({"900": jsonEncode(tempMap)});
              temp[0] = splitParts.join('+');
            } else {
              temp[0] = jsonEncode({"900": jsonEncode(tempMap)});
            }
          } else if (AppConstants.otherCalibration
              .contains(settingCategory.type)) {
            var splitParts = [];
            if (isToGem) {
              splitParts = temp[0].split('+');
            }
            var tempMap = jsonDecode(
                jsonDecode(isToGem ? splitParts[4] : temp[0])['900']);
            temp2 = tempMap['sentSms'].toString().split(',');
            temp2.add('${getSettingValue(settingCategory)}');
            tempMap['sentSms'] = temp2.join(',');
            if (isToGem) {
              splitParts[4] = jsonEncode({"900": jsonEncode(tempMap)});
              temp[0] = splitParts.join('+');
            } else {
              temp[0] = jsonEncode({"900": jsonEncode(tempMap)});
            }
          }
        }
      }
      result.addAll(temp);
    }
    return result.join(';');
  }

  String getRtcValue(settingCategory) {
    List listToAdd = [];
    settingCategory.setting.forEach((setting) {
      String? value;
      if (setting.title.toUpperCase() == "RTC") {
        listToAdd.add(setting.value ? 1 : 0);
      }
      if (setting.title.toUpperCase() == "RTC TIMER") {
        List<String> rtcTimes = [];

        for (var i = 0; i < setting.rtcSettings!.length; i++) {
          final onTime = setting.rtcSettings![i].onTime;
          final offTime = setting.rtcSettings![i].offTime;
          rtcTimes.add(
              '${onTime.replaceAll(":", ",")},${offTime.replaceAll(":", ",")}');
        }
        value = rtcTimes.join(',');
      }
      if (value != null) {
        listToAdd.add(value);
      }
    });
    return listToAdd.join(",");
  }

  dynamic getSettingValue(settingCategory, {bool? controlToOroGem}) {
    debugPrint('settingCategory.name ::: ${settingCategory.name}');
    List<String> values = [];
    List<WidgetSetting> filterList =
    List<WidgetSetting>.from(settingCategory.setting)
      ..sort((a, b) => a.payloadIndex.compareTo(b.payloadIndex));
    for (var setting in filterList) {
      String? value;
      if (setting.value is bool) {
        if (setting.title.toUpperCase() != 'RTC') {
          if (settingCategory.type == 211) {
            if (preferenceProvider.mode == "Duration" &&
                setting.serialNumber != 5) {
              value = setting.value ? "1" : "0";
            } else if (preferenceProvider.mode == "Manual" &&
                setting.serialNumber == 5) {
              value = setting.value ? "1" : "0";
            }
          } else {
            value = setting.value ? "1" : "0";
          }
        }
        if (controlToOroGem ?? false) {
          if (setting.title.toUpperCase() == "TANK ON/OFF" ||
              setting.title.toUpperCase() == "SUMP ON/OFF") {
            value = '0';
          }
        }
      } else if (setting.value is String) {
        if (settingCategory.type == 211) {
          if (setting.value.toString().contains(',')) {
            final parts = setting.value.split(',');
            if (setting.serialNumber <= 15) {
              if (preferenceProvider.mode == "Manual" &&
                  setting.serialNumber > 5) {
                value = "${parts[1]}";
              } else {
                final result = parts[0].split(':');
                value = "${result[0]},${result[1]}";
              }
            } else {
              value = setting.value;
            }
          } else {
            if (preferenceProvider.mode != "Manual") {
              if (setting.value.toString().contains(':')) {
                value = setting.value.replaceAll(":", ",");
              } else {
                value = setting.value;
              }
            }
          }
        } else {
          switch (setting.widgetTypeId) {
            case 3:
              if (setting.title.toUpperCase().contains("LIGHT")) {
                final result = setting.value.toString().split(':');
                value = setting.value.isEmpty
                    ? "00,00"
                    : "${result[0]},${result[1]}";
              } else {
                value = setting.value.isEmpty
                    ? "00,00,00"
                    : setting.value.replaceAll(":", ",");
              }
              break;
            case 1:
              if (settingCategory.type == 211 &&
                  preferenceProvider.mode != "Manual") {
                value = setting.value.isEmpty ? "000" : setting.value;
              } else {
                value = setting.value.isEmpty ? "000" : setting.value;
              }
              break;
            case 2:
              final parts = setting.value.split(',');
              final result = parts[0].split(':');
              value = "${result[0]},${result[1]}";
            default:
              value = setting.value.isEmpty ? "0" : setting.value;
              break;
          }
        }
      } else {
        if (setting.title.toUpperCase() == '2 PHASE' ||
            setting.title.toUpperCase() == 'AUTO RESTART 2 PHASE' ||
            (setting.title.toUpperCase() == "AUTO RESTART" &&
                setting.serialNumber == 8) ||
            setting.title.toUpperCase() == 'UPPER TANK LINEAR LEVEL SENSOR' ||
            setting.title.toUpperCase() == 'LOWER TANK LINEAR LEVEL SENSOR') {
          const phaseMap = {
            '[false, false, false]': '0',
            '[false, false, true]': '4',
            '[false, true, false]': '2',
            '[false, true, true]': '6',
            '[true, false, false]': '1',
            '[true, false, true]': '5',
            '[true, true, false]': '3',
            '[true, true, true]': '7',
          };
          value = phaseMap[setting.value.toString()] ?? "0";
        }
      }
      if (value != null) values.add(value);
    }
    return values.join(",");
  }
}

String? _titleDescription(String title) {
  switch (title.toUpperCase()) {
    case 'LOW VOLTAGE ON/OFF':
      return 'Cut off pump operation during grid voltage sags';
    case 'HIGH VOLTAGE ON/OFF':
      return 'Protect pump windings from grid over-voltage surges';
    case 'REVERSE PHASE':
      return 'Prevent reverse motor rotation on swapped supply leads';
    case 'VOLTAGE SPP':
      return 'Single-phase voltage loss prevention trip';
    case 'CURRENT SPP':
      return 'Current-based single-phase protection trip';
    case 'LIGHT ON/OFF':
      return 'Control auxiliary field station lighting relay';
    case 'PEAK HOUR ON/OFF':
      return 'Pause heavy loads during high-tariff utility hours';
    case 'PRESSURE SENSOR ON/OFF':
      return 'Monitor line pressure and flow deviations';
    case 'PRESSURE SWITCH ON/OFF':
      return 'Mechanical overpressure switch interlock';
    default:
      return null;
  }
}

Widget buildCustomListTileWidget(
    {required int modelId,
      required BuildContext context,
      required String title,
      String? subTitle,
      bool showTrailing = true,
      required int widgetType,
      dynamic value,
      void Function(dynamic newValue)? onValueChange,
      required Widget leading,
      bool conditionToShow = true,
      required bool hidden,
      required bool display,
      bool enabled = true,
      required List<TextInputFormatter> inputFormatters,
      required List<String> dataList,
      double fullWidth = 400,
      double halfWidth = 190}) {
  debugPrint("$title == $widgetType ");
  const mono = TextStyle(
      fontFamily: 'monospace', fontSize: 15, fontWeight: FontWeight.w600);

  Widget filledBox({required Widget child}) => Container(
    width: double.infinity,
    height: 46,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    alignment: Alignment.centerLeft,
    decoration: BoxDecoration(
        color: kFieldBg, borderRadius: BorderRadius.circular(10)),
    child: child,
  );

  Widget customWidget;
  switch (widgetType) {
    case 1:
    case 4:
      customWidget = Container(
        height: 46,
        decoration: BoxDecoration(
            color: kFieldBg, borderRadius: BorderRadius.circular(10)),
        child: TextFormField(
          key: Key(title),
          enabled: enabled,
          initialValue: value is String ? value : "",
          style: mono,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters:
          (widgetType == 1 && AppConstants.gemModelList.contains(modelId))
              ? AppProperties.regexForNumbers
              : AppProperties.regexForDecimal,
          decoration: const InputDecoration(
            hintText: "000",
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: InputBorder.none,
          ),
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          onChanged: (newValue) => onValueChange?.call(newValue),
        ),
      );
      break;
    case 2:
      customWidget = Switch(
        value: enabled ? (value != "" ? value : false) ?? false : false,
        onChanged: (newValue) {
          if (enabled) onValueChange?.call(newValue);
        },
      );
      break;
    case 3:
      customWidget = filledBox(
        child: enabled
            ? CustomNativeTimePicker(
          initialValue: value is String ? value : "00:00:00",
          is24HourMode: true,
          onChanged: (newValue) => onValueChange?.call(newValue),
          modelId: 1,
        )
            : Text(value ?? "00:00:00", style: mono),
      );
      break;
    case 6:
      customWidget = filledBox(child: Text(value ?? "Wait", style: mono));
      break;
    case 7:
      customWidget = buildPopUpMenuButton(
        context: context,
        dataList: dataList,
        onSelected: (newValue) {
          if (enabled) onValueChange?.call(newValue);
        },
        child: filledBox(
          child: Row(
            children: [
              Expanded(child: Text('$value', style: mono)),
              const Icon(Icons.arrow_drop_down, color: kMuted),
            ],
          ),
        ),
      );
      break;
    default:
      customWidget = Text('Unsupported Widget Type: $widgetType');
      break;
  }

  if (display == false) return const SizedBox.shrink();

  final description = _titleDescription(title);
  final isSwitch = widgetType == 2;
  final showLeading = leading is! SizedBox;

  final Widget body = isSwitch
      ? Container(
    width: fullWidth,
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kCardBorder))),
    child: Row(
      children: [
        if (showLeading) ...[leading, const SizedBox(width: 12)], // OLD ICON
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              if (description != null)
                Text(description,
                    style: const TextStyle(color: kMuted, fontSize: 12.5)),
              if (subTitle != null)
                Text(subTitle,
                    style: const TextStyle(color: kMuted, fontSize: 12)),
            ],
          ),
        ),
        if (showTrailing) customWidget,
      ],
    ),
  )
      : SizedBox(
    width: halfWidth,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showLeading) ...[leading, const SizedBox(width: 8)], // OLD ICON
              Expanded(
                child: Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13.5, color: Color(0xFF3A3F51))),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (showTrailing) customWidget,
          if (subTitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(subTitle,
                  style: const TextStyle(color: kMuted, fontSize: 12)),
            ),
        ],
      ),
    ),
  );

  return Visibility(
    visible: !hidden,
    child: CustomAnimatedSwitcher(condition: conditionToShow, child: body),
  );
}