import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../IrrigationProgram/view/schedule_screen.dart';
import '../model/preference_data_model.dart';
import '../state_management/preference_provider.dart';

class MoistureSettings extends StatelessWidget {
  const MoistureSettings({super.key});

  @override
  Widget build(BuildContext context) {
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
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.water_drop_outlined, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                "Moisture Settings",
                style: TextStyle(
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
              builder: (context, provider, _) => ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: provider.moistureSettings?.setting.length ?? 0,
                separatorBuilder: (context, index) => const Divider(height: 24, thickness: 0.5),
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
                          color: Theme.of(context).primaryColor,
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
                          color: Theme.of(context).primaryColor,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Switch(
            value: value,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
                  selectedColor: Theme.of(context).primaryColor.withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.black87,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
    return SizedBox(
      width: 80,
      child: TextFormField(
        initialValue: value,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: "000",
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
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
    );
  }
}
