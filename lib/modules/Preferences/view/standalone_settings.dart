import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hex/modules/IrrigationProgram/view/program_library.dart';
import 'package:hex/modules/IrrigationProgram/view/schedule_screen.dart';
import 'package:hex/modules/Preferences/state_management/preference_provider.dart';
import 'package:hex/modules/Preferences/view/moisture_settings.dart';
import 'package:hex/services/http_service.dart';
import 'package:hex/services/mqtt_service.dart';
import 'package:hex/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:responsive_grid/responsive_grid.dart';
import '../../../models/customer/site_model.dart';
import '../model/preference_data_model.dart';
import '../repository/preferences_repo.dart';
import '../widgets/progress_dialog.dart';
import '../../IrrigationProgram/widgets/custom_native_time_picker.dart';

class StandAloneSettings extends StatefulWidget {
  final int userId, customerId, selectedIndex;
  final MasterControllerModel masterData;

  const StandAloneSettings({
    super.key,
    required this.userId,
    required this.customerId,
    required this.masterData,
    required this.selectedIndex,
  });

  @override
  State<StandAloneSettings> createState() => _StandAloneSettingsState();
}

class _StandAloneSettingsState extends State<StandAloneSettings> {
  final PreferenceRepository repository = PreferenceRepository(HttpService());
  int _selectedSetting = 0;
  late final bool isPumpWithLight;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<PreferenceProvider>(context, listen: false);
    provider.getStandAloneSettings(
      userId: widget.customerId,
      controllerId: widget.masterData.controllerId,
      selectedIndex: widget.selectedIndex,
    );
    isPumpWithLight =
        AppConstants.pumpWithLightModelList.contains(widget.masterData.modelId);
  }

  @override
  Widget build(BuildContext context) {
    final valves = widget.masterData.configObjects
        .where((e) =>
            e.objectId ==
            (AppConstants.pumpWithLightModelList
                    .contains(widget.masterData.modelId)
                ? 19
                : 13))
        .map((ele) => ele.name)
        .toList();

    return Scaffold(
      body: Consumer<PreferenceProvider>(
        builder: (context, provider, child) {
          return (provider.standaloneSettings == null ||
                  provider.programSettings == null)
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Expanded(
                        child: _selectedSetting == 0
                            ? _buildValveSettings(context, valves, provider)
                            : const MoistureSettings(),
                      ),
                    ],
                  ),
                );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final provider =
              Provider.of<PreferenceProvider>(context, listen: false);
          if (widget.selectedIndex == 1 &&
              provider.standaloneSettings!.setting[0].value == true &&
              provider.standaloneSettings!.setting
                  .where((e) => e.serialNumber != 1)
                  .every((ele) => ele.value == false)) {
            _showAlert();
          } else {
            _sendSettings(context);
          }
        },
        label: const Text('Send', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.send_rounded),
      ),
    );
  }

  void _showAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text("Alert!", style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            "The standalone system cannot be activated without opening the valves, as this may cause the pipeline to burst.",
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        );
      },
    );
  }

  Widget _buildValveSettings(
      BuildContext context, List<String> valves, PreferenceProvider provider) {
    final primaryColor = Theme.of(context).primaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColorLight,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
              topLeft: Radius.circular(6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.settings_input_component_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                widget.selectedIndex == 1
                    ? "Standalone Settings"
                    : "Program settings",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              color: Colors.white,
              border: Border.all(
                color: Theme.of(context).primaryColorLight.withOpacity(0.4),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: ResponsiveGridList(
              desiredItemWidth:
                  MediaQuery.of(context).size.width <= 500 ? 150 : 200,
              minSpacing: 10,
              children: widget.selectedIndex == 1
                  ? List.generate(
                      valves.length + 1,
                      (i) => _buildSettingTile(
                          context,
                          provider.standaloneSettings!.setting[i],
                          valves,
                          i - 1),
                    )
                  : List.generate(
                      valves.length + 4,
                      (i) => _buildSettingTile(
                          context,
                          provider.programSettings!.setting[i],
                          valves,
                          i - 4),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(BuildContext context, WidgetSetting setting,
      List<String> titles, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).primaryColorLight.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: widget.selectedIndex == 1
          ? SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                widget.selectedIndex == 1
                    ? setting.serialNumber == 1
                        ? setting.title
                        : titles[index]
                    : [1, 2, 3, 4].contains(setting.serialNumber)
                        ? setting.title
                        : titles[index],
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              value: setting.value,
              onChanged: (value) => setState(() => setting.value = value),
            )
          : ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                [1, 2, 3, 4].contains(setting.serialNumber)
                    ? setting.title
                    : titles[index],
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              trailing: _buildTrailingWidget(context, setting),
            ),
    );
  }

  Widget _buildTrailingWidget(BuildContext context, WidgetSetting setting) {
    switch (setting.widgetTypeId) {
      case 3:
        return CustomNativeTimePicker(
          initialValue: setting.value!,
          is24HourMode: true,
          onChanged: (value) => setState(() => setting.value = value),
          modelId: AppConstants.ecoGemModelList.first,
        );
      case 2:
        return Switch(
          value: setting.value,
          onChanged: (value) => setState(() => setting.value = value),
        );
      case 1:
        return SizedBox(
          width: 80,
          child: TextFormField(
            initialValue: setting.value.toString(),
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            onChanged: (value) => setState(() => setting.value = value),
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              isDense: true,
              hintText: "000",
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: Theme.of(context).primaryColor, width: 1.5),
              ),
              fillColor: cardColor,
              filled: true,
            ),
          ),
        );
      default:
        return const Text("Unknown");
    }
  }

  Future<void> _sendSettings(BuildContext context) async {
    final provider = Provider.of<PreferenceProvider>(context, listen: false);
    Map<String, dynamic> rawPayload = {};

    if (widget.selectedIndex == 1) {
      rawPayload = {
        "sentSms":
            'standalone,${provider.standaloneSettings!.setting.map((e) => e.value ? '1' : '0').join(',')}'
      };
    } else {
      if (_selectedSetting == 0) {
        rawPayload = {
          "sentSms":
              'valvesetting,${provider.programSettings!.setting.map((e) {
            if (e.widgetTypeId == 2) {
              return e.value ? '1' : '0';
            } else if (e.value is String && (e.value as String).isEmpty) {
              return '0';
            } else {
              if (e.value.toString().contains(':')) {
                final result = e.value.split(':');
                if (e.serialNumber == 3) {
                  return '${result[0]},${result[1]},${result[2]}';
                } else {
                  return '${result[0]},${result[1]}';
                }
              } else {
                return e.value;
              }
            }
          }).join(',')}'
        };
      } else {
        rawPayload = {
          "sentSms":
              'moisturesetting,${provider.standaloneSettings!.setting.map((e) => e.widgetTypeId == 2 ? (e.value ? '1' : '0') : e.value).join(',')}'
        };
      }
    }
    final payload =
        jsonEncode({_selectedSetting == 0 ? "55" : "57": jsonEncode(rawPayload)});

    final resultFromDialog = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PayloadProgressDialog(
        payloads: [payload],
        deviceId: widget.masterData.deviceId,
        isToGem: false,
        mqttService: MqttService(),
        shouldSendFailedPayloads: false,
        isWlc: AppConstants.wlcModelList.contains(widget.masterData.modelId),
      ),
    );

    Map<String, dynamic> userData = {
      "userId": widget.customerId,
      "controllerId": widget.masterData.controllerId,
      "createUser": widget.userId,
      "hardware": rawPayload,
      if (_selectedSetting == 0)
        if (widget.selectedIndex == 1)
          "valveStandalone": provider.standaloneSettings!.toJson()
        else
          "valveSetting": provider.programSettings!.toJson()
      else
        "moistureSetting": provider.moistureSettings!.toJson()
    };

    if (resultFromDialog) {
      try {
        final result = widget.selectedIndex == 1
            ? await repository.createUserPreferenceValveStandaloneSetting(userData)
            : _selectedSetting == 0
                ? await repository.createUserPreferenceValveSetting(userData)
                : await repository.createUserPreferenceMoistureSetting(userData);
        final response = jsonDecode(result.body);
        showSnackBar(message: response['message'], context: context);
      } catch (error, stackTrace) {
        if (kDebugMode) {
          // print('Stack trace in the sending valve settings :: $stackTrace');
        }
        showSnackBar(message: '$error', context: context);
      }
    }
  }
}
