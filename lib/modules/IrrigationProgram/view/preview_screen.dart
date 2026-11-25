import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hex/services/mqtt_service.dart';
import 'package:hex/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../repository/irrigation_program_repo.dart';
import '../state_management/irrigation_program_provider.dart';
import '../../../StateManagement/mqtt_payload_provider.dart';
import '../widgets/custom_alert_dialog.dart';
import '../../SystemDefinitions/widgets/custom_snack_bar.dart';
import '../../../services/http_service.dart';
import '../../../utils/network_utils.dart';
import '../widgets/progress_dialog_ecogem.dart';
import 'program_library.dart';

final dateFormat = DateFormat('dd-MM-yyyy');

class PreviewScreen extends StatefulWidget {
  final int userId;
  final int customerId;
  final int controllerId;
  final int groupId;
  final int categoryId;
  final String deviceId;
  final int serialNumber;
  final bool toDashboard;
  final String? programType;
  final bool fromDealer;
  final int modelId;
  final String deviceName;
  final String categoryName;

  const PreviewScreen({
    super.key,
    required this.userId,
    required this.controllerId,
    required this.deviceId,
    required this.serialNumber,
    required this.toDashboard,
    this.programType,
    required this.fromDealer,
    required this.customerId,
    required this.groupId,
    required this.categoryId,
    required this.modelId,
    required this.deviceName,
    required this.categoryName,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class SegmentChartData {
  final String name;
  final double minutes;
  final double percentage;
  final Color color;

  SegmentChartData({
    required this.name,
    required this.minutes,
    required this.percentage,
    required this.color,
  });
}

class _PreviewScreenState extends State<PreviewScreen> {
  late IrrigationProgramMainProvider irrigationProvider;
  late MqttPayloadProvider mqttPayloadProvider;

  @override
  void initState() {
    super.initState();
    irrigationProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: false);
    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: false);
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        irrigationProvider.waterAndFert(widget.modelId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    irrigationProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: true);
    final isWide = MediaQuery.of(context).size.width >= 1000;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? MediaQuery.of(context).size.width * 0.04 : 16,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TOP DISPATCH BANNER CARD
          _buildDispatchBannerCard(context),
          const SizedBox(height: 16),

          // 2. RUNTIME DISTRIBUTION & PROGRAM PLANNING ROW
          _buildRuntimeAndPlanningRow(context, isWide),
          const SizedBox(height: 16),

          // 3. HARDWARE & CONFIGURATION SUMMARY ROW (4 Cards)
          _buildSummaryCardsRow(context, isWide),
          const SizedBox(height: 20),

          // 4. SEGMENT PLOT & VALVE DISTRIBUTION CARD
          _buildSegmentPlotDistributionCard(context),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // 1. Top Dispatch Banner Card
  Widget _buildDispatchBannerCard(BuildContext context) {
    // Calculate total cycle volume or estimated volume
    int estimatedLitres = 512;
    if (irrigationProvider.waterValueInQuantity != '' && irrigationProvider.waterValueInQuantity != '0') {
      final parsed = int.tryParse(irrigationProvider.waterValueInQuantity);
      if (parsed != null && parsed > 0) {
        estimatedLitres = parsed * (irrigationProvider.irrigationLine?.sequence.length ?? 1);
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5B21B6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Ready for Verification & Dispatch",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Audit Segment flow quotas, hardware allocations, and fail-safes below before saving.",
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "ESTIMATED CYCLE VOLUME",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "$estimatedLitres Litres",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5B21B6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Runtime Distribution & Program Planning Row
  Widget _buildRuntimeAndPlanningRow(BuildContext context, bool isWide) {
    final chartData = _generateChartData();
    final totalMins = chartData.fold<double>(0, (sum, item) => sum + item.minutes).toInt();

    final leftCard = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.access_time_rounded, color: Color(0xFF7C3AED), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "RUNTIME DISTRIBUTION BY SEGMENT",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Text(
                "${totalMins > 0 ? totalMins : 160} total mins",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Donut Chart & Legend
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: SfCircularChart(
                  margin: EdgeInsets.zero,
                  series: <CircularSeries>[
                    DoughnutSeries<SegmentChartData, String>(
                      dataSource: chartData,
                      xValueMapper: (SegmentChartData data, _) => data.name,
                      yValueMapper: (SegmentChartData data, _) => data.minutes,
                      pointColorMapper: (SegmentChartData data, _) => data.color,
                      innerRadius: '65%',
                    )
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: chartData.map((data) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: data.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Text(
                            "${data.minutes.toInt()}m (${data.percentage.toInt()}%)",
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final selectedMethod = irrigationProvider.selectedScheduleType;

    final rightCard = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF7C3AED), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "PROGRAM PLANNING PLANNING METHOD",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  selectedMethod.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Planning Description Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              selectedMethod == "No Planning Method"
                  ? "No calendar Planning Method configured. Program will execute only when triggered manually by operator or controller dispatch."
                  : "Program configured with $selectedMethod execution strategy.",
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
          ),
        ],
      ),
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: leftCard),
          const SizedBox(width: 16),
          Expanded(child: rightCard),
        ],
      );
    } else {
      return Column(
        children: [
          leftCard,
          const SizedBox(height: 16),
          rightCard,
        ],
      );
    }
  }

  List<SegmentChartData> _generateChartData() {
    final colors = [
      const Color(0xFF7C3AED),
      const Color(0xFF6366F1),
      const Color(0xFF06B6D4),
      const Color(0xFFF59E0B),
    ];

    final seqList = irrigationProvider.sequenceData;
    if (seqList.isEmpty) {
      return [
        SegmentChartData(name: "Segment 1.1", minutes: 80, percentage: 50, color: colors[0]),
        SegmentChartData(name: "Segment 1.2", minutes: 30, percentage: 19, color: colors[1]),
        SegmentChartData(name: "Segment 1.3", minutes: 30, percentage: 19, color: colors[2]),
        SegmentChartData(name: "Segment 1.4", minutes: 20, percentage: 13, color: colors[3]),
      ];
    }

    List<SegmentChartData> items = [];
    double totalMins = 0;

    for (int i = 0; i < seqList.length; i++) {
      final s = seqList[i];
      final name = s['seqName'] ?? 'Segment ${i + 1}';
      double mins = 30;
      final timeVal = s['timeValue']?.toString() ?? '';
      if (timeVal.isNotEmpty && timeVal.contains(':')) {
        final parts = timeVal.split(':');
        if (parts.length >= 2) {
          final h = double.tryParse(parts[0]) ?? 0;
          final m = double.tryParse(parts[1]) ?? 0;
          mins = (h * 60) + m;
        }
      }
      if (mins <= 0) mins = 20;
      totalMins += mins;
      items.add(SegmentChartData(
        name: name,
        minutes: mins,
        percentage: 0,
        color: colors[i % colors.length],
      ));
    }

    if (totalMins > 0) {
      items = items.map((e) {
        final pct = (e.minutes / totalMins) * 100;
        return SegmentChartData(
          name: e.name,
          minutes: e.minutes,
          percentage: pct,
          color: e.color,
        );
      }).toList();
    }

    return items;
  }

  // 3. Hardware Summary Cards Row (4 Cards)
  Widget _buildSummaryCardsRow(BuildContext context, bool isWide) {
    final pumpsList = irrigationProvider.selectedObjects!
        .where((e) => e.objectId == 5)
        .map((e) => e.name ?? 'Pump')
        .toList();
    final pumpsText = pumpsList.isNotEmpty ? pumpsList.join(', ') : 'Pump 4, Pump 5';

    final fertList = irrigationProvider.selectedObjects!
        .where((e) => e.objectId == 3)
        .map((e) => e.name ?? 'Site')
        .toList();
    final fertText = fertList.isNotEmpty
        ? fertList.join(', ')
        : 'Fertilization Site 1, Fertilization Site 2';

    final filterList = irrigationProvider.selectedObjects!
        .where((e) => e.objectId == 4)
        .map((e) => e.name ?? 'Filter')
        .toList();
    final filterText = filterList.isNotEmpty ? filterList.join(', ') : 'Filter 1 (Time)';

    final priorityScaleText =
        "${irrigationProvider.priority} Priority · ${irrigationProvider.adjustPercentage}%";

    final c1 = _buildSummaryTile(
      icon: Icons.bolt_outlined,
      label: "PUMPS & STATION",
      value: pumpsText,
    );
    final c2 = _buildSummaryTile(
      icon: Icons.science_outlined,
      label: "FERTILIZER SITES",
      value: fertText,
    );
    final c3 = _buildSummaryTile(
      icon: Icons.filter_alt_outlined,
      label: "FILTRATION UNITS",
      value: filterText,
    );
    final c4 = _buildSummaryTile(
      icon: Icons.tune_rounded,
      label: "PRIORITY / SCALE",
      value: priorityScaleText,
    );

    if (isWide) {
      return Row(
        children: [
          Expanded(child: c1),
          const SizedBox(width: 12),
          Expanded(child: c2),
          const SizedBox(width: 12),
          Expanded(child: c3),
          const SizedBox(width: 12),
          Expanded(child: c4),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: c1),
              const SizedBox(width: 12),
              Expanded(child: c2),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: c3),
              const SizedBox(width: 12),
              Expanded(child: c4),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildSummaryTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF7C3AED), size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 4. Segment Plot & Valve Distribution Card
  Widget _buildSegmentPlotDistributionCard(BuildContext context) {
    final sequenceList = irrigationProvider.irrigationLine?.sequence ?? [];
    final sampleLines = irrigationProvider.sampleIrrigationLine ?? [];

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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.layers_outlined, color: Color(0xFF7C3AED), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "SEGMENT PLOT & VALVE DISTRIBUTION",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Text(
                "${sequenceList.length} sequence${sequenceList.length > 1 ? 's' : ''}",
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Sequences List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sequenceList.length,
            itemBuilder: (context, seqIdx) {
              final seq = sequenceList[seqIdx];
              final seqName = seq['name'] ?? 'Segment ${seqIdx + 1}';
              final assignedValves = (seq['valve'] as List? ?? []);
              final assignedMainValves = (seq['mainValve'] as List? ?? []);

              final allValvesInSeq = [...assignedValves, ...assignedMainValves];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Segment Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        seqName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        "${sampleLines.length} plots · ${allValvesInSeq.length} valves",
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Plots Wrap
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: sampleLines.map((line) {
                      final plotName = line.irrigationLine.name ?? 'Plot';
                      final lineValves = line.valve ?? [];

                      // Find which of this plot's valves are in current sequence
                      final plotValvesInSeq = lineValves.where((v) {
                        return allValvesInSeq.any((sv) => sv['sNo'] == v.sNo);
                      }).toList();

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
                            Text(
                              plotName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (plotValvesInSeq.isNotEmpty)
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: plotValvesInSeq.map((v) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Text(
                                      v.name ?? 'Valve',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              )
                            else
                              const Text(
                                "No valves",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void sendFunction() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (!mounted) return;
    bool isOnline = await NetworkUtils.checkNow();
    if (!isOnline) {
      if (mounted) {
        showAdaptiveDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return CustomAlertDialog(
              title: 'No Internet Connection',
              content: 'Internet connection is unavailable. Please check your network connection and try again.',
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ],
            );
          },
        );
      }
      return;
    }

    if (!mounted) return;
    final mainProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: false);
    Map<String, dynamic> dataToMqtt = mainProvider.dataToMqtt(
      widget.serialNumber == 0 ? mainProvider.serialNumberCreation : widget.serialNumber,
      widget.programType,
    );
    Map<String, dynamic> dataToMqttEcoGem = {};
    dynamic ecoGemWFPayload;
    List<String> ecoGemWFPayloadList = [];
    if (AppConstants.ecoGemAndPlusModelList.contains(widget.modelId)) {
      dataToMqttEcoGem = mainProvider.dataToMqttForEcoGem(
        widget.serialNumber == 0 ? mainProvider.serialNumberCreation : widget.serialNumber,
        widget.programType,
      );
      ecoGemWFPayload = mainProvider.ecoGemPayloadForWF(
        widget.serialNumber == 0 ? mainProvider.serialNumberCreation : widget.serialNumber,
      );
      ecoGemWFPayloadList.add(jsonEncode(dataToMqttEcoGem));
      for (int i = 0; i < ecoGemWFPayload.length; i++) {
        final payload = {
          "260${i + 1}": {"2501": ecoGemWFPayload[i]}
        };
        ecoGemWFPayloadList.add(jsonEncode(payload));
      }
    }

    Map<String, dynamic> userData = {
      "defaultProgramName": mainProvider.defaultProgramName,
      "userId": widget.customerId,
      "controllerId": widget.controllerId,
      "createUser": widget.userId,
      "serialNumber": widget.serialNumber == 0 ? mainProvider.serialNumberCreation : widget.serialNumber,
    };

    if (mainProvider.irrigationLine!.sequence.isNotEmpty) {
      var dataToSend = {
        "sequence": mainProvider.irrigationLine!.sequence,
        "schedule": mainProvider.sampleScheduleModel!.toJson(),
        "conditions": mainProvider.sampleConditions != null ? mainProvider.sampleConditions!.toJson() : [],
        "waterAndFert": mainProvider.sequenceData,
        "selection": {
          ...mainProvider.additionalData!.toJson(),
          "selected": mainProvider.selectedObjects!.map((e) => e.toJson()).toList(),
        },
        "alarm": mainProvider.newAlarmList!.toJson(),
        "programName": mainProvider.programName,
        "priority": mainProvider.priority,
        "delayBetweenZones": mainProvider.programDetails!.delayBetweenZones,
        "adjustPercentage": mainProvider.programDetails!.adjustPercentage,
        "cyclicOnTime": "00:00:00",
        "cyclicOffTime": "00:00:00",
        "isPressureEnabled": '0',
        "pressure": "",
        "incompleteRestart": mainProvider.isCompletionEnabled ? "1" : "0",
        "controllerReadStatus": '0',
        "programType": mainProvider.selectedProgramType,
        "hardware": AppConstants.ecoGemAndPlusModelList.contains(widget.modelId) ? ecoGemWFPayloadList : dataToMqtt
      };
      userData.addAll(dataToSend);

      try {
        if (AppConstants.ecoGemAndPlusModelList.contains(widget.modelId)) {
          final result = await showDialog<String>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return EcoGemProgressDialog(
                payloads: ecoGemWFPayloadList,
                deviceId: widget.deviceId,
                mqttService: MqttService(),
              );
            },
          );

          if (result != null) {
            setState(() {
              userData['controllerReadStatus'] = result;
            });
          }
        } else {
          await validatePayloadSent(
            dialogContext: context,
            context: context,
            mqttPayloadProvider: mqttPayloadProvider,
            acknowledgedFunction: () {
              setState(() {
                userData['controllerReadStatus'] = "1";
              });
            },
            payload: dataToMqtt,
            payloadCode: "2500",
            deviceId: widget.deviceId,
          );
        }
      } catch (error) {
        scaffoldMessenger.showSnackBar(CustomSnackBar(message: 'Failed to update because of $error'));
      }

      Future.delayed(const Duration(milliseconds: 300), () async {
        final IrrigationProgramRepository repository = IrrigationProgramRepository(HttpService());
        final createUserProgram = await repository.createUserProgram(userData);
        final response = jsonDecode(createUserProgram.body);
        if (createUserProgram.statusCode == 200) {
          await mainProvider.programLibraryData(widget.customerId, widget.controllerId);
          scaffoldMessenger.showSnackBar(CustomSnackBar(message: response['message']));
          if (context.mounted) {
            navigator.pop();
          }
        }
      });
    } else {
      showAdaptiveDialog<Future>(
        context: context,
        builder: (BuildContext context) {
          return CustomAlertDialog(
            title: 'Warning',
            content: "Select valves to be sequence for Irrigation Program",
            actions: [
              TextButton(child: const Text("OK"), onPressed: () => Navigator.of(context).pop()),
            ],
          );
        },
      );
    }
  }
}
