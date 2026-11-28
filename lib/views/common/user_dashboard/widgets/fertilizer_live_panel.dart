import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hex/models/customer/site_model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../../../../StateManagement/mqtt_payload_provider.dart';
import '../../../../models/customer/extensions/program_extensions.dart';
import '../../../../models/customer/fertilizer_site_live_model.dart';
import '../../../../utils/constants.dart';
import '../../../../view_models/customer/customer_screen_controller_view_model.dart';

class _InjectorCardData {
  final String name;
  final bool isInProgress;
  final String durationStr;
  final double progress;
  final int percent;
  final String detail;

  const _InjectorCardData({
    required this.name,
    required this.isInProgress,
    required this.durationStr,
    required this.progress,
    required this.percent,
    required this.detail,
  });
}

class FertilizerLivePanel extends StatefulWidget {
  final String deviceId;
  final int controllerId;
  final int customerId;
  final bool isWide;

  const FertilizerLivePanel({
    super.key,
    required this.deviceId,
    required this.controllerId,
    required this.customerId,
    required this.isWide,
  });

  @override
  State<FertilizerLivePanel> createState() => _FertilizerLivePanelState();
}

class _FertilizerLivePanelState extends State<FertilizerLivePanel> {
  bool _isDisposed = false;
  late TooltipBehavior _tooltipBehavior;
  Timer? _liveTimer;
  final Map<String, int> _channelLiveElapsedSeconds = {};
  final Map<String, String> _lastChannelMqttCompleted = {};
  int? _fertLiveIrrigationSeconds;
  String? _lastFertMqttIrrigationCompleted;
  double? _selectedLineSNo;

