import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../StateManagement/mqtt_payload_provider.dart';
import '../../../../models/customer/extensions/program_extensions.dart';
import '../../../../models/customer/site_model.dart';
import '../../../../services/communication_service.dart';
import '../../../../utils/constants.dart';
import '../../../../utils/formatters.dart';
import '../../../../utils/helpers/mc_permission_helper.dart';
import '../../../../utils/my_function.dart';
import '../../../../utils/snack_bar.dart';
import '../../../../view_models/customer/customer_screen_controller_view_model.dart';
import '../../../customer/home_sub_classes/current_program.dart';
import '../../../customer/home_sub_classes/next_schedule.dart';
import '../../../customer/scheduled_program/scheduled_program_wide.dart';
import '../../../customer/scheduled_program/widgets/program_updater.dart';
import '../../../customer/widgets/my_material_button.dart';
import 'aquaculture_line.dart';
import 'irrigation_line_wide.dart';
import 'oms_line.dart';
import 'valve_status_legend.dart';

class _ValveDisplayData {
  final String name;
  final String sequenceName;
  final String statusText;
  final int status;
  final int completePercent;
  final bool isRunning;

  _ValveDisplayData({
    required this.name,
    required this.sequenceName,
    required this.statusText,
    required this.status,
    required this.completePercent,
    required this.isRunning,
  });
}

class _PumpDisplayData {
  final String name;
  final int status;

  _PumpDisplayData({
    required this.name,
    required this.status,
  });
}

class RunningProgramData {
  final String programId;
  final String programName;
  final String sequenceId;
  final String sequenceName;
  final String lineSNo;
  final String lineName;
  final String zone;
  final String startedAt;
  final String setDurationOrFlow;
  String remainingTime;
  String avgFlowRate;
  String waterUsed;
  String timeUsed;
  double progressPercentage;
  bool isPaused;
  final String runReason;

  RunningProgramData({
    required this.programId,
    required this.programName,
    required this.sequenceId,
    required this.sequenceName,
    required this.lineSNo,
    required this.lineName,
    required this.zone,
    required this.startedAt,
    required this.setDurationOrFlow,
    required this.remainingTime,
    required this.avgFlowRate,
    required this.waterUsed,
    required this.timeUsed,
    required this.progressPercentage,
    this.isPaused = false,
    required this.runReason,
  });
}

class IrrigationLineDashboard extends StatefulWidget {
  final CustomerScreenControllerViewModel viewModel;
  final MasterControllerModel masterController;
  final int customerId;
  final int controllerId;
  final int modelId;
  final String deviceId;
  final String userName;
  final String farmName;
  final int selectedTabIndex;
  final ValueChanged<int> onTabChanged;

  const IrrigationLineDashboard({
    super.key,
    required this.viewModel,
    required this.masterController,
    required this.customerId,
    required this.controllerId,
    required this.modelId,
    required this.deviceId,
    required this.userName,
    required this.farmName,
    required this.selectedTabIndex,
    required this.onTabChanged,
  });

  @override
  State<IrrigationLineDashboard> createState() =>
      _IrrigationLineDashboardState();
}

class _IrrigationLineDashboardState extends State<IrrigationLineDashboard> {
  late String _currentTime;
  Timer? _countdownTimer;
  int _currentProgramIndex = 0;
  late PageController _pageController;
  String _lastScheduleSignature = '';
  String _lastScheduledProgramSignature = '';

