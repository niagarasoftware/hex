import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../StateManagement/mqtt_payload_provider.dart';
import '../../StateManagement/overall_use.dart';
import '../../modules/IrrigationProgram/view/program_library.dart';
import '../../services/communication_service.dart';
import '../../services/mqtt_service.dart';
import '../../services/sftp_service.dart';
import '../../utils/environment.dart';
import '../../utils/snack_bar.dart';
import 'package:hex/utils/helpers/log_print.dart';

// Enum for log types
enum LogType {
  schedule(7),
  uart(8),
  uart0(9),
  uart4(10),
  mqtt(11);

  final int value;
  const LogType(this.value);
}

class ControllerLog extends StatefulWidget {
  final String deviceID;
  final String communicationType;

  const ControllerLog({Key? key, required this.deviceID, required this.communicationType}) : super(key: key);

  @override
  _ControllerLogState createState() => _ControllerLogState();
}

class _ControllerLogState extends State<ControllerLog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late OverAllUse overAllPvd;
  late MqttPayloadProvider mqttPayloadProvider;
  final MqttService manager = MqttService();
  LogType currentLogType = LogType.schedule;
  String logString = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: false);
    overAllPvd = Provider.of<OverAllUse>(context, listen: false);
    _tabController = TabController(length: 5, vsync: this);

    // MQTT subscriptions
    if (widget.communicationType == 'MQTT') {
      manager.topicToUnSubscribe('${Environment.mqttSubscribeTopic}/${widget.deviceID}');
      manager.topicToUnSubscribe('${Environment.mqttLogTopic}/${widget.deviceID}');
      manager.topicToSubscribe('${Environment.mqttLogTopic}/${widget.deviceID}');
    }
  }

  Future<String> getLogFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/log.txt';
  }

  Future<void> writeLog(String message) async {
    final path = await getLogFilePath();
    final file = File(path);
    await file.writeAsString('$message\n', mode: FileMode.append);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildScrollableText(String text) {
    return ScrollableTextWithSearch(text: text.isNotEmpty ? text : "Waiting...");
  }

  @override
  Widget build(BuildContext context) {
    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: true);
    status();
    final primaryColor = Theme.of(context).primaryColor;
    return SafeArea(
      child: Scaffold(
        backgroundColor: primaryColor.withOpacity(0.01),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: Column(
              children: [
                AppBar(
                  backgroundColor: primaryColor,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: const Text(
                    'Controller Log',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      tooltip: 'Refresh Logs',
                      onPressed: () => getlog(currentLogType.value),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear_all_rounded, color: Colors.white),
                      tooltip: 'Clear All Logs',
                      onPressed: () => _clearLog(),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color(0xFF64748B),
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      dividerColor: Colors.transparent,
                      onTap: (index) {
                        setState(() {
                          currentLogType = LogType.values[index];
                        });
                      },
                      tabs: const [
                        Tab(text: 'Schedule'),
                        Tab(text: 'UART'),
                        Tab(text: 'UART-0'),
                        Tab(text: 'UART-4'),
                        Tab(text: 'Mqtt'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildScrollableText(mqttPayloadProvider.sheduleLog),
                      _buildScrollableText(mqttPayloadProvider.uardLog),
                      _buildScrollableText(mqttPayloadProvider.uard0Log),
                      _buildScrollableText(mqttPayloadProvider.uard4Log),
                      _buildScrollableText(""),
                    ],
                  ),
                ),
                _buildActionButtons(),
              ],
            ),
            if (isLoading)
              Container(
                color: Colors.white.withOpacity(0.6),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogView(String text) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildScrollableText(text.isNotEmpty ? text : "Waiting..."),
      ),
    );
  }

  Future<void> uploadToFile(String type) async {
    final String dateString = DateFormat('yyyy-MM-dd').format(DateTime.now());

    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: false);
    AppLog.log(' mqttPayloadProvider.traceLog---->${mqttPayloadProvider.traceLog}');
    List<String> traceData = mqttPayloadProvider.traceLog;
    AppLog.log('traceData----->$traceData');
    SftpService sftpService = SftpService();
    int connectResponse = await sftpService.connect();
    if (connectResponse == 200) {
      await Future.delayed(const Duration(seconds: 1));
      String localFileNameForTrace = "gem_log";
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;
      String filePath = '$appDocPath/$localFileNameForTrace.txt';
      final localFile = File(filePath);
      await localFile.writeAsString(traceData.join('\n'));
      int uploadResponse = await sftpService.uploadFile(
          localFileName: localFileNameForTrace,
          remoteFilePath: '/home/ubuntu/oro2024/OroGem/OroGemLogs/${widget.deviceID}_${type}_$dateString.txt');
      if (uploadResponse == 200) {
        _showSnackBar("/home/ubuntu/oro2024/OroGem/OroGemLogs/${widget.deviceID}_${type}_$dateString.txt \n FTP upload success'...");
        AppLog.log('upload success');
      } else {
        _showSnackBar("FTP upload failed...");
        AppLog.log('upload failed');
      }
      sftpService.disconnect();
    }
  }

  Future<void> showBluetoothLoadingDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Consumer<MqttPayloadProvider>(
              builder: (context, provider, _) {
                final sizeInBytes = mqttPayloadProvider.traceLogSize;
                final totalSizeInBytes = mqttPayloadProvider.totalTraceLogSize;
                final totalSizeText = totalSizeInBytes > 1024
                    ? '${(totalSizeInBytes / 1024).toStringAsFixed(2)} KB'
                    : '$totalSizeInBytes bytes';
                final sizeText = sizeInBytes > 1024
                    ? '${(sizeInBytes / 1024).toStringAsFixed(2)} KB'
                    : '$sizeInBytes bytes';
                final percentage = totalSizeInBytes > 0
                    ? (sizeInBytes / totalSizeInBytes) * 100
                    : 0;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: percentage / 100),
                    const SizedBox(height: 16),
                    const Text("Fetching logs via Bluetooth..."),
                    Text(
                      'Loading logs... Size: $sizeText / $totalSizeText (${percentage.toStringAsFixed(1)}%)',
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text("Close"),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        provider.setTraceLoading(false);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: currentLogType != LogType.mqtt
          ? Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              children: [
                _buildButton(
                  label: 'Start',
                  bgColor: const Color(0xFFDCFCE7),
                  fgColor: const Color(0xFF15803D),
                  icon: Icons.play_arrow_rounded,
                  onPressed: () {
                    _showSnackBar("Start sending to Controller log...");
                    getlog(currentLogType.value);
                  },
                ),
                _buildButton(
                  label: 'Stop',
                  bgColor: const Color(0xFFFFE4E6),
                  fgColor: const Color(0xFFBE123C),
                  icon: Icons.stop_rounded,
                  onPressed: () {
                    _showSnackBar("Stop sending to Controller log...");
                    getlog(LogType.mqtt.value);
                  },
                ),
                _buildButton(
                  label: 'Clear',
                  bgColor: Colors.white,
                  fgColor: const Color(0xFF475569),
                  borderColor: const Color(0xFFCBD5E1),
                  icon: Icons.clear_all_rounded,
                  onPressed: () => _clearLog(),
                ),
                _buildButton(
                  label: 'Today FTP',
                  bgColor: const Color(0xFFE0F2FE),
                  fgColor: const Color(0xFF0369A1),
                  icon: Icons.cloud_upload_rounded,
                  onPressed: () {
                    mqttPayloadProvider.setTraceLoading(true);
                    _showSnackBar("Today log send FTP...");
                    getlog(currentLogType.value + 5);
                    showBluetoothLoadingDialog(context);
                  },
                ),
                if (widget.communicationType != "MQTT")
                  _buildButton(
                    label: 'Today FTP upload',
                    bgColor: const Color(0xFFE0F2FE),
                    fgColor: const Color(0xFF0369A1),
                    icon: Icons.cloud_upload_rounded,
                    onPressed: () {
                      _showSnackBar("Today log send FTP...");
                      uploadToFile('$currentLogType');
                    },
                  ),
                _buildButton(
                  label: 'Yesterday FTP',
                  bgColor: const Color(0xFFE0F2FE),
                  fgColor: const Color(0xFF0369A1),
                  icon: Icons.cloud_upload_rounded,
                  onPressed: () {
                    mqttPayloadProvider.setTraceLoading(true);
                    _showSnackBar("Yesterday log send FTP...");
                    getlog(currentLogType.value + 10);
                    showBluetoothLoadingDialog(context);
                  },
                ),
                if (widget.communicationType != "MQTT")
                  _buildButton(
                    label: 'Yesterday FTP Upload',
                    bgColor: const Color(0xFFE0F2FE),
                    fgColor: const Color(0xFF0369A1),
                    icon: Icons.cloud_upload_rounded,
                    onPressed: () {
                      _showSnackBar("Yesterday log send FTP...");
                      uploadToFile('$currentLogType');
                    },
                  ),
              ],
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              children: [
                _buildButton(
                  label: 'Today Mqtt FTP',
                  bgColor: const Color(0xFFE0F2FE),
                  fgColor: const Color(0xFF0369A1),
                  icon: Icons.cloud_upload_rounded,
                  onPressed: () {
                    _showSnackBar("Today Mqtt log send FTP...");
                    getlog(16);
                  },
                ),
                _buildButton(
                  label: 'Yesterday Mqtt FTP',
                  bgColor: const Color(0xFFE0F2FE),
                  fgColor: const Color(0xFF0369A1),
                  icon: Icons.cloud_upload_rounded,
                  onPressed: () {
                    _showSnackBar("Yesterday Mqtt log FTP...");
                    getlog(21);
                  },
                ),
                if (widget.communicationType != "MQTT")
                  _buildButton(
                    label: 'Yesterday FTP Upload BLE',
                    bgColor: const Color(0xFFE0F2FE),
                    fgColor: const Color(0xFF0369A1),
                    icon: Icons.cloud_upload_rounded,
                    onPressed: () {
                      _showSnackBar("Yesterday log send FTP...");
                      uploadToFile('$currentLogType');
                    },
                  ),
                if (widget.communicationType != "MQTT")
                  _buildButton(
                    label: 'Today FTP upload BLE',
                    bgColor: const Color(0xFFE0F2FE),
                    fgColor: const Color(0xFF0369A1),
                    icon: Icons.cloud_upload_rounded,
                    onPressed: () {
                      _showSnackBar("Today log send FTP... ");
                      uploadToFile('$currentLogType');
                    },
                  ),
              ],
            ),
    );
  }

  Widget _buildButton({
    required String label,
    required Color bgColor,
    required Color fgColor,
    required IconData icon,
    required VoidCallback onPressed,
    Color? borderColor,
  }) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        elevation: 0,
        side: borderColor != null ? BorderSide(color: borderColor, width: 1) : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: const Size(0, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 16, color: fgColor),
      label: Text(
        label,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: fgColor),
      ),
      onPressed: onPressed,
    );
  }

  void _clearLog() {
    _showSnackBar("Clear Controller log...");
    setState(() {
      switch (currentLogType) {
        case LogType.schedule:
          mqttPayloadProvider.sheduleLog = '';
          break;
        case LogType.uart:
          mqttPayloadProvider.uardLog = '';
          break;
        case LogType.uart0:
          mqttPayloadProvider.uard0Log = '';
          break;
        case LogType.uart4:
          mqttPayloadProvider.uard4Log = '';
          break;
        case LogType.mqtt:
          break;
      }
    });
  }

  Future<void> ftpStatusDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Consumer<MqttPayloadProvider>(
              builder: (context, mqttPayloadProvider, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    logString.contains("LogFileDetailsUpdated - Success")
                        ? const Icon(Icons.check_circle, color: Colors.green, size: 50)
                        : const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      logString.contains("LogFileDetailsUpdated - Success")
                          ? "Success"
                          : "Please wait...",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(logString, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        logString.contains("LogFileDetailsUpdated - Success") ? "Ok" : "Cancel",
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void status() {
    Map<String, dynamic>? ctrlData = mqttPayloadProvider.messageFromHw;
    if (ctrlData != null && ctrlData.isNotEmpty) {
      logString = ctrlData['Name'] ?? '';
    }
  }

  Future<void> getlog(int data) async {
    setState(() => isLoading = true);

    if (widget.communicationType == "MQTT") {
      try {
        manager.topicToUnSubscribe(
            '${Environment.mqttLogTopic}/${widget.deviceID}');
        manager.topicToSubscribe(
            '${Environment.mqttSubscribeTopic}/${widget.deviceID}');

        await Future.delayed(const Duration(seconds: 1));
        if (LogType.values.any((logType) => logType.value == data)) {
          String payloadCode = "5700";
          Map<String, dynamic> payload = {
            "5700": {"5701": "$data"},
          };

          if (manager.isConnected) {
            await validatePayloadSent(
              dialogContext: context,
              context: context,
              mqttPayloadProvider: mqttPayloadProvider,
              acknowledgedFunction: () {
                manager.topicToUnSubscribe(
                    '${Environment.mqttLogTopic}/${widget.deviceID}');
                manager.topicToSubscribe(
                    '${Environment.mqttLogTopic}/${widget.deviceID}');
              },
              payload: payload,
              payloadCode: payloadCode,
              deviceId: widget.deviceID,
            );
          } else {
            GlobalSnackBar.show(context, 'MQTT is Disconnected', 201);
          }
        } else {
          String payload = jsonEncode({
            "5700": {"5701": "$data"},
          });
          manager.topicToPublishAndItsMessage(
              payload, '${Environment.mqttPublishTopic}/${widget.deviceID}');
          await ftpStatusDialog(context);
        }
      } finally {
        setState(() => isLoading = false);
      }
    } else {
      try {
        String payLoadFinal = jsonEncode({
          "5700": {"5701": "$data"},
        });
        final result = await context.read<CommunicationService>().sendCommand(
            payload: payLoadFinal, serverMsg: '');
        if (result['http'] == true) {
          debugPrint("Payload sent to Server");
        }
        if (result['mqtt'] == true) {
          debugPrint("Payload sent to MQTT Box");
        }
        if (result['bluetooth'] == true) {
          debugPrint("Payload sent via Bluetooth");
        }
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    getlog(LogType.mqtt.value);
    _tabController.dispose();
    manager.topicToUnSubscribe('${Environment.mqttLogTopic}/${widget.deviceID}');
    super.dispose();
  }
}

class ScrollableTextWithSearch extends StatefulWidget {
  final String text;

  const ScrollableTextWithSearch({
    super.key,
    required this.text,
  });

  @override
  _ScrollableTextWithSearchState createState() =>
      _ScrollableTextWithSearchState();
}

class _ScrollableTextWithSearchState extends State<ScrollableTextWithSearch> {
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  List<int> _matches = [];
  final TextEditingController _searchController = TextEditingController();
  int _matchCount = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _matches = _findMatches(widget.text, _searchQuery);
    });
  }

  List<TextSpan> _highlightText(String text, List<int> matchPositions) {
    if (_searchQuery.isEmpty) return _formatTerminalLogText(text);

    List<TextSpan> children = [];
    int start = 0;

    for (int pos in matchPositions) {
      if (start < pos) {
        children.addAll(_formatTerminalLogText(text.substring(start, pos)));
      }
      children.add(TextSpan(
        text: text.substring(pos, pos + _searchQuery.length),
        style: const TextStyle(
          backgroundColor: Color(0xFFCA8A04),
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ));
      start = pos + _searchQuery.length;
    }

    if (start < text.length) {
      children.addAll(_formatTerminalLogText(text.substring(start)));
    }
    return children;
  }

  List<TextSpan> _formatTerminalLogText(String rawText) {
    if (rawText.isEmpty) return [];

    final pattern = RegExp(
      r'(\d{4}-\d{2}-\d{2}[\sT]\d{2}:\d{2}:\d{2}(?:\.\d+)?|\d{2}:\d{2}:\d{2}(?:\.\d+)?)'
      r'|(Urt0 Received|Process|Received|Sent|Schedule|ERROR|FAIL|Failed|SUCCESS|ACK|MQTT|UART|BLE)'
      r'|(\{[^}]*\}|\[[^\]]*\])',
      caseSensitive: false,
    );

    final List<TextSpan> spans = [];
    int lastMatchEnd = 0;

    for (final match in pattern.allMatches(rawText)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: rawText.substring(lastMatchEnd, match.start),
          style: const TextStyle(color: Color(0xFFE2E8F0), fontFamily: 'monospace', fontSize: 13, height: 1.45),
        ));
      }

      final matchedText = match.group(0)!;
      Color textColor = const Color(0xFFE2E8F0);
      FontWeight weight = FontWeight.normal;

      if (match.group(1) != null) {
        textColor = const Color(0xFF94A3B8);
      } else if (match.group(2) != null) {
        final lower = matchedText.toLowerCase();
        if (lower.contains('error') || lower.contains('fail')) {
          textColor = const Color(0xFFF87171);
          weight = FontWeight.bold;
        } else if (lower.contains('urt0') || lower.contains('received')) {
          textColor = const Color(0xFF38BDF8);
          weight = FontWeight.w600;
        } else if (lower.contains('process') || lower.contains('success') || lower.contains('ack')) {
          textColor = const Color(0xFF34D399);
          weight = FontWeight.w600;
        } else if (lower.contains('mqtt') || lower.contains('uart') || lower.contains('ble')) {
          textColor = const Color(0xFFFBBF24);
          weight = FontWeight.w600;
        } else {
          textColor = const Color(0xFF818CF8);
        }
      } else if (match.group(3) != null) {
        textColor = const Color(0xFFA78BFA);
      }

      spans.add(TextSpan(
        text: matchedText,
        style: TextStyle(
          color: textColor,
          fontWeight: weight,
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.45,
        ),
      ));

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < rawText.length) {
      spans.add(TextSpan(
        text: rawText.substring(lastMatchEnd),
        style: const TextStyle(color: Color(0xFFE2E8F0), fontFamily: 'monospace', fontSize: 13, height: 1.45),
      ));
    }

    return spans;
  }

  List<int> _findMatches(String text, String query) {
    if (query.isEmpty) return [];
    List<int> matches = [];
    int start = 0;

    String lowerText = text.toLowerCase();
    String lowerQuery = query.toLowerCase();

    while (start < lowerText.length) {
      start = lowerText.indexOf(lowerQuery, start);
      if (start == -1) break;
      matches.add(start);
      start += lowerQuery.length;
    }

    return matches;
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void didUpdateWidget(covariant ScrollableTextWithSearch oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.text.length > oldWidget.text.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _matches = _searchQuery.isEmpty ? [] : _findMatches(widget.text, _searchQuery);
    _matchCount = _matches.length;
    final isNarrow = MediaQuery.of(context).size.width < 420;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search logs, timestamps...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.cancel_rounded, color: Color(0xFF94A3B8), size: 16),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              if (!isNarrow) ...[
                const SizedBox(width: 12),
                Text(
                  'Matches found: $_matchCount',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          if (isNarrow) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Matches found: $_matchCount',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: SelectableText.rich(
                      TextSpan(
                        children: _highlightText(widget.text, _matches),
                      ),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
