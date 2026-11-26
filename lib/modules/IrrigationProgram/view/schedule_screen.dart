import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:hex/utils/Theme/oro_theme.dart';
import 'package:hex/utils/constants.dart';
import 'package:provider/provider.dart';
import '../state_management/irrigation_program_provider.dart';
import '../widgets/custom_date_picker.dart';
import '../widgets/custom_native_time_picker.dart';

final dateFormat = DateFormat('dd-MM-yyyy');

class ScheduleScreen extends StatefulWidget {
  final int serialNumber;
  final int modelId;

  const ScheduleScreen({
    super.key,
    required this.serialNumber,
    required this.modelId,
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late IrrigationProgramMainProvider irrigationProgramProvider;

  @override
  void initState() {
    super.initState();
    irrigationProgramProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: false);
    Future.delayed(Duration.zero, () {
      irrigationProgramProvider.updateCurrentRtcIndex(0);
    });
  }

  void addTab(dynamic rtcType) {
    final rtcMap = rtcType is Map ? rtcType : rtcType.rtc;
    if (rtcMap.length < 6) {
      setState(() {
        rtcMap["rtc${rtcMap.length + 1}"] = {
          "onTime": "00:00:00",
          "offTime": "00:00:00",
          "interval": "00:00:00",
          "noOfCycles": "1",
          "maxTime": "00:00:00",
          "condition": false,
          "stopMethod": "Continuous"
        };
      });
      irrigationProgramProvider.notifyUI();
    } else {
      showAdaptiveDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: const Text("Cannot add more than 6 RTC's"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  void deleteTab(dynamic rtcType) {
    final rtcMap = rtcType is Map ? rtcType : rtcType.rtc;
    if (rtcMap.length > 1) {
      setState(() {
        rtcMap.remove(rtcMap.keys.last);
      });
      irrigationProgramProvider.notifyUI();
    } else {
      showAdaptiveDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: const Text("Number of RTC's should be at least 1"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  void clearRtcTabs(dynamic rtcType) {
    final rtcMap = rtcType is Map ? rtcType : rtcType.rtc;
    if (rtcMap.length > 1) {
      setState(() {
        final firstKey = rtcMap.keys.first;
        final firstVal = rtcMap[firstKey];
        rtcMap.clear();
        rtcMap[firstKey] = firstVal;
      });
      irrigationProgramProvider.notifyUI();
    }
  }

  @override
  Widget build(BuildContext context) {
    irrigationProgramProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: true);

    if (irrigationProgramProvider.sampleScheduleModel == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isEcoGem = AppConstants.ecoGemAndPlusModelList.contains(widget.modelId);
    final scheduleType = irrigationProgramProvider.selectedScheduleType;

    final noScheduleCondition =
        scheduleType != irrigationProgramProvider.scheduleTypes[0] &&
        scheduleType != irrigationProgramProvider.scheduleTypes[3];

    final rtcType = scheduleType == irrigationProgramProvider.scheduleTypes[1]
        ? irrigationProgramProvider.sampleScheduleModel!.scheduleAsRunList
        : scheduleType == irrigationProgramProvider.scheduleTypes[2]
            ? irrigationProgramProvider.sampleScheduleModel!.scheduleByDays
            : irrigationProgramProvider.sampleScheduleModel!.scheduleAsRunList;

    final functionCondition = scheduleType == irrigationProgramProvider.scheduleTypes[1]
        ? irrigationProgramProvider.sampleScheduleModel!.scheduleAsRunList.rtc
        : irrigationProgramProvider.sampleScheduleModel!.scheduleByDays.rtc;

    final schedule = scheduleType == irrigationProgramProvider.scheduleTypes[1]
        ? irrigationProgramProvider.sampleScheduleModel!.scheduleAsRunList.schedule
        : irrigationProgramProvider.sampleScheduleModel!.scheduleByDays.schedule;

    final allowStopMethodCondition =
        irrigationProgramProvider.sampleScheduleModel!.defaultModel.allowStopMethod;
    final defaultOffTime =
        irrigationProgramProvider.sampleScheduleModel!.defaultModel.rtcOffTime;
    final defaultMaxTime =
        irrigationProgramProvider.sampleScheduleModel!.defaultModel.rtcMaxTime;

    var startDateStr = irrigationProgramProvider.startDate(serialNumber: widget.serialNumber);
    DateTime startDate = DateTime.tryParse(startDateStr) ?? DateTime.now();

    var endDateStr = schedule['endDate'] ?? DateTime.now().toString();
    DateTime endDate = DateTime.tryParse(endDateStr) ?? DateTime.now();
    if (endDate.isBefore(startDate)) {
      endDate = startDate;
    }

    final isForceToEndDate = schedule['isForceToEndDate'] ?? false;
    var noOfDays = ((schedule['noOfDays'] == "" || schedule['noOfDays'] == "0") ? "1" : schedule['noOfDays']) ?? '1';
    final runDays = ((schedule['runDays'] == "" || schedule['runDays'] == "0") ? "1" : schedule['runDays']) ?? '1';
    final skipDays = schedule['skipDays'] ?? '0';

    final firstDate = startDate.add(Duration(
      days: scheduleType == irrigationProgramProvider.scheduleTypes[1]
          ? (int.parse(noOfDays) - 1)
          : (int.parse(runDays != '' ? runDays : "1") + int.parse(skipDays != '' ? skipDays : "0")),
    ));

    final isWide = MediaQuery.of(context).size.width >= 1000;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? MediaQuery.of(context).size.width * 0.04 : 16,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ACTIVE PLANNING METHOD STRATEGY CARD
          _buildActivePlanningCard(context, isEcoGem, scheduleType),
          const SizedBox(height: 16),

          // 2. STRATEGY CONFIGURATION CONTROL CARDS (Row of 4 Cards)
          _buildConfigurationCardsRow(
            context: context,
            schedule: schedule,
            scheduleType: scheduleType,
            isForceToEndDate: isForceToEndDate,
            startDate: startDate,
            endDate: endDate,
            firstDate: firstDate,
            noOfDays: noOfDays,
            runDays: runDays,
            skipDays: skipDays,
            rtcType: rtcType,
          ),
          const SizedBox(height: 20),

          // 3. REAL-TIME CLOCK (RTC) TRIGGERS CONTAINER CARD
          if (noScheduleCondition)
            _buildRtcTriggersCard(
              context: context,
              functionCondition: functionCondition,
              rtcType: rtcType,
              allowStopMethodCondition: allowStopMethodCondition,
              defaultOffTime: defaultOffTime,
              defaultMaxTime: defaultMaxTime,
            ),

          // 4. DAY COUNT / PROGRAM SCHEDULE TYPE CARD
          if (scheduleType == irrigationProgramProvider.scheduleTypes[3])
            _buildDayCountScheduleCard(context, isEcoGem),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // 1. Active Planning Method Strategy Header Card
  Widget _buildActivePlanningCard(BuildContext context, bool isEcoGem, String currentScheduleType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ACTIVE PLANNING METHOD STRATEGY",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: primaryPurple,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "PLANNING METHOD ${currentScheduleType.toUpperCase()}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getPlanningSubtitle(currentScheduleType),
                  style: TextStyle(fontSize: 13, color: textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          InkWell(
            onTap: () => _showScheduleTypeDialog(context, isEcoGem),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: activeBgLavender,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Change Planning Method",
                    style: TextStyle(
                      color: primaryPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.keyboard_arrow_down, color: primaryPurple, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPlanningSubtitle(String type) {
    if (type == irrigationProgramProvider.scheduleTypes[1]) {
      return "Planning Method for specific days";
    } else if (type == irrigationProgramProvider.scheduleTypes[2]) {
      return "Planning Method based on run days and skip days";
    } else if (type == irrigationProgramProvider.scheduleTypes[3]) {
      return "Planning Method for recurring day count schedule";
    } else {
      return "Manually start execution whenever needed";
    }
  }

  void _showScheduleTypeDialog(BuildContext context, bool isEcoGem) {
    final types = isEcoGem
        ? irrigationProgramProvider.scheduleTypesForEcoGem
        : irrigationProgramProvider.scheduleTypes;

    final descriptions = isEcoGem
        ? [
            "Manually start whenever needed",
            "1. Without cycle limit, program will run continuously \n2. With cycle limit, program will run daily at real time clock by setting start time"
          ]
        : [
            "Manually start whenever needed",
            "Schedule for specific days",
            "Schedule based on run days, skip days",
            "1. Without cycle limit, program will run continuously \n2. With cycle limit, program will run daily at real time clock by setting start time"
          ];

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return SimpleDialog(
          title: Text(
            'Schedule types',
            style: TextStyle(color: primaryPurple, fontWeight: FontWeight.bold),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          children: List.generate(types.length, (i) {
            final isSelected = irrigationProgramProvider.selectedScheduleType == types[i];
            return Column(
              children: [
                SimpleDialogOption(
                  onPressed: () {
                    irrigationProgramProvider.updateSelectedScheduleType(types[i]);
                    Navigator.pop(ctx);
                  },
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    title: Text(
                      types[i],
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? primaryPurple : textDark,
                      ),
                    ),
                    subtitle: Text(
                      descriptions[i],
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                    trailing: Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? primaryPurple : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                if (i != types.length - 1) const Divider(indent: 20, endIndent: 20, height: 1),
              ],
            );
          }),
        );
      },
    );
  }

  // 2. Row of 4 Control Cards
  Widget _buildConfigurationCardsRow({
    required BuildContext context,
    required Map<String, dynamic> schedule,
    required String scheduleType,
    required bool isForceToEndDate,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime firstDate,
    required String noOfDays,
    required String runDays,
    required String skipDays,
    required dynamic rtcType,
  }) {
    final isWide = MediaQuery.of(context).size.width >= 1100;

    final card1 = DatePickerField(
      value: startDate,
      firstDate: DateTime.now(),
      onChanged: (newDate) => irrigationProgramProvider.updateDate(newDate, "startDate"),
      child: _buildControlCard(
        icon: Icons.calendar_today_rounded,
        topLabel: "START DATE",
        mainValue: dateFormat.format(startDate),
        pillBadge: "DD-MM-YYYY",
        statusText: "Scheduled to initiate at first RTC trigger",
        statusIcon: Icons.check_circle_outline,
        statusColor: const Color(0xFF16A34A),
      ),
    );

    final currentDaysVal = scheduleType == irrigationProgramProvider.scheduleTypes[1]
        ? noOfDays
        : runDays;

    final card2 = _buildControlCard(
      icon: Icons.sync_rounded,
      topLabel: scheduleType == irrigationProgramProvider.scheduleTypes[1] ? "REPEAT INTERVAL" : "RUN DAYS",
      mainValue: "$currentDaysVal Day${(int.tryParse(currentDaysVal) ?? 1) > 1 ? 's' : ''}",
      statusText: "Daily recurring execution",
      statusIcon: Icons.sync,
      statusColor: primaryPurple,
      trailingStepper: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStepperButton("-", () {
            final val = int.tryParse(currentDaysVal) ?? 1;
            if (val > 1) {
              final newStr = (val - 1).toString();
              if (scheduleType == irrigationProgramProvider.scheduleTypes[1]) {
                irrigationProgramProvider.updateNumberOfDays(newStr, 'noOfDays', rtcType);
              } else {
                irrigationProgramProvider.updateNumberOfDays(newStr, 'runDays', rtcType);
              }
            }
          }),
          const SizedBox(width: 4),
          _buildStepperButton("+", () {
            final val = int.tryParse(currentDaysVal) ?? 1;
            final newStr = (val + 1).toString();
            if (scheduleType == irrigationProgramProvider.scheduleTypes[1]) {
              irrigationProgramProvider.updateNumberOfDays(newStr, 'noOfDays', rtcType);
            } else {
              irrigationProgramProvider.updateNumberOfDays(newStr, 'runDays', rtcType);
            }
          }),
        ],
      ),
    );

    final card3 = _buildControlCard(
      icon: Icons.lock_clock_outlined,
      topLabel: "FORCE STOP ON END DATE",
      mainValue: "Force stop on End date",
      titleOnly: true,
      subBadge: "SAFETY RELAY ARMED",
      statusText: "Hardware safety relay terminates pump operation at midnight on cycle boundary.",
      trailingSwitch: Switch(
        value: isForceToEndDate,
        activeThumbColor: Colors.white,
        activeTrackColor: primaryPurple,
        onChanged: (val) => irrigationProgramProvider.updateForceToEndDate2(newValue: val),
      ),
    );

    final card4 = _buildControlCard(
      icon: Icons.lock_outlined,
      topLabel: "DAY 1",
      mainValue: "DAY 1",
      titleOnly: true,
      subBadge: "DO ONE TIME",
      statusText: "Hardware safety relay terminates pump operation at midnight on cycle boundary.",
      trailingIcon: Icons.keyboard_arrow_down,
    );

    if (isWide) {
      return Row(
        children: [
          Expanded(child: card1),
          const SizedBox(width: 12),
          Expanded(child: card2),
          const SizedBox(width: 12),
          Expanded(child: card3),
          const SizedBox(width: 12),
          Expanded(child: card4),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: card1),
              const SizedBox(width: 12),
              Expanded(child: card2),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: card3),
              const SizedBox(width: 12),
              Expanded(child: card4),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildControlCard({
    required IconData icon,
    required String topLabel,
    required String mainValue,
    String? pillBadge,
    String? subBadge,
    required String statusText,
    IconData? statusIcon,
    Color? statusColor,
    Widget? trailingStepper,
    Widget? trailingSwitch,
    IconData? trailingIcon,
    bool titleOnly = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: activeBgLavender,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primaryPurple, size: 18),
              ),
              if (trailingSwitch != null)
                trailingSwitch
              else if (trailingIcon != null)
                Icon(trailingIcon, color: textMuted, size: 20)
              else
                Text(
                  topLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Main Value Row
          if (titleOnly) ...[
            Text(
              mainValue,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            if (subBadge != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  subBadge,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF166534),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        mainValue,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (pillBadge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            pillBadge,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailingStepper != null) trailingStepper,
              ],
            ),
          ],

          const SizedBox(height: 14),

          // Bottom Status Text
          Row(
            children: [
              if (statusIcon != null)
                Icon(statusIcon, size: 14, color: statusColor ?? const Color(0xFF64748B)),
              if (statusIcon != null) const SizedBox(width: 4),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: statusColor ?? const Color(0xFF64748B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton(String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ),
    );
  }

  // 3. Real-Time Clock (RTC) Triggers Container Card
  Widget _buildRtcTriggersCard({
    required BuildContext context,
    required dynamic functionCondition,
    required dynamic rtcType,
    required bool allowStopMethodCondition,
    required bool defaultOffTime,
    required bool defaultMaxTime,
  }) {
    final rtcMap = functionCondition is Map ? functionCondition : rtcType.rtc;
    final keys = rtcMap.keys.toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: activeBgLavender,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.alarm_rounded, color: primaryPurple, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Real-Time Clock (RTC) Triggers",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Program hardware time-synchronized trigger channels and recurring execution sequences.",
                            style: TextStyle(fontSize: 13, color: textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    child: Text(
                      "Select",
                      style: TextStyle(color: textDark, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => clearRtcTabs(functionCondition),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFEE2E8)),
                      backgroundColor: const Color(0xFFFEF2F2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                    label: const Text(
                      "Clear",
                      style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => addTab(functionCondition),
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text(
                      "Add RTC Trigger",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // RTC Channels List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final key = keys[index];
              final data = rtcMap[key];
              return _buildRtcChannelCard(
                index: index,
                data: data,
                rtcType: rtcType,
                allowStopMethodCondition: allowStopMethodCondition,
                defaultOffTime: defaultOffTime,
                defaultMaxTime: defaultMaxTime,
                functionCondition: functionCondition,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRtcChannelCard({
    required int index,
    required dynamic data,
    required dynamic rtcType,
    required bool allowStopMethodCondition,
    required bool defaultOffTime,
    required bool defaultMaxTime,
    required dynamic functionCondition,
  }) {
    final stopMethod = data['stopMethod'] ?? irrigationProgramProvider.stopMethods[0];
    final isStopTimeActive = defaultOffTime || stopMethod == irrigationProgramProvider.stopMethods[1];
    final isMaxTimeActive = defaultMaxTime || stopMethod == irrigationProgramProvider.stopMethods[2];

    final isWide = MediaQuery.of(context).size.width >= 1100;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Channel Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "RTC ${index + 1}",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6D28D9),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                "Active Channel",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                onPressed: () => deleteTab(functionCondition),
                tooltip: "Delete RTC",
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Fields Row (6 Fields)
          if (isWide)
            Row(
              children: [
                Expanded(child: _buildTriggerModeField(index, stopMethod, rtcType, allowStopMethodCondition)),
                const SizedBox(width: 10),
                Expanded(child: _buildStartTimeField(index, data['onTime'], rtcType)),
                const SizedBox(width: 10),
                Expanded(child: _buildStopTimeField(index, data['offTime'], rtcType, isStopTimeActive)),
                const SizedBox(width: 10),
                Expanded(child: _buildCycleIntervalField(index, data['interval'], rtcType)),
                const SizedBox(width: 10),
                Expanded(child: _buildRepeatCyclesField(index, data['noOfCycles'], rtcType)),
                const SizedBox(width: 10),
                Expanded(child: _buildMaxRunTimeField(index, data['maxTime'], rtcType, isMaxTimeActive)),
              ],
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(width: 160, child: _buildTriggerModeField(index, stopMethod, rtcType, allowStopMethodCondition)),
                SizedBox(width: 160, child: _buildStartTimeField(index, data['onTime'], rtcType)),
                SizedBox(width: 160, child: _buildStopTimeField(index, data['offTime'], rtcType, isStopTimeActive)),
                SizedBox(width: 160, child: _buildCycleIntervalField(index, data['interval'], rtcType)),
                SizedBox(width: 160, child: _buildRepeatCyclesField(index, data['noOfCycles'], rtcType)),
                SizedBox(width: 160, child: _buildMaxRunTimeField(index, data['maxTime'], rtcType, isMaxTimeActive)),
              ],
            ),
        ],
      ),
    );
  }

  // Field 1: Trigger Mode / Stop Method
  Widget _buildTriggerModeField(int index, String currentMethod, dynamic rtcType, bool allowStopMethod) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TRIGGER MODE",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          allowStopMethod
              ? PopupMenuButton<String>(
                  onSelected: (val) {
                    irrigationProgramProvider.updateRtcProperty(val, index, 'stopMethod', rtcType);
                  },
                  itemBuilder: (ctx) => irrigationProgramProvider.stopMethods
                      .map((m) => PopupMenuItem(value: m, child: Text(m)))
                      .toList(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currentMethod,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
                    ],
                  ),
                )
              : Text(
                  currentMethod,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
        ],
      ),
    );
  }

  // Field 2: Start Time
  Widget _buildStartTimeField(int index, String onTime, dynamic rtcType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "START TIME",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomNativeTimePicker(
                initialValue: (onTime as String?) ?? "00:00:00",
                is24HourMode: true,
                modelId: widget.modelId,
                onChanged: (newTime) => irrigationProgramProvider.updateRtcProperty(newTime, index, 'onTime', rtcType),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF64748B)),
            ],
          ),
        ],
      ),
    );
  }

  // Field 3: Stop Time
  Widget _buildStopTimeField(int index, String offTime, dynamic rtcType, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "STOP TIME",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              isActive
                  ? CustomNativeTimePicker(
                      initialValue: (offTime as String?) ?? "00:00:00",
                      is24HourMode: true,
                      modelId: widget.modelId,
                      onChanged: (newTime) => irrigationProgramProvider.updateRtcProperty(newTime, index, 'offTime', rtcType),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF166534),
                      ),
                    )
                  : const Text(
                      "N/A",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
              Icon(
                isActive ? Icons.check_circle_outline : Icons.block,
                size: 16,
                color: isActive ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Field 4: Cycle Interval
  Widget _buildCycleIntervalField(int index, String interval, dynamic rtcType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "CYCLE INTERVAL",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomNativeTimePicker(
                initialValue: (interval as String?) ?? "00:00:00",
                is24HourMode: true,
                modelId: widget.modelId,
                onChanged: (newTime) => irrigationProgramProvider.updateRtcProperty(newTime, index, 'interval', rtcType),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Icon(Icons.sync_rounded, size: 16, color: Color(0xFF64748B)),
            ],
          ),
        ],
      ),
    );
  }

  // Field 5: Repeat Cycles
  Widget _buildRepeatCyclesField(int index, String noOfCycles, dynamic rtcType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "REPEAT CYCLES",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: (noOfCycles as String?) ?? "1",
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp('[^0-9]')),
                    LengthLimitingTextInputFormatter(2),
                  ],
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  onChanged: (val) => irrigationProgramProvider.updateRtcProperty(val, index, 'noOfCycles', rtcType),
                ),
              ),
              const Text(
                "RUNS",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Field 6: Max Run Time
  Widget _buildMaxRunTimeField(int index, String maxTime, dynamic rtcType, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "MAX RUN TIME",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              isActive
                  ? CustomNativeTimePicker(
                      initialValue: (maxTime as String?) ?? "00:00:00",
                      is24HourMode: true,
                      modelId: widget.modelId,
                      onChanged: (newTime) => irrigationProgramProvider.updateRtcProperty(newTime, index, 'maxTime', rtcType),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    )
                  : const Text(
                      "N/A",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
              Icon(
                isActive ? Icons.timer_outlined : Icons.block,
                size: 16,
                color: isActive ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Day Count Schedule Card
  Widget _buildDayCountScheduleCard(BuildContext context, bool isEcoGem) {
    final dayCountSchedule = irrigationProgramProvider.sampleScheduleModel!.dayCountSchedule.schedule;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.repeat_rounded, color: Color(0xFF5B21B6), size: 22),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Program Execution Schedule",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Configure repeat interval, start time, and cycle execution limits.",
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildDayCountField(
                  title: "CYCLE INTERVAL",
                  icon: Icons.sync_rounded,
                  child: CustomNativeTimePicker(
                    initialValue: dayCountSchedule["interval"] ?? "00:00:00",
                    is24HourMode: true,
                    modelId: widget.modelId,
                    onChanged: (newTime) => irrigationProgramProvider.updateDayCountSchedule(property: "interval", newValue: newTime),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (!isEcoGem)
                Expanded(
                  child: _buildDayCountField(
                    title: "SHOULD LIMIT CYCLES",
                    icon: Icons.check_box_outlined,
                    child: Checkbox(
                      value: dayCountSchedule["shouldLimitCycles"] ?? false,
                      activeColor: const Color(0xFF5B21B6),
                      onChanged: (val) => irrigationProgramProvider.updateDayCountSchedule(property: "shouldLimitCycles", newValue: val),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (isEcoGem || (dayCountSchedule["shouldLimitCycles"] ?? false))
                Expanded(
                  child: _buildDayCountField(
                    title: "START TIME",
                    icon: Icons.access_time_rounded,
                    child: CustomNativeTimePicker(
                      initialValue: dayCountSchedule["onTime"] ?? "00:00:00",
                      is24HourMode: true,
                      modelId: widget.modelId,
                      onChanged: (newTime) => irrigationProgramProvider.updateDayCountSchedule(property: "onTime", newValue: newTime),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ),
                ),
              if ((dayCountSchedule["shouldLimitCycles"] ?? false)) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDayCountField(
                    title: "NO. OF CYCLES",
                    icon: Icons.repeat_rounded,
                    child: TextFormField(
                      initialValue: dayCountSchedule["noOfCycles"] ?? "1",
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp('[^0-9]')),
                        LengthLimitingTextInputFormatter(2),
                      ],
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      onChanged: (val) => irrigationProgramProvider.updateDayCountSchedule(property: "noOfCycles", newValue: val),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayCountField({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, size: 16, color: const Color(0xFF64748B)),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
