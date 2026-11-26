import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:hex/Constants/properties.dart';
import 'package:hex/modules/IrrigationProgram/repository/irrigation_program_repo.dart';
import 'package:hex/modules/ScheduleView/repository/schedule_view_repo.dart';
import 'package:provider/provider.dart';
import '../../../Constants/constants.dart';
import '../../../services/mqtt_service.dart';
import '../../SystemDefinitions/widgets/custom_snack_bar.dart';
import '../widgets/custom_timeline_widget.dart';
import '../../../flavors.dart';
import '../../../services/http_service.dart';
import '../../../utils/environment.dart';
import '../../IrrigationProgram/view/program_library.dart';
import '../model/status_model.dart';
import '../widgets/custom_outer_cirlce.dart';

class ScheduleViewScreen extends StatefulWidget {
  const ScheduleViewScreen({
    super.key,
    required this.deviceId,
    required this.userId,
    required this.controllerId,
    required this.customerId,
    required this.groupId,
  });

  final String deviceId;
  final int userId, controllerId, customerId, groupId;

  @override
  State<ScheduleViewScreen> createState() => _ScheduleViewScreenState();
}

class _ScheduleViewScreenState extends State<ScheduleViewScreen> {
  DateTime date = DateTime.now();
  final ScheduleViewRepository repository = ScheduleViewRepository(HttpService());
  List<Map<String, dynamic>> configObjects = [];
  bool isToday = false;
  DateTime _focusedDay = DateTime.now();
  DateTime today = DateTime.now();
  List<int> selectedStatusList = [];
  List<StatusInfo> statusList = [];
  Map<String, dynamic> defaultData = {};
  List headUnits = [];
  List selectedHeadUnits = [];
  List programs = [];
  List selectedPrograms = [];
  List<String> sentMessage = [];
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestScheduleData();
  }

  /// Function to request schedule data
  Future<void> _requestScheduleData() async {
    MqttService().schedulePayload = null;
    await _getUserSequencePriority(widget.customerId, widget.controllerId);
    var userData = {
      "userId": widget.customerId,
      "controllerId": widget.controllerId,
      "groupId": widget.groupId,
      "categoryId": widget.groupId
    };
    var getUserConfigMaker = await IrrigationProgramRepository(HttpService()).getUserConfigMaker(userData);
    Map<String, dynamic> response = jsonDecode(getUserConfigMaker.body);
    selectedHeadUnits.clear();
    selectedStatusList.clear();
    selectedPrograms.clear();
    if (mounted) {
      setState(() {
        configObjects = List.from(response['data']['configObject']);

        if (MqttService().schedulePayload != null &&
            MqttService().schedulePayload!.isNotEmpty &&
            !MqttService().schedulePayload![0].containsKey('message')) {
          final headUnitSnoList = MqttService().schedulePayload!
              .map((e) => e['HeadUnit'].toString())
              .toList()
              .toSet();
          final programSnoList = MqttService().schedulePayload!
              .map((e) => e['ProgramS_No'].toString())
              .toList()
              .toSet();
          final statusCodeList = MqttService().schedulePayload!
              .map((e) => e['Status'])
              .toList()
              .toSet();

          statusList = statusCodeList.map((code) => _getStatusInfo(code)).toSet().toList();
          programs = defaultData['program']
              .where((program) => programSnoList.contains(program['sNo'].toString()))
              .toSet()
              .toList();

          headUnits = configObjects
              .where((obj) => headUnitSnoList.contains(obj['sNo'].toString()))
              .map((obj) => {'sNo': obj['sNo'], 'name': obj['name']})
              .toSet()
              .toList();
          if (selectedHeadUnits.isEmpty && headUnits.isNotEmpty) {
            selectedHeadUnits.add(headUnits[0]);
          }
        }
      });
    }
    Map<String, dynamic> data = {
      "2600": {"2601": "${DateFormat('yyyy-MM-dd').format(date)},${DateFormat('yyyy-MM-dd').format(date)}"}
    };
    MqttService().topicToPublishAndItsMessage(
        jsonEncode(data), '${Environment.mqttPublishTopic}/${widget.deviceId}');
  }

  /// Function to get user log data
  Future<void> _getUserSequencePriority(userId, controllerId) async {
    try {
      Map<String, dynamic> userData = {
        "userId": userId,
        "controllerId": controllerId,
        "fromDate": DateFormat('yyyy-MM-dd').format(date),
        "toDate": DateFormat('yyyy-MM-dd').format(date),
        "logType": 'Irrigation',
        "parameters": [
          "S_No", "ScheduleOrder", "ScaleFactor", "SkipFlag", "Status", "ProgramStartStopReason", "ScheduledStartTime",
          "IrrigationMethod", "IrrigationDuration_Quantity", "IrrigationDurationCompleted", "IrrigationQuantityCompleted",
          "Pump", "SequenceData", "HeadUnit", "ProgramS_No", "ZoneS_No", "CentralFilterOnOff", "LocalFilterOnOff", "CentralFilterSite",
          "LocalFilterSite", "CentralFilterSelection", "LocalFilterSelection", "CentralFertOnOff", "LocalFertOnOff", "CentralFertilizerSite",
          "LocalFertilizerSite", "CentralFertChannelSelection", "LocalFertChannelSelection", 'RtcNumber', 'CycleNumber', "Date"
        ]
      };
      var getUserScheduleLog = await repository.getUserIrrigationLog(userData);
      if (getUserScheduleLog.statusCode == 200) {
        final responseJson = getUserScheduleLog.body;
        final convertedJson = jsonDecode(responseJson);
        if (convertedJson["code"] == 200) {
          defaultData = convertedJson['data']['default'];
          MqttService().schedulePayload = Constants.dataConversionForScheduleView(
              convertedJson['data']['log'][0]['irrigation']);
        } else {
          MqttService().schedulePayload = [
            {"message": convertedJson['message']}
          ];
        }
      }
    } catch (e) {
      debugPrint("Error fetching schedule log: $e");
    }
  }

  Future<void> sentToServer(
      String msg, dynamic payLoad, int userId, int controllerId, int customerId) async {
    Map<String, Object> body = {
      "userId": customerId,
      "controllerId": controllerId,
      "messageStatus": msg.isNotEmpty ? msg : 'Just sent without changes',
      "data": payLoad,
      "hardware": payLoad,
      "createUser": userId
    };
    final response =
        await repository.createUserSentAndReceivedMessageManually(body);
    if (response.statusCode != 200) {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLargeScreen = MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Schedule View'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
         leading: Row(
          children: [
            const BackButton(),

          ],
        ),
        actions: [
          Container(
            height: 36,
            margin: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Filter',
                  icon: const Icon(Icons.filter_alt_outlined),
                  onPressed: () => _showStatusListDialog(context),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh_outlined),
                  onPressed: () => _requestScheduleData(),
                ),
                IconButton(
                  tooltip: 'Info',
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => _showInfoDialog(context),
                ),
              ],
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // -------------------------------------------------------------------
          // 1. Compact Top Date Selector Toolbar
          // -------------------------------------------------------------------
          _buildCompactDateSelector(),
          Divider(height: 1, color: colorScheme.outlineVariant),

          // -------------------------------------------------------------------
          // 2. Schedule Workspace (Full Width Stream Content)
          // -------------------------------------------------------------------
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>?>(
              stream: MqttService().schedulePayloadStream,
              initialData: MqttService().schedulePayload,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    (snapshot.data == null)) {
                  return Center(
                      child: CircularProgressIndicator(color: colorScheme.primary));
                }

                if (!snapshot.hasData ||
                    snapshot.data == null ||
                    (snapshot.data is List && snapshot.data!.isEmpty)) {
                  return const Center(child: Text('No schedule data available'));
                }

                final data = snapshot.data!;
                if (data.isNotEmpty && data[0].containsKey('message')) {
                  return Center(
                    child: Text(
                      "${data[0]['message']}",
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  );
                }

                // Derive headUnits and programs dynamically
                if (data.isNotEmpty && headUnits.isEmpty && configObjects.isNotEmpty) {
                  final headUnitSnoList =
                      data.map((e) => e['HeadUnit'].toString()).toSet();
                  final derivedHeadUnits = configObjects
                      .where((obj) => headUnitSnoList.contains(obj['sNo'].toString()))
                      .map((obj) => {'sNo': obj['sNo'], 'name': obj['name']})
                      .toList();

                  if (derivedHeadUnits.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() {
                        headUnits = derivedHeadUnits;
                        if (selectedHeadUnits.isEmpty) {
                          selectedHeadUnits.add(headUnits[0]);
                        }
                      });
                    });
                  }
                }

                if (data.isNotEmpty &&
                    programs.isEmpty &&
                    defaultData.isNotEmpty &&
                    defaultData['program'] != null) {
                  final programSnoList =
                      data.map((e) => e['ProgramS_No'].toString()).toSet();
                  final derivedPrograms = List.from(defaultData['program'])
                      .where((program) =>
                          programSnoList.contains(program['sNo'].toString()))
                      .toList();
                  if (derivedPrograms.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() {
                        programs = derivedPrograms;
                      });
                    });
                  }
                }

                return _buildScheduleWorkspace(data);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () async {
          final convertedList = MqttService().schedulePayload!;
          var listToMqtt = [];
          for (var i = 0; i < convertedList.length; i++) {
            String scheduleMap = ""
                "${convertedList[i]["S_No"]},"
                "${convertedList[i]["ScheduleOrder"]},"
                "${convertedList[i]["ScaleFactor"]},"
                "${convertedList[i]["SkipFlag"]},"
                "${convertedList[i]["Date"]},"
                "${convertedList[i]["HeadUnit"]},"
                "${convertedList[i]["CentralFilterOnOff"]},"
                "${convertedList[i]["LocalFilterOnOff"]},"
                "${convertedList[i]["CentralFilterSelection"]},"
                "${convertedList[i]["LocalFilterSelection"]},"
                "${convertedList[i]["CentralFertOnOff"]},"
                "${convertedList[i]["LocalFertOnOff"]},"
                "${convertedList[i]["CentralFertChannelSelection"]},"
                "${convertedList[i]["LocalFertChannelSelection"]}";
            listToMqtt.add(scheduleMap);
          }
          var dataToHardware = {
            "2700": {"2701": "${listToMqtt.join(";").toString()};"}
          };
          try {
            validatePayloadSent(
                dialogContext: context,
                context: context,
                acknowledgedFunction: () async {
                  try {
                    await sentToServer(
                        sentMessage.join('\n'),
                        dataToHardware,
                        widget.userId,
                        widget.controllerId,
                        widget.customerId);
                    _requestScheduleData();
                  } catch (error) {
                    debugPrint("Error sending payload: $error");
                  }
                },
                payload: dataToHardware,
                payloadCode: "2700",
                deviceId: widget.deviceId);
          } catch (error) {
            ScaffoldMessenger.of(context).showSnackBar(
                CustomSnackBar(message: 'Failed to update because of $error'));
          }
        },
        label: const Text('Send Changes', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.send_rounded),
      ),
    );
  }

  /// Compact Top Date Selector Bar
  Widget _buildCompactDateSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    final isToday = DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Selected Date Picker Trigger Button
            InkWell(
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2020, 1, 1),
                  lastDate: DateTime(2100, 12, 31),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(colorScheme: colorScheme),
                      child: child!,
                    );
                  },
                );
                if (pickedDate != null && pickedDate != date) {
                  setState(() {
                    date = pickedDate;
                    _focusedDay = pickedDate;
                  });
                  _requestScheduleData();
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.primary.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 18,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Selected Date',
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                          ),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy').format(date),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 20,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Previous & Next Day Buttons
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    onPressed: () {
                      setState(() {
                        date = date.subtract(const Duration(days: 1));
                        _focusedDay = date;
                      });
                      _requestScheduleData();
                    },
                    tooltip: 'Previous Day',
                  ),
                  Container(
                    width: 1,
                    height: 20,
                    color: colorScheme.outlineVariant,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    onPressed: () {
                      setState(() {
                        date = date.add(const Duration(days: 1));
                        _focusedDay = date;
                      });
                      _requestScheduleData();
                    },
                    tooltip: 'Next Day',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Today Shortcut Chip
            if (!isToday)
              ActionChip(
                avatar: const Icon(Icons.today_rounded, size: 16),
                label: const Text('Today',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                backgroundColor: colorScheme.surfaceContainerLow,
                side: BorderSide(color: colorScheme.outlineVariant),
                onPressed: () {
                  setState(() {
                    date = DateTime.now();
                    _focusedDay = date;
                  });
                  _requestScheduleData();
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Schedule Overview Counts
  Widget _buildOverviewCounts(List<Map<String, dynamic>> data) {
    final colorScheme = Theme.of(context).colorScheme;

    int total = data.length;
    int completed = 0;
    int running = 0;
    int pending = 0;

    for (var item in data) {
      final code = item['Status'];
      if ([2, 6, 9].contains(code)) {
        completed++;
      } else if ([1, 5].contains(code)) {
        running++;
      } else {
        pending++;
      }
    }

    Widget buildPill(String label, int count, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              '$label: ',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
            Text(
              '$count',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: colorScheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            buildPill('Total', total, colorScheme.primary),
            const SizedBox(width: 8),
            buildPill('Completed', completed, Colors.green),
            const SizedBox(width: 8),
            buildPill('Running', running, Colors.orange),
            const SizedBox(width: 8),
            buildPill('Pending', pending, colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  /// Head Unit Selectable Tabs
  Widget _buildHeadUnitTabs() {
    final colorScheme = Theme.of(context).colorScheme;
    if (headUnits.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Text(
            'Head Unit: ',
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: headUnits.map((hu) {
                  final isSelected = selectedHeadUnits
                      .any((element) => element['sNo'] == hu['sNo']);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(hu['name'] as String? ?? 'Head Unit'),
                      selected: isSelected,
                      selectedColor: colorScheme.primary,
                      backgroundColor: colorScheme.surfaceContainerLow,
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          selectedHeadUnits = [hu];
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Program Selectable Chips
  Widget _buildProgramChips() {
    final colorScheme = Theme.of(context).colorScheme;
    if (programs.isEmpty) return const SizedBox.shrink();

    final isAllSelected = selectedPrograms.isEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Text(
            'Programs: ',
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All Programs'),
                    selected: isAllSelected,
                    selectedColor: colorScheme.primaryContainer,
                    backgroundColor: colorScheme.surfaceContainerLow,
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight:
                          isAllSelected ? FontWeight.bold : FontWeight.w500,
                      color: isAllSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                    onSelected: (_) {
                      setState(() {
                        selectedPrograms.clear();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ...programs.map((prog) {
                    final isSelected =
                        selectedPrograms.any((p) => p['sNo'] == prog['sNo']);

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(prog['name'] as String? ?? 'Program'),
                        selected: isSelected,
                        selectedColor: colorScheme.primaryContainer,
                        backgroundColor: colorScheme.surfaceContainerLow,
                        labelStyle: TextStyle(
                          fontSize: 12.5,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedPrograms.add(prog);
                            } else {
                              selectedPrograms.removeWhere(
                                  (p) => p['sNo'] == prog['sNo']);
                            }
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Full Width Schedule Workspace
  Widget _buildScheduleWorkspace(List<Map<String, dynamic>> data) {
    return Column(
      children: [
        _buildOverviewCounts(data),
        _buildHeadUnitTabs(),
        _buildProgramChips(),
        const SizedBox(height: 8),

        // Timeline and program list
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final bool headUnitMatches = selectedHeadUnits.isNotEmpty
                      ? selectedHeadUnits.any((element) =>
                          element['sNo'].toString() ==
                          data[index]['HeadUnit'].toString())
                      : true;

                  final bool programMatches = selectedPrograms.isNotEmpty
                      ? selectedPrograms.any((element) =>
                          element['sNo'].toString() ==
                          data[index]['ProgramS_No'].toString())
                      : true;

                  final bool statusMatches = selectedStatusList.isNotEmpty
                      ? selectedStatusList.contains(data[index]['Status'])
                      : true;

                  if (!headUnitMatches || !programMatches || !statusMatches) {
                    return const SizedBox.shrink();
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: TimeLine(
                      itemGap: 0,
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      indicators: [
                        _buildTimeLineIndicators(
                            data[index], index, data.length)
                      ],
                      children: [
                        _buildScheduleCard(
                            data[index], index, data.length, constraints)
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Widget for displaying the timeline indicators
  Widget _buildTimeLineIndicators(
      Map<String, dynamic> data, int index, int totalItems) {
    StatusInfo status = _getStatusInfo(data["Status"]);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          painter: CheckmarkPainter(color: status.color),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: status.color,
            ),
            height: 20,
            width: 20,
            child: Icon(status.icon, color: Colors.white, size: 16),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            width: 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: status.color,
            ),
          ),
        )
      ],
    );
  }

  int parseValue(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();

    if (value is String) {
      final trimmedValue = value.trim();
      if (RegExp(r'^\d{1,2}:\d{2}:\d{2}$').hasMatch(trimmedValue)) {
        return durationToSeconds(trimmedValue);
      }
      return double.tryParse(trimmedValue)?.toInt() ?? 0;
    }
    return 0;
  }

  int durationToSeconds(String value) {
    final parts = value.split(':');
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final seconds = int.tryParse(parts[2]) ?? 0;

    return (hours * 3600) + (minutes * 60) + seconds;
  }

  /// Widget for displaying the schedule card
  Widget _buildScheduleCard(Map<String, dynamic> data, int index,
      int totalItems, BoxConstraints constraints) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scheduleItem = data;
    final screenSize = MediaQuery.of(context).size.width;

    final String method = scheduleItem["IrrigationMethod"].toString();
    final String inputValue =
        scheduleItem["IrrigationDuration_Quantity"].toString();
    final String completedValue = method == "1"
        ? scheduleItem["IrrigationDurationCompleted"].toString()
        : scheduleItem["IrrigationQuantityCompleted"].toString();

    final String pumps = scheduleItem['Pump'];
    final String valves = scheduleItem['SequenceData'];
    final String startTime = scheduleItem["ScheduledStartTime"].toString();
    final StatusInfo status = _getStatusInfo(scheduleItem["Status"]);
    final StatusInfo reason =
        _getStatusInfo(scheduleItem["ProgramStartStopReason"]);
    DateTime scheduleDate = DateTime.parse(scheduleItem["Date"]);
    DateTime todayDate = DateTime.now();

    DateTime scheduleDateWithoutTime =
        DateTime(scheduleDate.year, scheduleDate.month, scheduleDate.day);
    DateTime todayWithoutTime =
        DateTime(todayDate.year, todayDate.month, todayDate.day);

    final String time12 = DateFormat("hh:mm:ss")
        .format(DateFormat("HH:mm:ss").parse(startTime));

    final int input = parseValue(inputValue);
    final int completed = parseValue(completedValue);

    final double progressValue = method == "1"
        ? _calculateTimeProgress(inputValue, completedValue)
        : (input > 0 ? completed / input : 0.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                      color: status.color, borderRadius: BorderRadius.circular(5)),
                  height: 5,
                  width: 20,
                  margin: const EdgeInsets.only(right: 10),
                ),
                Text(time12,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: colorScheme.primary)),
              ],
            ),
            if (screenSize <= 700)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text("Reason: ${reason.reason}",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary)),
              ),
          ],
        ),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          surfaceTintColor: colorScheme.surface,
          color: colorScheme.surface,
          elevation: 3,
          child: Padding(
            padding: EdgeInsets.all(screenSize >= 700 ? 12 : 8),
            child: Row(
              children: [
                _buildScheduleOrderCircle('${scheduleItem["ScheduleOrder"]}', theme),
                const SizedBox(width: 12),
                _buildStatusSection(
                    status,
                    _buildProgressIndicator(
                        completedValue, progressValue, theme),
                    scheduleItem),
                const SizedBox(width: 12),
                Expanded(
                    flex: screenSize >= 700 ? 2 : 1,
                    child: _buildDetailsSection(
                        completedValue, inputValue, reason, theme)),
                if (screenSize >= 700) ...[
                  _buildDetailChip("Pumps", _getItemNames(pumps)),
                  _buildDetailChip("Valves", _getItemNames(valves)),
                  _buildDetailChip(
                      "Scale Factor", "${scheduleItem["ScaleFactor"]}"),
                  _buildRtcCycleInfo(scheduleItem, theme),
                ],
                const SizedBox(width: 8),
                _buildIconButton(
                    Icons.edit_note_outlined,
                    (([0, 1, 4, 5].contains(status.code)) ||
                            (scheduleDateWithoutTime.isAfter(todayWithoutTime) ||
                                scheduleDateWithoutTime
                                    .isAtSameMomentAs(todayWithoutTime)))
                        ? () {
                            _textController.text =
                                scheduleItem["ScaleFactor"].toString();
                            _showEditSideSheet(scheduleItem, constraints, index);
                          }
                        : null),
                const SizedBox(width: 8),
                _buildIconButton(
                    scheduleItem["SkipFlag"] == 0
                        ? Icons.skip_next
                        : Icons.undo_sharp,
                    (([0, 1, 4, 5].contains(status.code)) &&
                            (scheduleDateWithoutTime.isAfter(todayWithoutTime) ||
                                scheduleDateWithoutTime
                                    .isAtSameMomentAs(todayWithoutTime)))
                        ? () {
                            setState(() {
                              scheduleItem["SkipFlag"] =
                                  scheduleItem["SkipFlag"] == 0 ? 1 : 0;
                              if (scheduleItem["SkipFlag"] == 1) {
                                if (!sentMessage.contains(
                                    "${scheduleItem["ProgramName"]} - ${scheduleItem["ZoneName"]} is skipped")) {
                                  sentMessage.add(
                                      "${scheduleItem["ProgramName"]} - ${scheduleItem["ZoneName"]} is skipped");
                                }
                              } else {
                                if (!sentMessage.contains(
                                    "${scheduleItem["ProgramName"]} - ${scheduleItem["ZoneName"]} is un skipped")) {
                                  sentMessage.add(
                                      "${scheduleItem["ProgramName"]} - ${scheduleItem["ZoneName"]} is un skipped");
                                }
                              }
                            });
                          }
                        : null),
                if (screenSize < 700)
                  _buildMoreOptions(screenSize, index, scheduleItem),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Helper function to get the names of the pumps and valves
  String _getItemNames(String sNoList) {
    List<String> names = [];
    List<String> sNoItems = sNoList.split('_');

    for (int i = 0; i < sNoItems.length; i++) {
      final double valve = double.tryParse(sNoItems[i]) ?? 0;
      final List<String> valveNames = configObjects
          .where((element) => element['sNo'] == valve)
          .map((element) => element['name'] as String)
          .toList();

      names.addAll(valveNames);
    }

    return names.isNotEmpty ? names.join(', ') : "N/A";
  }

  String _getItemNameSingleString(String sNo) {
    final double? valve = double.tryParse(sNo);
    if (valve == null) return 'N/A';

    for (final element in configObjects) {
      if (element['sNo'] == valve) {
        return element['name'] as String;
      }
    }
    return 'N/A';
  }

  /// Helper function to get the program name
  String _getProgramName(dynamic sNo) {
    if (sNo is String) {
      sNo = int.parse(sNo);
    }
    if (defaultData.containsKey('program') && defaultData['program'] != null) {
      for (int i = 0; i < defaultData['program'].length; i++) {
        if (defaultData['program'][i]['sNo'] == sNo) {
          return defaultData['program'][i]['name'];
        }
      }
    }
    return '';
  }

  /// Helper function to get the zone name
  String _getZoneName(String sNo) {
    if (defaultData.containsKey('sequence') && defaultData['sequence'] != null) {
      for (int i = 0; i < defaultData['sequence'].length; i++) {
        if (defaultData['sequence'][i]['sNo'] == sNo) {
          return defaultData['sequence'][i]['name'];
        }
      }
    }
    return '';
  }

  /// Helper function to build icon buttons
  Widget _buildIconButton(IconData icon, Function()? onPressed) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return GestureDetector(
      onTap: onPressed,
      child: PhysicalModel(
        color: onPressed != null
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerLow,
        shape: BoxShape.circle,
        elevation: 3,
        shadowColor: onPressed != null
            ? colorScheme.primary.withOpacity(0.3)
            : colorScheme.outlineVariant,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: onPressed != null
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: 1),
          ),
          child: Icon(
            icon,
            color: onPressed != null
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
      ),
    );
  }

  /// Helper function to calculate time-based progress
  double _calculateTimeProgress(String input, String completed) {
    List<int> parseTime(String time) =>
        time.split(':').map(int.parse).toList();

    var inputParts = parseTime(input);
    var completedParts = parseTime(completed);

    var inDuration = Duration(
        hours: inputParts[0], minutes: inputParts[1], seconds: inputParts[2]);
    var completedDuration = Duration(
        hours: completedParts[0],
        minutes: completedParts[1],
        seconds: completedParts[2]);

    if (inDuration.inMilliseconds == 0) return 0.0;
    return completedDuration.inMilliseconds / inDuration.inMilliseconds;
  }

  /// Widget for displaying the schedule order inside a circle
  Widget _buildScheduleOrderCircle(String order, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Container(
      height: 30,
      width: 30,
      decoration:
          BoxDecoration(shape: BoxShape.circle, color: colorScheme.primary),
      child: Center(
        child: Text(order, style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold)),
      ),
    );
  }

  /// Widget for displaying status information
  Widget _buildStatusSection(
      StatusInfo status, Widget? childWidget, scheduleItem) {
    return Expanded(
      flex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_getProgramName(scheduleItem['ProgramS_No']),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal)),
          Text(_getZoneName(scheduleItem['ZoneS_No']),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(status.statusString,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal)),
          if (childWidget != null) ...[const SizedBox(height: 5), childWidget]
        ],
      ),
    );
  }

  /// Widget for displaying the progress indicator
  Widget _buildProgressIndicator(
      String completedValue, double progressValue, ThemeData theme) {
    return Tooltip(
      message: completedValue,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 0.3, color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(10),
        ),
        child: LinearProgressIndicator(
          value: progressValue.clamp(0.0, 1.0),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          minHeight: 8,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Widget for displaying details (Completed, Actual, Reason, Pumps, Valves, etc.)
  Widget _buildDetailsSection(
      String completedValue, String inputValue, StatusInfo reason, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Completed: $completedValue",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
        Text("Actual: $inputValue", style: const TextStyle(fontSize: 12)),
        if (MediaQuery.of(context).size.width >= 700)
          Text("Reason: ${reason.reason}",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary)),
      ],
    );
  }

  /// Widget for displaying RTC and Cycle information
  Widget _buildRtcCycleInfo(
      Map<String, dynamic> scheduleItem, ThemeData theme) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: ['Rtc', 'Cycle'].map((label) {
          return RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "${label.toUpperCase()} : ",
                  style: theme.textTheme.bodySmall!
                      .copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                TextSpan(
                  text: '${scheduleItem['${label}Number']}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Widget for "More" options button
  Widget _buildMoreOptions(double screenSize, int index, scheduleItem) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext dialogContext) {
            return Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInfoRow(
                    screenSize,
                    'assets/Images/Svg/objectId_5.svg',
                    _buildDetailChip(
                        "Pumps", _getItemNames(scheduleItem['Pump'])),
                  ),
                  _buildInfoRow(
                    screenSize,
                    'assets/Images/Svg/objectId_13.svg',
                    _buildDetailChip("Valves",
                        _getItemNames(scheduleItem['SequenceData'])),
                  ),
                  _buildInfoRow(
                    screenSize,
                    null,
                    _buildRtcCycleInfo(scheduleItem, Theme.of(context)),
                    iconData: Icons.schedule,
                  ),
                ],
              ),
            );
          },
        );
      },
      child: const Icon(Icons.more_vert),
    );
  }

  Widget _buildInfoRow(double width, String? assetPath, Widget content,
      {IconData? iconData}) {
    return Container(
      width: width - 30,
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: assetPath != null
                ? SvgPicture.asset(assetPath)
                : Icon(iconData, color: Colors.white),
          ),
          const SizedBox(width: 12),
          content,
        ],
      ),
    );
  }

  /// Widget for displaying the detail chip
  Widget _buildDetailChip(String title, String names) {
    return Expanded(
      flex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(names),
          Text(title, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  /// Helper function to get the status information
  StatusInfo _getStatusInfo(dynamic code) {
    if (code is String) {
      code = int.parse(code);
    }
    final Map<int, StatusInfo> statusMap = {
      0: StatusInfo(Colors.grey, "Pending", Icons.pending, "Unknown", code),
      1: StatusInfo(Colors.orange, "Running", Icons.run_circle, "Running As Per Schedule", code),
      2: StatusInfo(Colors.green, "Completed", Icons.done, "Turned On Manually", code),
      3: StatusInfo(Colors.yellow, "Skipped by user", Icons.skip_next, "Started By Condition", code),
      4: StatusInfo(Colors.orangeAccent, "Day schedule pending", Icons.pending_actions, "Turned Off Manually", code),
      5: StatusInfo(const Color(0xFF0D5D9A), "Day schedule running", Icons.run_circle_outlined, "Program Turned Off", code),
      6: StatusInfo(Colors.yellowAccent, "Day schedule completed", Icons.done_all_outlined, "Zone Turned Off", code),
      7: StatusInfo(Colors.red, "Day schedule skipped", Icons.incomplete_circle, "Stopped By Condition", code),
      8: StatusInfo(Colors.redAccent, "Postponed partially to tomorrow", Icons.repartition, "Disabled By Condition", code),
      9: StatusInfo(Colors.green, "Postponed fully to tomorrow", Icons.add_alert_outlined, "Stand Alone Program Started", code),
      10: StatusInfo(Colors.amberAccent, "RTC off time reached", Icons.timer_outlined, "Stand Alone Program Stopped", code),
      11: StatusInfo(Colors.amber, "RTC max time reached", Icons.share_arrival_time_rounded, "Stand Alone Program Stopped After Set Value", code),
      12: StatusInfo(Colors.amber, "Skipped By High Flow", Icons.speed_outlined, "Stand Alone Manual Started", code),
      13: StatusInfo(Colors.amber, "Skipped By Low Flow", Icons.speed_outlined, "Stand Alone Manual Stopped", code),
      14: StatusInfo(Colors.amber, "Skipped By No Flow", Icons.water_drop_outlined, "Stand Alone Manual Stopped After Set Value", code),
      15: StatusInfo(Colors.amber, "Skipped By Global limit", Icons.production_quantity_limits, "StartedByDayCountRtc", code),
      16: StatusInfo(Colors.amber, "Stopped manually", Icons.touch_app_outlined, "Paused By User", code),
      17: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Manually Started Paused By User", code),
      18: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Program Deleted", code),
      19: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Program Ready", code),
      20: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Program Completed", code),
      21: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Resumed By User", code),
      22: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Paused By Condition", code),
      23: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Program Ready And Run By Condition", code),
      24: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Running As Per Schedule And Condition", code),
      25: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Started By Condition Paused By User", code),
      26: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Started By Condition Paused By User", code),
      27: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Resumed ByCondition", code),
      28: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Bypassed Start Condition Manually", code),
      29: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Bypassed Stop ConditionManually", code),
      30: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Continue Manually", code),
      31: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, " - ", code),
      32: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Waiting For Condition", code),
      33: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Started By Condition And Run As Per Schedule", code),
    };

    return statusMap[code] ??
        StatusInfo(Colors.black, "Unknown", Icons.error,
            "Unsupported status code: $code", code);
  }

  /// Helper function to show the status list dialog
  void _showStatusListDialog(BuildContext context) {
    showAdaptiveDialog(
      context: context,
      builder: (BuildContext context) {
        List<int> tempSelectionList = List.from(selectedStatusList);

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter stateSetter) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < statusList.length; i++)
                    CheckboxListTile(
                      title: Text(statusList[i].statusString),
                      value: tempSelectionList.contains(statusList[i].code),
                      onChanged: (newValue) {
                        stateSetter(() {
                          if (tempSelectionList.contains(statusList[i].code)) {
                            tempSelectionList.remove(statusList[i].code);
                          } else {
                            tempSelectionList.add(statusList[i].code);
                          }
                        });
                      },
                    )
                ],
              ),
              actions: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child:
                      const Text("Cancel", style: TextStyle(color: Colors.red)),
                ),
                OutlinedButton(
                  onPressed: () {
                    stateSetter(() {
                      setState(() {
                        selectedStatusList = List.from(tempSelectionList);
                      });
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text("Apply"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Helper function to show the info dialog
  void _showInfoDialog(BuildContext context) {
    showAdaptiveDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Color indications',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          content: SizedBox(
            height: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 12; i++)
                    Container(
                      margin:
                          const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _getStatusInfo(i).color,
                            radius: 10,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Text(
                            i != 12
                                ? _getStatusInfo(i).statusString
                                : "Auto skipped",
                            style: const TextStyle(fontWeight: FontWeight.w400),
                          )
                        ],
                      ),
                    )
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showEditSideSheet(
    dynamic scheduleItem,
    BoxConstraints constraints,
    int index,
  ) {
    String getStringValue(dynamic value) {
      if (value == null) {
        return "";
      }
      return value.toString().trim();
    }

    final String centralFertilizerSiteName = getStringValue(
      scheduleItem["CentralFertilizerSiteName"],
    ).isNotEmpty
        ? getStringValue(
            scheduleItem["CentralFertilizerSiteName"],
          )
        : getStringValue(
            scheduleItem["CentralFertilizerSite"],
          );

    final String localFertilizerSiteName = getStringValue(
      scheduleItem["LocalFertilizerSiteName"],
    ).isNotEmpty
        ? getStringValue(
            scheduleItem["LocalFertilizerSiteName"],
          )
        : getStringValue(
            scheduleItem["LocalFertilizerSite"],
          );

    final String centralFertChannelSelection = getStringValue(
      scheduleItem["CentralFertChannelSelection"],
    );

    final String localFertChannelSelection = getStringValue(
      scheduleItem["LocalFertChannelSelection"],
    );

    showGeneralDialog(
      barrierLabel: "Side sheet",
      barrierDismissible: true,
      transitionDuration: const Duration(
        milliseconds: 300,
      ),
      context: context,
      pageBuilder: (
        context,
        animation1,
        animation2,
      ) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 15,
            color: Colors.transparent,
            child: StatefulBuilder(
              builder: (
                BuildContext context,
                StateSetter stateSetter,
              ) {
                return Container(
                  padding: const EdgeInsets.all(15),
                  height: double.infinity,
                  width: constraints.maxWidth < 600
                      ? constraints.maxWidth * 0.7
                      : constraints.maxWidth * 0.2,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Scale Factor",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: TextFormField(
                                initialValue: scheduleItem["ScaleFactor"]
                                        ?.toString() ??
                                    "0",
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                decoration: const InputDecoration(
                                  suffixText: "%",
                                ),
                                onChanged: (
                                  String newValue,
                                ) {
                                  stateSetter(() {
                                    if (newValue.trim().isNotEmpty) {
                                      scheduleItem["ScaleFactor"] =
                                          newValue.trim();
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        Divider(
                          thickness: 0.3,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        if (centralFertilizerSiteName.isNotEmpty)
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _getItemNameSingleString(
                                          centralFertilizerSiteName),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value:
                                        scheduleItem["CentralFertOnOff"] == 1,
                                    onChanged: (
                                      bool value,
                                    ) {
                                      stateSetter(() {
                                        scheduleItem["CentralFertOnOff"] =
                                            value ? 1 : 0;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              if (scheduleItem["CentralFertOnOff"] == 1 &&
                                  centralFertChannelSelection.isNotEmpty)
                                _buildChannelList(
                                  scheduleItem: scheduleItem,
                                  selectionKey: "CentralFertChannelSelection",
                                  nameKey: "CentralFertChannelName",
                                  stateSetter: stateSetter,
                                ),
                              Divider(
                                thickness: 0.3,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        if (localFertilizerSiteName.isNotEmpty)
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      localFertilizerSiteName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value:
                                        scheduleItem["LocalFertOnOff"] == 1,
                                    onChanged: (
                                      bool value,
                                    ) {
                                      stateSetter(() {
                                        scheduleItem["LocalFertOnOff"] =
                                            value ? 1 : 0;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              if (scheduleItem["LocalFertOnOff"] == 1 &&
                                  localFertChannelSelection.isNotEmpty)
                                _buildChannelList(
                                  scheduleItem: scheduleItem,
                                  selectionKey: "LocalFertChannelSelection",
                                  nameKey: "LocalFertChannelName",
                                  stateSetter: stateSetter,
                                ),
                              Divider(
                                thickness: 0.3,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      transitionBuilder: (
        context,
        animation1,
        animation2,
        child,
      ) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation1,
              curve: Curves.easeOut,
            ),
          ),
          child: child,
        );
      },
    );
  }

  Widget _buildChannelList({
    required dynamic scheduleItem,
    required String selectionKey,
    required String nameKey,
    required StateSetter stateSetter,
  }) {
    final dynamic selectionValue = scheduleItem[selectionKey];
    if (selectionValue == null) return const SizedBox.shrink();

    final String selectionString = selectionValue.toString().trim();
    if (selectionString.isEmpty) return const SizedBox.shrink();

    final dynamic nameValue = scheduleItem[nameKey];
    List<String> channelNames = [];

    if (nameValue != null) {
      if (nameValue is List) {
        channelNames = nameValue
            .map((item) => item?.toString().trim() ?? "")
            .toList();
      } else {
        final String nameString = nameValue.toString().trim();
        if (nameString.isNotEmpty) {
          channelNames = nameString.split('_');
        }
      }
    }

    final List<String> selections = selectionString.split('_');

    if (channelNames.isEmpty) {
      return Column(
        children: List.generate(
          selections.length,
          (channelIndex) {
            final bool isSelected = selections[channelIndex] == "1";

            return CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text("Channel ${channelIndex + 1}"),
              value: isSelected,
              onChanged: (bool? value) {
                stateSetter(() {
                  selections[channelIndex] = value == true ? "1" : "0";
                  scheduleItem[selectionKey] = selections.join('_');
                });
              },
            );
          },
        ),
      );
    }

    return Column(
      children: List.generate(
        channelNames.length,
        (channelIndex) {
          final bool isSelected = channelIndex < selections.length &&
              selections[channelIndex] == "1";

          final String channelName = channelNames[channelIndex].trim().isNotEmpty
              ? channelNames[channelIndex]
              : "Channel ${channelIndex + 1}";

          return CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(channelName, style: const TextStyle(fontSize: 14)),
            value: isSelected,
            onChanged: (bool? value) {
              stateSetter(() {
                while (selections.length <= channelIndex) {
                  selections.add("0");
                }
                selections[channelIndex] = value == true ? "1" : "0";
                scheduleItem[selectionKey] = selections.join('_');
              });
            },
          );
        },
      ),
    );
  }
}
