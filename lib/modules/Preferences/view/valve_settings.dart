import 'package:flutter/material.dart';
import 'package:hex/modules/IrrigationProgram/widgets/custom_native_time_picker.dart';
import 'package:hex/modules/Preferences/model/preference_data_model.dart';
import 'package:hex/modules/Preferences/state_management/preference_provider.dart';
import 'package:provider/provider.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

import '../../../models/customer/site_model.dart';
import '../../IrrigationProgram/view/schedule_screen.dart';

class ValveSettings extends StatefulWidget {
  final int selectedMode;
  final MasterControllerModel masterData;
  const ValveSettings({super.key, required this.masterData, required this.selectedMode});

  @override
  State<ValveSettings> createState() => _ValveSettingsState();
}

class _ValveSettingsState extends State<ValveSettings> {

  @override
  void initState() {
    super.initState();
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = Provider.of<PreferenceProvider>(context, listen: false);
        setState(() {
          if (widget.selectedMode == 1) {
            provider.standaloneSettings!.setting[4].value = true;
          } else {
            provider.standaloneSettings!.setting[4].value = false;
          }
        });
        provider.getMode();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final valves = widget.masterData.configObjects.where((e) => e.objectId == 13).toList();
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Column(
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
                const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  widget.selectedMode == 1 ? "Standalone Settings" : "Program Settings",
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
              child: Consumer<PreferenceProvider>(
                builder: (context, provider, _) {
                  final settings = provider.standaloneSettings!.setting;
                  final firstHalf = settings.sublist(0, 5);
                  final secondHalf = settings.sublist(
                    widget.selectedMode == 2 ? 5 : 4,
                    (widget.selectedMode == 2 ? 4 : 5) + valves.length,
                  );

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (widget.selectedMode == 2) ...[
                        ResponsiveGridList(
                          listViewBuilderOptions: ListViewBuilderOptions(shrinkWrap: true),
                          minItemWidth: MediaQuery.of(context).size.width <= 500 ? 150 : 200,
                          children: [
                            ...firstHalf
                                .where((e) => e.serialNumber != 5)
                                .map((item) => _buildSettingTile(context, item)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                      ],
                      ResponsiveGridList(
                        listViewBuilderOptions: ListViewBuilderOptions(shrinkWrap: true),
                        minItemWidth: MediaQuery.of(context).size.width <= 500 ? 150 : 200,
                        children: [
                          ...secondHalf.map(
                            (item) => _buildSecondHalfTile(context, item, provider.mode),
                          ),
                        ],
                      ),
                      const SizedBox(height: 60),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(BuildContext context, WidgetSetting settingItem) {
    final provider = Provider.of<PreferenceProvider>(context, listen: false);

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
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          settingItem.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        trailing: IntrinsicWidth(
          child: settingItem.widgetTypeId == 3
              ? CustomNativeTimePicker(
                  initialValue: settingItem.value!,
                  is24HourMode: true,
                  onChanged: (newValue) {
                    provider.updateSettingValue(settingItem.title, newValue);
                  },
                  modelId: widget.masterData.modelId,
                )
              : settingItem.widgetTypeId == 2
                  ? Switch(
                      value: settingItem.value,
                      onChanged: (newValue) {
                        provider.updateSwitchValue(settingItem.title, newValue);
                      },
                    )
                  : SizedBox(
                      width: 80,
                      child: TextFormField(
                        key: Key(settingItem.title),
                        initialValue: settingItem.value,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        onChanged: (newValue) {
                          provider.updateSettingValue(settingItem.title, newValue);
                        },
                        onTapOutside: (_) {
                          FocusScope.of(context).unfocus();
                        },
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: "000",
                          contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
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
                            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
                          ),
                          fillColor: cardColor,
                          filled: true,
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildSecondHalfTile(BuildContext context, WidgetSetting settingItem, String mode) {
    final provider = Provider.of<PreferenceProvider>(context, listen: false);

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
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          settingItem.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        trailing: IntrinsicWidth(
          child: mode == "Manual"
              ? Switch(
                  value: settingItem.serialNumber != 5
                      ? provider.getSwitchState(settingItem.value)
                      : settingItem.value,
                  onChanged: (newValue) {
                    if (settingItem.serialNumber != 5) {
                      provider.updateSwitchValue(settingItem.title, newValue);
                    } else {
                      setState(() {
                        provider.standaloneSettings!.setting[4].value = newValue;
                      });
                    }
                  },
                )
              : settingItem.serialNumber != 5
                  ? CustomNativeTimePicker(
                      initialValue: provider.getDuration(settingItem.value),
                      is24HourMode: true,
                      onChanged: (newValue) {
                        provider.updateSettingValue(settingItem.title, newValue);
                      },
                      modelId: widget.masterData.modelId,
                    )
                  : Container(),
        ),
      ),
    );
  }
}