  @override
  void initState() {
    super.initState();

    _tooltipBehavior = TooltipBehavior(
      enable: true,
      header: '',
      format: 'point.x : point.y',
    );

    _liveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      bool hasChanges = false;
      if (_channelLiveElapsedSeconds.isNotEmpty) {
        _channelLiveElapsedSeconds.forEach((k, v) {
          _channelLiveElapsedSeconds[k] = v + 1;
        });
        hasChanges = true;
      }
      if (_fertLiveIrrigationSeconds != null) {
        _fertLiveIrrigationSeconds = _fertLiveIrrigationSeconds! + 1;
        hasChanges = true;
      }
      if (hasChanges) {
        setState(() {});
      }
    });

    // Initial call
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CustomerScreenControllerViewModel>().onFertilizerLiveSync();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _liveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MqttPayloadProvider>(
      builder: (context, mqtt, _) {
        if (_isDisposed) {
          return const SizedBox.shrink();
        }

        if (mqtt.fertilizerSiteMap.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text("Waiting for live data..."),
            ),
          );
        }

        if (mqtt.fertilizerSiteMap.isEmpty ||
            mqtt.fertilizerSiteMap.values.first.valve.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text("No Live Data Available"),
            ),
          );
        }

        final viewModel =
            Provider.of<CustomerScreenControllerViewModel>(context);
        final master = viewModel
            .mySiteList.data[viewModel.sIndex].master[viewModel.mIndex];
        final linesWithFertilizer = master.irrigationLine
            .where((l) =>
                l.centralFertilizerSite != null ||
                l.localFertilizerSite != null)
            .toList();

        IrrigationLineModel? selectedLine;
        if (linesWithFertilizer.isNotEmpty) {
          if (_selectedLineSNo != null &&
              linesWithFertilizer.any((l) => l.sNo == _selectedLineSNo)) {
            selectedLine = linesWithFertilizer
                .firstWhere((l) => l.sNo == _selectedLineSNo);
          } else {
            for (final l in linesWithFertilizer) {
              final fs = l.centralFertilizerSite ?? l.localFertilizerSite;
              if (fs != null) {
                final sInt = fs.sNo.toInt().toString();
                final sStr = fs.sNo.toString();
                if (mqtt.fertilizerSiteMap.entries.any((e) =>
                    (e.key == sInt ||
                        e.key == sStr ||
                        double.tryParse(e.key) == fs.sNo) &&
                    (e.value.valve.isNotEmpty ||
                        e.value.pump.isNotEmpty ||
                        e.value.programSNo.isNotEmpty))) {
                  selectedLine = l;
                  break;
                }
              }
            }
            selectedLine ??= linesWithFertilizer.first;
            _selectedLineSNo = selectedLine.sNo;
          }
        }

        FertilizerSiteLiveModel? site;
        final selectedFertSite = selectedLine?.centralFertilizerSite ??
            selectedLine?.localFertilizerSite;
        if (selectedFertSite != null) {
          final sInt = selectedFertSite.sNo.toInt().toString();
          final sStr = selectedFertSite.sNo.toString();
          for (final entry in mqtt.fertilizerSiteMap.entries) {
            if (entry.key == sInt ||
                entry.key == sStr ||
                double.tryParse(entry.key) == selectedFertSite.sNo) {
              site = entry.value;
              break;
            }
          }
        }
        site ??= mqtt.fertilizerSiteMap.values.first;

        final scheduledProgram = viewModel.mySiteList.data[viewModel.sIndex]
            .master[viewModel.mIndex].programList;

        final bool hasLiveActive =
            site.programSNo.isNotEmpty && site.programSNo != "0";
        String programName = hasLiveActive
            ? scheduledProgram.getProgramName(site.programSNo)
            : '--';
        if (programName.isEmpty) {
          programName = hasLiveActive ? 'Program ${site.programSNo}' : '--';
        }
        String zoneName = hasLiveActive
            ? scheduledProgram.getSequenceName(site.programSNo, site.zoneSNo)
            : '--';
        if (zoneName.isEmpty) {
          zoneName = hasLiveActive ? 'Sequence ${site.zoneSNo}' : '--';
        }

        final configObjects = viewModel.mySiteList.data[viewModel.sIndex]
            .master[viewModel.mIndex].configObjects;

        //pump ----------------------------------------------------------------------
        List<double> pumpSerials = site.pump.isNotEmpty
            ? site.pump.split('_').map((e) => double.tryParse(e) ?? 0).toList()
            : [];
        List<String> pumpNames = pumpSerials
            .map((serial) => configObjects.getObjectName(serial))
            .toList();
        List<String> pumpStatuses =
            site.pumpStatus.isNotEmpty ? site.pumpStatus.split('_') : [];

        //valve---------------------------------------------------------------
        List<double> valveSerials = site.valve.isNotEmpty
            ? site.valve.split('_').map((e) => double.tryParse(e) ?? 0).toList()
            : [];
        List<String> valveNames = valveSerials
            .map((serial) => configObjects.getObjectName(serial))
            .toList();
        List<String> valveStatuses =
            site.valveStatus.isNotEmpty ? site.valveStatus.split('_') : [];

        //booster--------------------------------------------------------------------
        List<double> boosterSerials = site.booster.isNotEmpty
            ? site.booster
                .split('_')
                .map((e) => double.tryParse(e) ?? 0)
                .toList()
            : [];
        List<String> boosterNames = boosterSerials
            .map((serial) => configObjects.getObjectName(serial))
            .toList();
        List<String> boosterStatuses =
            site.boosterStatus.isNotEmpty ? site.boosterStatus.split('_') : [];

        //sensors==================================================================
        List<double> pressureInSerials = site.pressureIn.isNotEmpty
            ? site.pressureIn
                .split('_')
                .map((e) => double.tryParse(e) ?? 0)
                .toList()
            : [];
        List<String> pressureInNames = pressureInSerials
            .map((serial) => configObjects.getObjectName(serial))
            .toList();
        List<String> pressureInValues = site.pressureInValue.isNotEmpty
            ? site.pressureInValue.split('_')
            : [];

        List<double> pressureOutSerials = site.pressureOut.isNotEmpty
            ? site.pressureOut
                .split('_')
                .map((e) => double.tryParse(e) ?? 0)
                .toList()
            : [];
        List<String> pressureOutNames = pressureOutSerials
            .map((serial) => configObjects.getObjectName(serial))
            .toList();
        List<String> pressureOutValues = site.pressureOutValue.isNotEmpty
            ? site.pressureOutValue.split('_')
            : [];

        List<double> waterMeterSerials = site.waterMeter.isNotEmpty
            ? site.waterMeter
                .split('_')
                .map((e) => double.tryParse(e) ?? 0)
                .toList()
            : [];
        List<String> waterMeterNames = waterMeterSerials
            .map((serial) => configObjects.getObjectName(serial))
            .toList();
        List<String> waterMeterValues = site.waterMeterValue.isNotEmpty
            ? site.waterMeterValue.split('_')
            : [];

        //frt channel--------------------------------------------------------
        List<ChannelDurationBarModel> chartData = [];
        List<_InjectorCardData> injectors = [];

        List<double> channelSerials = site.fertilizerChannel.isNotEmpty
            ? site.fertilizerChannel
                .split('_')
                .map((e) => double.tryParse(e) ?? 0)
                .toList()
            : [];

        for (int chIndex = 0; chIndex < channelSerials.length; chIndex++) {
          final serial = channelSerials[chIndex];
          FertilizerChannelLiveModel? channel;
          final sInt = serial.toInt().toString();
          final sStr = serial.toString();
          for (final entry in mqtt.fertilizerChannelMap.entries) {
            if (entry.key == sInt ||
                entry.key == sStr ||
                double.tryParse(entry.key) == serial) {
              channel = entry.value;
              break;
            }
          }
          final rawName = configObjects.getObjectName(serial);
          String channelDisplayName;
          if (rawName.isNotEmpty) {
            channelDisplayName = rawName.replaceAll(RegExp(r'Injector\s*', caseSensitive: false), 'Channel ');
          } else {
            channelDisplayName = 'Channel ${chIndex + 1}';
          }

          final chOther = mqtt.getChannelOtherData(sStr) ??
              mqtt.getChannelOtherData(sInt) ??
              mqtt.getChannelOtherData(serial.toInt().toString());

          double totSec = 0;
          double compSec = 0;
          String totDurStr = '00:00:00';
          String compDurStr = '00:00:00';

          // Priority 1: Real-time channel data from 2407 MQTT topic (same as Old UI)
          if (chOther != null && chOther.isNotEmpty) {
            final parts = chOther.split(',');
            if (parts.length > 3) {
              totDurStr = parts[2];
              compDurStr = parts[3];
              totSec = _parseDuration(totDurStr);
              compSec = _parseDuration(compDurStr);
            }
          }
          // Priority 2: 7702 MQTT fertilizerChannelMap
          if (totSec == 0 && compSec == 0 && channel != null) {
            totDurStr = channel.fertilizerChannelDuration;
            compDurStr = channel.fertilizerChannelDurationCompleted;
            totSec = _parseDuration(totDurStr);
            compSec = _parseDuration(compDurStr);
          }

          final chStatusStr = mqtt.getChannelOnOffStatus(sStr) ??
              mqtt.getChannelOnOffStatus(sInt) ??
              mqtt.getChannelOnOffStatus(serial.toInt().toString());
          int channelStatus = 0;
          if (chStatusStr != null) {
            final parts = chStatusStr.split(',');
            if (parts.length > 1) {
              channelStatus = int.tryParse(parts[1]) ?? 0;
            }
          }

          final bool isChannelActive =
              channelStatus == 1 && programName != '--';
          final chKey = '${site.sNo}_${serial.toInt()}';

          if (isChannelActive) {
            if (_lastChannelMqttCompleted[chKey] != compDurStr) {
              _lastChannelMqttCompleted[chKey] = compDurStr;
              _channelLiveElapsedSeconds[chKey] = compSec.toInt();
            }
          } else {
            _channelLiveElapsedSeconds.remove(chKey);
            _lastChannelMqttCompleted.remove(chKey);
          }

          final int currentLiveSec = isChannelActive
              ? (_channelLiveElapsedSeconds[chKey] ?? compSec.toInt())
              : 0;
          final String displayTotDur =
              isChannelActive ? totDurStr : '00:00:00';
          final String displayCompDur = isChannelActive
              ? formatSeconds(currentLiveSec.toDouble())
              : '00:00:00';
          final double progressRatio = (isChannelActive && totSec > 0)
              ? (currentLiveSec / totSec).clamp(0.0, 1.0)
              : 0.0;
          final int pct = (progressRatio * 100).toInt();

          injectors.add(_InjectorCardData(
            name: channelDisplayName,
            isInProgress: isChannelActive,
            durationStr: displayTotDur,
            progress: progressRatio,
            percent: pct,
            detail: isChannelActive && totSec > 0
                ? '$displayCompDur / $displayTotDur'
                : '—',
          ));

          chartData.add(
            ChannelDurationBarModel(
              channel: channelDisplayName,
              total: totSec,
              completed: currentLiveSec.toDouble(),
            ),
          );
        }

        final String ecValue = site.ecDataList.isNotEmpty
            ? site.ecDataList.last.value.toStringAsFixed(2)
            : (site.ecData.isNotEmpty ? site.ecData : '--');
        final String phValue = site.phDataList.isNotEmpty
            ? site.phDataList.last.value.toStringAsFixed(2)
            : (site.phData.isNotEmpty ? site.phData : '--');

        final bool isTimeMethod = site.irrigationMethod.toLowerCase() == "1";
        String progressTitle = isTimeMethod
            ? 'Irrigation progress (Time)'
            : 'Irrigation progress (Quantity)';
        String progressRight = '';
        double progressRatio = 0.0;
        String remDurationHms = '';

        if (isTimeMethod) {
          final totSec = _parseDuration(site.irrigationDurationQty);
          final compSec = _parseDuration(site.irrigationDurationCompleted);

          if (_lastFertMqttIrrigationCompleted != site.irrigationDurationCompleted) {
            _lastFertMqttIrrigationCompleted = site.irrigationDurationCompleted;
            _fertLiveIrrigationSeconds = compSec.toInt();
          }
          final currentIrrSec = _fertLiveIrrigationSeconds ?? compSec.toInt();
          final displayCompIrrHms = formatSeconds(currentIrrSec.toDouble());

          progressRatio = totSec > 0 ? (currentIrrSec / totSec).clamp(0.0, 1.0) : 0.0;
          // Old UI logic directly from MQTT
          progressRight =
              'Total Duration : ${site.irrigationDurationQty} / $displayCompIrrHms';
          final remSec = (totSec - currentIrrSec).clamp(0.0, totSec);
          if (remSec > 0) {
            remDurationHms = formatSeconds(remSec);
          }
        } else {
          _fertLiveIrrigationSeconds = null;
          _lastFertMqttIrrigationCompleted = null;
          final comp = double.tryParse(site.irrigationQuantityCompleted) ?? 0;
          final tot = double.tryParse(site.irrigationDurationQty) ?? 0;
          progressRatio = tot > 0 ? (comp / tot).clamp(0.0, 1.0) : 0.0;
          progressRight =
              '${comp.toStringAsFixed(2)} / ${tot.toStringAsFixed(1)} Ltr';
        }

        return Container(
          width: widget.isWide ? 620 : MediaQuery.sizeOf(context).width,
          color: const Color(0xFFF8FAFC),
          child: Column(
            children: [
              buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (linesWithFertilizer.length > 1 &&
                          selectedLine != null) ...[
                        _buildLineDropdown(linesWithFertilizer, selectedLine),
                        const SizedBox(height: 12),
                      ],
                      _buildTopMetricCards(
                        programName: programName,
                        zoneName: zoneName,
                        ecValue: ecValue,
                        phValue: phValue,
                      ),
                      const SizedBox(height: 14),
                      _buildInjectorsCard(injectors),
                      const SizedBox(height: 14),
                      _buildLiveFlowPathCard(
                        runningPumps: pumpNames,
                        boosterPumps: boosterNames,
                        activeInjectors:
                            injectors.where((inj) => inj.isInProgress).toList(),
                        remDurationHms: remDurationHms,
                        openedValves: valveNames,
                        zoneName: zoneName,
                        programName: programName,
                      ),
                      const SizedBox(height: 14),
                      _buildIrrigationProgressCard(
                        progressTitle: progressTitle,
                        progressRight: progressRight,
                        progressRatio: progressRatio,
                      ),
                      const SizedBox(height: 14),
                      buildGraphRow(site),
                      const SizedBox(height: 14),
                      buildSensorsCard(
                        prsInNames: pressureInNames,
                        prsInValue: pressureInValues,
                        prsOutName: pressureOutNames,
                        prsOutValue: pressureOutValues,
                        wmNames: waterMeterNames,
                        wmValue: waterMeterValues,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopMetricCards({
    required String programName,
    required String zoneName,
    required String ecValue,
    required String phValue,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Program',
                value: programName,
                subtitle: zoneName != '--' ? 'Zone: $zoneName' : '--',
                icon: Icons.calendar_today_outlined,
                iconColor: const Color(0xFF0284C7),
                iconBgColor: const Color(0xFFE0F2FE),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'EC',
                value: ecValue,
                unit: ecValue != '--' ? 'mS/cm' : null,
                subtitle: 'Live reading',
                icon: Icons.bolt_rounded,
                iconColor: const Color(0xFFF59E0B),
                iconBgColor: const Color(0xFFFEF3C7),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: 'pH',
                value: phValue,
                subtitle: 'Live reading',
                icon: Icons.science_outlined,
                iconColor: const Color(0xFF0D9488),
                iconBgColor: const Color(0xFFCCFBF1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    String? unit,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (unit != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        unit,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildInjectorsCard(List<_InjectorCardData> injectors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Channels',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Completed',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (injectors.isEmpty)
            const Text('No injectors configured',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)))
          else
            for (int i = 0; i < injectors.length; i += 2) ...[
              if (i > 0) const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildInjectorItem(injectors[i])),
                  if (i + 1 < injectors.length) ...[
                    const SizedBox(width: 10),
                    Expanded(child: _buildInjectorItem(injectors[i + 1])),
                  ],
                ],
              ),
            ],
        ],
      ),
    );
  }

  Widget _buildInjectorItem(_InjectorCardData data) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: data.isInProgress
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data.isInProgress ? 'In progress' : 'Not used',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: data.isInProgress
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            data.durationStr,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: data.progress,
              minHeight: 5,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                data.isInProgress
                    ? const Color(0xFF10B981)
                    : const Color(0xFFCBD5E1),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${data.percent}% complete',
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
              Text(
                data.detail,
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLineDropdown(
      List<IrrigationLineModel> lines, IrrigationLineModel selectedLine) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.alt_route, size: 16, color: Color(0xFF0284C7)),
          const SizedBox(width: 8),
          const Text('Line: ',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B))),
          DropdownButtonHideUnderline(
            child: DropdownButton<double>(
              value: selectedLine.sNo,
              isDense: true,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0F172A)),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A)),
              items: lines.map((l) {
                final fs = l.centralFertilizerSite ?? l.localFertilizerSite;
                return DropdownMenuItem<double>(
                  value: l.sNo,
                  child: Text(fs != null ? '${l.name} (${fs.name})' : l.name),
                );
              }).toList(),
              onChanged: (newSNo) {
                if (newSNo != null) {
                  setState(() {
                    _selectedLineSNo = newSNo;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIrrigationProgressCard({
    required String progressTitle,
    required String progressRight,
    required double progressRatio,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                progressTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                progressRight,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Container(color: const Color(0xFF3B82F6)),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: 92,
                    child: Stack(
                      children: [
                        Container(color: const Color(0xFFE2E8F0)),
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progressRatio,
                          child: Container(color: const Color(0xFF10B981)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: 4,
                    child: Container(color: const Color(0xFF3B82F6)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pre water',
                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              Text('Fertilizer',
                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              Text('Post water',
                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveFlowPathCard({
    required List<String> runningPumps,
    required List<String> boosterPumps,
    required List<_InjectorCardData> activeInjectors,
    required String remDurationHms,
    required List<String> openedValves,
    required String zoneName,
    required String programName,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live flow path',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('Active',
                      style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  const SizedBox(width: 10),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('Injecting',
                      style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFlowPillBox(
                    'Pumps', '${runningPumps.length} on', runningPumps),
                _buildFlowPipe(),
                _buildFlowPillBox(
                    'Booster', '${boosterPumps.length} on', boosterPumps),
                _buildFlowPipe(),
                _buildFlowInjectionPill(activeInjectors, remDurationHms),
                _buildFlowPipe(),
                _buildFlowPillBox(
                    'Valves', '${openedValves.length} open', openedValves),
                _buildFlowPipe(),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Zone',
                          style: TextStyle(
                              fontSize: 10, color: Color(0xFF64748B))),
                      Text(zoneName,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A))),
                      Text(programName,
                          style: const TextStyle(
                              fontSize: 9, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowPipe() {
    return Container(width: 20, height: 4, color: const Color(0xFF10B981));
  }

  Widget _buildFlowPillBox(String title, String badge, List<String> items) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style:
                      const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              Text(badge,
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF16A34A))),
            ],
          ),
          const SizedBox(height: 4),
          if (items.isEmpty)
            const Text('None',
                style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8)))
          else
            for (final it in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('• $it',
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A))),
              ),
        ],
      ),
    );
  }

  Widget _buildFlowInjectionPill(
      List<_InjectorCardData> activeInjectors, String remDurationHms) {
    final bool isRunning = activeInjectors.isNotEmpty;
    return Container(
      width: 140,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isRunning ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color:
                isRunning ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Injection',
                  style: TextStyle(fontSize: 10, color: Color(0xFF92400E))),
              Text(isRunning ? 'Running' : 'Idle',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isRunning
                          ? const Color(0xFFD97706)
                          : const Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(height: 4),
          if (!isRunning)
            const Text('No injection',
                style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8)))
          else
            for (final inj in activeInjectors)
              Text('• ${inj.name}',
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF78350F))),
          if (remDurationHms.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('$remDurationHms left',
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E))),
          ],
        ],
      ),
    );
  }

  double _parseDuration(String time) {
    if (time.isEmpty) return 0;

    final parts = time.split(':');
    if (parts.length != 3) return 0;

    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final seconds = int.tryParse(parts[2]) ?? 0;

    return (hours * 3600 + minutes * 60 + seconds).toDouble();
  }

  Widget buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Fertilizer Live Monitoring",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              IconButton(
                  onPressed: () {
                    context
                        .read<CustomerScreenControllerViewModel>()
                        .onFertilizerLiveSync();
                  },
                  icon: const Icon(Icons.refresh)),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => Navigator.pop(context),
                child: const CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.close_outlined,
                      size: 20, color: Colors.black54),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget buildInfoRow(String program, String zone) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                bottomLeft: Radius.circular(5),
              ),
              border: Border.all(
                color: Colors.black12,
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 5),
                const Icon(Icons.event_note, color: Colors.grey),
                const SizedBox(width: 5),
                const Text("Program : ", style: TextStyle(color: Colors.grey)),
                Text(program, style: const TextStyle(color: Colors.black)),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(5),
                bottomRight: Radius.circular(5),
              ),
              border: Border.all(
                color: Colors.black12,
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 5),
                const Icon(Icons.location_on, color: Colors.grey),
                const SizedBox(width: 5),
                const Text("Zone : ", style: TextStyle(color: Colors.grey)),
                Text(zone, style: const TextStyle(color: Colors.black)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildMainStatusCard({
    required String programName,
    required String zoneName,
    required List<String> pumpNames,
    required List<String> pumpStatuses,
    required List<String> valveNames,
    required List<String> valveStatuses,
    required List<String> boosterNames,
    required List<String> boosterStatus,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildInfoRow(programName, zoneName),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _buildDeviceRow(
                title: "Running Pumps",
                assetType: "pump",
                itemNames: pumpNames,
                statuses: pumpStatuses,
              )),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildDeviceRow(
                title: "Opened Valves",
                assetType: "valve",
                itemNames: valveNames,
                statuses: valveStatuses,
              )),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildDeviceRow(
                title: "Booster pump",
                assetType: "booster",
                itemNames: boosterNames,
                statuses: boosterStatus,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildLiveChannelChart(List<ChannelDurationBarModel> chartData) {
    return SizedBox(
      height: (chartData.length * 45) + 80,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 8),
        child: Padding(
          padding: const EdgeInsets.only(right: 5),
          child: SfCartesianChart(
            legend: const Legend(
              isVisible: true,
              position: LegendPosition.top,
              alignment: ChartAlignment.far,
            ),
            primaryXAxis: const CategoryAxis(),
            primaryYAxis: const NumericAxis(),
            series: <BarSeries<ChannelDurationBarModel, String>>[
              BarSeries<ChannelDurationBarModel, String>(
                name: "Total Duration",
                dataSource: chartData,
                color: Colors.indigo,
                xValueMapper: (data, _) => data.channel,
                yValueMapper: (data, _) => data.total,
                dataLabelSettings: DataLabelSettings(
                  isVisible: true,
                  labelAlignment: ChartDataLabelAlignment.outer,
                  builder: (dynamic data, dynamic point, dynamic series,
                      int pointIndex, int seriesIndex) {
                    final model = data as ChannelDurationBarModel;
                    return Text(
                      formatSeconds(model.total),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              BarSeries<ChannelDurationBarModel, String>(
                name: "Completed",
                dataSource: chartData,
                color: Colors.green,
                xValueMapper: (data, _) => data.channel,
                yValueMapper: (data, _) => data.completed,
                dataLabelSettings: DataLabelSettings(
                  isVisible: true,
                  labelAlignment: ChartDataLabelAlignment.outer,
                  builder: (dynamic data, dynamic point, dynamic series,
                      int pointIndex, int seriesIndex) {
                    final model = data as ChannelDurationBarModel;
                    return Text(
                      formatSeconds(model.completed),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String formatSeconds(double seconds) {
    final int sec = seconds.toInt();

    final int hours = sec ~/ 3600;
    final int minutes = (sec % 3600) ~/ 60;
    final int remainingSeconds = sec % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildDeviceRow({
    required String title,
    required String assetType,
    required List<String> itemNames,
    required List<String> statuses,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        border: Border.all(
          color: Colors.black12,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 5),
          Center(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
          const Divider(height: 8, color: Colors.black12),
          Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: List.generate(itemNames.length, (index) {
              final statusValue =
                  (index < statuses.length && statuses[index].isNotEmpty)
                      ? int.tryParse(statuses[index]) ?? 0
                      : 0;

              return SizedBox(
                width: 80,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                        width: 60,
                        height: 60,
                        child: AppConstants.getAssetForFrtLive(
                            assetType, statusValue)),
                    Text(
                      itemNames[index],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                    const SizedBox(height: 5),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget buildStatusBox(
    String title,
    List<String> numbers,
    List<String> status,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(numbers.length, (i) {
                final isOn = i < status.length && status[i] == "1";
                return Column(
                  children: [
                    Icon(icon, color: isOn ? Colors.green : Colors.red),
                    Text(numbers[i]),
                  ],
                );
              }),
            )
          ],
        ),
      ),
    );
  }

  Widget buildGraphRow(FertilizerSiteLiveModel site) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 14),
      child: Column(
        children: [
          buildGraphCard("EC", site.ecDataList),
          buildGraphCard("pH", site.phDataList),
        ],
      ),
    );
  }

  Widget buildGraphCard(String title, List<TimeValueModel> data) {
    final latestValue =
        data.isNotEmpty ? data.last.value.toStringAsFixed(2) : "--";

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black,
                ),
              ),
              Text(
                latestValue,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 100,
            child: data.isEmpty
                ? const Center(child: Text("No Data"))
                : SfCartesianChart(
                    tooltipBehavior: _tooltipBehavior,
                    primaryXAxis: const CategoryAxis(
                      labelStyle: TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    ),
                    primaryYAxis: const NumericAxis(
                      labelStyle: TextStyle(
                        fontSize: 10,
                        color: Colors.black,
                      ),
                    ),
                    series: <LineSeries<TimeValueModel, String>>[
                      LineSeries<TimeValueModel, String>(
                        dataSource: data,
                        xValueMapper: (item, _) => item.time,
                        yValueMapper: (item, _) => item.value,
                        markerSettings: const MarkerSettings(
                          isVisible: true,
                        ),
                        enableTooltip: true,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget buildSensorsCard({
    required List<String> prsInNames,
    required List<String> prsInValue,
    required List<String> prsOutName,
    required List<String> prsOutValue,
    required List<String> wmNames,
    required List<String> wmValue,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child: _buildSensorRow(
            title: "Pressure IN",
            sensorType: "Pressure Sensor",
            sensorNames: prsInNames,
            value: prsInValue,
          )),
          const SizedBox(width: 8),
          Expanded(
              child: _buildSensorRow(
            title: "Pressure OUT",
            sensorType: "Pressure Sensor",
            sensorNames: prsOutName,
            value: prsOutValue,
          )),
          const SizedBox(width: 8),
          Expanded(
              child: _buildSensorRow(
            title: "Water Meter",
            sensorType: "Water Meter",
            sensorNames: wmNames,
            value: wmValue,
          )),
        ],
      ),
    );
  }

  Widget _buildSensorRow({
    required String title,
    required String sensorType,
    required List<String> sensorNames,
    required List<String> value,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        border: Border.all(
          color: Colors.black12,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          const Divider(height: 8, color: Colors.black12),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: List.generate(sensorNames.length, (index) {
              final snrValue = (index < value.length && value[index].isNotEmpty)
                  ? double.tryParse(value[index]) ?? 0.0
                  : 0.0;

              return Center(
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: SfRadialGauge(
                    axes: <RadialAxis>[
                      RadialAxis(
                        minimum: 0,
                        maximum: 10,
                        ranges: <GaugeRange>[
                          GaugeRange(
                              startValue: 0, endValue: 2, color: Colors.red),
                          GaugeRange(
                              startValue: 2, endValue: 4, color: Colors.orange),
                          GaugeRange(
                              startValue: 4, endValue: 10, color: Colors.green),
                        ],
                        pointers: <GaugePointer>[
                          NeedlePointer(
                            value: snrValue,
                            needleLength: 0.7,
                            needleStartWidth: 1,
                            needleEndWidth: 5,
                            needleColor: Colors.black87,
                            enableAnimation: true,
                            animationDuration: 800,
                            knobStyle: const KnobStyle(
                              knobRadius: 0.09,
                              color: Colors.black,
                            ),
                          ),
                        ],
                        annotations: <GaugeAnnotation>[
                          GaugeAnnotation(
                            widget: Text(
                              snrValue.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            angle: 90,
                            positionFactor: 0.5,
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget buildIrrigationGauge(FertilizerSiteLiveModel site) {
    final method = site.irrigationMethod.toLowerCase();

    final preTime = method == "1"
        ? parseTimeToMinutes(site.preTimeQty)
        : double.tryParse(site.preTimeQty) ?? 0;

    final postTime = method == "1"
        ? parseTimeToMinutes(site.postTimeQty)
        : double.tryParse(site.postTimeQty) ?? 0;

    final durationQty = method == "1"
        ? parseTimeToMinutes(site.irrigationDurationQty)
        : double.tryParse(site.irrigationDurationQty) ?? 0;

    final durationCompleted = method == "1"
        ? parseTimeToMinutes(site.irrigationDurationCompleted)
        : double.tryParse(site.irrigationDurationCompleted) ?? 0;

    final quantityCompleted =
        double.tryParse(site.irrigationQuantityCompleted) ?? 0;

    final currentProgress =
        method == "1" ? durationCompleted : quantityCompleted;
    final totalRange = preTime + durationQty + postTime;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Text(
              "Irrigation Progress (${method == "1" ? "Time" : "Quantity"})",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SfLinearGauge(
            minimum: 0,
            maximum: totalRange == 0 ? 100 : totalRange,
            showTicks: false,
            showLabels: false,
            axisTrackStyle: const LinearAxisTrackStyle(
              thickness: 25,
              color: Colors.black12,
            ),
            ranges: [
              LinearGaugeRange(
                startValue: 0,
                endValue: preTime,
                color: Colors.blue,
              ),
              LinearGaugeRange(
                startValue: preTime,
                endValue: preTime + durationQty,
                color: Colors.green,
              ),
              LinearGaugeRange(
                startValue: preTime + durationQty,
                endValue: totalRange, // must match maximum
                color: Colors.blue,
              ),
            ],
            markerPointers: [
              LinearShapePointer(
                value: currentProgress,
                shapeType: LinearShapePointerType.invertedTriangle,
                color: Colors.red,
                width: 18,
                height: 18,
              ),

              LinearWidgetPointer(
                value: preTime / 2,
                position: LinearElementPosition.cross,
                child: const Text(
                  "Pre water",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                  ),
                ),
              ),

              // MAIN Label
              LinearWidgetPointer(
                value: preTime + (durationQty / 2),
                position: LinearElementPosition.cross,
                child: const Text(
                  "Fertilizer",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                  ),
                ),
              ),

              // POST Label
              LinearWidgetPointer(
                value: preTime + durationQty + (postTime / 2),
                position: LinearElementPosition.cross,
                child: const Text(
                  "Post water",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          method == "1"
              ? Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Total Duration : ",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        "${formatMinutesToHMS(totalRange)} / ${formatMinutesToHMS(currentProgress)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                )
              : Text(
                  "${currentProgress.toStringAsFixed(2)} / "
                  "${totalRange.toStringAsFixed(1)} Ltr",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
        ],
      ),
    );
  }

  double parseTimeToMinutes(String value) {
    if (value.contains(":")) {
      final parts = value.split(":");
      if (parts.length == 3) {
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = int.tryParse(parts[1]) ?? 0;
        final seconds = int.tryParse(parts[2]) ?? 0;

        return (hours * 60) + minutes + (seconds / 60);
      }
    }
    return double.tryParse(value) ?? 0;
  }

  String formatMinutesToHMS(double minutes) {
    final totalSeconds = (minutes * 60).round();

    final hours = totalSeconds ~/ 3600;
    final minutesPart = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    return "${hours.toString().padLeft(2, '0')}:"
        "${minutesPart.toString().padLeft(2, '0')}:"
        "${seconds.toString().padLeft(2, '0')}";
  }
}
