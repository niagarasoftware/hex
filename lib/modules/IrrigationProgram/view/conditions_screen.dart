import 'package:flutter/material.dart';
import 'package:hex/utils/Theme/oro_theme.dart';
import 'package:provider/provider.dart';
import '../../../views/customer/controller_settings/wide/condition_library_wide.dart';
import '../state_management/irrigation_program_provider.dart';

class ConditionsScreen extends StatefulWidget {
  final int userId;
  final int controllerId;
  final int customerId;
  final int serialNumber;
  final String deviceId;

  const ConditionsScreen({
    super.key,
    required this.userId,
    required this.controllerId,
    required this.serialNumber,
    required this.deviceId,
    required this.customerId,
  });

  @override
  State<ConditionsScreen> createState() => _ConditionsScreenState();
}

class _ConditionsScreenState extends State<ConditionsScreen> {
  late IrrigationProgramMainProvider irrigationProgramProvider;

  @override
  void initState() {
    super.initState();
    irrigationProgramProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: false);
  }

  Color _getIconBgColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFD1FAE5);
      case 1:
        return const Color(0xFFFDE8E8);
      case 2:
        return activeBgLavender;
      case 3:
        return const Color(0xFFFFE5CC);
      default:
        return primaryBackground;
    }
  }

  Color _getIconColor(int index) {
    switch (index) {
      case 0:
        return avatarGreen;
      case 1:
        return const Color(0xFFDC3545);
      case 2:
        return primaryPurple;
      case 3:
        return brandOrange;
      default:
        return primaryPurple;
    }
  }

  IconData _getConditionIcon(int index) {
    switch (index) {
      case 0:
        return Icons.play_arrow_outlined;
      case 1:
        return Icons.crop_square_rounded;
      case 2:
        return Icons.check_circle_outline_rounded;
      case 3:
        return Icons.block_rounded;
      default:
        return Icons.sensors_outlined;
    }
  }

  String _getConditionKey(int index) {
    switch (index) {
      case 0:
        return "start";
      case 1:
        return "stop";
      case 2:
        return "enable";
      case 3:
        return "disable";
      default:
        return "trigger";
    }
  }

  String _getConditionDescription(int index) {
    switch (index) {
      case 0:
        return "Start the program automatically when this sensor trigger evaluates true";
      case 1:
        return "Immediately halt the program when this emergency or threshold trigger is met";
      case 2:
        return "Allow the program to execute only while this environmental baseline remains true";
      case 3:
        return "Block the Planning Method program from running while this trigger persists";
      default:
        return "Configure sensor trigger rules for program execution";
    }
  }

  @override
  Widget build(BuildContext context) {
    irrigationProgramProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: true);

    if (irrigationProgramProvider.sampleConditions == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final conditionsList = irrigationProgramProvider.sampleConditions!.condition;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final isWide = constraints.maxWidth >= 750;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? MediaQuery.of(context).size.width * 0.04 : 16,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Interlock & Safety Triggers Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "INTERLOCK & SAFETY TRIGGERS",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: primaryPurple,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Sensor Trigger Matrix",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Attach automated environmental triggers from soil moisture, weather stations, or pressure transducers to control when this program can start, stop, or pause.",
                            style: TextStyle(
                              fontSize: 13,
                              color: textMuted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: primaryBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline, size: 15, color: primaryPurple),
                          const SizedBox(width: 6),
                          Text(
                            "Real-time polling frequency: 15s",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2x2 Grid or Vertical list of trigger cards
              isWide
                  ? GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 210,
                      ),
                      itemCount: conditionsList.length,
                      itemBuilder: (context, idx) => _buildTriggerCard(idx, conditionsList[idx]),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: conditionsList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, idx) => _buildTriggerCard(idx, conditionsList[idx]),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTriggerCard(int conditionTypeIndex, dynamic condition) {
    final selected = condition.selected ?? false;
    final title = condition.title ?? '';
    final selectedName = (condition.value != null && condition.value['name'] != null && condition.value['name'].toString().isNotEmpty)
        ? condition.value['name'].toString()
        : null;

    final bgColor = _getIconBgColor(conditionTypeIndex);
    final iconColor = _getIconColor(conditionTypeIndex);
    final iconData = _getConditionIcon(conditionTypeIndex);
    final keyName = _getConditionKey(conditionTypeIndex);
    final description = _getConditionDescription(conditionTypeIndex);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (selected || selectedName != null) ? primaryPurple : const Color(0xFFE2E8F0),
          width: (selected || selectedName != null) ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          "Condition key: ",
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          keyName,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: primaryPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Description Text
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: textMuted,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Bottom Select Button
          InkWell(
            onTap: () {
              if (!selected) {
                irrigationProgramProvider.updateConditionType(true, conditionTypeIndex);
              }
              _showConditionSelectionDialog(conditionTypeIndex, title);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: activeBgLavender,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryPurple.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (selectedName != null) ...[
                          Icon(Icons.check_circle, size: 16, color: primaryPurple),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            selectedName ?? "+ Select Sensor Trigger",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: primaryPurple,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: primaryPurple,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConditionSelectionDialog(int conditionTypeIndex, String title) {
    final navigator = Navigator.of(context);

    showAdaptiveDialog(
      context: context,
      builder: (BuildContext dialogContext) => Consumer<IrrigationProgramMainProvider>(
        builder: (context, conditionsProvider, child) {
          final libraryList = conditionsProvider.sampleConditions!.defaultData.conditionLibrary;
          final currentSelectedName = conditionsProvider.sampleConditions!.condition[conditionTypeIndex].value['name'];

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Select $title',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textDark),
            ),
            content: SizedBox(
              height: 320,
              width: 400,
              child: libraryList.isEmpty
                  ? const Center(child: Text("No conditions found in library"))
                  : Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        child: Column(
                          children: libraryList.asMap().entries.map((entry) {
                            final conditionItem = entry.value;
                            final conditionName = conditionItem.name;
                            final conditionSno = conditionItem.sNo;
                            final subTitle = conditionItem.rule;
                            final isSelected = currentSelectedName == conditionName;

                            return ListTile(
                              leading: Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: isSelected ? primaryPurple : const Color(0xFF94A3B8),
                              ),
                              title: Text(
                                conditionName,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 14,
                                  color: isSelected ? primaryPurple : textDark,
                                ),
                              ),
                              subtitle: Text(subTitle, style: TextStyle(fontSize: 12, color: textMuted)),
                              onTap: () {
                                conditionsProvider.updateConditions(title, conditionSno, conditionName, conditionTypeIndex);
                                Future.delayed(const Duration(milliseconds: 200), () {
                                  if (dialogContext.mounted) {
                                    Navigator.of(dialogContext).pop();
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text("Cancel"),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  navigator.push(
                    MaterialPageRoute(
                      builder: (BuildContext context) => ConditionLibraryWide(
                        userId: widget.userId,
                        controllerId: widget.controllerId,
                        deviceId: widget.deviceId,
                        customerId: widget.customerId,
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: primaryPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Edit Conditions"),
              ),
            ],
          );
        },
      ),
    );
  }
}
