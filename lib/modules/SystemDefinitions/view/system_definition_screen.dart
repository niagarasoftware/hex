import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hex/Constants/properties.dart';
import 'package:hex/services/mqtt_service.dart';
import 'package:provider/provider.dart';
import '../model/system_definition_model.dart';
import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../StateManagement/overall_use.dart';
import '../../IrrigationProgram/widgets/custom_tile.dart';
import '../repository/system_definitions_repo.dart';
import '../state_management/system_definition_provider.dart';
import '../../IrrigationProgram/widgets/custom_animated_switcher.dart';
import '../../IrrigationProgram/widgets/custom_native_time_picker.dart';
import '../widgets/custom_snack_bar.dart';
import '../../../services/http_service.dart';
import '../../../utils/environment.dart';
import '../../IrrigationProgram/view/program_library.dart';
import '../../IrrigationProgram/view/schedule_screen.dart';

import '../widgets/custom_switch_tile.dart';
import '../widgets/custom_timer_tile.dart';

class SystemDefinition extends StatefulWidget {
  final int userId;
  final int controllerId;
  final int customerId;
  final String deviceId;
  const SystemDefinition({
    super.key,
    required this.userId,
    required this.controllerId,
    required this.deviceId,
    required this.customerId,
  });

  @override
  State<SystemDefinition> createState() => _SystemDefinitionState();
}

class _SystemDefinitionState extends State<SystemDefinition> {
  final SystemDefinitionsRepository repository =
  SystemDefinitionsRepository(HttpService());
  late OverAllUse overAllPvd;
  late SystemDefinitionProvider systemDefinitionProvider;
  late MqttPayloadProvider mqttPayloadProvider;

