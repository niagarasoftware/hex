import 'package:flutter/material.dart';
import 'package:hex/modules/IrrigationProgram/widgets/custom_native_time_picker.dart';
import 'package:hex/modules/Preferences/model/preference_data_model.dart';
import 'package:hex/modules/Preferences/state_management/preference_provider.dart';
import 'package:provider/provider.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

import '../../../models/customer/site_model.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = Provider.of<PreferenceProvider>(context, listen: false);
      if (provider.standaloneSettings != null &&
          provider.standaloneSettings!.setting.length > 4) {
        setState(() {
          if (widget.selectedMode == 1) {
            provider.standaloneSettings!.setting[4].value = true;
          } else {
            provider.standaloneSettings!.setting[4].value = false;
          }
        });
      }
      provider.getMode();
    });
  }

  @override
  Widget build(BuildContext context) {
    final valves = widget.masterData.configObjects.where((e) => e.objectId == 13).toList();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Column(
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
                Icon(Icons.tune_rounded, color: colorScheme.onPrimaryContainer, size: 18),
                const SizedBox(width: 8),
                Text(
                  widget.selectedMode == 1 ? "Standalone Settings" : "Program Settings",
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
              child: Consumer<PreferenceProvider>(
                builder: (context, provider, _) {
                  if (provider.standaloneSettings == null ||
                      provider.standaloneSettings!.setting.length < 5) {
                    return const Center(child: CircularProgressIndicator());
                  }
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
                        Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.5)),
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
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          settingItem.title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colorScheme.onSurface),
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
            activeThumbColor: colorScheme.onPrimary,
            activeTrackColor: colorScheme.primary,
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
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              decoration: InputDecoration(
                isDense: true,
                hintText: "000",
                contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
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
          ),
        ),
      ),
    );
  }

  Widget _buildSecondHalfTile(BuildContext context, WidgetSetting settingItem, String mode) {
    final provider = Provider.of<PreferenceProvider>(context, listen: false);
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
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          settingItem.title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colorScheme.onSurface),
        ),
        trailing: IntrinsicWidth(
          child: mode == "Manual"
              ? Switch(
            value: settingItem.serialNumber != 5
                ? provider.getSwitchState(settingItem.value)
                : settingItem.value,
            activeThumbColor: colorScheme.onPrimary,
            activeTrackColor: colorScheme.primary,
            onChanged: (newValue) {
              if (settingItem.serialNumber != 5) {
                provider.updateSwitchValue(settingItem.title, newValue);
              } else {
                if (mounted) {
                  setState(() {
                    provider.standaloneSettings!.setting[4].value = newValue;
                  });
                }
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
