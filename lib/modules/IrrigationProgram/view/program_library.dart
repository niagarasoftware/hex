import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:hex/services/mqtt_service.dart';
import 'package:hex/utils/Theme/oro_theme.dart';
import 'package:provider/provider.dart';

import '../../../Constants/constants.dart';
import '../../../Widgets/HoursMinutesSeconds.dart';
import '../../../models/customer/site_model.dart';
import '../../../services/http_service.dart';
import '../../../utils/constants.dart';
import '../model/sequence_model.dart';
import '../repository/irrigation_program_repo.dart';
import '../state_management/irrigation_program_provider.dart';
import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../StateManagement/overall_use.dart';
import '../widgets/custom_alert_dialog.dart';
import '../../SystemDefinitions/widgets/custom_snack_bar.dart';
import '../../../utils/environment.dart';
import '../widgets/custom_drop_down_tile.dart';
import '../widgets/progress_dialog_ecogem.dart';
import 'irrigation_program_main.dart';

class ProgramLibraryScreenNew extends StatefulWidget {
  final int userId;
  final int controllerId;
  final int customerId;
  final int groupId;
  final int categoryId;
  final String deviceId;
  final int modelId;
  final String deviceName;
  final String categoryName;
  final void Function(String msg) callbackFunction;
  final List<NodeListModel> nodeList;

  const ProgramLibraryScreenNew({
    super.key,
    required this.userId,
    required this.controllerId,
    required this.deviceId,
    required this.customerId,
    required this.groupId,
    required this.categoryId,
    required this.modelId,
    required this.deviceName,
    required this.categoryName,
    required this.callbackFunction,
    required this.nodeList,
  });

  @override
  State<ProgramLibraryScreenNew> createState() => _ProgramLibraryScreenNewState();
}

