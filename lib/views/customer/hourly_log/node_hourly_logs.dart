import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../models/customer/site_model.dart';
import '../../../repository/repository.dart';
import '../../../services/http_service.dart';
import '../../../utils/Theme/oro_theme.dart';
import '../../../view_models/customer/node_hourly_logs_vm.dart';

class NodeHourlyLogs extends StatelessWidget {
  const NodeHourlyLogs({
    super.key,
    required this.userId,
    required this.controllerId,
    required this.nodes,
  });

  final int userId;
  final int controllerId;
  final List<NodeListModel> nodes;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NodeHourlyLogsVm(
        Repository(HttpService()),
        userId,
        controllerId,
        nodes,
      )..getNodeLogs(),
      child: const _NodeHourlyLogsView(),
    );
  }
}

class _NodeHourlyLogsView extends StatelessWidget {
  const _NodeHourlyLogsView();

  @override
  Widget build(BuildContext context) {
    return Consumer<NodeHourlyLogsVm>(
      builder: (context, viewModel, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: primaryPurple,
            foregroundColor: Colors.white,
            elevation: 0,
            titleSpacing: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Hourly Power Logs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: viewModel.isLoading
                      ? null
                      : () => viewModel.selectDate(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('yyyy-MM-dd')
                              .format(viewModel.selectedDate),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Top Date Banner / Quick Information Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: activeBgLavender,
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.electric_meter_outlined,
                      size: 18,
                      color: brandIconBg,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Power logs for ${DateFormat('EEEE, MMM d, yyyy').format(viewModel.selectedDate)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${viewModel.nodeDataMap.length} Node${viewModel.nodeDataMap.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryPurple,
                      ),
                    ),
                  ],
                ),
              ),
              // Main Body Content
              Expanded(
                child: viewModel.isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(primaryPurple),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading hourly power logs...',
                              style: TextStyle(
                                fontSize: 14,
                                color: textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : viewModel.nodeDataMap.isEmpty
                        ? Center(
                            child: Container(
                              margin: const EdgeInsets.all(24),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: const BoxDecoration(
                                      color: activeBgLavender,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.power_off_rounded,
                                      size: 40,
                                      color: brandIconBg,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No Node Power Logs Found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    viewModel.errorMessage.isNotEmpty
                                        ? viewModel.errorMessage
                                        : 'Node hourly power logs not found for ${DateFormat('yyyy-MM-dd').format(viewModel.selectedDate)}.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        viewModel.selectDate(context),
                                    icon: const Icon(
                                      Icons.calendar_month_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Change Date'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryPurple,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            itemCount: viewModel.nodeDataMap.length,
                            itemBuilder: (context, index) {
                              final entry = viewModel.nodeDataMap.entries
                                  .elementAt(index);

                              final String nodeId = entry.key;
                              final List<ChartDataLog> chartData = entry.value;

                              if (chartData.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              final deviceName = chartData.first.deviceName;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // Header section
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16),
                                        ),
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Color(0xFFE2E8F0),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: activeBgLavender,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.developer_board_rounded,
                                              color: brandIconBg,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  deviceName,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: textDark,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Node ID: $nodeId',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: textMuted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: activeBgLavender,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: primaryPurple
                                                    .withOpacity(0.2),
                                              ),
                                            ),
                                            child: const Text(
                                              'Voltage',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: primaryPurple,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Chart Canvas
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 8,
                                        bottom: 12,
                                        left: 8,
                                        right: 12,
                                      ),
                                      child: SizedBox(
                                        height: 320,
                                        child: SfCartesianChart(
                                          key: ValueKey(
                                            '${viewModel.selectedDate}_$nodeId',
                                          ),
                                          plotAreaBorderWidth: 0,
                                          enableAxisAnimation: false,
                                          legend: const Legend(
                                            isVisible: true,
                                            position: LegendPosition.top,
                                            overflowMode:
                                                LegendItemOverflowMode.wrap,
                                            textStyle: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: textDark,
                                            ),
                                          ),
                                          trackballBehavior: TrackballBehavior(
                                            enable: true,
                                            activationMode:
                                                ActivationMode.singleTap,
                                            tooltipDisplayMode:
                                                TrackballDisplayMode
                                                    .groupAllPoints,
                                            lineType: TrackballLineType.vertical,
                                            lineColor: primaryPurple
                                                .withOpacity(0.5),
                                            tooltipSettings:
                                                const InteractiveTooltip(
                                              enable: true,
                                              color: brandIconBg,
                                              textStyle: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          zoomPanBehavior: ZoomPanBehavior(
                                            enablePinching: true,
                                            enablePanning: true,
                                            zoomMode: ZoomMode.x,
                                          ),
                                          primaryXAxis: const CategoryAxis(
                                            labelStyle: TextStyle(
                                              fontSize: 10,
                                              color: textMuted,
                                            ),
                                            majorGridLines:
                                                MajorGridLines(width: 0),
                                            axisLine: AxisLine(
                                              color: Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          primaryYAxis: const NumericAxis(
                                            title: AxisTitle(
                                              text: 'Voltage (V)',
                                              textStyle: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: textMuted,
                                              ),
                                            ),
                                            labelStyle: TextStyle(
                                              fontSize: 10,
                                              color: textMuted,
                                            ),
                                            majorGridLines: MajorGridLines(
                                              width: 1,
                                              color: Color(0xFFF1F5F9),
                                              dashArray: <double>[4, 4],
                                            ),
                                            axisLine: AxisLine(width: 0),
                                          ),
                                          series: <
                                              LineSeries<ChartDataLog, String>>[
                                            LineSeries<ChartDataLog, String>(
                                              animationDuration: 0,
                                              dataSource: chartData,
                                              xValueMapper: (data, _) =>
                                                  data.hour,
                                              yValueMapper: (data, _) =>
                                                  data.batteryVoltage,
                                              name: 'Battery Voltage',
                                              color: primaryPurple,
                                              width: 2.5,
                                              markerSettings:
                                                  const MarkerSettings(
                                                isVisible: true,
                                                height: 6,
                                                width: 6,
                                                color: brandIconBg,
                                                borderColor: Colors.white,
                                                borderWidth: 1.5,
                                              ),
                                              dataLabelSettings:
                                                  const DataLabelSettings(
                                                isVisible: false,
                                              ),
                                            ),
                                            LineSeries<ChartDataLog, String>(
                                              animationDuration: 0,
                                              dataSource: chartData,
                                              xValueMapper: (data, _) =>
                                                  data.hour,
                                              yValueMapper: (data, _) =>
                                                  data.solarVoltage,
                                              name: 'Solar Voltage',
                                              color: const Color(0xFFD97706),
                                              width: 2.5,
                                              markerSettings:
                                                  const MarkerSettings(
                                                isVisible: true,
                                                height: 6,
                                                width: 6,
                                                color: Color(0xFFD97706),
                                                borderColor: Colors.white,
                                                borderWidth: 1.5,
                                              ),
                                              dataLabelSettings:
                                                  const DataLabelSettings(
                                                isVisible: false,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
