import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../IrrigationProgram/view/schedule_screen.dart';
import '../model/preference_data_model.dart';
import '../state_management/preference_provider.dart';

class MoistureSettings extends StatelessWidget {
  const MoistureSettings({super.key});

  @override
  Widget build(BuildContext context) {
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
              Icon(Icons.water_drop_outlined, color: colorScheme.onPrimaryContainer, size: 18),
              const SizedBox(width: 8),
              Text(
                "Moisture Settings",
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
              builder: (context, provider, _) => ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: provider.moistureSettings?.setting.length ?? 0,
                separatorBuilder: (context, index) => Divider(height: 24, thickness: 0.5, color: colorScheme.outlineVariant.withOpacity(0.5)),
                itemBuilder: (context, index) => _buildSettingItem(
                  context,
                  provider,
                  provider.moistureSettings!.setting[index],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
      BuildContext context,
      PreferenceProvider provider,
      WidgetSetting item,
      ) {
    const settingOptions = ["Both", "Any", "Moisture 1", "Moisture 2"];

    switch (item.serialNumber) {
      case 1:
        return _SwitchTile(
          title: item.title,
          value: item.value as bool,
          onChanged: (value) =>
              provider.updateMoistureSwitchValue(item.title, value),
        );
      case 2:
        return _RadioTile(
          title: item.title,
          options: settingOptions,
          value: item.value as int,
          onChanged: (value) => provider.updateRadioValue(item.title, value!),
        );
      default:
        final values = (item.value as String).split(',');
        final colorScheme = Theme.of(context).colorScheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.serialNumber == 3)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Expanded(child: SizedBox()),
                    SizedBox(
                      width: 80,
                      child: Text(
                        "Min",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 80,
                      child: Text(
                        "Max",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            _RangeInputTile(
              title: item.title,
              firstValue: values[0],
              secondValue: values[1],
              onChanged1: (value) =>
                  provider.updateMoistureSettingValue(item.title, value, true),
              onChanged2: (value) =>
                  provider.updateMoistureSettingValue(item.title, value, false),
            ),
          ],
        );
    }
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colorScheme.onSurface),
            ),
          ),
          Switch(
            value: value,
            activeColor: colorScheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _RadioTile extends StatelessWidget {
  final String title;
  final List<String> options;
  final int value;
  final ValueChanged<int?> onChanged;

  const _RadioTile({
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colorScheme.onSurface),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options.asMap().entries.map((entry) {
              final optionIndex = entry.key + 1;
              final isSelected = value == optionIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(entry.value),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) onChanged(optionIndex);
                  },
                  selectedColor: colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _RangeInputTile extends StatelessWidget {
  final String title;
  final String firstValue;
  final String secondValue;
  final ValueChanged<String> onChanged1;
  final ValueChanged<String> onChanged2;

  const _RangeInputTile({
    required this.title,
    required this.firstValue,
    required this.secondValue,
    required this.onChanged1,
    required this.onChanged2,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
            ),
          ),
          _NumberInputField(
            value: firstValue,
            onChanged: onChanged1,
          ),
          const SizedBox(width: 16),
          _NumberInputField(
            value: secondValue,
            onChanged: onChanged2,
          ),
        ],
      ),
    );
  }
}

class _NumberInputField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _NumberInputField({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 80,
      child: TextFormField(
        initialValue: value,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        onChanged: onChanged,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: "000",
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
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
  }
}