class _ProgramLibraryScreenNewState extends State<ProgramLibraryScreenNew> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _programNameFocusNode = FocusNode();
  late IrrigationProgramMainProvider irrigationProgramMainProvider;
  TextEditingController copyController = TextEditingController();
  String tempProgramName = '';
  String controllerReadStatus = "0";
  String controllerReadStatusForDayCount = "0";
  final IrrigationProgramRepository repository = IrrigationProgramRepository(HttpService());
  DayCountRtcModel dayCountRtcModel = DayCountRtcModel.fromJson({});
  ProgramQueueModel programQueueModel = ProgramQueueModel.fromJson({});
  bool isLoading = false;
  int selectedProgramIndex = 0;

  @override
  void initState() {
    irrigationProgramMainProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: false);
    irrigationProgramMainProvider.programLibraryData(widget.customerId, widget.controllerId);
    _searchController.addListener(() {
      setState(() {
        selectedProgramIndex = 0;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _programNameFocusNode.dispose();
    copyController.dispose();
    super.dispose();
  }

  Future<void> getUserDayCountRtc() async {
    try {
      var userData = {
        "userId": widget.customerId,
        "controllerId": widget.controllerId,
      };

      var getUserDayCountRtcResult = await repository.getDayCountRtc(userData);
      if (getUserDayCountRtcResult.statusCode == 200) {
        final responseJson = getUserDayCountRtcResult.body;
        final convertedJson = jsonDecode(responseJson);
        if (convertedJson['data']['dayCountRtc'] != null) {
          setState(() {
            dayCountRtcModel = DayCountRtcModel.fromJson(convertedJson['data']['dayCountRtc']);
            programQueueModel = ProgramQueueModel.fromJson(convertedJson['data']['programQueue']);
          });
        }
      } else {
        log("HTTP Request failed or received an unexpected response.");
        throw Exception("HTTP Request failed or received an unexpected response.");
      }
    } catch (e, stackTrace) {
      log('Error in getUserDayCountRtc : $e');
      log('Stack Trace in getUserDayCountRtc: $stackTrace');
    }
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return "P";
    List<String> words = name.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return (words[0][0] + words[1][0]).toUpperCase();
    } else if (words[0].length >= 2) {
      return words[0].substring(0, 2).toUpperCase();
    } else {
      return words[0][0].toUpperCase();
    }
  }

  List<Program> _getFilteredPrograms() {
    if (irrigationProgramMainProvider.programLibrary == null) return [];
    final all = irrigationProgramMainProvider.programLibrary!.program;
    final selectedFilter = irrigationProgramMainProvider.selectedFilterType; // 0: Active, 1: Inactive
    final query = _searchController.text.trim().toLowerCase();

    return all.where((p) {
      if (p.programName.isEmpty) return false;
      final isActive = p.active == "1";
      if (selectedFilter == 0 && !isActive) return false;
      if (selectedFilter == 1 && isActive) return false;

      if (query.isNotEmpty) {
        final name = (p.programName.isNotEmpty ? p.programName : p.defaultProgramName).toLowerCase();
        return name.contains(query);
      }
      return true;
    }).toList();
  }

  int _getActiveCount() {
    if (irrigationProgramMainProvider.programLibrary == null) return 0;
    return irrigationProgramMainProvider.programLibrary!.program
        .where((p) => p.programName.isNotEmpty && p.active == "1")
        .length;
  }

  int _getInactiveCount() {
    if (irrigationProgramMainProvider.programLibrary == null) return 0;
    return irrigationProgramMainProvider.programLibrary!.program
        .where((p) => p.programName.isNotEmpty && p.active == "0")
        .length;
  }

  @override
  Widget build(BuildContext context) {
    irrigationProgramMainProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: true);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: primaryBackground,
      appBar: AppBar(
        backgroundColor: primaryBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            InkWell(
              onTap: () {
                widget.callbackFunction('Program created');
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(Icons.arrow_back, size: 20, color: Color(0xFF1E293B)),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Program Library',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
                Text(
                  'Manage irrigation Planning Methods, manual cycles and zone assignments',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (AppConstants.ecoGemAndPlusModelList.contains(widget.modelId))
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: OutlinedButton(
                onPressed: () async {
                  await getUserDayCountRtc();
                  showIrrigationSettings(context);
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryPurple),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: Text("Day count RTC", style: TextStyle(color: primaryPurple, fontWeight: FontWeight.w600)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FilledButton.icon(
              onPressed: () {
                if (AppConstants.ecoGemAndPlusModelList.contains(widget.modelId)) {
                  irrigationProgramMainProvider.programLibrary!.programLimit = 4;
                }
                createProgram(context, irrigationProgramMainProvider);
              },
              style: FilledButton.styleFrom(
                backgroundColor: primaryPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: const Text(
                "Create Program",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: irrigationProgramMainProvider.programLibrary != null
          ? RefreshIndicator(
              onRefresh: () => irrigationProgramMainProvider.programLibraryData(widget.customerId, widget.controllerId),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final filteredList = _getFilteredPrograms();
                  final isWide = constraints.maxWidth >= 850;

                  if (selectedProgramIndex >= filteredList.length) {
                    selectedProgramIndex = 0;
                  }
                  final selectedProgram = filteredList.isNotEmpty ? filteredList[selectedProgramIndex] : null;

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Master List Panel
                              SizedBox(
                                width: 340,
                                child: _buildMasterListPanel(filteredList),
                              ),
                              const SizedBox(width: 16),
                              // Right Program Detail Panel
                              Expanded(
                                child: _buildDetailPanel(selectedProgram),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Expanded(
                                flex: 4,
                                child: _buildMasterListPanel(filteredList),
                              ),
                              const SizedBox(height: 12),
                              if (selectedProgram != null)
                                Expanded(
                                  flex: 5,
                                  child: _buildDetailPanel(selectedProgram),
                                ),
                            ],
                          ),
                  );
                },
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildMasterListPanel(List<Program> filteredList) {
    final activeCount = _getActiveCount();
    final inactiveCount = _getInactiveCount();

    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        children: [
          // Filter Tabs (Active vs Inactive)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: primaryBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      irrigationProgramMainProvider.updateSelectedFilterType(0);
                      setState(() {
                        selectedProgramIndex = 0;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: irrigationProgramMainProvider.selectedFilterType == 0
                            ? activeBgLavender
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: irrigationProgramMainProvider.selectedFilterType == 0
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: irrigationProgramMainProvider.selectedFilterType == 0
                                  ? primaryPurple
                                  : textMuted,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: irrigationProgramMainProvider.selectedFilterType == 0
                                  ? primaryPurple.withOpacity(0.15)
                                  : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$activeCount',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: irrigationProgramMainProvider.selectedFilterType == 0
                                    ? primaryPurple
                                    : textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      irrigationProgramMainProvider.updateSelectedFilterType(1);
                      setState(() {
                        selectedProgramIndex = 0;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: irrigationProgramMainProvider.selectedFilterType == 1
                            ? activeBgLavender
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Inactive',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: irrigationProgramMainProvider.selectedFilterType == 1
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: irrigationProgramMainProvider.selectedFilterType == 1
                                  ? primaryPurple
                                  : textMuted,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: irrigationProgramMainProvider.selectedFilterType == 1
                                  ? primaryPurple.withOpacity(0.15)
                                  : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$inactiveCount',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: irrigationProgramMainProvider.selectedFilterType == 1
                                    ? primaryPurple
                                    : textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Search box
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Search programs',
                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Programs List
          Expanded(
            child: filteredList.isEmpty
                ? const Center(
                    child: Text(
                      "No programs found",
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final program = filteredList[idx];
                      final isSelected = selectedProgramIndex == idx;
                      final name = program.programName.isNotEmpty ? program.programName : program.defaultProgramName;
                      final initials = _getInitials(name);
                      final zoneCount = program.sequence.length;
                      final subtitleText = program.schedule['selected'] != null && program.schedule['selected'].toString().isNotEmpty
                          ? program.schedule['selected'].toString()
                          : "Manual start";

                      return InkWell(
                        onTap: () {
                          if (selectedProgramIndex == idx) {
                            navigateToIrrigationProgram(program);
                          } else {
                            setState(() {
                              selectedProgramIndex = idx;
                            });
                          }
                        },
                        onDoubleTap: () => navigateToIrrigationProgram(program),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected ? activeBgLavender : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? primaryPurple : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isSelected ? primaryPurple.withOpacity(0.2) : const Color(0xFFD1FAE5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isSelected ? primaryPurple : avatarGreen,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isSelected ? const Color(0xFF1E1B4B) : const Color(0xFF1E293B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      subtitleText,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '$zoneCount zone${zoneCount > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_forward_ios, size: 14),
                                    color: isSelected ? primaryPurple : const Color(0xFF94A3B8),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: "Configure program steps",
                                    onPressed: () => navigateToIrrigationProgram(program),
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
        ],
      ),
    );
  }

  String _formatZoneName(dynamic seqItem, int programSerialNumber, int index) {
    if (seqItem == null || seqItem is! Map) {
      return 'Sequence $programSerialNumber.${index + 1}';
    }

    final rawName = seqItem['name']?.toString().trim() ?? '';
    if (rawName.isEmpty) {
      return 'Sequence $programSerialNumber.${index + 1}';
    }

    final defaultSeqPattern = RegExp(r'^Sequence\s+\d+(\.\d+)?$', caseSensitive: false);
    if (defaultSeqPattern.hasMatch(rawName)) {
      return 'Sequence $programSerialNumber.${index + 1}';
    }

    return rawName;
  }

  Widget buildRtcWidget({required String title, required String dataString}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(color: Color(0xFF5B21B6), fontSize: 12, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 2),
          Text(
            dataString,
            style: const TextStyle(fontSize: 14, overflow: TextOverflow.ellipsis, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanningMethodCard(Program programItem) {
    final scheduleByDays = programItem.schedule['selected'] == irrigationProgramMainProvider.scheduleTypes[1];
    final scheduleAsRunList = programItem.schedule['selected'] == irrigationProgramMainProvider.scheduleTypes[2];

    final startDate = scheduleByDays
        ? (programItem.schedule['scheduleAsRunList']?['schedule']?['startDate'] ?? programItem.schedule['scheduleByDays']?['schedule']?['startDate'] ?? DateTime.now().toString())
        : scheduleAsRunList
        ? (programItem.schedule['scheduleByDays']?['schedule']?['startDate'] ?? programItem.schedule['scheduleAsRunList']?['schedule']?['startDate'] ?? DateTime.now().toString())
        : DateTime.now().toString();

    final endDate = scheduleByDays
        ? (programItem.schedule['scheduleAsRunList']?['schedule']?['endDate'] ?? programItem.schedule['scheduleByDays']?['schedule']?['endDate'] ?? DateTime.now().toString())
        : scheduleAsRunList
        ? (programItem.schedule['scheduleByDays']?['schedule']?['endDate'] ?? programItem.schedule['scheduleAsRunList']?['schedule']?['endDate'] ?? DateTime.now().toString())
        : DateTime.now().toString();

    final isForceToEndDate = scheduleByDays
        ? (programItem.schedule['scheduleAsRunList']?['schedule']?['isForceToEndDate'] ?? false)
        : scheduleAsRunList
        ? (programItem.schedule['scheduleByDays']?['schedule']?['isForceToEndDate'] ?? false)
        : false;

    final rtcType = scheduleByDays
        ? (programItem.schedule['scheduleAsRunList']?['rtc'] ?? programItem.schedule['scheduleByDays']?['rtc'] ?? {})
        : scheduleAsRunList
        ? (programItem.schedule['scheduleByDays']?['rtc'] ?? programItem.schedule['scheduleAsRunList']?['rtc'] ?? {})
        : {};

    int pageCount = (rtcType is Map) ? rtcType.length : (rtcType is List) ? rtcType.length : 0;
    final isScheduled = (scheduleByDays || scheduleAsRunList) && pageCount > 0;

    String startDateOnly = "Manual start";
    String endDateOnly = "No end date";
    try {
      startDateOnly = DateFormat('MMM d').format(DateTime.parse(startDate));
      endDateOnly = DateFormat('MMM d').format(DateTime.parse(endDate));
    } catch (_) {}

    String getWeekday(int weekday) {
      const daysInWeek = 7;
      List<String> weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
      int adjustedWeekday = (weekday - 1 + daysInWeek) % daysInWeek;
      return weekdays[adjustedWeekday];
    }

    List<String> days = List.generate(
      scheduleByDays
          ? int.parse(programItem.schedule['scheduleAsRunList']?['schedule']?['noOfDays']?.toString().isNotEmpty == true ? programItem.schedule['scheduleAsRunList']['schedule']['noOfDays'].toString() : "1")
          : scheduleAsRunList
          ? int.parse(programItem.schedule['scheduleByDays']?['schedule']?['runDays']?.toString().isNotEmpty == true ? programItem.schedule['scheduleByDays']['schedule']['runDays'].toString() : '0') + int.parse(programItem.schedule['scheduleByDays']?['schedule']?['skipDays']?.toString() ?? '0')
          : 0,
      (index) {
        DateTime currentDate = DateTime.tryParse(startDate)?.add(Duration(days: index)) ?? DateTime.now();
        return getWeekday(currentDate.weekday);
      },
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (scheduleByDays || scheduleAsRunList)
                ? "$startDateOnly - ${(isForceToEndDate ?? false) ? endDateOnly : "No end date"}"
                : "Manual start",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                programItem.programName.isNotEmpty
                    ? (programItem.schedule['selected']?.toString().isNotEmpty == true
                        ? (programItem.schedule['selected'].toString().toLowerCase().substring(0, 1).toUpperCase() +
                            programItem.schedule['selected'].toString().toLowerCase().substring(1))
                        : "No schedule")
                    : "Inactive program",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                scheduleByDays
                    ? "${programItem.schedule['scheduleAsRunList']?['schedule']?['noOfDays']?.toString() == "" ? '1' : (programItem.schedule['scheduleAsRunList']?['schedule']?['noOfDays']?.toString() ?? '1')} day cycle"
                    : scheduleAsRunList
                    ? "Run days - ${programItem.schedule['scheduleByDays']?['schedule']?['runDays']?.toString() ?? '1'} \nSkip days - ${programItem.schedule['scheduleByDays']?['schedule']?['skipDays']?.toString() ?? '0'}"
                    : "-",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              )
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (scheduleByDays)
                for (var index = 0; index < days.length; index++)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      days[index],
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryPurple),
                    ),
                  )
              else if (scheduleAsRunList)
                for (var index = 0; index < days.length; index++)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: index >= int.parse(programItem.schedule['scheduleByDays']?['schedule']?['runDays']?.toString().isNotEmpty == true
                          ? programItem.schedule['scheduleByDays']['schedule']['runDays'].toString() : "0")
                          ? const Color(0xFFFFEFE1)
                          : const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      days[index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: index >= int.parse(programItem.schedule['scheduleByDays']?['schedule']?['runDays']?.toString().isNotEmpty == true
                            ? programItem.schedule['scheduleByDays']['schedule']['runDays'].toString() : "0")
                            ? const Color(0xFFC2410C)
                            : primaryPurple,
                      ),
                    ),
                  )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "NOT SCHEDULED",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                  ),
                )
            ],
          ),
          const SizedBox(height: 14),
          if (isScheduled && pageCount > 0)
            Column(
              children: [
                for (var index = 0; index < pageCount; index++)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        buildRtcWidget(title: "RTC No", dataString: '${index + 1}'),
                        const SizedBox(width: 10),
                        buildRtcWidget(
                          title: "Start time",
                          dataString: (rtcType is Map && rtcType['rtc${index + 1}'] != null)
                              ? rtcType['rtc${index + 1}']['onTime']?.toString() ?? '00:00:00'
                              : (rtcType is List && index < rtcType.length)
                              ? rtcType[index]['onTime']?.toString() ?? '00:00:00'
                              : '00:00:00',
                        ),
                        const SizedBox(width: 10),
                        buildRtcWidget(
                          title: "Cycle Interval",
                          dataString: (rtcType is Map && rtcType['rtc${index + 1}'] != null)
                              ? rtcType['rtc${index + 1}']['interval']?.toString() ?? '00:00:00'
                              : (rtcType is List && index < rtcType.length)
                              ? rtcType[index]['interval']?.toString() ?? '00:00:00'
                              : '00:00:00',
                        ),
                        const SizedBox(width: 10),
                        buildRtcWidget(
                          title: "Cycles",
                          dataString: (rtcType is Map && rtcType['rtc${index + 1}'] != null)
                              ? rtcType['rtc${index + 1}']['noOfCycles']?.toString() ?? '1'
                              : (rtcType is List && index < rtcType.length)
                              ? rtcType[index]['noOfCycles']?.toString() ?? '1'
                              : '1',
                        ),
                        const SizedBox(width: 10),
                        if ((rtcType is Map && rtcType['rtc${index + 1}'] != null && rtcType['rtc${index + 1}']['stopMethod'] == irrigationProgramMainProvider.stopMethods[1]) ||
                            (rtcType is List && index < rtcType.length && rtcType[index]['stopMethod'] == irrigationProgramMainProvider.stopMethods[1]))
                          buildRtcWidget(
                            title: "Off time",
                            dataString: (rtcType is Map && rtcType['rtc${index + 1}'] != null)
                                ? rtcType['rtc${index + 1}']['offTime']?.toString() ?? '-'
                                : rtcType[index]['offTime']?.toString() ?? '-',
                          )
                        else if ((rtcType is Map && rtcType['rtc${index + 1}'] != null && rtcType['rtc${index + 1}']['stopMethod'] == irrigationProgramMainProvider.stopMethods[2]) ||
                            (rtcType is List && index < rtcType.length && rtcType[index]['stopMethod'] == irrigationProgramMainProvider.stopMethods[2]))
                          buildRtcWidget(
                            title: "Max time",
                            dataString: (rtcType is Map && rtcType['rtc${index + 1}'] != null)
                                ? rtcType['rtc${index + 1}']['maxTime']?.toString() ?? '-'
                                : rtcType[index]['maxTime']?.toString() ?? '-',
                          )
                        else
                          buildRtcWidget(
                            title: "Off time",
                            dataString: (rtcType is Map && rtcType['rtc${index + 1}'] != null && rtcType['rtc${index + 1}']['offTime'] != null && rtcType['rtc${index + 1}']['offTime'].toString().isNotEmpty)
                                ? rtcType['rtc${index + 1}']['offTime'].toString()
                                : (rtcType is List && index < rtcType.length && rtcType[index]['offTime'] != null)
                                ? rtcType[index]['offTime'].toString()
                                : '-',
                          ),
                      ],
                    ),
                  ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                "RTC not available for this method",
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel(Program? program) {
    if (program == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assignment_outlined, size: 48, color: Color(0xFF94A3B8)),
              SizedBox(height: 12),
              Text(
                "Select a program to view details",
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    final name = program.programName.isNotEmpty ? program.programName : program.defaultProgramName;
    final zoneCount = program.sequence.length;

    final scheduleByDays = program.schedule['selected'] == irrigationProgramMainProvider.scheduleTypes[1];
    final scheduleAsRunList = program.schedule['selected'] == irrigationProgramMainProvider.scheduleTypes[2];

    final isManual = !scheduleByDays && !scheduleAsRunList;

    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title & Action Buttons
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => navigateToIrrigationProgram(program),
                  borderRadius: BorderRadius.circular(8),
                  child: Tooltip(
                    message: "Click to open program steps editor",
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.edit_note, color: primaryPurple, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  // Configure Program Steps Button
                  OutlinedButton.icon(
                    onPressed: () => navigateToIrrigationProgram(program),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryPurple, width: 1.5),
                      backgroundColor: activeBgLavender,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    icon: Icon(Icons.tune, size: 16, color: primaryPurple),
                    label: Text(
                      "Configure Steps",
                      style: TextStyle(color: primaryPurple, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Primary Action Button (Run Now / Activate)
                  FilledButton.icon(
                    onPressed: () async {
                      if (program.active == "1") {
                        var dataToMqtt = program.hardwareData;
                        try {
                          if (AppConstants.ecoGemAndPlusModelList.contains(widget.modelId)) {
                            final result = await showDialog<String>(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return EcoGemProgressDialog(
                                  payloads: List<String>.from(dataToMqtt),
                                  deviceId: widget.deviceId,
                                  mqttService: MqttService(),
                                );
                              },
                            );

                            if (result != null) {
                              setState(() {
                                controllerReadStatus = result;
                              });
                            }
                          } else {
                            await validatePayloadSent(
                              dialogContext: context,
                              context: context,
                              acknowledgedFunction: () {
                                setState(() {
                                  controllerReadStatus = "1";
                                });
                              },
                              payload: dataToMqtt,
                              payloadCode: "2500",
                              deviceId: widget.deviceId,
                            ).whenComplete(() async {
                              if (MqttService().acknowledgementPayload!['cM']['4201']['Code'] != "200") {
                                setState(() {
                                  controllerReadStatus = "0";
                                });
                              }
                            });
                          }
                          await saveProgramDetails(program, dataToMqtt);
                          await Future.delayed(const Duration(seconds: 1), () async {
                            await irrigationProgramMainProvider.programLibraryData(widget.customerId, widget.controllerId);
                          });
                        } catch (error) {
                          showSnackBar(message: 'Failed to update because of $error', context: context);
                        }
                      } else {
                        showConfirmationDialog(program, "active");
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    icon: Icon(
                      program.active == "1" ? Icons.play_arrow : Icons.check_circle_outline,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      program.active == "1" ? "Run now" : "Activate",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Edit Button
                  OutlinedButton(
                    onPressed: () {
                      final programList = irrigationProgramMainProvider.programLibrary!.program;
                      showEditItemDialog(program, selectedProgramIndex, programList);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    child: const Text("Edit", style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  if (program.active == "1") ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        showConfirmationDialog(program, "inactive");
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFEE2E2)),
                        backgroundColor: const Color(0xFFFEF2F2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      icon: const Icon(Icons.block, size: 16, color: Color(0xFFDC2626)),
                      label: const Text("Deactivate", style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ],
                  const SizedBox(width: 8),
                  // Copy Button
                  OutlinedButton(
                    onPressed: () {
                      tempProgramName = "";
                      copyController.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: copyController.text.length,
                      );
                      final serialNumber = irrigationProgramMainProvider.programLibrary!.program.any((element) => element.programName.isEmpty)
                          ? irrigationProgramMainProvider.programLibrary!.program.firstWhere((element) => element.programName.isEmpty).serialNumber
                          : irrigationProgramMainProvider.programLibrary!.program.length + 1;
                      final programType = program.programType;
                      String defaultProgramName = "Program $serialNumber";
                      copyController.text = defaultProgramName;
                      programCopy(
                        program: program,
                        serialNumber: serialNumber,
                        programType: programType,
                        programName: defaultProgramName,
                        defaultProgramName: defaultProgramName,
                        programLibraryData: irrigationProgramMainProvider.programLibrary!.program,
                        context: context,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    child: const Text("Copy", style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  // Delete Button
                  OutlinedButton(
                    onPressed: () {
                      showConfirmationDialog(program, "delete");
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFEE2E2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    child: const Text("Delete", style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Badges Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  program.active == "0"
                      ? "INACTIVE"
                      : isManual
                          ? "MANUAL START"
                          : program.schedule['selected'].toString().toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#PRG-${program.serialNumber.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Subtitle description text
          Text(
            program.active == "0"
                ? "This program is paused and will not start until activated."
                : isManual
                    ? "Manual program execution. Runs on request."
                    : "Scheduled irrigation program strategy.",
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),

          // Planning Method Section
          const Text(
            "PLANNING METHOD",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          _buildPlanningMethodCard(program),
          const SizedBox(height: 24),

          // Zones Section
          Text(
            "ZONES ($zoneCount)",
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: zoneCount == 0
                ? [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Text(
                        "No zones assigned",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                      ),
                    )
                  ]
                : List.generate(zoneCount, (index) {
                    final seq = program.sequence[index];
                    final zoneName = _formatZoneName(seq, program.serialNumber, index);
                    final valves = (seq is Map && seq['valve'] is List) ? seq['valve'] as List : [];
                    final valveCount = valves.length;
                    final valveNames = valves
                        .map((v) => (v is Map) ? (v['name'] ?? v['valveName'] ?? '').toString() : '')
                        .where((n) => n.isNotEmpty)
                        .join(', ');

                    final label = valveCount > 0 ? '$zoneName ($valveCount valve${valveCount > 1 ? 's' : ''})' : zoneName;

                    return Tooltip(
                      message: valveNames.isNotEmpty ? 'Valves: $valveNames' : zoneName,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                        ),
                      ),
                    );
                  }),
          ),

          const Spacer(),
          const Divider(color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),
          // Footer bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                program.active == "1" ? "Manual execution only" : "Inactive",
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              Text(
                "ID: #PRG-${program.serialNumber.toString().padLeft(2, '0')}",
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void showIrrigationSettings(BuildContext parentContext) {
    final theme = Theme.of(parentContext);
    final initialDayCountSnapshot = dayCountRtcModel.toJson();
    final initialQueueSnapshot = programQueueModel.toJson();

    showModalBottomSheet(
      context: parentContext,
      showDragHandle: true,
      isScrollControlled: false,
      scrollControlDisabledMaxHeightRatio: 0.7,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          Widget timePickerTile({
            required String title,
            required String currentTime,
            required VoidCallback onTap,
          }) {
            return ListTile(
              title: Text(title),
              trailing: Text(Constants.showHourAndMinuteOnly(currentTime, widget.modelId)),
              leading: Icon(Icons.access_time, color: theme.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              onTap: onTap,
            );
          }

          void showTimePicker(String initialTime, Function(String) onSelected) {
            showDialog(
              context: context,
              builder: (_) {
                final overAllPvd = context.read<OverAllUse>();
                return AlertDialog(
                  title: HoursMinutesSeconds(
                    initialTime: initialTime,
                    modelId: widget.modelId,
                    onPressed: () {
                      final time = '${overAllPvd.hrs.toString().padLeft(2, '0')}:'
                          '${overAllPvd.min.toString().padLeft(2, '0')}:'
                          '${overAllPvd.sec.toString().padLeft(2, '0')}';
                      onSelected(time);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Day Count RTC', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Enable Day Count RTC'),
                  value: dayCountRtcModel.dayCountRtc,
                  activeColor: theme.primaryColor,
                  onChanged: (v) => setState(() => dayCountRtcModel.dayCountRtc = v),
                ),
                if (dayCountRtcModel.dayCountRtc) ...[
                  const SizedBox(height: 16),
                  timePickerTile(
                    title: 'RTC Time',
                    currentTime: dayCountRtcModel.dayCountRtcTime,
                    onTap: () => showTimePicker(dayCountRtcModel.dayCountRtcTime, (t) => setState(() => dayCountRtcModel.dayCountRtcTime = t)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('Program runs daily at this time!', style: TextStyle(color: Colors.grey[600])),
                  ),
                ],
                const SizedBox(height: 20),
                if (AppConstants.ecoGemAndPlusModelList.contains(widget.modelId)) ...[
                  const Divider(),
                  Text('Program Queue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Program Queue'),
                    value: programQueueModel.programQueue,
                    activeTrackColor: theme.primaryColor,
                    onChanged: (v) => setState(() => programQueueModel.programQueue = v),
                  ),
                  if (programQueueModel.programQueue) ...[
                    SwitchListTile(
                      title: const Text('Enable Queue Restart'),
                      value: programQueueModel.autoQueueRestart,
                      activeColor: theme.primaryColor,
                      onChanged: (v) => setState(() => programQueueModel.autoQueueRestart = v),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(4, (index) {
                      return Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            title: DropdownButtonFormField<String>(
                              value: programQueueModel.queueOrder[index] != '0' ? programQueueModel.queueOrder[index] : '0',
                              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                              items: [
                                const DropdownMenuItem(value: '0', child: Text('None')),
                                ...irrigationProgramMainProvider.programLibrary!.program.map(
                                  (p) => DropdownMenuItem(value: p.serialNumber.toString(), child: Text(p.programName)),
                                ),
                              ],
                              onChanged: (v) => setState(() => programQueueModel.queueOrder[index] = v ?? '0'),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          if (programQueueModel.autoQueueRestart)
                            timePickerTile(
                              title: 'Delay ${index + 1}→${index == 3 ? 1 : index + 2}',
                              currentTime: programQueueModel.queueOrderRestartTimes[index],
                              onTap: () => showTimePicker(
                                programQueueModel.queueOrderRestartTimes[index],
                                (t) => setState(() => programQueueModel.queueOrderRestartTimes[index] = t),
                              ),
                            ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }),
                    const Text('Queue Preview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Order: ${programQueueModel.queueOrder.map((s) => s == '0' ? "None" : irrigationProgramMainProvider.programLibrary!.program.firstWhere((p) => p.serialNumber.toString() == s).programName).join(" → ")}'
                        '${programQueueModel.autoQueueRestart ? " (restarts)" : ""}'
                        '${programQueueModel.skipDays ? ", skips every ${programQueueModel.noOfSkipDays} days" : ""}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
                Text('Skip Days', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Enable Skip Days'),
                  value: programQueueModel.skipDays,
                  activeColor: theme.primaryColor,
                  onChanged: (v) => setState(() => programQueueModel.skipDays = v),
                ),
                if (programQueueModel.skipDays) ...[
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text('Number of Skip Days'),
                    subtitle: Text('${programQueueModel.noOfSkipDays} days'),
                    leading: Icon(Icons.calendar_today, color: theme.primaryColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey[300]!)),
                    onTap: () async {
                      final days = await showDialog<int>(
                        context: context,
                        builder: (_) => NumberPickerDialog(
                          initialValue: int.tryParse(programQueueModel.noOfSkipDays) ?? 1,
                          minValue: 1,
                          maxValue: 30,
                        ),
                      );
                      if (days != null) setState(() => programQueueModel.noOfSkipDays = days.toString());
                    },
                  ),
                ],
                const SizedBox(height: 20),
                Text('Drip Standalone', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                SwitchListTile(
                  title: const Text('Drip Standalone Mode'),
                  value: programQueueModel.dripStandaloneMode,
                  activeColor: theme.primaryColor,
                  onChanged: (v) => setState(() => programQueueModel.dripStandaloneMode = v),
                ),
                const Divider(height: 40),
                Text('Agitator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                SwitchListTile(
                  title: const Text('Agitator ON/OFF'),
                  value: programQueueModel.agitatorOnOff,
                  activeTrackColor: theme.primaryColor,
                  onChanged: (v) => setState(() => programQueueModel.agitatorOnOff = v),
                ),
                if (programQueueModel.agitatorOnOff) ...[
                  const SizedBox(height: 16),
                  timePickerTile(
                    title: 'Agitator RTC ON Time',
                    currentTime: programQueueModel.agitatorRTCOnTime,
                    onTap: () => showTimePicker(programQueueModel.agitatorRTCOnTime, (t) => setState(() => programQueueModel.agitatorRTCOnTime = t)),
                  ),
                  const SizedBox(height: 16),
                  timePickerTile(
                    title: 'Agitator RTC OFF Time',
                    currentTime: programQueueModel.agitatorRTCOffTime,
                    onTap: () => showTimePicker(programQueueModel.agitatorRTCOffTime, (t) => setState(() => programQueueModel.agitatorRTCOffTime = t)),
                  ),
                  const SizedBox(height: 16),
                  timePickerTile(
                    title: 'Agitator Cyclic ON Time',
                    currentTime: programQueueModel.agitatorCycONTime,
                    onTap: () => showTimePicker(programQueueModel.agitatorCycONTime, (t) => setState(() => programQueueModel.agitatorCycONTime = t)),
                  ),
                  const SizedBox(height: 16),
                  timePickerTile(
                    title: 'Agitator Cyclic OFF Time',
                    currentTime: programQueueModel.agitatorCycOffTime,
                    onTap: () => showTimePicker(programQueueModel.agitatorCycOffTime, (t) => setState(() => programQueueModel.agitatorCycOffTime = t)),
                  ),
                ],
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final Map<String, dynamic> dayCountRtcToNova = {
                        "7000": {
                          "7001":
                              "${dayCountRtcModel.dayCountRtc ? 1 : 0},${DateFormat.Hm().format(DateTime.parse('2025-01-01 ${dayCountRtcModel.dayCountRtcTime}')).split(':').join(',')}"
                        }
                      };

                      final Map<String, dynamic> programQueueToNova = {
                        "8000": {
                          "8001":
                              "${programQueueModel.programQueue ? 1 : 0},"
                                  "${programQueueModel.queueOrder.join(',')},"
                                  "${programQueueModel.autoQueueRestart ? 1 : 0},"
                                  "${programQueueModel.queueOrderRestartTimes.join(',').replaceAll(':', ',')},"
                                  "${programQueueModel.skipDays ? 1 : 0},"
                                  "${programQueueModel.noOfSkipDays},"
                                  "${programQueueModel.runDays ? 1 : 0},"
                                  "${programQueueModel.noOfRunDays},"
                                  "${0},"
                                  "${programQueueModel.dripStandaloneMode ? 1 : 0},"
                                  "${programQueueModel.agitatorOnOff ? 1 : 0},"
                                  "${programQueueModel.agitatorRTCOnTime.replaceAll(':', ',')},"
                                  "${programQueueModel.agitatorRTCOffTime.replaceAll(':', ',')},"
                                  "${programQueueModel.agitatorCycONTime.replaceAll(':', ',')},"
                                  "${programQueueModel.agitatorCycOffTime.replaceAll(':', ',')}"
                        }
                      };

                      final List<String> payloadList = [
                        if (initialDayCountSnapshot.toString() != dayCountRtcModel.toJson().toString()) jsonEncode(dayCountRtcToNova),
                        if (initialQueueSnapshot.toString() != programQueueModel.toJson().toString()) jsonEncode(programQueueToNova)
                      ];

                      final List<String> payloadList2 = [jsonEncode(dayCountRtcToNova), jsonEncode(programQueueToNova)];

                      final result = await showDialog<String>(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => EcoGemProgressDialog(
                          payloads: payloadList.isEmpty ? payloadList2 : payloadList,
                          deviceId: widget.deviceId,
                          mqttService: MqttService(),
                        ),
                      );

                      if (result != null) setState(() => controllerReadStatus = result);

                      final response = await repository.createDayCountRtc({
                        "userId": widget.customerId,
                        "controllerId": widget.controllerId,
                        "dayCountRtc": {
                          "dayCountRtc": dayCountRtcModel.toJson(),
                          "programQueue": programQueueModel.toJson(),
                        },
                        "createUser": widget.userId,
                        "controllerReadStatus": controllerReadStatusForDayCount,
                      });
                      final message = jsonDecode(response.body)['message'];
                      ScaffoldMessenger.of(context).showSnackBar(CustomSnackBar(message: message));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
                    }

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Submit', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void createProgram(BuildContext context, IrrigationProgramMainProvider programProvider) {
    final programs = programProvider.programLibrary!.program;
    final nonEmptyPrograms = programs.where((element) => element.programName.isNotEmpty).length;
    final programLimit = programProvider.programLibrary!.programLimit;

    if (nonEmptyPrograms >= programLimit) {
      _showLimitExceededDialog(context);
      return;
    }

    final serialNumber = programs.any((element) => element.programName.isEmpty)
        ? programs.firstWhere((element) => element.programName.isEmpty).serialNumber
        : 0;

    Future navigateToIrrigationProgram() => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IrrigationProgram(
              userId: widget.userId,
              controllerId: widget.controllerId,
              serialNumber: serialNumber,
              programType: irrigationProgramMainProvider.selectedProgramType,
              deviceId: widget.deviceId,
              fromDealer: false,
              customerId: widget.customerId,
              groupId: widget.groupId,
              categoryId: widget.categoryId,
              modelId: widget.modelId,
              deviceName: widget.deviceName,
              categoryName: widget.categoryName,
              nodeList: widget.nodeList,
            ),
          ),
        );

    if (programProvider.programLibrary!.defaultProgramTypes.length > 1) {
      showAdaptiveDialog(
        context: context,
        builder: (BuildContext dialogContext) => Consumer<IrrigationProgramMainProvider>(
          builder: (context, provider, child) {
            return AlertDialog(
              title: Text(
                "Select Program type",
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: provider.programLibrary!.defaultProgramTypes
                    .map(
                      (e) => RadioListTile(
                        title: Text(e),
                        value: e,
                        groupValue: provider.selectedProgramType,
                        onChanged: (newValue) => provider.updateProgramName(newValue, 'programType'),
                      ),
                    )
                    .toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    navigateToIrrigationProgram();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        ),
      );
    } else {
      navigateToIrrigationProgram();
    }
  }

  void _showLimitExceededDialog(BuildContext context) {
    showAdaptiveDialog(
      context: context,
      builder: (BuildContext dialogContext) => CustomAlertDialog(
        title: "Alert",
        content: "The program limit is exceeded as defined in the Product limit!",
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void programCopy({
    required BuildContext context,
    required Program program,
    required int serialNumber,
    required String programType,
    required String programName,
    required String defaultProgramName,
    required List<Program> programLibraryData,
  }) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    String tempProgramName = "";

    showAdaptiveDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter stateSetter) {
            return AlertDialog(
              title: const Text("Program copy!"),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: copyController,
                      autofocus: true,
                      onChanged: (newValue) {
                        stateSetter(() {
                          tempProgramName = newValue;
                        });
                      },
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(20),
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Name cannot be empty";
                        }
                        if (programLibraryData.any((element) => element.programName == value)) {
                          return "Name already exists";
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    tempProgramName = "";
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      createCopyOfProgram(
                        oldSerialNumber: program.serialNumber,
                        serialNumber: serialNumber,
                        programName: tempProgramName.isEmpty ? defaultProgramName : tempProgramName,
                        defaultProgramName: defaultProgramName,
                        programType: programType,
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void createCopyOfProgram({
    required int oldSerialNumber,
    required int serialNumber,
    required String programName,
    required String defaultProgramName,
    required String programType,
  }) {
    irrigationProgramMainProvider
        .userProgramCopy(widget.userId, widget.controllerId, oldSerialNumber, serialNumber, programName, defaultProgramName, programType, widget.customerId)
        .then((String message) {
      ScaffoldMessenger.of(context).showSnackBar(CustomSnackBar(message: message));
    }).then((value) => irrigationProgramMainProvider.programLibraryData(widget.customerId, widget.controllerId).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(CustomSnackBar(message: error));
        }));
  }

  void showConfirmationDialog(Program program, String toMove) {
    showAdaptiveDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CustomAlertDialog(
          title: "Confirmation",
          content: 'Are you sure you want to ${toMove == "delete" ? "delete" : toMove == "active" ? "move to active" : "move to inactive"}?',
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                if (toMove == "active" || toMove == "inactive") {
                  var dataToMqtt = program.hardwareData;
                  Map<String, dynamic> deleteProgramToHardware = {
                    "3800": {
                      "3801": "${program.serialNumber};"
                    }
                  };
                  try {
                    Navigator.of(dialogContext).pop();
                    if (AppConstants.ecoGemAndPlusModelList.contains(widget.modelId) && toMove == "active") {
                      final result = await showDialog<String>(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return EcoGemProgressDialog(
                            payloads: List<String>.from(dataToMqtt),
                            deviceId: widget.deviceId,
                            mqttService: MqttService(),
                          );
                        },
                      );

                      if (result != null) {
                        setState(() {
                          controllerReadStatus = result;
                        });
                        deleteProgram(program, toMove);
                      }
                    } else {
                      await validatePayloadSent(
                        dialogContext: context,
                        context: context,
                        acknowledgedFunction: () {
                          setState(() {
                            controllerReadStatus = "1";
                          });
                          deleteProgram(program, toMove);
                        },
                        payload: toMove == "active" ? dataToMqtt : deleteProgramToHardware,
                        payloadCode: toMove == "active" ? "2500" : "3800",
                        deviceId: widget.deviceId,
                      ).whenComplete(() async {
                        if (MqttService().acknowledgementPayload!['cM']['4201']['Code'] != "200") {
                          setState(() {
                            controllerReadStatus = "0";
                          });
                        }
                      });
                    }

                    await Future.delayed(const Duration(seconds: 1), () async {
                      await irrigationProgramMainProvider.programLibraryData(widget.customerId, widget.controllerId);
                    });
                    if (toMove != "inactive") {
                      if (irrigationProgramMainProvider.programLibrary!.program.any((element) => element.programName.isNotEmpty)) {
                        irrigationProgramMainProvider.updateSelectedFilterType(0);
                      }
                    }
                  } catch (error) {
                    showSnackBar(message: 'Failed to update because of $error', context: context);
                  }
                } else {
                  deleteProgram(program, toMove);
                  if (irrigationProgramMainProvider.programLibrary!.program.any((element) => element.programName.isNotEmpty && element.active == "0")) {
                    irrigationProgramMainProvider.updateSelectedFilterType(0);
                  }
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  void deleteProgram(Program program, String active) {
    irrigationProgramMainProvider
        .userProgramReset(widget.userId, widget.controllerId, program.programId, widget.deviceId, program.serialNumber, program.defaultProgramName, program.programName, active, controllerReadStatus, widget.customerId)
        .then((String message) {
      ScaffoldMessenger.of(context).showSnackBar(CustomSnackBar(message: message));
    }).then((value) => irrigationProgramMainProvider.programLibraryData(widget.customerId, widget.controllerId).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(CustomSnackBar(message: error));
        }));
  }

  void showEditItemDialog(Program program, int index, List<Program> programLibraryData) {
    showAdaptiveDialog(
      context: context,
      builder: (BuildContext dialogContext) => Consumer<IrrigationProgramMainProvider>(
        builder: (context, scheduleProvider, child) {
          final GlobalKey<FormState> formKey = GlobalKey<FormState>();
          return AlertDialog(
            surfaceTintColor: Colors.white,
            title: const Text('Edit Item'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: program.programName.isNotEmpty ? program.programName : program.defaultProgramName,
                    focusNode: _programNameFocusNode,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(20),
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s.]')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Name cannot be empty";
                      } else if (programLibraryData.any((element) => element.programName == value && element.serialNumber != program.serialNumber)) {
                        return "Name already exists";
                      } else {
                        setState(() {
                          program.programName = value;
                        });
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 5),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                    child: CustomDropdownTile(
                      showCircleAvatar: false,
                      width: 70,
                      title: 'Priority',
                      subtitle: 'Description',
                      showSubTitle: false,
                      content: Icons.priority_high,
                      dropdownItems: irrigationProgramMainProvider.priorityList.map((item) => item).toList(),
                      selectedValue: program.priority,
                      onChanged: (newValue) {
                        irrigationProgramMainProvider.updatePriority(newValue, index);
                        _programNameFocusNode.unfocus();
                      },
                      includeNoneOption: false,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    Map<String, dynamic> dataToMqtt = {
                      "2800": {
                        "2801": "${program.serialNumber},${program.priority == irrigationProgramMainProvider.priorityList[0] ? 1 : 0}"
                      },
                    };

                    try {
                      await validatePayloadSent(
                        dialogContext: context,
                        context: context,
                        acknowledgedFunction: () {
                          setState(() {
                            controllerReadStatus = "1";
                          });
                        },
                        payload: dataToMqtt,
                        payloadCode: "2800",
                        deviceId: widget.deviceId,
                      ).whenComplete(() {
                        if (MqttService().acknowledgementPayload!['cM']['4201']['Code'] != "200") {
                          setState(() {
                            controllerReadStatus = "0";
                          });
                        }
                      });
                      await saveProgramDetails(program, dataToMqtt);
                      await Future.delayed(const Duration(seconds: 2), () async {
                        await irrigationProgramMainProvider.programLibraryData(widget.customerId, widget.controllerId);
                      });
                    } catch (error) {
                      showSnackBar(message: 'Failed to update because of $error', context: dialogContext);
                    }
                    Navigator.pop(dialogContext);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> saveProgramDetails(Program program, hardwareData) async {
    irrigationProgramMainProvider
        .updateUserProgramDetails(widget.userId, widget.controllerId, program.serialNumber, program.programId, program.programName, program.priority, program.defaultProgramName, controllerReadStatus, hardwareData, widget.customerId)
        .then((value) => ScaffoldMessenger.of(context).showSnackBar(CustomSnackBar(message: value)));
  }

  void navigateToIrrigationProgram(Program program) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IrrigationProgram(
          userId: widget.userId,
          controllerId: widget.controllerId,
          serialNumber: program.serialNumber,
          programType: program.programType,
          deviceId: widget.deviceId,
          fromDealer: false,
          customerId: widget.customerId,
          groupId: widget.groupId,
          categoryId: widget.categoryId,
          modelId: widget.modelId,
          deviceName: widget.deviceName,
          categoryName: widget.categoryName,
          nodeList: widget.nodeList,
        ),
      ),
    );
  }
}

Map<String, dynamic>? extract4201Map(dynamic message) {
  if (message == null || message is! Map) return null;

  try {
    if (message['cM'] is Map && message['cM']['4201'] != null) {
      if (message['cM']['4201'] is Map) {
        return Map<String, dynamic>.from(message['cM']['4201']);
      }
    }

    if (message['4200'] != null) {
      var val4200 = message['4200'];
      if (val4200 is List && val4200.isNotEmpty) {
        if (val4200[0] is Map && val4200[0]['4201'] is Map) {
          return Map<String, dynamic>.from(val4200[0]['4201']);
        }
      } else if (val4200 is Map && val4200['4201'] is Map) {
        return Map<String, dynamic>.from(val4200['4201']);
      }
    }

    if (message['4201'] is Map) {
      return Map<String, dynamic>.from(message['4201']);
    }
  } catch (e) {
    debugPrint("Error extracting 4201 map: $e");
  }

  return null;
}

Future<void> validatePayloadSent({
  required BuildContext dialogContext,
  required BuildContext context,
  MqttPayloadProvider? mqttPayloadProvider,
  required void Function() acknowledgedFunction,
  void Function()? failedFunction,
  required payload,
  required String payloadCode,
  required String deviceId,
}) async {
  bool dialogDismissed = false;

  void closeWaitDialog() {
    if (!dialogDismissed) {
      dialogDismissed = true;
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  try {
    MqttService().acknowledgementPayload = null;

    await MqttService().topicToPublishAndItsMessage(
        jsonEncode(payload), '${Environment.mqttPublishTopic}/$deviceId');

    bool isAcknowledged = false;
    Map<String, dynamic>? matched4201;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text("Please wait..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      await for (final message in MqttService().payloadController.timeout(
        const Duration(seconds: 30),
        onTimeout: (sink) => sink.close(),
      )) {
        if (message != null) {
          final map4201 = extract4201Map(message);
          if (map4201 != null) {
            final String? resPayloadCode = map4201['PayloadCode']?.toString();
            if (resPayloadCode == payloadCode ||
                resPayloadCode == '4202' ||
                (payloadCode == '400' &&
                    (resPayloadCode == '401' || resPayloadCode == '402'))) {
              isAcknowledged = true;
              matched4201 = map4201;
              MqttService().acknowledgementPayload = message is Map<String, dynamic>
                  ? message
                  : {'cM': {'4201': map4201}};
              break;
            }
          }
        }
      }
    } finally {
      closeWaitDialog();
    }

    if (isAcknowledged && matched4201 != null) {
      final codeStr = matched4201['Code']?.toString() ?? '';
      final msgStr = matched4201['Message']?.toString() ?? '';
      final nameStr = matched4201['Name']?.toString() ?? '';

      bool isSuccess = (codeStr == "200" || codeStr == "67") &&
          !msgStr.toUpperCase().contains("FAILED");

      if (isSuccess) {
        acknowledgedFunction();
      } else {
        if (failedFunction != null) {
          failedFunction();
        }
        String errorText = msgStr.trim().isNotEmpty
            ? msgStr
            : (nameStr.trim().isNotEmpty ? nameStr : "Execution failed");
        showSnackBar(message: errorText, context: context);
      }
    } else {
      showAlertDialog(
        message: "Controller is not responding",
        context: context,
      );
    }
  } catch (error, stackTrace) {
    closeWaitDialog();
    print("==================== ERROR IN validatePayloadSent ====================");
    print("Error: $error");
    print("StackTrace:\n$stackTrace");
    print("======================================================================");
    showAlertDialog(message: error.toString(), context: context);
  }
}

void showAlertDialog({required String message, Widget? child, required BuildContext context}) {
  showAdaptiveDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Alert"),
          content: child ?? Text(message),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("OK"))
          ],
        );
      });
}

void showSnackBar({required String message, required BuildContext context}) {
  ScaffoldMessenger.of(context).showSnackBar(CustomSnackBar(message: message));
}

class NumberPickerDialog extends StatelessWidget {
  final int initialValue;
  final int minValue;
  final int maxValue;

  const NumberPickerDialog({
    super.key,
    required this.initialValue,
    required this.minValue,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    int value = initialValue;
    return AlertDialog(
      title: const Text('Set Skip Days'),
      content: StatefulBuilder(
        builder: (context, setState) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: value > minValue ? () => setState(() => value--) : null,
                color: theme.primaryColor,
              ),
              Text('$value days'),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: value < maxValue ? () => setState(() => value++) : null,
                color: theme.primaryColor,
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, value),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
