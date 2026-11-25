import 'package:flutter/material.dart';
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
        return const Color(0xFFECFDF5);
      case 1:
        return const Color(0xFFFEF2F2);
      case 2:
        return const Color(0xFFF5F3FF);
      case 3:
        return const Color(0xFFFFF7ED);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _getIconColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFF10B981);
      case 1:
        return const Color(0xFFEF4444);
      case 2:
        return const Color(0xFF7C3AED);
      case 3:
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF5B21B6);
    }
  }

  IconData _getConditionIcon(int index) {
    switch (index) {
      case 0:
        return Icons.play_arrow_outlined;
      case 1:
        return Icons.stop_outlined;
      case 2:
        return Icons.check_circle_outline;
      case 3:
        return Icons.block_outlined;
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (irrigationProgramProvider.sampleConditions == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final conditionsList = irrigationProgramProvider.sampleConditions!.condition;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final isWide = constraints.maxWidth >= 750;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
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
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "INTERLOCK & SAFETY TRIGGERS",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5B21B6),
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "Sensor Trigger Matrix",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Attach automated environmental triggers from soil moisture, weather stations, or pressure transducers to control when this program can start, stop, or pause.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.query_builder, size: 14, color: colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            "Real-time polling frequency: 15s",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant),
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
                        mainAxisExtent: 220,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selected = condition.selected;
    final title = condition.title;
    final selectedName = condition.value != null && condition.value['name'] != null ? condition.value['name'].toString() : null;

    final bgColor = _getIconBgColor(conditionTypeIndex);
    final iconColor = _getIconColor(conditionTypeIndex);
    final iconData = _getConditionIcon(conditionTypeIndex);
    final keyName = _getConditionKey(conditionTypeIndex);
    final description = _getConditionDescription(conditionTypeIndex);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
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
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Condition key: $keyName',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: selected,
                  activeThumbColor: colorScheme.onPrimary,
                  activeTrackColor: colorScheme.primary,
                  onChanged: (newValue) {
                    irrigationProgramProvider.updateConditionType(newValue, conditionTypeIndex);
                  },
                ),
              ),
            ],
          ),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          InkWell(
            onTap: () {
              if (!selected) {
                irrigationProgramProvider.updateConditionType(true, conditionTypeIndex);
              }
              _showConditionSelectionDialog(conditionTypeIndex, title);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedName ?? "+ Select Sensor Trigger",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: colorScheme.primary,
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
    showAdaptiveDialog(
      context: context,
      builder: (BuildContext dialogContext) => Consumer<IrrigationProgramMainProvider>(
        builder: (context, conditionsProvider, child) {
          final libraryList = conditionsProvider.sampleConditions!.defaultData.conditionLibrary;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Select $title',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
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
                          children: libraryList.asMap().entries.map((conditions) {
                            final conditionName = conditions.value.name;
                            final conditionSno = conditions.value.sNo;
                            final subTitle = conditions.value.rule;

                            return RadioListTile<String>(
                              title: Text(conditionName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: Text(subTitle, style: const TextStyle(fontSize: 12)),
                              value: conditionName,
                              groupValue: conditionsProvider.sampleConditions!.condition[conditionTypeIndex].value['name'],
                              activeColor: const Color(0xFF5B21B6),
                              onChanged: (newValue) {
                                conditionsProvider.updateConditions(title, conditionSno, newValue, conditionTypeIndex);
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  Navigator.of(context).pop();
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
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel"),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
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
                  backgroundColor: const Color(0xFF5B21B6),
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
