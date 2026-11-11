import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hex/services/mqtt_service.dart';
import 'package:hex/utils/constants.dart';
import 'package:hex/utils/environment.dart';
import 'package:provider/provider.dart';

import '../../../Constants/constants.dart';
import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../services/communication_service.dart';
import '../model/preference_data_model.dart';
import '../state_management/preference_provider.dart';

class ViewConfig extends StatefulWidget {
  final int userId, modelId;
  final bool isLora;
  const ViewConfig(
      {super.key,
      required this.userId,
      required this.isLora,
      required this.modelId});

  @override
  State<ViewConfig> createState() => _ViewConfigState();
}

class _ViewConfigState extends State<ViewConfig> {
  late Map<int, String> configs;
  String selectedPayload = "pumpconfig";
  bool _hasTimedOut = false;
  Timer? _timeoutTimer;
  int _remainingTime = 0;
  final MqttService mqttService = MqttService();
  final List<String> titles = [
    "Nothing",
    "Motor 1",
    "Motor 2",
    "Motor 1, Motor 2",
    "Motor 3",
    "Motor 1, Motor 3",
    "Motor 2, Motor 3",
    "Motor 1, Motor 2, Motor 3",
  ];

  Map<int, String> generateDynamicConfigs(int pumpConfig) {
    Map<int, String> indexToName = {
      1: "pumpconfig",
      2: "tankconfig",
      3: "ctconfig",
      4: "calibration",
      5: "voltageconfig",
      6: "currentconfig1",
      9: "delayconfig1",
      12: "rtcconfig1",
      15: "scheduleconfig1",
    };

    if (pumpConfig >= 2) {
      indexToName.addAll({
        7: "currentconfig2",
        10: "delayconfig2",
        13: "rtcconfig2",
        16: "scheduleconfig2",
      });
    }
    if (pumpConfig >= 3) {
      indexToName.addAll({
        8: "currentconfig3",
        11: "delayconfig3",
        14: "rtcconfig3",
        17: "scheduleconfig3",
      });
    }
    if (pumpConfig >= 4) {
      indexToName.addAll({
        18: "currentconfig4",
        19: "delayconfig4",
        20: "rtcconfig4",
        21: "scheduleconfig4",
      });
    }

    return indexToName;
  }