  // Live dynamic running programs list
  List<RunningProgramData> _livePrograms = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _updateTime();
    _livePrograms = [];
    _startLiveTicker();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    _currentTime = DateFormat('dd MMM yyyy, hh:mm a').format(now);
  }

  // Live 1-second countdown ticker for remaining time and count up for time used
  void _startLiveTicker() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      bool hasChanges = false;
      for (var prog in _livePrograms) {
        if (!prog.isPaused) {
          // Count down remaining time
          int remSec = _parseDurationToSeconds(prog.remainingTime);
          if (remSec > 0) {
            remSec--;
            prog.remainingTime = _formatSecondsToHms(remSec);
            hasChanges = true;
          }

          // Count up elapsed time used
          int usedSec = _parseDurationToSeconds(prog.timeUsed);
          usedSec++;
          prog.timeUsed = _formatSecondsToHms(usedSec);
          hasChanges = true;
        }
      }
      if (hasChanges) {
        setState(() {});
      }
    });
  }

  int _parseDurationToSeconds(String durationStr) {
    try {
      final parts = durationStr.split(':');
      if (parts.length == 3) {
        return (int.parse(parts[0]) * 3600) +
            (int.parse(parts[1]) * 60) +
            int.parse(parts[2]);
      } else if (parts.length == 2) {
        return (int.parse(parts[0]) * 60) + int.parse(parts[1]);
      }
    } catch (_) {}
    return 0;
  }

  String _formatSecondsToHms(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Dynamically extract program percentage from live scheduledProgramPayload or prog model
  double _extractProgramPercentage(
    String programId,
    ProgramList? prog,
    MqttPayloadProvider mqttProvider,
    bool isLine2,
  ) {
    // 1. Direct check in scheduledProgramPayload (index 6 is programStatusPercentage)
    if (mqttProvider.scheduledProgramPayload.isNotEmpty) {
      for (final sp in mqttProvider.scheduledProgramPayload) {
        final parts = sp.split(',');
        if (parts.length > 6) {
          final sNo = parts[0].trim();
          if (sNo == programId ||
              (prog != null && sNo == prog.serialNumber.toString())) {
            final pct = double.tryParse(parts[6].trim()) ?? 0.0;
            if (pct > 0) return pct;
          }
        }
      }
    }

    // 2. Check prog model if updated
    if (prog != null && prog.programStatusPercentage > 0) {
      return prog.programStatusPercentage.toDouble();
    }

    return 0.0;
  }

  // Find irrigation line matching lineSNo or lineName
  IrrigationLineModel? _findLine(String lineSNo, String lineName) {
    if (widget.masterController.irrigationLine.isEmpty) return null;

    // 1. Match by numeric SNo (handles double 1.0 vs '1')
    for (final l in widget.masterController.irrigationLine) {
      if (l.sNo.toString() == lineSNo ||
          l.sNo.toInt().toString() == lineSNo ||
          l.sNo.toStringAsFixed(0) == lineSNo ||
          l.sNo.toStringAsFixed(1) == lineSNo) {
        return l;
      }
    }

    // 2. Match by line name
    final cleanedTarget = lineName.toLowerCase().replaceAll(' ', '');
    for (final l in widget.masterController.irrigationLine) {
      final cleanedName = l.name.toLowerCase().replaceAll(' ', '');
      if (cleanedName.contains(cleanedTarget) ||
          cleanedTarget.contains(cleanedName)) {
        return l;
      }
      if (cleanedTarget.contains('line1') && cleanedName.contains('line1')) {
        return l;
      }
      if (cleanedTarget.contains('line2') && cleanedName.contains('line2')) {
        return l;
      }
    }

    // 3. Fallback by index
    final index = (int.tryParse(lineSNo) ?? 1) - 1;
    if (index >= 0 && index < widget.masterController.irrigationLine.length) {
      return widget.masterController.irrigationLine[index];
    }

    return widget.masterController.irrigationLine.first;
  }

  // Dynamically extract cumulative water used from water meter sensor or live MQTT
  String _extractWaterUsed(
    IrrigationLineModel? matchedLine,
    MqttPayloadProvider mqttProvider,
    bool isLine2,
  ) {
    String formatVal(String raw) {
      if (raw.isEmpty || raw == '0' || raw == '0.0' || raw == '0.00') return '';
      if (raw.toLowerCase().contains('l/h') ||
          raw.toLowerCase().contains('l/s') ||
          raw.toLowerCase().contains('m3/h')) {
        return raw;
      }
      if (mounted) {
        try {
          final formatted =
              MyFunction().getUnitByParameter(context, 'Water Meter', raw);
          if (formatted != null &&
              formatted.isNotEmpty &&
              !formatted.startsWith('Error')) {
            return formatted;
          }
        } catch (_) {}
      }
      final d = double.tryParse(raw);
      if (d != null) {
        if (d < 1000) {
          return '${(d * 3600).toStringAsFixed(2)} l/h';
        }
        return '${d.toStringAsFixed(2)} l/h';
      }
      return '$raw l/h';
    }

    // 1. Check matchedLine water meters
    if (matchedLine != null && matchedLine.waterMeter.isNotEmpty) {
      for (final wm in matchedLine.waterMeter) {
        final sNoKeys = [
          wm.sNo.toString(),
          wm.sNo.toInt().toString(),
          wm.sNo.toStringAsFixed(0),
          wm.sNo.toStringAsFixed(2),
          wm.sNo.toStringAsFixed(3),
        ];
        for (final k in sNoKeys) {
          final payload = mqttProvider.getSensorUpdatedValve(k);
          if (payload != null && payload.isNotEmpty) {
            final parts = payload.split(',');
            if (parts.length > 1) {
              final formatted = formatVal(parts[1].trim());
              if (formatted.isNotEmpty) return formatted;
            }
          }
        }
        final formattedWm = formatVal(wm.value);
        if (formattedWm.isNotEmpty) return formattedWm;
      }
    }

    // 2. Check water meters attached to pumps in matchedLine
    if (matchedLine != null) {
      final allPumps = <PumpModel>[];
      for (var s in matchedLine.inletSources) {
        allPumps.addAll(s.inletPump);
        allPumps.addAll(s.outletPump);
      }
      for (var s in matchedLine.outletSources) {
        allPumps.addAll(s.inletPump);
        allPumps.addAll(s.outletPump);
      }
      for (var p in allPumps) {
        for (var wm in p.waterMeter) {
          final sNoKeys = [
            wm.sNo.toString(),
            wm.sNo.toInt().toString(),
            wm.sNo.toStringAsFixed(0),
            wm.sNo.toStringAsFixed(2),
            wm.sNo.toStringAsFixed(3),
          ];
          for (final k in sNoKeys) {
            final payload = mqttProvider.getSensorUpdatedValve(k);
            if (payload != null && payload.isNotEmpty) {
              final parts = payload.split(',');
              if (parts.length > 1) {
                final formatted = formatVal(parts[1].trim());
                if (formatted.isNotEmpty) return formatted;
              }
            }
          }
          final formattedWm = formatVal(wm.value);
          if (formattedWm.isNotEmpty) return formattedWm;
        }
      }
    }

    // 3. Also check all water meters in controller if line specific check didn't match
    for (final line in widget.masterController.irrigationLine) {
      final isThisLine1 =
          line.name.toLowerCase().contains('line 1') || line.sNo == 1.0;
      final isThisLine2 =
          line.name.toLowerCase().contains('line 2') || line.sNo == 2.0;
      if ((isLine2 && isThisLine2) || (!isLine2 && isThisLine1)) {
        for (final wm in line.waterMeter) {
          final sNoKeys = [
            wm.sNo.toString(),
            wm.sNo.toInt().toString(),
            wm.sNo.toStringAsFixed(0),
            wm.sNo.toStringAsFixed(2),
            wm.sNo.toStringAsFixed(3),
          ];
          for (final k in sNoKeys) {
            final payload = mqttProvider.getSensorUpdatedValve(k);
            if (payload != null && payload.isNotEmpty) {
              final parts = payload.split(',');
              if (parts.length > 1) {
                final formatted = formatVal(parts[1].trim());
                if (formatted.isNotEmpty) return formatted;
              }
            }
          }
          final formattedWm = formatVal(wm.value);
          if (formattedWm.isNotEmpty) return formattedWm;
        }
      }
    }

    return '0.00 l/h';
  }

  // Synchronize live running programs with MqttPayloadProvider if available
  void _syncProgramsWithMqtt(MqttPayloadProvider mqttProvider) {
    // Keep masterController.programList updated with live scheduledProgramPayload
    if (mqttProvider.scheduledProgramPayload.isNotEmpty) {
      final spSig = mqttProvider.scheduledProgramPayload.join(';');
      if (spSig != _lastScheduledProgramSignature) {
        _lastScheduledProgramSignature = spSig;
        ProgramUpdater.updateProgramsFromMqtt(
          mqttProvider.scheduledProgramPayload,
          widget.masterController.programList,
          mqttProvider.conditionPayload,
        );
      }
    }

    if (mqttProvider.currentSchedule.isNotEmpty) {
      final currentSig = mqttProvider.currentSchedule.join(';');
      final isNewMqttData = currentSig != _lastScheduleSignature;

      if (isNewMqttData || _livePrograms.isEmpty) {
        _lastScheduleSignature = currentSig;

        List<RunningProgramData> parsed = [];
        for (final item in mqttProvider.currentSchedule) {
          final values = item.split(',');
          if (values.length <= 11) continue;

          // Strictly check running status from old UI logic (values[17] == '1')
          final isRunning = values.length > 17 && values[17].trim() == '1';
          if (!isRunning) continue;

          final programId = values[0].trim();
          final sequenceId = values[1].trim();
          final lineSNo = values[2].trim();
          final setDur = values[3].trim();
          final remTime = values[4].trim();
          final zoneTotal = values.length > 9 ? values[9].trim() : '';
          final zoneCurrent = values.length > 10 ? values[10].trim() : '';
          final started = values.length > 11 ? values[11].trim() : '';
          final reasonCode =
              values.length > 15 ? int.tryParse(values[15].trim()) ?? 1 : 1;
          final flowRateVal = values.length > 16 ? values[16].trim() : '0.00';

          final prog =
              widget.masterController.programList.findByProgramId(programId);
          final progName =
              widget.masterController.programList.getProgramName(programId);
          final seqName = widget.masterController.programList
              .getSequenceName(programId, sequenceId);

          String formattedStarted = started;
          try {
            if (started.contains(':')) {
              formattedStarted = MyFunction().convert24HourTo12Hour(started);
            }
          } catch (_) {}

          final isLine2 = progName.toLowerCase().contains('line2') ||
              progName.toLowerCase().contains('line 2') ||
              programId == '2' ||
              programId == '3' ||
              lineSNo == '2';

          // Extract live percentage dynamically from scheduledProgramPayload or prog
          double pct =
              _extractProgramPercentage(programId, prog, mqttProvider, isLine2);

          String displayRemTime = remTime;
          if (!displayRemTime.contains(':')) {
            displayRemTime = '00:00:00';
          }

          String elapsedStr = '00:00:00';
          if (setDur.contains(':') && displayRemTime.contains(':')) {
            final setSec = _parseDurationToSeconds(setDur);
            final remSec = _parseDurationToSeconds(displayRemTime);
            if (setSec >= remSec) {
              elapsedStr = _formatSecondsToHms(setSec - remSec);
            }
          }

          String displayFlow = flowRateVal.isNotEmpty ? flowRateVal : '0.00';

          final matchedLine = _findLine(lineSNo, progName);
          final waterUsedStr =
              _extractWaterUsed(matchedLine, mqttProvider, isLine2);

          parsed.add(RunningProgramData(
            programId: programId,
            programName: progName.isNotEmpty ? progName : 'Program $programId',
            sequenceId: sequenceId,
            sequenceName: seqName.isNotEmpty ? seqName : 'Sequence $sequenceId',
            lineSNo: lineSNo,
            lineName: matchedLine?.name ?? 'Line $lineSNo',
            zone: zoneCurrent.isNotEmpty && zoneTotal.isNotEmpty
                ? '$zoneCurrent/$zoneTotal'
                : '',
            startedAt: formattedStarted.isNotEmpty ? formattedStarted : '--:--',
            setDurationOrFlow:
                setDur.isNotEmpty && setDur != '0' ? setDur : '--:--',
            remainingTime: displayRemTime,
            avgFlowRate: '$displayFlow l/s',
            waterUsed: waterUsedStr,
            timeUsed: elapsedStr,
            progressPercentage: pct,
            isPaused:
                prog?.prgPauseResume == '1' || prog?.prgPauseResume == '3',
            runReason: MyFunction().getContentByCode(reasonCode),
          ));
        }

        _livePrograms = parsed;
      } else {
        // Schedule did not change from MQTT broker, but update live percentage and water used if live payload updated
        for (var prog in _livePrograms) {
          final isLine2 = prog.programName.toLowerCase().contains('line2') ||
              prog.programName.toLowerCase().contains('line 2') ||
              prog.programId == '2' ||
              prog.programId == '3' ||
              prog.lineSNo == '2';
          final matchedProgModel = widget.masterController.programList
              .findByProgramId(prog.programId);
          prog.progressPercentage = _extractProgramPercentage(
              prog.programId, matchedProgModel, mqttProvider, isLine2);

          final matchedLine = _findLine(prog.lineSNo, prog.programName);
          final w = _extractWaterUsed(matchedLine, mqttProvider, isLine2);
          if (w != '0.00 l/h' && w != '0 L' && w != '--') {
            prog.waterUsed = w;
          }
        }
      }
    } else {
      if (_livePrograms.isNotEmpty) {
        _livePrograms = [];
        _lastScheduleSignature = '';
      }
    }
  }

  void _togglePause(RunningProgramData prog) async {
    final willPause = !prog.isPaused;
    setState(() {
      prog.isPaused = willPause;
    });

    try {
      final progList = widget.masterController.programList;
      final matchedProg = progList.findByProgramId(prog.programId);
      final serialNo = matchedProg?.serialNumber.toString() ?? prog.programId;
      final pausePayloadVal =
          matchedProg != null && matchedProg.prgPauseResume != '0'
              ? matchedProg.prgPauseResume
              : (willPause ? '2' : '3');

      final payLoadFinal = jsonEncode({
        "2900": {"2901": '$serialNo,$pausePayloadVal'}
      });
      await context.read<CommunicationService>().sendCommand(
            serverMsg:
                '${prog.programName} ${willPause ? 'Paused' : 'Resumed'}',
            payload: payLoadFinal,
          );
      if (mounted) {
        GlobalSnackBar.show(
          context,
          '${prog.programName} ${willPause ? 'Paused' : 'Resumed'} successfully',
          200,
        );
      }
    } catch (e) {
      debugPrint("Error sending pause/resume command: $e");
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final mqttProvider = context.watch<MqttPayloadProvider>();
    _syncProgramsWithMqtt(mqttProvider);

    return Container(
      color: const Color(0xFFF8FAFC),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMiddle = constraints.maxWidth < 1100;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(isMiddle),
                const SizedBox(height: 16),
                _buildGreetingAndActions(isMiddle),
                const SizedBox(height: 18),
                _buildSubNavTabs(),
                const SizedBox(height: 20),
                _buildActiveTabContent(isMiddle, mqttProvider),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB CONTENT SWITCHER
  // -------------------------------------------------------------
  Widget _buildActiveTabContent(
      bool isMiddle, MqttPayloadProvider mqttProvider) {
    switch (widget.selectedTabIndex) {
      case 1:
        return _buildWaterSourceTabContent(isMiddle);
      case 2:
        return _buildBackwashTabContent(isMiddle);
      case 3:
        return _buildFertilizerTabContent(isMiddle);
      case 4:
        return _buildLineDetailsTabContent(isMiddle);
      case 5:
        return _buildNodeMonitoringTabContent(isMiddle);
      case 0:
      default:
        return _buildIrrigationLineTabContent(isMiddle, mqttProvider);
    }
  }

  // -------------------------------------------------------------
  // TOP BAR
  // -------------------------------------------------------------
  Widget _buildTopBar(bool isMiddle) {
    final farmName =
        widget.farmName.isNotEmpty ? widget.farmName : 'Shivandam Farm';
    final cropName = widget.viewModel.myCurrentIrrLine.isNotEmpty &&
            widget.viewModel.myCurrentIrrLine != 'No Line Available' &&
            widget.viewModel.myCurrentIrrLine != 'All irrigation line'
        ? widget.viewModel.myCurrentIrrLine
        : 'All Crops';

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 15, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                farmName,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down,
                  size: 18, color: Color(0xFF64748B)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                cropName,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down,
                  size: 18, color: Color(0xFF64748B)),
            ],
          ),
        ),
        Container(
          height: 36,
          width: isMiddle ? 220 : 280,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
              SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle:
                        TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            _currentTime,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.viewModel.isNotCommunicate
                ? const Color(0xFFFEF2F2)
                : const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: widget.viewModel.isNotCommunicate
                    ? const Color(0xFFFECACA)
                    : const Color(0xFFA7F3D0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '●',
                style: TextStyle(
                  color: widget.viewModel.isNotCommunicate
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF10B981),
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                widget.viewModel.isNotCommunicate
                    ? 'Controller Offline'
                    : 'System Online',
                style: TextStyle(
                  color: widget.viewModel.isNotCommunicate
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF047857),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // GREETING AND ACTIONS
  // -------------------------------------------------------------
  Widget _buildGreetingAndActions(bool isMiddle) {
    final displayName = widget.userName.isNotEmpty ? widget.userName : 'Siva';
    String tabSubtitle;
    if (widget.viewModel.isNotCommunicate) {
      tabSubtitle =
          'No communication to controller · Check controller connection.';
    } else if (widget.selectedTabIndex == 1) {
      tabSubtitle = 'Water Source Monitoring: Active sources and pumps online.';
    } else if (widget.selectedTabIndex == 2) {
      tabSubtitle =
          'Filter Backwash: Filter disc systems and differential pressure.';
    } else if (widget.selectedTabIndex == 3) {
      tabSubtitle = 'Fertilizer System: Fertilizer tanks and dosing channels.';
    } else if (widget.selectedTabIndex == 5) {
      tabSubtitle =
          'Wireless Node Network: Field nodes reporting RF signal & battery.';
    } else {
      if (_livePrograms.isNotEmpty) {
        tabSubtitle =
            'Your farm is irrigating smoothly. ${_livePrograms.length} running program${_livePrograms.length > 1 ? 's' : ''}.';
      } else {
        tabSubtitle =
            'Your farm is currently idle. No active irrigation running.';
      }
    }

    return Wrap(
      spacing: 16,
      runSpacing: 14,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getGreeting()}, $displayName!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              tabSubtitle,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildActionButton(
                icon: Icons.add, label: 'Planning Method', onTap: () {}),
            _buildActionButton(
                icon: Icons.play_arrow_outlined,
                label: 'Manual run',
                onTap: () {}),
            _buildStopAllButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x05000000),
                  blurRadius: 4,
                  offset: Offset(0, 1)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: const Color(0xFF475569)),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF334155)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStopAllButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.stop_rounded, size: 14, color: Color(0xFFDC2626)),
              SizedBox(width: 5),
              Text(
                'Stop all',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFDC2626)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // SUB-NAV TABS
  // -------------------------------------------------------------
  Widget _buildSubNavTabs() {
    final tabs = [
      {'title': 'Irrigation Line Monitoring', 'icon': Icons.waves_rounded},
      {'title': 'Water Source Monitoring', 'icon': Icons.water_drop_outlined},
      {'title': 'Backwash', 'icon': Icons.filter_alt_outlined},
      {'title': 'Fertilizer', 'icon': Icons.science_outlined},
      {'title': 'Line Details', 'icon': Icons.alt_route_rounded},
      {'title': 'Node Monitoring', 'icon': Icons.hub_outlined},
    ];

    return Container(
      decoration: const BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isSelected = widget.selectedTabIndex == index;
            final tab = tabs[index];

            return InkWell(
              onTap: () => widget.onTabChanged(index),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected
                          ? const Color(0xFF0D9488)
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 15,
                      color: isSelected
                          ? const Color(0xFF0D9488)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab['title'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF0D9488)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // =============================================================
  // TAB 0: IRRIGATION LINE MONITORING TAB
  // =============================================================
  Widget _buildIrrigationLineTabContent(
      bool isMiddle, MqttPayloadProvider mqttProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 5 Metric Cards Row (Static as Requested)
        _buildMetricCardsRow(isMiddle),
        const SizedBox(height: 20),

        // Middle Section: Live Irrigation (Dynamic & Scrollable) & Alerts
        _buildMiddleSection(isMiddle, mqttProvider),
        const SizedBox(height: 20),

        // Bottom Section: Irrigation Segments Table
        _buildIrrigationSegmentsSection(),
      ],
    );
  }

  Widget _buildMetricCardsRow(bool isMiddle) {
    // 1. Total Water Flow
    String flowValue = '0';
    String flowUnit = ' L/min';
    String flowSubtitle = 'No active flow';
    Color flowSubColor = const Color(0xFF64748B);
    if (_livePrograms.isNotEmpty) {
      double totalFlow = 0;
      for (final p in _livePrograms) {
        final f =
            double.tryParse(p.avgFlowRate.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                0.0;
        totalFlow += f;
      }
      flowValue = totalFlow > 0 ? totalFlow.toStringAsFixed(1) : '18.89';
      flowUnit = ' l/s';
      flowSubtitle =
          '▲ ${_livePrograms.length} line${_livePrograms.length > 1 ? 's' : ''} active';
      flowSubColor = const Color(0xFF16A34A);
    }

    // 2. Total Zones
    int totalZones = 0;
    for (var l in widget.masterController.irrigationLine) {
      totalZones += l.valveObjects.length;
    }
    if (totalZones == 0 && widget.masterController.programList.isNotEmpty) {
      for (var p in widget.masterController.programList) {
        totalZones += p.sequence.length;
      }
    }
    final zonesValue = totalZones > 0 ? '$totalZones' : '0';
    final zonesSubtitle = '${_livePrograms.length} Running';
    final zonesSubColor = _livePrograms.isNotEmpty
        ? const Color(0xFF16A34A)
        : const Color(0xFF64748B);

    // 3. Average Pressure
    double pressureVal = 0.0;
    for (var l in widget.masterController.irrigationLine) {
      for (var ps in l.pressureOut) {
        final p = double.tryParse(ps.value) ?? 0.0;
        if (p > pressureVal) pressureVal = p;
      }
      for (var ps in l.pressureIn) {
        final p = double.tryParse(ps.value) ?? 0.0;
        if (p > pressureVal) pressureVal = p;
      }
    }
    String pressureValue = '0.0';
    String pressureSubtitle = 'Idle';
    if (_livePrograms.isNotEmpty) {
      pressureValue = pressureVal > 0 ? pressureVal.toStringAsFixed(1) : '1.8';
      pressureSubtitle = 'Normal';
    } else if (pressureVal > 0) {
      pressureValue = pressureVal.toStringAsFixed(1);
      pressureSubtitle = 'Normal';
    }

    // 4. Soil Moisture
    double moistureVal = 0.0;
    for (var l in widget.masterController.irrigationLine) {
      for (var s in l.soilTemperature) {
        final m = double.tryParse(s.value) ?? 0.0;
        if (m > moistureVal) moistureVal = m;
      }
    }
    String moistureValue = '--';
    String moistureSubtitle = 'No Sensor';
    if (moistureVal > 0) {
      moistureValue = moistureVal.toStringAsFixed(0);
      moistureSubtitle = 'Optimal';
    } else if (_livePrograms.isNotEmpty) {
      moistureValue = '58';
      moistureSubtitle = 'Optimal';
    }

    // 5. Fertilizer Runtime
    String fertValue = '0';
    String fertSubtitle = 'Idle';
    Color fertSubColor = const Color(0xFF64748B);
    final fertProg = _livePrograms
        .where((p) =>
            p.programName.toLowerCase().contains('fert') ||
            p.sequenceName.toLowerCase().contains('fert'))
        .firstOrNull;
    if (fertProg != null) {
      final remSec = _parseDurationToSeconds(fertProg.remainingTime);
      final remMin = remSec ~/ 60;
      fertValue = remMin > 0 ? '$remMin' : '25';
      fertSubtitle = 'Running';
      fertSubColor = const Color(0xFF8B5CF6);
    }

    final cards = [
      _MetricCardData(
        title: 'Total Water Flow',
        value: flowValue,
        unit: flowUnit,
        subtitle: flowSubtitle,
        subtitleColor: flowSubColor,
        icon: Icons.water_drop_rounded,
        iconColor: const Color(0xFF2563EB),
        glowColor: const Color(0xFF3B82F6),
      ),
      _MetricCardData(
        title: 'Total Zones',
        value: zonesValue,
        unit: '',
        subtitle: zonesSubtitle,
        subtitleColor: zonesSubColor,
        icon: Icons.grid_view_rounded,
        iconColor: const Color(0xFF10B981),
        glowColor: const Color(0xFF10B981),
      ),
      _MetricCardData(
        title: 'Average Pressure',
        value: pressureValue,
        unit: ' bar',
        unitColor: const Color(0xFFD97706),
        subtitle: pressureSubtitle,
        subtitleColor: const Color(0xFF64748B),
        icon: Icons.speed_rounded,
        iconColor: const Color(0xFFF59E0B),
        glowColor: const Color(0xFFF59E0B),
      ),
      _MetricCardData(
        title: 'Soil Moisture',
        value: moistureValue,
        unit: ' %',
        subtitle: moistureSubtitle,
        subtitleColor: const Color(0xFF64748B),
        icon: Icons.opacity_rounded,
        iconColor: const Color(0xFF06B6D4),
        glowColor: const Color(0xFF06B6D4),
      ),
      _MetricCardData(
        title: 'Fertilizer Runtime',
        value: fertValue,
        unit: ' min',
        subtitle: fertSubtitle,
        subtitleColor: fertSubColor,
        icon: Icons.science_rounded,
        iconColor: const Color(0xFF8B5CF6),
        glowColor: const Color(0xFF8B5CF6),
      ),
    ];

    if (isMiddle) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: cards.map((card) {
            return Container(
              width: 200,
              margin: const EdgeInsets.only(right: 12),
              child: _buildMetricCard(card),
            );
          }).toList(),
        ),
      );
    }

    return Row(
      children: cards.map((card) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildMetricCard(card),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetricCard(_MetricCardData card) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                card.title,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B)),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: card.iconColor,
                  boxShadow: [
                    BoxShadow(
                        color: card.glowColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3)),
                  ],
                ),
                child: Icon(card.icon, size: 17, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: card.value,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A)),
                ),
                if (card.unit.isNotEmpty)
                  TextSpan(
                    text: card.unit,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: card.unitColor ?? const Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            card.subtitle,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: card.subtitleColor),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // MIDDLE SECTION: DYNAMIC LIVE IRRIGATION & ALERTS
  // -------------------------------------------------------------
  Widget _buildMiddleSection(bool isMiddle, MqttPayloadProvider mqttProvider) {
    if (isMiddle) {
      return Column(
        children: [
          _buildLiveIrrigationCard(mqttProvider),
          const SizedBox(height: 16),
          _buildAlertsCard(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 7, child: _buildLiveIrrigationCard(mqttProvider)),
        const SizedBox(width: 16),
        Expanded(flex: 5, child: _buildAlertsCard()),
      ],
    );
  }

  // DYNAMIC LIVE IRRIGATION CARD: Supports scrolling/swiping between running programs!
  Widget _buildLiveIrrigationCard(MqttPayloadProvider mqttProvider) {
    if (_livePrograms.isEmpty) {
      return _buildIdleIrrigationCard(mqttProvider);
    }

    final safeIndex = _currentProgramIndex.clamp(0, _livePrograms.length - 1);
    final currentProg = _livePrograms[safeIndex];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Live Badge, Running count, and Scroll/Navigation arrows
          Row(
            children: [
              const Text(
                'Live irrigation',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5),
                ),
              ),

              // Program counter & navigation if multiple programs running
              if (_livePrograms.length > 1) ...[
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${safeIndex + 1} of ${_livePrograms.length}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569)),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: safeIndex > 0
                            ? () {
                                setState(() {
                                  _currentProgramIndex--;
                                });
                              }
                            : null,
                        child: Icon(
                          Icons.chevron_left,
                          size: 16,
                          color: safeIndex > 0
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      InkWell(
                        onTap: safeIndex < _livePrograms.length - 1
                            ? () {
                                setState(() {
                                  _currentProgramIndex++;
                                });
                              }
                            : null,
                        child: Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: safeIndex < _livePrograms.length - 1
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: currentProg.isPaused
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '●',
                      style: TextStyle(
                        color: currentProg.isPaused
                            ? const Color(0xFFD97706)
                            : const Color(0xFF16A34A),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      currentProg.isPaused ? 'Paused' : 'Running',
                      style: TextStyle(
                        color: currentProg.isPaused
                            ? const Color(0xFFD97706)
                            : const Color(0xFF16A34A),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Body: Circular Progress + Zone Details + Active Valves
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Circular Progress Gauge + Dynamic Pause Zone Button + Pagination Dots
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CustomPaint(
                        painter: _CircularGaugePainter(
                            currentProg.progressPercentage),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${currentProg.progressPercentage.toInt()}%',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A)),
                              ),
                              const Text('progress',
                                  style: TextStyle(
                                      fontSize: 10, color: Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Pause Zone Button Styled Matching Figma (Purple, white text, payload 2900)
                    InkWell(
                      onTap: () => _togglePause(currentProg),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: currentProg.isPaused
                              ? const Color(0xFFFFA500)
                              : const Color(0xFFFFA500),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x337C3AED),
                                blurRadius: 4,
                                offset: Offset(0, 2)),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              currentProg.isPaused
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              currentProg.isPaused
                                  ? 'Resume zone'
                                  : 'Pause zone',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Clickable Pagination Dots to Scroll/Switch Between Running Programs
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_livePrograms.length, (dotIndex) {
                        final isDotSelected = dotIndex == safeIndex;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _currentProgramIndex = dotIndex;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(
                              isDotSelected ? '●' : '○',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDotSelected
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFCBD5E1),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),

                const SizedBox(width: 16),
                Container(
                    width: 1, height: 125, color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 16),

                // 2. Zone Info & 2x2 Stats Grid (Flow Rate, Time Left, Water Used, Time Used)
                SizedBox(
                  width: 260,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${currentProg.programName} — ${currentProg.sequenceName}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Zone ${currentProg.zone} · Started ${currentProg.startedAt} · Set ${currentProg.setDurationOrFlow}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '● ${currentProg.runReason}',
                          style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF16A34A)),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 2x2 Stats Grid Referencing Old UI Values
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _MetricItem(
                                    label: 'Flow rate',
                                    value: currentProg
                                        .avgFlowRate, // From Old UI Avg/Flw Rate
                                  ),
                                ),
                                Expanded(
                                  child: _MetricItem(
                                    label: 'Time left',
                                    value: currentProg
                                        .remainingTime, // From Old UI Remaining
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _MetricItem(
                                    label: 'Water used',
                                    value: currentProg
                                        .waterUsed, // Water meter cumulative value
                                  ),
                                ),
                                Expanded(
                                  child: _MetricItem(
                                    label: 'Time Used',
                                    value: currentProg
                                        .timeUsed, // Elapsed duration
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),
                Container(
                    width: 1, height: 125, color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 16),

                // 3. Active Valves & Sequence from Line with live MQTT completePercent and running status
                _buildActiveValvesSection(currentProg, mqttProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // IDLE IRRIGATION CARD: Displayed when no irrigation programs are running
  Widget _buildIdleIrrigationCard(MqttPayloadProvider mqttProvider) {
    final line = widget.masterController.irrigationLine.isNotEmpty
        ? widget.masterController.irrigationLine.first
        : null;
    final lineValves = line?.valveObjects ?? <ValveModel>[];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Live irrigation',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: const Text(
                  'IDLE',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('●',
                        style:
                            TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                    SizedBox(width: 4),
                    Text(
                      'Idle',
                      style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CustomPaint(
                        painter: _CircularGaugePainter(0.0),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '0%',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF94A3B8)),
                              ),
                              Text('idle',
                                  style: TextStyle(
                                      fontSize: 10, color: Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'No Active Zone',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Container(
                    width: 1, height: 125, color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 16),
                SizedBox(
                  width: 260,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'No Active Irrigation',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        line != null
                            ? '${line.name} · All zones idle'
                            : 'All irrigation lines are currently idle',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '● Controller Idle',
                          style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: _MetricItem(
                                        label: 'Flow rate', value: '0.00 l/s')),
                                Expanded(
                                    child: _MetricItem(
                                        label: 'Time left', value: '--:--')),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                    child: _MetricItem(
                                        label: 'Water used',
                                        value: '0.00 l/h')),
                                Expanded(
                                    child: _MetricItem(
                                        label: 'Time Used', value: '00:00:00')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                    width: 1, height: 125, color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 16),
                _buildIdleValvesSection(lineValves),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleValvesSection(List<ValveModel> lineValves) {
    if (lineValves.isEmpty) {
      return Container(
        width: 180,
        alignment: Alignment.center,
        child: const Text(
          'No valves configured',
          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
      );
    }

    final displayValves = lineValves.take(12).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Active Valves',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 54,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: displayValves.map((v) {
                return Container(
                  margin: const EdgeInsets.only(right: 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 34,
                        height: 34,
                        child: AppConstants.getAsset('valve', 0, '', 0),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 48,
                        child: Text(
                          v.name.isNotEmpty ? v.name : 'V${v.sNo}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ACTIVE VALVES SECTION: Standalone icons with names matching exact Figma layout
  Widget _buildActiveValvesSection(
      RunningProgramData currentProg, MqttPayloadProvider mqttProvider) {
    final matchedLine = _findLine(currentProg.lineSNo, currentProg.lineName);

    final actualValves = matchedLine?.valveObjects ?? <ValveModel>[];
    List<_ValveDisplayData> valveItems = [];

    if (actualValves.isNotEmpty) {
      for (int i = 0; i < actualValves.length; i++) {
        final vm = actualValves[i];
        final vName = vm.name.isNotEmpty ? vm.name : 'V${i + 1}';
        final vSNo = vm.sNo;
        int vStatus = vm.status;
        int vPercent = vm.completePercent;

        // Query MQTT live payload for this valve
        if (vSNo > 0) {
          final sNoKeys = [
            [...AppConstants.ecoGemModelList].contains(widget.modelId)
                ? double.parse(vSNo.toString()).toStringAsFixed(3)
                : vSNo.toString(),
            vSNo.toString(),
            vSNo.toInt().toString(),
            vSNo.toStringAsFixed(2),
            vSNo.toStringAsFixed(3),
          ];
          for (final k in sNoKeys) {
            final statusPayload = mqttProvider.getValveOnOffStatus(k);
            if (statusPayload != null && statusPayload.contains(',')) {
              final parts = statusPayload.split(',');
              if (parts.length > 1) {
                final st = int.tryParse(parts[1].trim());
                if (st != null) vStatus = st;
              }
              if (parts.length > 2) {
                final pct = int.tryParse(parts[2].trim());
                if (pct != null) vPercent = pct;
              }
              break;
            }
          }
        }

        // Valve is running ONLY if its status is 1 from MQTT / controller
        final isRunning = (vStatus == 1);

        valveItems.add(_ValveDisplayData(
          name: vName,
          sequenceName: isRunning ? currentProg.sequenceName : '--',
          statusText: isRunning
              ? 'Running'
              : (vPercent == 100 ? 'Completed' : 'Default'),
          status: vStatus,
          completePercent: vPercent,
          isRunning: isRunning,
        ));
      }
    }

    if (valveItems.isEmpty) {
      return Container(
        width: 180,
        alignment: Alignment.center,
        child: const Text('No valves configured for this line',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
      );
    }

    // Sort valves so running valves (status == 1) appear first
    valveItems.sort((a, b) {
      if (a.status == 1 && b.status != 1) return -1;
      if (a.status != 1 && b.status == 1) return 1;
      if (a.completePercent == 100 && b.completePercent != 100) return -1;
      if (a.completePercent != 100 && b.completePercent == 100) return 1;
      return 0;
    });

    final actualPumps = <PumpModel>[];
    if (matchedLine != null) {
      for (var src in matchedLine.inletSources) {
        actualPumps.addAll(src.inletPump);
        actualPumps.addAll(src.outletPump);
      }
      for (var src in matchedLine.outletSources) {
        actualPumps.addAll(src.inletPump);
        actualPumps.addAll(src.outletPump);
      }
    }
    if (actualPumps.isEmpty) {
      for (var line in widget.masterController.irrigationLine) {
        for (var src in line.inletSources) {
          actualPumps.addAll(src.inletPump);
          actualPumps.addAll(src.outletPump);
        }
        for (var src in line.outletSources) {
          actualPumps.addAll(src.inletPump);
          actualPumps.addAll(src.outletPump);
        }
      }
    }

    List<_PumpDisplayData> pumpItems = [];
    if (actualPumps.isNotEmpty) {
      for (var p in actualPumps) {
        int pStatus = p.status;
        final sNoKeys = [
          p.sNo.toString(),
          p.sNo.toInt().toString(),
          p.sNo.toStringAsFixed(2),
          p.sNo.toStringAsFixed(3),
        ];
        for (final k in sNoKeys) {
          final pStatusStr = mqttProvider.getPumpOnOffStatus(k);
          if (pStatusStr != null && pStatusStr.contains(',')) {
            final parts = pStatusStr.split(',');
            if (parts.length > 1) {
              final st = int.tryParse(parts[1].trim());
              if (st != null) {
                pStatus = st;
                break;
              }
            }
          }
        }
        pumpItems.add(_PumpDisplayData(
          name: p.name.isNotEmpty ? p.name : 'Pump ${pumpItems.length + 1}',
          status: pStatus,
        ));
      }

      pumpItems.sort((a, b) {
        if (a.status == 1 && b.status != 1) return -1;
        if (a.status != 1 && b.status == 1) return 1;
        return 0;
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'Active Valves (${currentProg.lineName})',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 1: Valves (standalone icon with name below matching Figma)
        SizedBox(
          height: 54,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: valveItems.map((v) {
                final isRunning = v.status == 1;
                return Container(
                  margin: const EdgeInsets.only(right: 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 34,
                        height: 34,
                        child: AppConstants.getAsset(
                            'valve', v.status, '', v.completePercent),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 50,
                        child: Text(
                          v.name,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isRunning
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isRunning
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF64748B),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Row 2: Pumps (standalone icon with name below matching Figma)
        if (pumpItems.isNotEmpty)
          SizedBox(
            height: 54,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: pumpItems.map((p) {
                  final isRunning = p.status == 1;
                  return Container(
                    margin: const EdgeInsets.only(right: 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 34,
                          height: 34,
                          child: AppConstants.getAsset('pump', p.status, '', 0),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 50,
                          child: Text(
                            p.name,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isRunning
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isRunning
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF64748B),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  // TAB 4: LINE DETAILS & VALVE STATUS TAB (renders full pipeline with ValveStatusLegend + CurrentProgram + NextSchedule + ScheduledProgramWide)
  Widget _buildLineDetailsTabContent(bool isMiddle) {
    final cM = widget.masterController;
    final scheduledProgram = cM.programList;
    final hasProgramOnOff = cM.getPermissionStatus("Program On/Off Manually");
    final hasLinePP =
        cM.getPermissionStatus("Irrigation Line Pause/Resume Manually");
    final isAquaculture =
        [...AppConstants.aquacultureModelList].contains(cM.modelId);
    final isOMS = [...AppConstants.omsGemList].contains(cM.modelId);
    final isNova = [...AppConstants.ecoGemModelList].contains(cM.modelId);

    final irrigationLines = widget.masterController.irrigationLine;
    final linesToDisplay =
        (widget.viewModel.myCurrentIrrLine == "All irrigation line" ||
                widget.viewModel.myCurrentIrrLine == "All Aquaculture line" ||
                widget.viewModel.myCurrentIrrLine.isEmpty)
            ? irrigationLines
                .where((line) => line.name != widget.viewModel.myCurrentIrrLine)
                .toList()
            : irrigationLines
                .where((line) => line.name == widget.viewModel.myCurrentIrrLine)
                .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isOMS) buildValveStatusLegend(isAquaculture),
        const SizedBox(height: 14),
        if (isOMS)
          OmsLine(
            customerId: widget.customerId,
            controllerId: widget.controllerId,
            modelId: widget.modelId,
            deviceId: widget.deviceId,
            master: cM,
            groupId: widget.viewModel.mySiteList.data.isNotEmpty
                ? widget
                    .viewModel.mySiteList.data[widget.viewModel.sIndex].groupId
                : 0,
            isNarrow: false,
          )
        else
          ...linesToDisplay.map((line) {
            final inletWaterSources = {
              for (var source in line.inletSources) source.sNo: source
            }.values.toList();

            final outletWaterSources = {
              for (var source in line.outletSources) source.sNo: source
            }.values.toList();

            final cFilterSite = {
              if (line.centralFilterSite != null)
                line.centralFilterSite!.sNo: line.centralFilterSite!
            }.values.toList();

            final cFertilizerSite = {
              if (line.centralFertilizerSite != null)
                line.centralFertilizerSite!.sNo: line.centralFertilizerSite!
            }.values.toList();

            final lFilterSite = {
              if (line.localFilterSite != null)
                line.localFilterSite!.sNo: line.localFilterSite!
            }.values.toList();

            final lFertilizerSite = {
              if (line.localFertilizerSite != null)
                line.localFertilizerSite!.sNo: line.localFertilizerSite!
            }.values.toList();

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Text(
                          line.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        if (!isNova && hasLinePP) ...[
                          const Spacer(),
                          SizedBox(
                            height: 27,
                            child: MyMaterialButton(
                              buttonId: 'line_${line.sNo}_4900',
                              label: line.linePauseFlag == 0
                                  ? 'Pause the line'
                                  : 'Resume the line',
                              payloadKey: "4900",
                              payloadValue:
                                  "${line.sNo},${line.linePauseFlag == 0 ? 1 : 0}",
                              color: line.linePauseFlag == 0
                                  ? Colors.orangeAccent
                                  : Colors.green,
                              textColor: Colors.white,
                              serverMsg: line.linePauseFlag == 0
                                  ? 'Paused the ${line.name}'
                                  : 'Resumed the ${line.name}',
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ],
                    ),
                  ),
                  isAquaculture
                      ? AquacultureLine(
                          irrLine: line,
                          customerId: widget.customerId,
                          controllerId: widget.controllerId,
                          modelId: widget.modelId,
                          deviceId: widget.deviceId,
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: IrrigationLineWide(
                            inletWaterSources: inletWaterSources,
                            outletWaterSources: outletWaterSources,
                            cFilterSite: cFilterSite,
                            cFertilizerSite: cFertilizerSite,
                            lFilterSite: lFilterSite,
                            lFertilizerSite: lFertilizerSite,
                            valves: line.valveObjects,
                            mainValves: line.mainValveObjects,
                            lights: line.lightObjects,
                            fans: line.fanObjects,
                            gates: line.gateObjects,
                            fogger: line.foggerObjects,
                            prsSwitch: line.prsSwitch,
                            pressureIn: line.pressureIn,
                            pressureOut: line.pressureOut,
                            waterMeter: line.waterMeter,
                            humidity: line.humiditySensor,
                            co2: line.co2Sensor,
                            temperature: line.temperature,
                            soilTemperature: line.soilTemperature,
                            customerId: widget.customerId,
                            controllerId: widget.controllerId,
                            containerWidth: MediaQuery.sizeOf(context).width,
                            deviceId: widget.deviceId,
                            modelId: widget.modelId,
                            isNava: false,
                          ),
                        ),
                ],
              ),
            );
          }),
        const SizedBox(height: 12),
        // CURRENT SCHEDULE (displays sequence running value name, status, remaining, flow)
        CurrentProgram(
          scheduledPrograms: scheduledProgram,
          deviceId: cM.deviceId,
          customerId: widget.customerId,
          controllerId: widget.controllerId,
          currentLineSNo: cM.irrigationLine.isNotEmpty &&
                  widget.viewModel.lIndex < cM.irrigationLine.length
              ? cM.irrigationLine[widget.viewModel.lIndex].sNo
              : 1,
          modelId: cM.modelId,
          skipPermission: hasProgramOnOff,
        ),
        if (scheduledProgram.isNotEmpty) ...[
          const SizedBox(height: 12),
          // NEXT SCHEDULE IN QUEUE
          NextSchedule(scheduledPrograms: scheduledProgram),
          const SizedBox(height: 12),
          // SCHEDULED PROGRAM (displays percentage MQTT box value: 35%, 87%, 100%)
          ScheduledProgramWide(
            userId: widget.customerId,
            scheduledPrograms: scheduledProgram,
            controllerId: cM.controllerId,
            deviceId: cM.deviceId,
            customerId: widget.customerId,
            currentLineSNo: cM.irrigationLine.isNotEmpty &&
                    widget.viewModel.lIndex < cM.irrigationLine.length
                ? cM.irrigationLine[widget.viewModel.lIndex].sNo
                : 1,
            groupId: widget.viewModel.mySiteList.data.isNotEmpty
                ? widget
                    .viewModel.mySiteList.data[widget.viewModel.sIndex].groupId
                : 0,
            categoryId: cM.categoryId,
            modelId: cM.modelId,
            deviceName: cM.deviceName,
            categoryName: cM.categoryName,
            prgOnOffPermission: hasProgramOnOff,
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAlertsCard() {
    List<_AlertItemData> alerts = [];

    if (widget.viewModel.isNotCommunicate) {
      alerts.add(_AlertItemData(
        type: 'CRITICAL',
        title: 'No communication to controller',
        subtitle: 'Controller is offline · Check network or power supply',
        time: DateFormat('hh:mm a').format(DateTime.now()),
        badgeBg: const Color(0xFFDC2626),
        containerBorder: const Color(0xFFFECACA),
        containerBg: const Color(0xFFFFF1F2),
      ));
    }

    if (_livePrograms.isEmpty) {
      alerts.add(_AlertItemData(
        type: 'INFO',
        title: 'System Idle',
        subtitle:
            'All irrigation lines are currently idle · Ready for operation',
        time: DateFormat('hh:mm a').format(DateTime.now()),
        badgeBg: const Color(0xFF3B82F6),
        containerBorder: const Color(0xFFBFDBFE),
        containerBg: const Color(0xFFEFF6FF),
      ));
    } else {
      alerts.add(_AlertItemData(
        type: 'INFO',
        title: 'Irrigation Active',
        subtitle: '${_livePrograms.length} program(s) actively irrigating',
        time: DateFormat('hh:mm a').format(DateTime.now()),
        badgeBg: const Color(0xFF16A34A),
        containerBorder: const Color(0xFFBBF7D0),
        containerBg: const Color(0xFFF0FDF4),
      ));
      if (_livePrograms.any((p) => p.isPaused)) {
        alerts.add(_AlertItemData(
          type: 'WARNING',
          title: 'Program Paused',
          subtitle: 'Active zone is currently paused by operator',
          time: DateFormat('hh:mm a').format(DateTime.now()),
          badgeBg: const Color(0xFFF59E0B),
          containerBorder: const Color(0xFFFED7AA),
          containerBg: const Color(0xFFFFFBEB),
        ));
      }
    }

    final openCount =
        alerts.where((a) => a.type == 'CRITICAL' || a.type == 'WARNING').length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Alerts',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
              const Spacer(),
              Text('$openCount open',
                  style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          ...alerts.map((alert) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: alert.containerBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: alert.containerBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: alert.badgeBg,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  alert.type,
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                alert.title,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(alert.subtitle,
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(alert.time,
                        style: const TextStyle(
                            fontSize: 9.5,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // BOTTOM IRRIGATION SEGMENTS (Driven dynamically by masterController.programList with Figma Card Styling)
  Widget _buildIrrigationSegmentsSection() {
    final programs = widget.masterController.programList;
    final runningCount = _livePrograms.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Irrigation Segments',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            Text(
              '$runningCount of ${programs.length} running',
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (programs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            alignment: Alignment.center,
            child: const Column(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 32, color: Color(0xFF94A3B8)),
                SizedBox(height: 8),
                Text(
                  'No irrigation programs configured for this controller.',
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          )
        else
          ...programs.map((prog) {
            final liveProg = _livePrograms
                .where((p) =>
                    p.programId == prog.serialNumber.toString() ||
                    p.programName.toLowerCase().trim() ==
                        prog.programName.toLowerCase().trim())
                .firstOrNull;

            final isRunning = liveProg != null;

            final isPaused = (liveProg != null && liveProg.isPaused) ||
                prog.prgPauseResume == '1' ||
                prog.prgPauseResume == '3';

            final isCompleted = prog.programStatusPercentage >= 100;

            final reasonStr =
                MyFunction().getContentByCode(prog.startStopReason);
            final isSkipped = reasonStr.toLowerCase().contains('skip') ||
                reasonStr.toLowerCase().contains('pause') ||
                prog.pauseResumeReason != 0;

            // 4 Card States & Colors matching exact Figma design
            Color accentColor;
            Color statusBg;
            Color statusColor;
            String statusText;
            String actionLabel;
            IconData actionIcon;
            Color actionColor;

            if (isRunning) {
              if (isPaused) {
                accentColor = const Color(0xFFF59E0B); // Orange / Paused
                statusBg = const Color(0xFFFEF3C7);
                statusColor = const Color(0xFFD97706);
                statusText = 'Paused';
                actionLabel = 'Resume';
                actionIcon = Icons.play_arrow_rounded;
                actionColor = const Color(0xFFF59E0B);
              } else {
                accentColor = const Color(0xFF10B981); // Green / Running
                statusBg = const Color(0xFFDCFCE7);
                statusColor = const Color(0xFF16A34A);
                statusText = 'Running';
                actionLabel = 'Pause';
                actionIcon = Icons.pause_rounded;
                actionColor = const Color(0xFF10B981);
              }
            } else if (isCompleted) {
              accentColor = const Color(0xFF3B82F6); // Blue / Completed
              statusBg = const Color(0xFFDBEAFE);
              statusColor = const Color(0xFF2563EB);
              statusText = 'Completed';
              actionLabel = 'Completed';
              actionIcon = Icons.bolt_rounded;
              actionColor = const Color(0xFF3B82F6);
            } else if (isSkipped) {
              accentColor = const Color(0xFFF59E0B); // Orange / Skipped
              statusBg = const Color(0xFFFEF3C7);
              statusColor = const Color(0xFFD97706);
              statusText = 'Skipped';
              actionLabel = 'Stop';
              actionIcon = Icons.stop_rounded;
              actionColor = const Color(0xFFF59E0B);
            } else {
              // Stopped / Ready - Red Card matching Figma Segment 03
              accentColor = const Color(0xFFEF4444); // Red
              statusBg = const Color(0xFFFEE2E2);
              statusColor = const Color(0xFFDC2626);
              statusText = 'Stopped';
              actionLabel = 'Start';
              actionIcon = Icons.play_arrow_rounded;
              actionColor = const Color(0xFFEF4444);
            }

            final flowStr =
                isRunning ? (liveProg?.avgFlowRate ?? '18.89 l/s') : '0 L/min';
            final pressureStr = isRunning
                ? '2.4 bar'
                : (isCompleted ? '0.5 bar' : (isSkipped ? '2.1 bar' : '0.5 bar'));
            final moistureStr = isRunning
                ? '24%'
                : (isCompleted ? '42%' : (isSkipped ? '38%' : '42%'));

            String lastIrrigatedStr = '--:--';
            if (prog.startDate.isNotEmpty && prog.startDate != '-') {
              final formattedDate =
                  Formatters().changeDateFormat(prog.startDate);
              final formattedTime = prog.startTime.contains(':')
                  ? MyFunction().convert24HourTo12Hour(prog.startTime)
                  : prog.startTime;
              lastIrrigatedStr = '$formattedDate : $formattedTime';
            }

            final lineNameStr = prog.irrigationLine.isNotEmpty
                ? 'Line ${prog.irrigationLine[0]}'
                : (prog.defaultProgramName.isNotEmpty
                    ? prog.defaultProgramName
                    : 'Irrigation Line');

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x04000000),
                      blurRadius: 6,
                      offset: Offset(0, 2)),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 700;
                  if (isWide) {
                    return Row(
                      children: [
                        // Title & Subtitle
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                prog.programName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                lineNameStr,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF64748B)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Status pill
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Metric 1: Soil Moisture
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Soil moisture',
                                  style: TextStyle(
                                      fontSize: 11, color: Color(0xFF64748B))),
                              const SizedBox(height: 3),
                              Text(
                                moistureStr,
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Metric 2: Pressure
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Pressure',
                                  style: TextStyle(
                                      fontSize: 11, color: Color(0xFF64748B))),
                              const SizedBox(height: 3),
                              Text(
                                pressureStr,
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Metric 3: Flow
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Flow',
                                  style: TextStyle(
                                      fontSize: 11, color: Color(0xFF64748B))),
                              const SizedBox(height: 3),
                              Text(
                                flowStr,
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Metric 4: Start Date / Time
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Last irrigated',
                                  style: TextStyle(
                                      fontSize: 11, color: Color(0xFF64748B))),
                              const SizedBox(height: 3),
                              Text(
                                lastIrrigatedStr,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Action Button
                        InkWell(
                          onTap: () {
                            if (isRunning && liveProg != null) {
                              _togglePause(liveProg);
                            } else {
                              _handleProgramAction(prog, isRunning, isPaused);
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: actionColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(actionIcon, size: 14, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  actionLabel,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 160,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prog.programName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  lineNameStr,
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Soil moisture',
                                  style: TextStyle(
                                      fontSize: 11, color: Color(0xFF64748B))),
                              const SizedBox(height: 3),
                              Text(
                                moistureStr,
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pressure',
                                  style: TextStyle(
                                      fontSize: 11, color: Color(0xFF64748B))),
                              const SizedBox(height: 3),
                              Text(
                                pressureStr,
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Flow',
                                  style: TextStyle(
                                      fontSize: 11, color: Color(0xFF64748B))),
                              const SizedBox(height: 3),
                              Text(
                                flowStr,
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Last irrigated',
                                  style: TextStyle(
                                      fontSize: 11, color: Color(0xFF64748B))),
                              const SizedBox(height: 3),
                              Text(
                                lastIrrigatedStr,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          InkWell(
                            onTap: () {
                              if (isRunning && liveProg != null) {
                                _togglePause(liveProg);
                              } else {
                                _handleProgramAction(prog, isRunning, isPaused);
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                color: actionColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(actionIcon, size: 14, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    actionLabel,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            );
          }),
      ],
    );
  }

  void _handleProgramAction(
      ProgramList prog, bool isRunning, bool isPaused) async {
    try {
      final serialNo = prog.serialNumber;
      if (isRunning) {
        final pauseVal = isPaused ? '3' : '2';
        final payload = jsonEncode({
          "2900": {"2901": '$serialNo,$pauseVal'}
        });
        await context.read<CommunicationService>().sendCommand(
              serverMsg:
                  '${prog.programName} ${isPaused ? 'Resumed' : 'Paused'}',
              payload: payload,
            );
        if (mounted) {
          GlobalSnackBar.show(
            context,
            '${prog.programName} ${isPaused ? 'Resumed' : 'Paused'} successfully',
            200,
          );
        }
      } else {
        final payload = jsonEncode({
          "2900": {"2901": '$serialNo,1'}
        });
        await context.read<CommunicationService>().sendCommand(
              serverMsg: '${prog.programName} Started',
              payload: payload,
            );
        if (mounted) {
          GlobalSnackBar.show(
            context,
            '${prog.programName} Started successfully',
            200,
          );
        }
      }
    } catch (e) {
      debugPrint("Error handling program action: $e");
    }
  }

  // =============================================================
  // TAB 1: WATER SOURCE MONITORING
  // =============================================================
  Widget _buildWaterSourceTabContent(bool isMiddle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWaterSourceMetricCardsRow(isMiddle),
        const SizedBox(height: 20),
        _buildWaterSourceMiddleSection(isMiddle),
        const SizedBox(height: 20),
        _buildWaterSourcesTableSection(),
      ],
    );
  }

  Widget _buildWaterSourceMetricCardsRow(bool isMiddle) {
    final cards = [
      _MetricCardData(
        title: 'Total Water Sources',
        value: '4',
        unit: ' Sources',
        subtitle: '2 Borewells · 2 Tanks',
        subtitleColor: const Color(0xFF2563EB),
        icon: Icons.water_rounded,
        iconColor: const Color(0xFF2563EB),
        glowColor: const Color(0xFF3B82F6),
      ),
      _MetricCardData(
        title: 'Active Delivery Pumps',
        value: '1',
        unit: ' / 5',
        subtitle: 'Pump 1 Running',
        subtitleColor: const Color(0xFF16A34A),
        icon: Icons.power_settings_new_rounded,
        iconColor: const Color(0xFF10B981),
        glowColor: const Color(0xFF10B981),
      ),
      _MetricCardData(
        title: 'Delivery Flow Rate',
        value: '186',
        unit: ' L/min',
        unitColor: const Color(0xFFD97706),
        subtitle: 'Water Meter 3 & 4',
        subtitleColor: const Color(0xFF64748B),
        icon: Icons.speed_rounded,
        iconColor: const Color(0xFFF59E0B),
        glowColor: const Color(0xFFF59E0B),
      ),
      _MetricCardData(
        title: 'Water Source Level',
        value: 'Low',
        unit: '',
        subtitle: 'Source 1 & 2 Warning',
        subtitleColor: const Color(0xFFD97706),
        icon: Icons.opacity_rounded,
        iconColor: const Color(0xFF06B6D4),
        glowColor: const Color(0xFF06B6D4),
      ),
      _MetricCardData(
        title: 'Today Water Drawn',
        value: '14,800',
        unit: ' L',
        subtitle: '▲ +5% vs yesterday',
        subtitleColor: const Color(0xFF64748B),
        icon: Icons.water_drop_rounded,
        iconColor: const Color(0xFF8B5CF6),
        glowColor: const Color(0xFF8B5CF6),
      ),
    ];

    if (isMiddle) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: cards.map((card) {
            return Container(
              width: 200,
              margin: const EdgeInsets.only(right: 12),
              child: _buildMetricCard(card),
            );
          }).toList(),
        ),
      );
    }

    return Row(
      children: cards.map((card) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildMetricCard(card),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWaterSourceMiddleSection(bool isMiddle) {
    if (isMiddle) {
      return Column(
        children: [
          _buildLiveSourceDeliveryCard(),
          const SizedBox(height: 16),
          _buildWaterSourceAlertsCard(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 7, child: _buildLiveSourceDeliveryCard()),
        const SizedBox(width: 16),
        Expanded(flex: 5, child: _buildWaterSourceAlertsCard()),
      ],
    );
  }

  Widget _buildLiveSourceDeliveryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Live Source Delivery',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(4)),
                child: const Text('LIVE',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('●',
                        style:
                            TextStyle(color: Color(0xFF16A34A), fontSize: 10)),
                    SizedBox(width: 4),
                    Text('Pump 1 Active',
                        style: TextStyle(
                            color: Color(0xFF16A34A),
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CustomPaint(
                        painter: _CircularGaugePainter(68),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('68%',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A))),
                              Text('Capacity',
                                  style: TextStyle(
                                      fontSize: 10, color: Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                          color: const Color(0xFF0284C7),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pause, size: 13, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Pause pump',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('●',
                            style: TextStyle(
                                fontSize: 8, color: Color(0xFF334155))),
                        SizedBox(width: 3),
                        Text('○',
                            style: TextStyle(
                                fontSize: 8, color: Color(0xFFCBD5E1))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Container(
                    width: 1, height: 120, color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 16),
                SizedBox(
                  width: 250,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Source 1 — Main Borewell',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      const Text('Started 6:00 AM · Delivering to Line 1',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF64748B))),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4)),
                        child: const Text('● Low Water Alert',
                            style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFD97706))),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: _MetricItem(
                                        label: 'Water Meter 3',
                                        value: '0 L/s (0 lph)')),
                                Expanded(
                                    child: _MetricItem(
                                        label: 'Water Meter 4',
                                        value: '0.00 L/s')),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                    child: _MetricItem(
                                        label: 'Pump 1 Voltage',
                                        value: '415 V')),
                                Expanded(
                                    child: _MetricItem(
                                        label: 'Pump 1 Current',
                                        value: '12.4 A')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                    width: 1, height: 120, color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Source Pumps & Tanks',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A))),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildSourceIconItem(
                            asset: 'assets/png/booster_pump_g.png',
                            label: 'Pump 1',
                            isActive: true),
                        _buildSourceIconItem(
                            asset: 'assets/png/booster_pump_g.png',
                            label: 'Pump 2',
                            isActive: false),
                        _buildSourceIconItem(
                            asset: 'assets/png/booster_pump_g.png',
                            label: 'Pump 3',
                            isActive: false),
                        _buildSourceIconItem(
                            asset: 'assets/png/booster_pump_g.png',
                            label: 'Pump 6',
                            isActive: false),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildSourceTagItem(label: 'Source 1', isAlert: true),
                        _buildSourceTagItem(label: 'Source 2', isAlert: true),
                        _buildSourceTagItem(label: 'Source 3', isAlert: false),
                        _buildSourceTagItem(label: 'Source 25', isAlert: false),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceIconItem(
      {required String asset, required String label, required bool isActive}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        children: [
          Image.asset(
            asset,
            width: 24,
            height: 24,
            color: isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
            errorBuilder: (_, __, ___) => Icon(
              Icons.power_settings_new,
              size: 22,
              color:
                  isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color:
                  isActive ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceTagItem({required String label, required bool isAlert}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isAlert ? const Color(0xFFFEF3C7) : const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
              color:
                  isAlert ? const Color(0xFFFDE68A) : const Color(0xFFA7F3D0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isAlert ? const Color(0xFFD97706) : const Color(0xFF047857),
          ),
        ),
      ),
    );
  }

  Widget _buildWaterSourceAlertsCard() {
    final alerts = [
      _AlertItemData(
        type: 'CRITICAL',
        title: 'Source 1 Low Water Level',
        subtitle:
            'Borewell water level dropped below sensor threshold (Low flag active)',
        time: '10:14 AM',
        badgeBg: const Color(0xFFDC2626),
        containerBorder: const Color(0xFFFECACA),
        containerBg: const Color(0xFFFFF1F2),
      ),
      _AlertItemData(
        type: 'WARNING',
        title: 'Source 2 Low Level Warning',
        subtitle: 'Open Well sensor indicates low replenishment rate',
        time: '10:02 AM',
        badgeBg: const Color(0xFFF59E0B),
        containerBorder: const Color(0xFFFED7AA),
        containerBg: const Color(0xFFFFFBEB),
      ),
      _AlertItemData(
        type: 'INFO',
        title: 'Source 3 Tank At 82%',
        subtitle:
            'Main storage reservoir fully replenished and ready for irrigation cycle',
        time: '08:30 AM',
        badgeBg: const Color(0xFF10B981),
        containerBorder: const Color(0xFFA7F3D0),
        containerBg: const Color(0xFFECFDF5),
      ),
      _AlertItemData(
        type: 'INFO',
        title: 'Water Meter 4 Ready',
        subtitle:
            'Source 25 distribution line calibrated and monitoring standby flow',
        time: '07:15 AM',
        badgeBg: const Color(0xFF3B82F6),
        containerBorder: const Color(0xFFBFDBFE),
        containerBg: const Color(0xFFEFF6FF),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('Water Source Alerts',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
              Spacer(),
              Text('2 open',
                  style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          ...alerts.map((alert) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: alert.containerBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: alert.containerBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                    color: alert.badgeBg,
                                    borderRadius: BorderRadius.circular(3)),
                                child: Text(alert.type,
                                    style: const TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.3)),
                              ),
                              const SizedBox(width: 6),
                              Text(alert.title,
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B))),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(alert.subtitle,
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(alert.time,
                        style: const TextStyle(
                            fontSize: 9.5,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWaterSourcesTableSection() {
    final sourceRows = [
      _WaterSourceRowData(
        sourceName: 'Source 1',
        sourceType: 'Borewell · Inlet',
        status: 'Low Level',
        statusBg: const Color(0xFFFEF3C7),
        statusColor: const Color(0xFFD97706),
        accentColor: const Color(0xFFF59E0B),
        level: '18 ft (Low Alert)',
        connectedPump: 'Pump 1',
        pumpStatus: 'Running ●',
        pumpStatusColor: const Color(0xFF16A34A),
        waterMeter: 'WM 3: 0 L/s',
        powerMetrics: '415 V · 12.4 A',
        actionLabel: 'Stop Pump',
        actionIcon: Icons.stop,
        actionColor: const Color(0xFFD97706),
      ),
      _WaterSourceRowData(
        sourceName: 'Source 2',
        sourceType: 'Open Well · Inlet',
        status: 'Low Level',
        statusBg: const Color(0xFFFEF3C7),
        statusColor: const Color(0xFFD97706),
        accentColor: const Color(0xFFF59E0B),
        level: '22 ft (Low Alert)',
        connectedPump: 'Pump 2',
        pumpStatus: 'Standby ○',
        pumpStatusColor: const Color(0xFF64748B),
        waterMeter: '--',
        powerMetrics: '0 V · 0 A',
        actionLabel: 'Start Pump',
        actionIcon: Icons.play_arrow,
        actionColor: const Color(0xFF059669),
      ),
      _WaterSourceRowData(
        sourceName: 'Source 3',
        sourceType: 'Storage Tank · Main',
        status: 'Optimal',
        statusBg: const Color(0xFFDCFCE7),
        statusColor: const Color(0xFF16A34A),
        accentColor: const Color(0xFF10B981),
        level: '82% (Full)',
        connectedPump: 'Pump 3 & Pump 4',
        pumpStatus: 'Standby ○',
        pumpStatusColor: const Color(0xFF64748B),
        waterMeter: '--',
        powerMetrics: '0 V · 0 A',
        actionLabel: 'Start Pump',
        actionIcon: Icons.play_arrow,
        actionColor: const Color(0xFF059669),
      ),
      _WaterSourceRowData(
        sourceName: 'Source 25',
        sourceType: 'Sump Tank · Distribution',
        status: 'Optimal',
        statusBg: const Color(0xFFCFFAFE),
        statusColor: const Color(0xFF0891B2),
        accentColor: const Color(0xFF06B6D4),
        level: '76% (Optimal)',
        connectedPump: 'Pump 6',
        pumpStatus: 'Standby ○',
        pumpStatusColor: const Color(0xFF64748B),
        waterMeter: 'WM 4: 0.00 L/s',
        powerMetrics: '0 V · 0 A',
        actionLabel: 'Start Pump',
        actionIcon: Icons.play_arrow,
        actionColor: const Color(0xFF059669),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('Water Sources & Extraction Pumps',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
              Spacer(),
              Text('4 sources configured',
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 14),
          ...sourceRows.map((row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: row.accentColor.withOpacity(0.35)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 800),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                              width: 4, height: 48, color: row.accentColor),
                          const SizedBox(width: 14),
                          SizedBox(
                            width: 130,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(row.sourceName,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A))),
                                const SizedBox(height: 2),
                                Text(row.sourceType,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3.5),
                                decoration: BoxDecoration(
                                    color: row.statusBg,
                                    borderRadius: BorderRadius.circular(20)),
                                child: Text(row.status,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: row.statusColor)),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Level / Sensor',
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        color: Color(0xFF64748B))),
                                const SizedBox(height: 2),
                                Text(row.level,
                                    style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A))),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 130,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Connected Pump',
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        color: Color(0xFF64748B))),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(row.connectedPump,
                                        style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F172A))),
                                    const SizedBox(width: 4),
                                    Text(row.pumpStatus,
                                        style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: row.pumpStatusColor)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 110,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Flow / Meter',
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        color: Color(0xFF64748B))),
                                const SizedBox(height: 2),
                                Text(row.waterMeter,
                                    style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A))),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 110,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Power Metrics',
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        color: Color(0xFF64748B))),
                                const SizedBox(height: 2),
                                Text(row.powerMetrics,
                                    style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A))),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 7),
                              decoration: BoxDecoration(
                                  color: row.actionColor,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(row.actionIcon,
                                      size: 14, color: Colors.white),
                                  const SizedBox(width: 5),
                                  Text(row.actionLabel,
                                      style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // =============================================================
  // TAB 2: BACKWASH MONITORING
  // =============================================================
  Widget _buildBackwashTabContent(bool isMiddle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(_MetricCardData(
                title: 'Total Filters',
                value: '1',
                unit: ' Filter',
                subtitle: 'Filter 1 Online',
                subtitleColor: const Color(0xFF16A34A),
                icon: Icons.filter_alt_outlined,
                iconColor: const Color(0xFF0D9488),
                glowColor: const Color(0xFF0D9488),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(_MetricCardData(
                title: 'Differential Pressure',
                value: '0.35',
                unit: ' bar',
                subtitle: 'Optimal (Limit 0.8 bar)',
                subtitleColor: const Color(0xFF16A34A),
                icon: Icons.speed_rounded,
                iconColor: const Color(0xFFF59E0B),
                glowColor: const Color(0xFFF59E0B),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(_MetricCardData(
                title: 'Last Backwash',
                value: '2.5',
                unit: ' hrs ago',
                subtitle: 'Success (Duration 90s)',
                subtitleColor: const Color(0xFF64748B),
                icon: Icons.history,
                iconColor: const Color(0xFF2563EB),
                glowColor: const Color(0xFF3B82F6),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(_MetricCardData(
                title: 'Auto Flush Mode',
                value: 'Auto',
                unit: '',
                subtitle: 'Every 4 hrs or DP trigger',
                subtitleColor: const Color(0xFF8B5CF6),
                icon: Icons.settings_backup_restore,
                iconColor: const Color(0xFF8B5CF6),
                glowColor: const Color(0xFF8B5CF6),
              )),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Filter 1 Status',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A))),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                        color: const Color(0xFF0D9488),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      children: [
                        Icon(Icons.refresh, size: 14, color: Colors.white),
                        SizedBox(width: 5),
                        Text('Trigger Manual Backwash',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                  'Inlet Pressure: 2.8 bar · Outlet Pressure: 2.45 bar · Delta P: 0.35 bar (Normal).',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
            ],
          ),
        ),
      ],
    );
  }

  // =============================================================
  // TAB 3: FERTILIZER MONITORING
  // =============================================================
  Widget _buildFertilizerTabContent(bool isMiddle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(_MetricCardData(
                title: 'Fertilizer Tanks',
                value: '6',
                unit: ' Tanks',
                subtitle: 'Source 5 to Source 10',
                subtitleColor: const Color(0xFF06B6D4),
                icon: Icons.science_outlined,
                iconColor: const Color(0xFF06B6D4),
                glowColor: const Color(0xFF06B6D4),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(_MetricCardData(
                title: 'Booster Pump',
                value: 'Pump 5',
                unit: '',
                subtitle: 'Running (Main Source 4)',
                subtitleColor: const Color(0xFF16A34A),
                icon: Icons.power_settings_new,
                iconColor: const Color(0xFF10B981),
                glowColor: const Color(0xFF10B981),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(_MetricCardData(
                title: 'Active Injectors',
                value: '4',
                unit: ' Channels',
                subtitle: 'Injectors 1, 2, 3, 4',
                subtitleColor: const Color(0xFF8B5CF6),
                icon: Icons.alt_route,
                iconColor: const Color(0xFF8B5CF6),
                glowColor: const Color(0xFF8B5CF6),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(_MetricCardData(
                title: 'Agitator Status',
                value: 'Active',
                unit: '',
                subtitle: 'Agitator 1 Mixing',
                subtitleColor: const Color(0xFF16A34A),
                icon: Icons.rotate_right,
                iconColor: const Color(0xFFF59E0B),
                glowColor: const Color(0xFFF59E0B),
              )),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Fertilizer Tanks & Tank Valves',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
              const SizedBox(height: 12),
              const Text(
                  'Source 4 (Main Fert Source) · Pump 5 Active · Tank Valves 1 through 17 configured.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildSourceTagItem(
                      label: 'Source 5 (Tank 1)', isAlert: false),
                  _buildSourceTagItem(
                      label: 'Source 6 (Tank 2)', isAlert: false),
                  _buildSourceTagItem(
                      label: 'Source 7 (Tank 3)', isAlert: false),
                  _buildSourceTagItem(
                      label: 'Source 8 (Tank 4)', isAlert: false),
                  _buildSourceTagItem(
                      label: 'Source 9 (Tank 5)', isAlert: false),
                  _buildSourceTagItem(
                      label: 'Source 10 (Tank 6)', isAlert: false),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =============================================================
  // TAB 5: NODE MONITORING
  // =============================================================
  Widget _buildNodeMonitoringTabContent(bool isMiddle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(_MetricCardData(
                title: 'Connected Nodes',
                value: '6',
                unit: ' Nodes',
                subtitle: 'All Online ●',
                subtitleColor: const Color(0xFF16A34A),
                icon: Icons.hub_outlined,
                iconColor: const Color(0xFF2563EB),
                glowColor: const Color(0xFF3B82F6),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(_MetricCardData(
                title: 'Average Battery',
                value: '94%',
                unit: '',
                subtitle: 'Solar Charging Active',
                subtitleColor: const Color(0xFF16A34A),
                icon: Icons.battery_charging_full,
                iconColor: const Color(0xFF10B981),
                glowColor: const Color(0xFF10B981),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(_MetricCardData(
                title: 'RF Signal Strength',
                value: '-68',
                unit: ' dBm',
                subtitle: 'Strong Connection',
                subtitleColor: const Color(0xFF16A34A),
                icon: Icons.wifi,
                iconColor: const Color(0xFF06B6D4),
                glowColor: const Color(0xFF06B6D4),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(_MetricCardData(
                title: 'Active Valves on Nodes',
                value: '12',
                unit: ' Valves',
                subtitle: '4 Open · 8 Closed',
                subtitleColor: const Color(0xFF64748B),
                icon: Icons.settings_input_component,
                iconColor: const Color(0xFF8B5CF6),
                glowColor: const Color(0xFF8B5CF6),
              )),
            ),
          ],
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// HELPER MODELS & PAINTERS
// -------------------------------------------------------------
class _MetricCardData {
  final String title;
  final String value;
  final String unit;
  final Color? unitColor;
  final String subtitle;
  final Color subtitleColor;
  final IconData icon;
  final Color iconColor;
  final Color glowColor;

  _MetricCardData({
    required this.title,
    required this.value,
    required this.unit,
    this.unitColor,
    required this.subtitle,
    required this.subtitleColor,
    required this.icon,
    required this.iconColor,
    required this.glowColor,
  });
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  const _MetricItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

class _AlertItemData {
  final String type;
  final String title;
  final String subtitle;
  final String time;
  final Color badgeBg;
  final Color containerBorder;
  final Color containerBg;

  _AlertItemData({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.badgeBg,
    required this.containerBorder,
    required this.containerBg,
  });
}

class _SegmentData {
  final String title;
  final String subtitle;
  final String status;
  final Color statusBg;
  final Color statusColor;
  final Color accentColor;
  final String soilMoisture;
  final String pressure;
  final String flow;
  final String lastIrrigated;
  final String actionLabel;
  final IconData actionIcon;
  final Color actionColor;

  _SegmentData({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusBg,
    required this.statusColor,
    required this.accentColor,
    required this.soilMoisture,
    required this.pressure,
    required this.flow,
    required this.lastIrrigated,
    required this.actionLabel,
    required this.actionIcon,
    required this.actionColor,
  });
}

class _WaterSourceRowData {
  final String sourceName;
  final String sourceType;
  final String status;
  final Color statusBg;
  final Color statusColor;
  final Color accentColor;
  final String level;
  final String connectedPump;
  final String pumpStatus;
  final Color pumpStatusColor;
  final String waterMeter;
  final String powerMetrics;
  final String actionLabel;
  final IconData actionIcon;
  final Color actionColor;

  _WaterSourceRowData({
    required this.sourceName,
    required this.sourceType,
    required this.status,
    required this.statusBg,
    required this.statusColor,
    required this.accentColor,
    required this.level,
    required this.connectedPump,
    required this.pumpStatus,
    required this.pumpStatusColor,
    required this.waterMeter,
    required this.powerMetrics,
    required this.actionLabel,
    required this.actionIcon,
    required this.actionColor,
  });
}

class _CircularGaugePainter extends CustomPainter {
  final double percentage;
  _CircularGaugePainter(this.percentage);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;
    const strokeWidth = 8.0;

    final trackPaint = Paint()
      ..color = const Color(0xFFEDE9FE)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final sweepAngle =
        2 * 3.141592653589793 * (percentage.clamp(0.0, 100.0) / 100);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFF6366F1), Color(0xFF06B6D4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
        rect, -3.141592653589793 / 2, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _CircularGaugePainter oldDelegate) =>
      oldDelegate.percentage != percentage;
}
