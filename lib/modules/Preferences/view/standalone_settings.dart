import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hex/modules/IrrigationProgram/view/program_library.dart';
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
import '../../SystemDefinitions/widgets/custom_snack_bar.dart';

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
  final int _selectedSetting = 0;
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
    final colorScheme = Theme.of(context).colorScheme;
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
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: Consumer<PreferenceProvider>(
        builder: (context, provider, child) {
          return (provider.standaloneSettings == null ||
              provider.programSettings == null)
              ? const Center(child: CircularProgressIndicator())
              : Padding(
            padding: const EdgeInsets.all(12),
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
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
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
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: colorScheme.error),
              const SizedBox(width: 8),
              Text("Alert!", style: TextStyle(color: colorScheme.error, fontSize: 18, fontWeight: FontWeight.bold)),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(14),
              topLeft: Radius.circular(6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.settings_input_component_rounded,
                  color: colorScheme.onPrimaryContainer, size: 18),
              const SizedBox(width: 8),
              Text(
                widget.selectedIndex == 1
                    ? "Standalone Settings"
                    : "Program settings",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
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
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              color: colorScheme.surface,
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.025),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.4),
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
          TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colorScheme.onSurface),
        ),
        value: setting.value,
        activeThumbColor: colorScheme.onPrimary,
        activeTrackColor: colorScheme.primary,
        onChanged: (value) => setState(() => setting.value = value),
      )
          : ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          [1, 2, 3, 4].contains(setting.serialNumber)
              ? setting.title
              : titles[index],
          style:
          TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colorScheme.onSurface),
        ),
        trailing: _buildTrailingWidget(context, setting),
      ),
    );
  }

  Widget _buildTrailingWidget(BuildContext context, WidgetSetting setting) {
    final colorScheme = Theme.of(context).colorScheme;
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
          activeThumbColor: colorScheme.onPrimary,
          activeTrackColor: colorScheme.primary,
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
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
            decoration: InputDecoration(
              isDense: true,
              hintText: "000",
              contentPadding:
              const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
              ),
              fillColor: colorScheme.surfaceContainerLow,
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

    if (resultFromDialog == true) {
      try {
        final result = widget.selectedIndex == 1
            ? await repository.createUserPreferenceValveStandaloneSetting(userData)
            : _selectedSetting == 0
            ? await repository.createUserPreferenceValveSetting(userData)
            : await repository.createUserPreferenceMoistureSetting(userData);
        final response = jsonDecode(result.body);
        if (!mounted) return;
        showSnackBar(
          message: response['message'] ?? 'Settings updated successfully!',
          context: context,
          color: Colors.green.shade700,
        );
      } catch (error) {
        if (!mounted) return;
        showSnackBar(
          message: 'Failed to save settings: $error',
          context: context,
          color: Colors.red.shade700,
        );
      }
    } else {
      if (!mounted) return;
      showSnackBar(
        message: 'Failed to send settings. Please try again.',
        context: context,
        color: Colors.red.shade700,
      );
    }
  }

  void showSnackBar({required String message, required BuildContext context, Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      CustomSnackBar(
        message: message,
        color: color ?? (message.toLowerCase().contains('failed') || message.toLowerCase().contains('error')
            ? Colors.red.shade700
            : Colors.green.shade700),
      ),
    );
  }
}