  void requestViewConfig(int index, {String? newSelectedPayload}) async {
    final mqttProvider = context.read<MqttPayloadProvider>();
    final preferenceProvider = context.read<PreferenceProvider>();

    mqttProvider.viewSettingsList.clear();
    mqttProvider.cCList.clear();

    _timeoutTimer?.cancel();

    setState(() {
      if (newSelectedPayload != null) selectedPayload = newSelectedPayload;
      _hasTimedOut = false;
      _remainingTime = 90;
    });

    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        debugPrint('Widget unmounted - cancelling timer');
        timer.cancel();
        return;
      }

      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
        debugPrint('Timer tick for $selectedPayload: $_remainingTime');
      } else {
        debugPrint('Timer timeout for $selectedPayload');
        timer.cancel();
        if (mounted) {
          setState(() {
            _hasTimedOut = true;
          });
        }
      }
    });

    if (AppConstants.gemModelList.contains(widget.modelId)) {
      final pump = preferenceProvider
          .commonPumpSettings![preferenceProvider.selectedTabIndex];
      final payload = jsonEncode({"sentSms": "viewconfig,$index"});
      final payload2 = jsonEncode({"0": payload});
      final viewConfig = {
        "5900": {
          "5901":
              "${pump.serialNumber}+${pump.referenceNumber}+${pump.deviceId}+${pump.interfaceTypeId}+$payload2+${4}"
        }
      };
      mqttService.topicToPublishAndItsMessage(
        jsonEncode(viewConfig),
        "${Environment.mqttPublishTopic}/${preferenceProvider.generalData!.deviceId}",
      );
    } else {
      var payload = jsonEncode({"sentSms": "viewconfig"});
      final result = await context.read<CommunicationService>().sendCommand(
            serverMsg: '',
            payload: AppConstants.wlcModelList.contains(widget.modelId)
                ? Constants.sendPayloadWithCrc(payload)
                : payload,
          );
      debugPrint('view config result => $result');
    }
  }

  void updateViewPayloads(String pumpConfigValue) {
    int numberOfPumps = int.tryParse(pumpConfigValue) ?? 1;
    configs = generateDynamicConfigs(numberOfPumps);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    configs = generateDynamicConfigs(1);
    requestViewConfig(1);
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  int? getKeyFromValue(Map<int, String> configs, String selectedPayload) {
    for (var entry in configs.entries) {
      if (entry.value == selectedPayload) {
        return entry.key;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final preferenceProvider = context.read<PreferenceProvider>();
    final mqttProvider = context.watch<MqttPayloadProvider>();
    final deviceId = preferenceProvider
        .commonPumpSettings![preferenceProvider.selectedTabIndex].deviceId;

    if (widget.isLora) {
      if (_hasPayload(selectedPayload, mqttProvider, deviceId)) {
        debugPrint('Received LORA response for $deviceId - cancelling timer');
        _timeoutTimer?.cancel();
        _hasTimedOut = false;
      }
    } else {
      if (mqttProvider.viewSettingsList.isNotEmpty &&
          mqttProvider.cCList.contains(deviceId)) {
        _timeoutTimer?.cancel();
        _hasTimedOut = false;
      }
    }

    if (_hasTimedOut) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDropdown(),
              const SizedBox(height: 20),
              Icon(Icons.wifi_off_rounded, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 12),
              const Text(
                "Device is not responding",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "Please check device connectivity and try again.",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  final key = getKeyFromValue(configs, selectedPayload) ?? 1;
                  requestViewConfig(key);
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.isLora
        ? (mqttProvider.viewSetting.isEmpty ||
            (mqttProvider.viewSetting['cC'] != null &&
                !mqttProvider.viewSetting['cC'].contains(deviceId)) ||
            !_hasPayload(
                selectedPayload, context.read<MqttPayloadProvider>(), deviceId))
        : (!mqttProvider.cCList.contains(deviceId))) {
      final primaryColor = Theme.of(context).primaryColor;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryColor.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Fetching configuration...",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Time remaining: ${_remainingTime}s",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          _buildDropdown(),
          const SizedBox(height: 10),
          if (_hasPayload("pumpconfig", mqttProvider, deviceId))
            _buildPumpConfig(
              widget.isLora
                  ? mqttProvider.viewSetting['cM'][0]["pumpconfig"]
                  : '${jsonDecode(mqttProvider.viewSettingsList[0])[0]['pumpconfig']}',
              preferenceProvider,
            )
          else if (_hasPayload("tankconfig", mqttProvider, deviceId))
            _buildTankConfig(
              widget.isLora
                  ? mqttProvider.viewSetting['cM'][0]["tankconfig"]
                  : _getNumberOfTankConfig(mqttProvider),
              preferenceProvider,
            )
          else if (_hasPayload("ctconfig", mqttProvider, deviceId) ||
              _hasPayload("voltageconfig", mqttProvider, deviceId) ||
              _hasPayload("calibration", mqttProvider, deviceId))
            Expanded(child: _buildCommonSettingCategory(mqttProvider, deviceId))
          else
            Expanded(
                child: _buildIndividualSettingCategory(mqttProvider, deviceId)),
        ],
      ),
    );
  }

  String _getNumberOfTankConfig(MqttPayloadProvider mqttProvider) {
    final noOfPumps = widget.isLora
        ? mqttProvider.viewSetting['cM'][0]["pumpconfig"]
        : '${jsonDecode(mqttProvider.viewSettingsList[0])[0]['pumpconfig']}';
    List<String> tankConfig = [];
    for (int i = 0; i < int.parse(noOfPumps.toString().split(',')[0]); i++) {
      tankConfig.add(
          '${jsonDecode(mqttProvider.viewSettingsList[i + 1])[5]['tankconfig']}');
    }

    return tankConfig.join(',');
  }

  Widget _buildDropdown() {
    final primaryColor = Theme.of(context).primaryColor;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          border: Border.all(color: primaryColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(25),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            menuMaxHeight: 300,
            value: selectedPayload,
            borderRadius: BorderRadius.circular(12),
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor),
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            items: configs.entries
                .map((entry) => DropdownMenuItem<String>(
                      value: entry.value,
                      child: Text(entry.value),
                    ))
                .toList(),
            onChanged: (String? value) {
              if (value == null) return;
              setState(() {
                selectedPayload = value;
              });
              final int key =
                  configs.entries.firstWhere((entry) => entry.value == value).key;
              if (widget.isLora) {
                requestViewConfig(key, newSelectedPayload: value);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPumpConfig(String payload, PreferenceProvider prefProvider) {
    final values = payload.split(',');
    updateViewPayloads(values[0]);
    List<String> titles = ['Number of pumps'];
    if (widget.isLora) {
      final pumpNames = prefProvider.individualPumpSetting!
          .where((e) =>
              e.deviceId ==
              prefProvider
                  .commonPumpSettings![prefProvider.selectedTabIndex].deviceId)
          .map((e) => e.name)
          .toList();
      titles.add('Serial id');
      titles.addAll(pumpNames);
    }

    final primaryColorLight = Theme.of(context).primaryColorLight;

    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: primaryColorLight.withOpacity(0.5),
          width: 0.5,
        ),
        borderRadius: const BorderRadius.only(
            bottomRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            topRight: Radius.circular(12)),
      ),
      margin: const EdgeInsets.only(left: 0, right: 0, bottom: 15),
      elevation: 2,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          titles.length,
          (i) => _buildListTile(titles[i].toUpperCase(), values[i]),
        ),
      ),
    );
  }

  bool _hasPayload(String key, MqttPayloadProvider provider, String deviceId) {
    if (widget.isLora) {
      String mqttKey = key;
      if (key.startsWith('currentconfig')) mqttKey = 'currentconfig';
      if (key.startsWith('delayconfig')) mqttKey = 'delayconfig';
      if (key.startsWith('rtcconfig')) mqttKey = 'rtcconfig';
      if (key.startsWith('scheduleconfig')) mqttKey = 'scheduleconfig';
      bool result = provider.viewSetting.isNotEmpty &&
          provider.viewSetting['cM'].isNotEmpty &&
          provider.viewSetting['cM'].first.containsKey(mqttKey) &&
          provider.viewSetting['cC'] == deviceId &&
          selectedPayload.contains(key);
      return result;
    } else {
      switch (key) {
        case 'pumpconfig':
          return provider.viewSettingsList.isNotEmpty &&
              jsonDecode(provider.viewSettingsList[0])[0][key] != null &&
              selectedPayload.contains(key) &&
              provider.cCList.contains(deviceId);
        case 'tankconfig':
          return provider.viewSettingsList.isNotEmpty &&
              jsonDecode(provider.viewSettingsList[1])[5][key] != null &&
              selectedPayload.contains(key) &&
              provider.cCList.contains(deviceId);
        case 'ctconfig':
          return provider.viewSettingsList.isNotEmpty &&
              jsonDecode(provider.viewSettingsList[0])[1][key] != null &&
              selectedPayload.contains(key) &&
              provider.cCList.contains(deviceId);
        case 'voltageconfig':
          return provider.viewSettingsList.isNotEmpty &&
              jsonDecode(provider.viewSettingsList[0])[2][key] != null &&
              selectedPayload.contains(key) &&
              provider.cCList.contains(deviceId);
        case 'currentconfig':
          return provider.viewSettingsList.isNotEmpty &&
              jsonDecode(provider.viewSettingsList[1])[3][key] != null &&
              selectedPayload.contains(key) &&
              provider.cCList.contains(deviceId);
        case 'rtcconfig':
          return provider.viewSettingsList.isNotEmpty &&
              jsonDecode(provider.viewSettingsList[1])[2][key] != null &&
              selectedPayload.contains(key) &&
              provider.cCList.contains(deviceId);
        case 'delayconfig':
          return provider.viewSettingsList.isNotEmpty &&
              jsonDecode(provider.viewSettingsList[1])[1][key] != null &&
              selectedPayload.contains(key) &&
              provider.cCList.contains(deviceId);
        case 'scheduleconfig':
          return provider.viewSettingsList.isNotEmpty &&
              jsonDecode(provider.viewSettingsList[1])[4][key] != null &&
              selectedPayload.contains(key) &&
              provider.cCList.contains(deviceId);
        case 'calibration':
          return provider.viewSettingsList.isNotEmpty &&
              jsonDecode(provider.viewSettingsList[0])[3][key] != null &&
              selectedPayload.contains(key) &&
              provider.cCList.contains(deviceId);
      }
      return false;
    }
  }

  Widget _buildTankConfig(String payload, PreferenceProvider prefProvider) {
    final values = payload.split(',');
    final groups = List.generate(
      (values.length / 9).ceil(),
      (i) => values.skip(i * 9).take(9).toList(),
    );

    final titles = [
      "Number of sump float",
      "Sump low float",
      "Sump high float",
      "Number of tank float",
      "Tank low float",
      "Tank high float",
      "Level on off",
      "Flow on off",
      "Pressure on off"
    ];

    final pumpNames = prefProvider.commonPumpSettings!.length > 1
        ? prefProvider.individualPumpSetting!
            .where((e) =>
                e.deviceId ==
                prefProvider
                    .commonPumpSettings![
                        context.read<PreferenceProvider>().selectedTabIndex]
                    .deviceId)
            .map((e) => e.name)
            .toList()
        : prefProvider.individualPumpSetting!.map((e) => e.name).toList();

    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 20,
              runSpacing: 20,
              children: [
                for (int i = 0; i < pumpNames.length; i++)
                  SizedBox(
                    width: MediaQuery.of(context).size.width <= 500
                        ? MediaQuery.of(context).size.width
                        : 400,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IntrinsicWidth(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            height: 28,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColorLight,
                                borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(16),
                                    topLeft: Radius.circular(4))),
                            child: Center(
                              child: Text(
                                pumpNames[i],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                        Card(
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: Theme.of(context).primaryColorLight.withOpacity(0.5),
                              width: 0.5,
                            ),
                            borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                                topRight: Radius.circular(12)),
                          ),
                          margin: const EdgeInsets.only(
                              left: 0, right: 0, bottom: 15),
                          elevation: 2,
                          color: Colors.white,
                          surfaceTintColor: Colors.white,
                          child: Column(
                            children: [
                              ...groups[i].asMap().entries.map(
                                    (entry) => _buildListTile(
                                        titles[entry.key].toUpperCase(),
                                        entry.value),
                                  )
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommonSettingCategory(MqttPayloadProvider provider, deviceId) {
    final prefProvider = context.read<PreferenceProvider>();
    final settings = prefProvider
        .commonPumpSettings![prefProvider.selectedTabIndex].settingList;
    final calibrationSettings = prefProvider.calibrationSetting!.isNotEmpty
        ? prefProvider
            .calibrationSetting![prefProvider.selectedTabIndex].settingList
        : null;

    return SingleChildScrollView(
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.start,
            spacing: 20,
            runSpacing: 20,
            children: [
              ...(!_hasPayload('calibration', provider, deviceId)
                  ? settings.map((setting) {
                      if (AppConstants.otherSetting.contains(setting.type) &&
                          _hasPayload('ctconfig', provider, deviceId)) {
                        final values = widget.isLora
                            ? provider.viewSetting['cM'].first['ctconfig']
                                .split(',')
                            : '${jsonDecode(provider.viewSettingsList[0])[1]['ctconfig']}'
                                .split(',');
                        return Column(
                          children: [
                            _buildSettingCard(setting, values),
                            _buildSettingCard(setting, values, titles: titles),
                          ],
                        );
                      } else if (AppConstants.voltageSetting
                              .contains(setting.type) &&
                          _hasPayload('voltageconfig', provider, deviceId)) {
                        final values = widget.isLora
                            ? provider.viewSetting['cM'].first['voltageconfig']
                                .split(',')
                            : '${jsonDecode(provider.viewSettingsList[0])[2]['voltageconfig']}'
                                .split(',');
                        return _buildSettingCard(setting, values);
                      }
                      return Container();
                    }).toList()
                  : calibrationSettings != null
                      ? calibrationSettings.map((setting) {
                          if ([
                            ...AppConstants.voltageCalibration,
                            ...AppConstants.currentCalibration,
                            ...AppConstants.otherCalibration
                          ].contains(setting.type)) {
                            final List<String> values = widget.isLora
                                ? provider
                                    .viewSetting['cM'].first['calibration']
                                    .split(',')
                                : '${jsonDecode(provider.viewSettingsList[0])[3]['calibration']}'
                                    .split(',');
                            return _buildSettingCard(
                              setting,
                              AppConstants.voltageCalibration
                                      .contains(setting.type)
                                  ? values
                                  : AppConstants.currentCalibration
                                          .contains(setting.type)
                                      ? values.skip(3).toList()
                                      : values.skip(6).toList(),
                            );
                          }
                          return Container();
                        }).toList()
                      : <Widget>[]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(SettingList setting, List<String> values,
      {List<String> titles = const []}) {
    int range = setting.setting.length < values.length
        ? setting.setting.length
        : values.length;
    return SizedBox(
      width: MediaQuery.of(context).size.width <= 500
          ? MediaQuery.of(context).size.width
          : 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicWidth(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              height: 28,
              decoration: BoxDecoration(
                  color: Theme.of(context).primaryColorLight,
                  borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      topLeft: Radius.circular(4))),
              child: Center(
                child: Text(
                  titles.isEmpty ? setting.name : "2 PH ON/OFF Reference",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Theme.of(context).primaryColorLight.withOpacity(0.5),
                width: 0.5,
              ),
              borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  topRight: Radius.circular(12)),
            ),
            margin: const EdgeInsets.only(left: 0, right: 0, bottom: 15),
            elevation: 2,
            color: Colors.white,
            surfaceTintColor: Colors.white,
            child: Column(children: [
              if (titles.isEmpty)
                ...List.generate(
                  range,
                  (i) {
                    if (i < values.length && i < setting.setting.length) {
                      return _buildListTile(
                          setting.setting[i].title, values[i]);
                    } else {
                      return const SizedBox();
                    }
                  },
                )
              else
                ...List.generate(
                  titles.length,
                  (i) => _buildListTile(titles[i], "$i"),
                )
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualSettingCategory(
      MqttPayloadProvider provider, deviceId) {
    final prefProvider = context.read<PreferenceProvider>();
    final pumps = prefProvider.commonPumpSettings!.length > 1
        ? prefProvider.individualPumpSetting!
            .where((e) =>
                e.deviceId ==
                prefProvider.commonPumpSettings![prefProvider.selectedTabIndex]
                    .deviceId)
            .toList()
        : prefProvider.individualPumpSetting!;

    return SingleChildScrollView(
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.start,
            spacing: 20,
            runSpacing: 20,
            children: pumps.isNotEmpty
                ? pumps[0].settingList.map((setting) {
                    if ([23, ...AppConstants.currentSetting]
                            .contains(setting.type) &&
                        _hasPayload('currentconfig', provider, deviceId)) {
                      return _buildConfigCard(
                          provider, setting, pumps, 'currentconfig');
                    }
                    if ([22, ...AppConstants.timerSetting]
                            .contains(setting.type) &&
                        (_hasPayload('rtcconfig', provider, deviceId) ||
                            _hasPayload('delayconfig', provider, deviceId))) {
                      return _hasPayload('rtcconfig', provider, deviceId)
                          ? _buildRTCConfigCard(provider, setting, pumps)
                          : _buildDelayConfigCard(provider, setting, pumps);
                    }
                    if ([25, ...AppConstants.additionalSetting]
                            .contains(setting.type) &&
                        _hasPayload('scheduleconfig', provider, deviceId)) {
                      return _buildConfigCard(
                          provider, setting, pumps, 'scheduleconfig');
                    }
                    return Container();
                  }).toList()
                : [],
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard(MqttPayloadProvider provider, dynamic setting,
      List pumps, String configType) {
    final values = _getConfigValues(provider, configType);
    final pumpName = _getPumpName(pumps, configType);
    return _buildSettingCardWithTitle(pumpName, setting, values,
        offset: widget.isLora ? 1 : 0);
  }

  Widget _buildRTCConfigCard(
      MqttPayloadProvider provider, dynamic setting, List pumps) {
    final rtcValues = _getConfigValues(provider, 'rtcconfig');
    final pumpName = _getPumpName(pumps, 'rtcconfig');

    return SizedBox(
      width: MediaQuery.of(context).size.width <= 500
          ? MediaQuery.of(context).size.width
          : 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicWidth(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              height: 28,
              decoration: BoxDecoration(
                  color: Theme.of(context).primaryColorLight,
                  borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      topLeft: Radius.circular(4))),
              child: Center(
                child: Text(
                  pumpName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Theme.of(context).primaryColorLight.withOpacity(0.5),
                width: 0.5,
              ),
              borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  topRight: Radius.circular(12)),
            ),
            margin: const EdgeInsets.only(left: 0, right: 0, bottom: 15),
            elevation: 2,
            color: Colors.white,
            surfaceTintColor: Colors.white,
            child: Column(
              children: [
                _buildListTile(setting.setting[11].title,
                    widget.isLora ? rtcValues[1] : rtcValues[0]),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildRTCTable(setting, rtcValues),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDelayConfigCard(
      MqttPayloadProvider provider, dynamic setting, List pumps) {
    final delayValues = _getConfigValues(provider, 'delayconfig');
    final pumpName = _getPumpName(pumps, 'delayconfig');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicWidth(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            height: 28,
            decoration: BoxDecoration(
                color: Theme.of(context).primaryColorLight,
                borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    topLeft: Radius.circular(4))),
            child: Center(
              child: Text(
                pumpName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ),
        Card(
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Theme.of(context).primaryColorLight.withOpacity(0.5),
              width: 0.5,
            ),
            borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                topRight: Radius.circular(12)),
          ),
          margin: const EdgeInsets.only(left: 0, right: 0, bottom: 15),
          elevation: 2,
          color: Colors.white,
          surfaceTintColor: Colors.white,
          child: Column(
            children: [
              ...List.generate(setting.setting.length, (i) {
                if (delayValues.length > (widget.isLora ? (i + 1) : i)) {
                  return _buildListTile(setting.setting[i].title,
                      widget.isLora ? delayValues[i + 1] : delayValues[i]);
                }
                return Container();
              }),
            ],
          ),
        )
      ],
    );
  }

  List<String> _getConfigValues(
      MqttPayloadProvider provider, String configType) {
    return widget.isLora
        ? provider.viewSetting['cM'].first[configType].split(',')
        : jsonDecode(provider.viewSettingsList[_getPayloadIndex(configType)])[
                _getConfigTypeIndex(configType)][configType]
            .split(',');
  }

  int _getConfigTypeIndex(String configType) {
    switch (configType) {
      case 'currentconfig':
        return 3;
      case 'rtcconfig':
        return 2;
      case 'delayconfig':
        return 1;
      case 'scheduleconfig':
        return 4;
      default:
        return 0;
    }
  }

  int _getPayloadIndex(String configType) {
    return selectedPayload.contains('${configType}2')
        ? 2
        : selectedPayload.contains('${configType}3')
            ? 3
            : selectedPayload.contains('${configType}4')
                ? 4
                : 1;
  }

  String _getPumpName(List pumps, String configType) {
    int index = _getPayloadIndex(configType) - 1;
    return (pumps.length > index) ? pumps[index].name : 'Not Configured';
  }

  Widget _buildRTCTable(dynamic setting, List<String> rtcValues) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
      },
      border: TableBorder.all(
        color: Colors.grey.shade200,
        width: 1,
        borderRadius: BorderRadius.circular(8),
      ),
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                  child: Text('RTC',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Theme.of(context).primaryColor))),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                  child: Text('On Time (HH:MM:SS)',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Theme.of(context).primaryColor))),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                  child: Text('Off Time (HH:MM:SS)',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Theme.of(context).primaryColor))),
            ),
          ],
        ),
        if (setting.setting[12].rtcSettings != null)
          ...setting.setting[12].rtcSettings!.asMap().entries.map((entry) {
            final idx = entry.key;
            final timeValues = extractValues(
                idx, rtcValues.skip(widget.isLora ? 2 : 1).toList());
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                      child: Text('${idx + 1}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                      child: Text(timeValues[0],
                          style: const TextStyle(fontSize: 12))),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                      child: Text(timeValues[1],
                          style: const TextStyle(fontSize: 12))),
                ),
              ],
            );
          }),
      ],
    );
  }

  Widget _buildSettingCardWithTitle(String title, setting, List<String> values,
      {int offset = 0}) {
    return SizedBox(
      width: MediaQuery.of(context).size.width <= 500
          ? MediaQuery.of(context).size.width
          : 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicWidth(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              height: 28,
              decoration: BoxDecoration(
                  color: Theme.of(context).primaryColorLight,
                  borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      topLeft: Radius.circular(4))),
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Theme.of(context).primaryColorLight.withOpacity(0.5),
                width: 0.5,
              ),
              borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  topRight: Radius.circular(12)),
            ),
            margin: const EdgeInsets.only(left: 0, right: 0, bottom: 15),
            elevation: 2,
            color: Colors.white,
            surfaceTintColor: Colors.white,
            child: Column(
              children: [
                ...List.generate(
                  setting.setting.length,
                  (i) {
                    if (values.length > i) {
                      return _buildListTile(
                          setting.setting[i].title, values[i + offset]);
                    }
                    return Container();
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  List<String> extractValues(int index, List<String> values) {
    final start = index * 2;
    return values.sublist(start, start + 2);
  }
}