  @override
  void initState() {
    super.initState();
    systemDefinitionProvider =
        Provider.of<SystemDefinitionProvider>(context, listen: false);
    mqttPayloadProvider =
        Provider.of<MqttPayloadProvider>(context, listen: false);
    overAllPvd = Provider.of<OverAllUse>(context, listen: false);
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        systemDefinitionProvider.getUserPlanningSystemDefinition(
            widget.customerId, widget.controllerId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    systemDefinitionProvider =
        Provider.of<SystemDefinitionProvider>(context, listen: true);
    mqttPayloadProvider =
        Provider.of<MqttPayloadProvider>(context, listen: true);
    overAllPvd = Provider.of<OverAllUse>(context, listen: true);
    final screenSize = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = Theme.of(context).primaryColor;

    if (systemDefinitionProvider.irrigationLineSystemData == null) {
      return Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final lineData = systemDefinitionProvider.irrigationLineSystemData!;

    return RefreshIndicator(
      onRefresh: () => systemDefinitionProvider.getUserPlanningSystemDefinition(
          widget.customerId, widget.controllerId),
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: screenSize <= 600
            ? AppBar(
          title: const Text(
            "System Definition",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          automaticallyImplyLeading: true,
          bottom: PreferredSize(
            preferredSize: const Size(double.maxFinite, 44),
            child: Container(
              color: colorScheme.surfaceContainerLow,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < lineData.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: AppProperties.buildSideBarMenuList(
                          context: context,
                          title: lineData[i].name,
                          dataList: lineData.map((e) => e.name).toList(),
                          index: i,
                          selected:
                          systemDefinitionProvider.selectedIrrigationLine == i,
                          onTap: (index) {
                            systemDefinitionProvider
                                .updateSelectedProgramCategory(index);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        )
            : null,
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final isCompact = constraints.maxWidth <= 600;

            return Column(
              children: [
                if (!isCompact)
                  Container(
                    width: double.infinity,
                    color: colorScheme.surface,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 980),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (var i = 0; i < lineData.length; i++)
                                Container(
                                  width: 200,
                                  margin: const EdgeInsets.only(right: 10),
                                  child: AppProperties.buildSideBarMenuList(
                                    context: context,
                                    title: lineData[i].name,
                                    dataList: lineData.map((e) => e.name).toList(),
                                    index: i,
                                    selected:
                                    systemDefinitionProvider.selectedIrrigationLine == i,
                                    onTap: (index) {
                                      systemDefinitionProvider
                                          .updateSelectedProgramCategory(index);
                                    },
                                    constraints: constraints,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: lineData.length,
                    itemBuilder: (BuildContext context, int lineIndex) {
                      if (systemDefinitionProvider.selectedIrrigationLine !=
                          lineIndex) {
                        return const SizedBox.shrink();
                      }
                      return _buildLineContent(
                        context: context,
                        lineIndex: lineIndex,
                        constraints: constraints,
                        isCompact: isCompact,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: MaterialButton(
          minWidth: 110,
          height: 44,
          color: systemDefinitionProvider.controllerReadStatus == "1"
              ? primaryColor
              : Colors.orangeAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textColor: systemDefinitionProvider.controllerReadStatus == "1"
              ? Colors.white
              : Colors.black,
          onPressed: _handleSendPayload,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.send_rounded, size: 18),
              SizedBox(width: 8),
              Text(
                "Send",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildLineContent({
    required BuildContext context,
    required int lineIndex,
    required BoxConstraints constraints,
    required bool isCompact,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final lineItem =
    systemDefinitionProvider.irrigationLineSystemData![lineIndex];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // All lines master toggle card (only shown for Line index 0)
              if (systemDefinitionProvider.selectedIrrigationLine == 0) ...[
                _buildSectionCard(
                  context: context,
                  title: "Master Control",
                  subtitle: "Global power override for all irrigation lines",
                  icon: Icons.clear_all,
                  child: _buildSwitchRow(
                    context: context,
                    title: "All irrigation line should run while power off",
                    subtitle:
                    "Keep all irrigation lines running during grid power outages",
                    value: systemDefinitionProvider.enableAll,
                    icon: Icons.clear_all,
                    onChanged: (newValue) {
                      setState(() {
                        systemDefinitionProvider.enableAll = newValue;
                        for (var i = 0;
                        i <
                            systemDefinitionProvider
                                .irrigationLineSystemData!
                                .length;
                        i++) {
                          systemDefinitionProvider.irrigationLineSystemData![i]
                              .systemDefinition.irrigationLineOn =
                              systemDefinitionProvider.enableAll;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Main Line Settings Card
              _buildSectionCard(
                context: context,
                title: lineItem.name,
                subtitle: "Line power override and energy saving configuration",
                icon: Icons.tune_rounded,
                child: Column(
                  children: [
                    _buildSwitchRow(
                      context: context,
                      title: "Should run while power off",
                      subtitle:
                      "Allow this line to continue operating during power outages",
                      value: lineItem.systemDefinition.irrigationLineOn,
                      icon: Icons.power_settings_new,
                      onChanged: (newValue) {
                        setState(() {
                          lineItem.systemDefinition.irrigationLineOn = newValue;
                          if (systemDefinitionProvider.irrigationLineSystemData!
                              .every((element) =>
                          element.systemDefinition.irrigationLineOn ==
                              true)) {
                            systemDefinitionProvider.enableAll = true;
                          } else {
                            systemDefinitionProvider.enableAll = false;
                          }
                        });
                      },
                    ),
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: colorScheme.outlineVariant.withOpacity(0.3),
                    ),
                    _buildSwitchRow(
                      context: context,
                      title: "Enable energy save function",
                      subtitle:
                      "Restrict line irrigation operation to daylight hours",
                      value: lineItem.systemDefinition.status,
                      icon: Icons.energy_savings_leaf,
                      onChanged: (newValue) {
                        setState(() {
                          lineItem.systemDefinition.status = newValue;
                        });
                      },
                    ),
                    // Energy save time pickers
                    CustomAnimatedSwitcher(
                      condition: lineItem.systemDefinition.status,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withOpacity(0.3),
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, cardConstraints) {
                            const spacing = 12.0;
                            final isHalf = cardConstraints.maxWidth >= 420;
                            final fieldWidth = isHalf
                                ? ((cardConstraints.maxWidth - spacing) / 2)
                                .floorToDouble() -
                                1.0
                                : cardConstraints.maxWidth;

                            return Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: [
                                SizedBox(
                                  width: fieldWidth,
                                  child: _buildTimeInputField(
                                    context: context,
                                    label: "Start day time",
                                    icon: Icons.start,
                                    iconColor: Colors.green,
                                    child: CustomNativeTimePicker(
                                      initialValue:
                                      lineItem.systemDefinition.startDayTime,
                                      is24HourMode: false,
                                      onChanged: (newValue) {
                                        setState(() {
                                          lineItem.systemDefinition.startDayTime =
                                              newValue;
                                        });
                                      },
                                      modelId: 1,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: fieldWidth,
                                  child: _buildTimeInputField(
                                    context: context,
                                    label: "Stop day time",
                                    icon: Icons.stop,
                                    iconColor: Colors.red.shade400,
                                    child: CustomNativeTimePicker(
                                      initialValue:
                                      lineItem.systemDefinition.stopDayTime,
                                      is24HourMode: false,
                                      onChanged: (newValue) {
                                        setState(() {
                                          lineItem.systemDefinition.stopDayTime =
                                              newValue;
                                        });
                                      },
                                      modelId: 1,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Pause By Days Card
              _buildSectionCard(
                context: context,
                title: "Pause By Days",
                subtitle:
                "Configure weekday schedule windows to pause irrigation",
                icon: Icons.pause_circle_outline_rounded,
                child: Column(
                  children: [
                    _buildSwitchRow(
                      context: context,
                      title: "Pause by days",
                      subtitle:
                      "Enable weekly day-wise operation pause intervals",
                      value: lineItem.systemDefinition.pauseMainLine,
                      icon: Icons.pause,
                      onChanged: (newValue) {
                        setState(() {
                          lineItem.systemDefinition.pauseMainLine = newValue;
                        });
                      },
                    ),
                    CustomAnimatedSwitcher(
                      condition: lineItem.systemDefinition.pauseMainLine,
                      child: Container(
                        margin: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withOpacity(0.4),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Table Header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerLow,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                border: Border(
                                  bottom: BorderSide(
                                    color: colorScheme.outlineVariant
                                        .withOpacity(0.3),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 44,
                                    child: Text(
                                      "S.No",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 70,
                                    child: Text(
                                      "Days",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      "From",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      "To",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      "Active",
                                      textAlign: TextAlign.end,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Days Rows
                            for (var i = 0; i < 7; i++)
                              Column(
                                children: [
                                  buildDayTimePicker(
                                    day: systemDefinitionProvider.days[i],
                                    dayTimeRange: systemDefinitionProvider
                                        .daysFromAndToTimes(lineIndex: lineIndex)[i],
                                    dayCount: systemDefinitionProvider.values[i],
                                    checkBoxValue: systemDefinitionProvider
                                        .isSelectedList(lineIndex: lineIndex)[i],
                                    constraints: constraints,
                                    lineIndex: lineIndex,
                                  ),
                                  if (i < 6)
                                    Divider(
                                      height: 1,
                                      thickness: 0.5,
                                      color: colorScheme.outlineVariant
                                          .withOpacity(0.3),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: colorScheme.primaryContainer.withOpacity(0.4),
                    child: Icon(icon, color: primaryColor, size: 16),
                  ),
                ),
                const SizedBox(width: 10),
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
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: colorScheme.primaryContainer.withOpacity(0.4),
              child: Icon(icon, color: primaryColor, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: colorScheme.onPrimary,
            activeTrackColor: colorScheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInputField({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: child,
          ),
        ),
      ],
    );
  }

  Future<void> _handleSendPayload() async {
    Map<String, dynamic> dataToMqtt = {
      "2200": {
        "2201": systemDefinitionProvider.irrigationLineSystemData!
            .map((e) => e.toMqtt())
            .toList()
            .join(";"),
      }
    };

    Map<String, dynamic> userData = {
      "userId": widget.customerId,
      "controllerId": widget.controllerId,
      "createUser": widget.userId,
      "systemDefinition": {
        "systemDefinition": systemDefinitionProvider.irrigationLineSystemData!
            .map((e) => e.toJson())
            .toList(),
        "controllerReadStatus": "1"
      },
      "hardware": dataToMqtt
    };

    try {
      await validatePayloadSent(
          dialogContext: context,
          context: context,
          mqttPayloadProvider: mqttPayloadProvider,
          acknowledgedFunction: () {
            if (!mounted) return;
            setState(() {
              userData['systemDefinition']['controllerReadStatus'] = "1";
              systemDefinitionProvider.controllerReadStatus = "1";
            });
          },
          payload: dataToMqtt,
          payloadCode: "2200",
          deviceId: widget.deviceId);

      await Future.delayed(const Duration(seconds: 1), () async {
        final createUserPlanningSystemDefinition =
        await repository.createUserPlanningSystemDefinition(userData);
        final response =
        jsonDecode(createUserPlanningSystemDefinition.body);
        debugPrint('response:$response');
        if (createUserPlanningSystemDefinition.statusCode == 200) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            CustomSnackBar(
              message: response['message'] ?? "System definition sent successfully",
              color: Colors.green.shade700,
            ),
          );
        }
      });

      MqttService().topicToPublishAndItsMessage(
          jsonEncode(dataToMqtt), '${Environment.mqttPublishTopic}/${widget.deviceId}');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar(
          message: 'Failed to update because of $error',
          color: Colors.red.shade700,
        ),
      );
      debugPrint("Error: $error");
    }
  }

  Widget buildTimePicker(
      {required String currentValue,
        required Function(String) onTap,
        required bool is24HourMode}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(width: 1, color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomNativeTimePicker(
        initialValue: currentValue,
        is24HourMode: is24HourMode,
        onChanged: (newTime) => onTap(newTime),
        modelId: 1,
      ),
    );
  }

  Widget buildSwitchTile(
      {required String title,
        required bool value,
        required Function(bool) onChanged,
        required IconData icon}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: CustomSwitchTile(
        title: title,
        showCircleAvatar: true,
        value: value,
        icon: icon,
        onChanged: onChanged,
      ),
    );
  }

  Widget buildTimerTile(
      {required String subtitle,
        required String initialValue,
        required Function(String) onChanged,
        required IconData icon,
        required bool is24HourMode}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: CustomTimerTile(
        subtitle: subtitle,
        initialValue: initialValue,
        onChanged: onChanged,
        isSeconds: false,
        icon: icon,
        isNative: true,
        is24HourMode: is24HourMode,
        modelId: 1,
      ),
    );
  }

  Widget buildDayTimePicker(
      {required String day,
        required DayTimeRange dayTimeRange,
        required dayCount,
        required checkBoxValue,
        required int lineIndex,
        required constraints}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer<SystemDefinitionProvider>(
      builder: (BuildContext context,
          SystemDefinitionProvider systemDefinitionProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: checkBoxValue
              ? colorScheme.surface
              : colorScheme.surfaceContainerLow.withOpacity(0.5),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Text(
                  "$dayCount",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: checkBoxValue
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: checkBoxValue
                        ? Theme.of(context).primaryColor
                        : colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                ),
              ),
              Expanded(
                child: IgnorePointer(
                  ignoring: !checkBoxValue,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: checkBoxValue
                          ? colorScheme.surfaceContainerLow
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: CustomNativeTimePicker(
                      initialValue: dayTimeRange.from,
                      style: TextStyle(
                        color: checkBoxValue
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant.withOpacity(0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      is24HourMode: false,
                      onChanged: (newTime) =>
                          systemDefinitionProvider.updateDayTimeRange(
                              dayTimeRange, newTime, dayTimeRange.to),
                      modelId: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: IgnorePointer(
                  ignoring: !checkBoxValue,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: checkBoxValue
                          ? colorScheme.surfaceContainerLow
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: CustomNativeTimePicker(
                      initialValue: dayTimeRange.to,
                      style: TextStyle(
                        color: checkBoxValue
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant.withOpacity(0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      is24HourMode: false,
                      onChanged: (newTime) =>
                          systemDefinitionProvider.updateDayTimeRange(
                              dayTimeRange, dayTimeRange.from, newTime),
                      modelId: 1,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 50,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Checkbox(
                    value: checkBoxValue,
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: (newValue) =>
                        systemDefinitionProvider.updateCheckBoxes(
                            dayCount, newValue, lineIndex),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildTimeRow(
      {required String from,
        required String to,
        required Function(String, String) onChanged,
        required bool checkBox,
        required Function(bool?) onChangedBool,
        required constraints}) {
    final colorScheme = Theme.of(context).colorScheme;
    return constraints.maxWidth <= 600
        ? Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IgnorePointer(
          ignoring: !checkBox,
          child: CustomNativeTimePicker(
            initialValue: from,
            style: TextStyle(
              color: checkBox
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant.withOpacity(0.5),
              fontSize: 14,
            ),
            is24HourMode: false,
            onChanged: (newTime) => onChanged(newTime, to),
            modelId: 1,
          ),
        ),
        IgnorePointer(
          ignoring: !checkBox,
          child: CustomNativeTimePicker(
            initialValue: to,
            style: TextStyle(
              color: checkBox
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant.withOpacity(0.5),
              fontSize: 14,
            ),
            is24HourMode: false,
            onChanged: (newTime) => onChanged(from, newTime),
            modelId: 1,
          ),
        ),
        Checkbox(
          value: checkBox,
          activeColor: Theme.of(context).primaryColor,
          onChanged: onChangedBool,
        ),
      ],
    )
        : Column(
      children: [
        const SizedBox(height: 10),
        IgnorePointer(
          ignoring: !checkBox,
          child: CustomNativeTimePicker(
            initialValue: from,
            style: TextStyle(
              color: checkBox
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant.withOpacity(0.5),
              fontSize: 14,
            ),
            is24HourMode: false,
            onChanged: (newTime) => onChanged(newTime, to),
            modelId: 1,
          ),
        ),
        const SizedBox(height: 10),
        IgnorePointer(
          ignoring: !checkBox,
          child: CustomNativeTimePicker(
            initialValue: to,
            style: TextStyle(
              color: checkBox
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant.withOpacity(0.5),
              fontSize: 14,
            ),
            is24HourMode: false,
            onChanged: (newTime) => onChanged(from, newTime),
            modelId: 1,
          ),
        ),
      ],
    );
  }
}
