import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../models/customer/site_model.dart';
import '../../../repository/repository.dart';
import '../../../services/http_service.dart';
import '../../../utils/Theme/oro_theme.dart';
import '../../../utils/my_function.dart';
import '../../../view_models/customer/sensor_hourly_logs_vm.dart';

class SensorHourlyLogs extends StatelessWidget {
  const SensorHourlyLogs({
    super.key,
    required this.userId,
    required this.controllerId,
    required this.configObjects,
  });

  final int userId;
  final int controllerId;
  final List<ConfigObject> configObjects;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SensorHourlyLogsVm(
        Repository(HttpService()),
        userId,
        controllerId,
        configObjects,
      )..getSensorHourlyLogs(),
      child: Consumer<SensorHourlyLogsVm>(
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
                      Icons.sensors_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Hourly Sensor Logs',
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
                // Top Date Banner / Quick Navigation Header
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
                        Icons.insert_chart_outlined_rounded,
                        size: 18,
                        color: brandIconBg,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Logs for ${DateFormat('EEEE, MMM d, yyyy').format(viewModel.selectedDate)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${viewModel.sensorsBySNo.length} Sensor${viewModel.sensorsBySNo.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryPurple,
                        ),
                      ),
                    ],
                  ),
                ),
                // Main Content Body
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
                                'Loading hourly sensor logs...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : viewModel.sensorsBySNo.isEmpty
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
                                        Icons.sensors_off_rounded,
                                        size: 40,
                                        color: brandIconBg,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No Sensor Logs Available',
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
                                          : 'No sensor logs recorded for ${DateFormat('yyyy-MM-dd').format(viewModel.selectedDate)}.',
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
                              itemCount: viewModel.sensorsBySNo.entries.length,
                              itemBuilder: (context, index) {
                                final entry = viewModel.sensorsBySNo.entries
                                    .elementAt(index);
                                final List<SensorHourlyData> chartData =
                                    entry.value;

                                if (chartData.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                final String sensorName =
                                    chartData.first.name ?? '';
                                final String objectName =
                                    chartData.first.objectName;
                                final String sensorUnit = MyFunction()
                                    .getSensorUnit(objectName, context);

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
                                      // Chart Header Bar
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
                                              padding:
                                                  const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: activeBgLavender,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                Icons.sensors_rounded,
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
                                                    sensorName,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: textDark,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    objectName,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: textMuted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (sensorUnit.isNotEmpty)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
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
                                                child: Text(
                                                  sensorUnit,
                                                  style: const TextStyle(
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
                                          height: 300,
                                          child: SfCartesianChart(
                                            plotAreaBorderWidth: 0,
                                            trackballBehavior:
                                                TrackballBehavior(
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
                                                format: 'point.x : point.y',
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
                                            primaryXAxis: CategoryAxis(
                                              interval: 1,
                                              labelRotation: 45,
                                              labelStyle: const TextStyle(
                                                fontSize: 10,
                                                color: textMuted,
                                              ),
                                              majorGridLines:
                                                  const MajorGridLines(width: 0),
                                              axisLine: const AxisLine(
                                                color: Color(0xFFE2E8F0),
                                              ),
                                              initialVisibleMaximum: 9,
                                            ),
                                            primaryYAxis: NumericAxis(
                                              title: AxisTitle(
                                                text: sensorUnit,
                                                textStyle: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: textMuted,
                                                ),
                                              ),
                                              labelStyle: const TextStyle(
                                                fontSize: 10,
                                                color: textMuted,
                                              ),
                                              majorGridLines:
                                                  const MajorGridLines(
                                                width: 1,
                                                color: Color(0xFFF1F5F9),
                                                dashArray: <double>[4, 4],
                                              ),
                                              axisLine: const AxisLine(width: 0),
                                            ),
                                            series: <
                                                LineSeries<SensorHourlyData,
                                                    String>>[
                                              LineSeries<SensorHourlyData,
                                                  String>(
                                                dataSource: chartData,
                                                xValueMapper: (data, _) =>
                                                    data.hour,
                                                yValueMapper: (data, _) =>
                                                    MyFunction().getChartValue(
                                                  context,
                                                  data.objectName,
                                                  data.value ?? 0.0,
                                                ),
                                                name: objectName,
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
      ),
    );
  }
}
