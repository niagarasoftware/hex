import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hex/modules/Preferences/state_management/preference_provider.dart';
import 'package:provider/provider.dart';
import '../../../Constants/constants.dart';
import '../../../services/communication_service.dart';
import '../../../services/mqtt_service.dart';

class PayloadProgressDialog extends StatefulWidget {
  final List<String> payloads;
  final String deviceId;
  final bool isToGem;
  final bool isWlc;
  final MqttService mqttService;
  final bool shouldSendFailedPayloads;

  const PayloadProgressDialog({
    super.key,
    required this.payloads,
    required this.deviceId,
    required this.isToGem,
    required this.isWlc,
    required this.mqttService,
    required this.shouldSendFailedPayloads,
  });

  @override
  State<PayloadProgressDialog> createState() => _PayloadProgressDialogState();
}

class _PayloadProgressDialogState extends State<PayloadProgressDialog> {
  late List<Map<String, dynamic>> payloadStatuses;
  bool breakLoop = false;
  bool isAllProcessed = false;
  bool isAllSent = false;
  String mqttError = '';
  bool isSending = false;

  static const Map<String, String> statusMessages = {
    "100": "Other settings",
    "200": "Voltage settings",
    "400-1": "Current settings for pump 1",
    "300-1": "Delay settings for pump 1",
    "500-1": "RTC settings for pump 1",
    "600-1": "Schedule config for pump 1",
    "400-2": "Current settings for pump 2",
    "300-2": "Delay settings for pump 2",
    "500-2": "RTC settings for pump 2",
    "600-2": "Schedule config for pump 2",
    "400-3": "Current settings for pump 3",
    "300-3": "Delay settings for pump 3",
    "500-3": "RTC settings for pump 3",
    "600-3": "Schedule config for pump 3",
    "400-4": "Current settings for pump 4",
    "300-4": "Delay settings for pump 4",
    "500-4": "RTC settings for pump 4",
    "600-4": "Schedule config for pump 4",
    "900": "Calibration settings",
    "55": "Valve settings",
    "57": "Moisture settings",
  };

  @override
  void initState() {
    super.initState();
    if (mounted) {
      payloadStatuses = widget.payloads.map((payload) {
        try {
          var payloadToDecode =
              widget.isToGem ? payload.split('+')[4] : payload;
          var decodedData = jsonDecode(payloadToDecode);
          var key = decodedData.keys.first;

          return {
            'payload': payload,
            'status': 'Pending',
            'reference':
                widget.isToGem ? payload.split('+')[2] : 'Device payload',
            'selected': true,
            'key': key,
          };
        } catch (error, stackTrace) {
          print(
              "==================== ERROR PARSING PAYLOAD ====================");
          print("Payload: $payload");
          print("Error: $error");
          print("StackTrace:\n$stackTrace");
          print(
              "===============================================================");
          return {
            'payload': payload,
            'status': 'Failed',
            'reference': 'Invalid payload',
            'selected': false,
            'key': '0',
          };
        }
      }).toList();
    }
  }

  void _checkAllProcessed() {
    bool allProcessed = payloadStatuses
        .where((s) => s['selected'])
        .every((p) => p['status'] != 'Pending');
    bool allSent = payloadStatuses
        .where((s) => s['selected'])
        .every((p) => p['status'] == 'Sent');

    if (mounted) {
      setState(() {
        if (allProcessed) {
          isAllProcessed = true;
          isAllSent = allSent;
        }
      });
    }
  }

  Future<void> _processPayloads() async {
    setState(() {
      isSending = true;
    });
    for (int i = 0; i < widget.payloads.length && !breakLoop; i++) {
      if (!payloadStatuses[i]['selected']) continue;
      var payload = widget.payloads[i];
      var payloadToDecode = widget.isToGem ? payload.split('+')[4] : payload;
      var decodedData = jsonDecode(payloadToDecode);
      var key = decodedData.keys.first;

      setState(() {
        payloadStatuses[i]['status'] = 'Sending';
      });

      bool isAcknowledged = await _waitForControllerResponse(payload, key, i);

      if (mounted) {
        setState(() {
          payloadStatuses[i]['status'] = isAcknowledged ? 'Sent' : 'Failed';
        });
      }
    }
    _checkAllProcessed();
  }

  Future<bool> _waitForControllerResponse(
      String payload, String key, int index) async {
    try {
      Map<String, dynamic> gemPayload = {};
      if (widget.isToGem) {
        gemPayload = {
          "5900": {
            "5901": payload,
          }
        };
      }
      final result = await context.read<CommunicationService>().sendCommand(
            serverMsg: '',
            payload: widget.isToGem
                ? jsonEncode(gemPayload)
                : widget.isWlc
                    ? Constants.sendPayloadWithCrc(jsonDecode(payload)[key])
                    : jsonDecode(payload)[key],
          );
      debugPrint("progress dialog result => $result");

      bool isAcknowledged = false;
      int maxWaitTime = 20;
      int elapsedTime = 0;
      int oroPumpIndex = 0;
      if (widget.isToGem) {
        oroPumpIndex = context
            .read<PreferenceProvider>()
            .commonPumpSettings!
            .indexWhere((element) => element.deviceId == payload.split('+')[2]);
      }
      await for (var mqttMessage
          in widget.mqttService.preferenceAckStream.timeout(
        Duration(seconds: maxWaitTime),
        onTimeout: (sink) {
          sink.close();
        },
      )) {
        if (elapsedTime >= maxWaitTime || breakLoop) break;

        if (mqttMessage!['cM'].contains(key) &&
            (widget.isToGem
                ? mqttMessage['cC'] == payload.split('+')[2]
                : true)) {
          context.read<PreferenceProvider>().updateControllerReaStatus(
                key: key,
                oroPumpIndex: oroPumpIndex,
                failed: widget.shouldSendFailedPayloads,
              );
          isAcknowledged = true;
          break;
        }

        await Future.delayed(const Duration(seconds: 1));
        elapsedTime++;
      }

      return isAcknowledged;
    } catch (error, stackTrace) {
      print(
          "==================== ERROR IN WAIT FOR RESPONSE ====================");
      print("Error: $error");
      print("StackTrace:\n$stackTrace");
      print(
          "====================================================================");
      return false;
    }
  }

  Future<void> retryFailedPayloads() async {
    setState(() {
      breakLoop = false;
      mqttError = '';
    });

    for (int i = 0; i < payloadStatuses.length; i++) {
      if (payloadStatuses[i]['selected'] &&
          payloadStatuses[i]['status'] == 'Failed') {
        var payload = payloadStatuses[i]['payload'];
        var payloadToDecode = widget.isToGem ? payload.split('+')[4] : payload;
        var decodedData = jsonDecode(payloadToDecode);
        var key = decodedData.keys.first;

        setState(() {
          payloadStatuses[i]['status'] = 'Retrying';
        });

        bool isAcknowledged = await _waitForControllerResponse(payload, key, i);

        setState(() {
          payloadStatuses[i]['status'] = isAcknowledged ? 'Sent' : 'Failed';
        });
      }
    }

    _checkAllProcessed();
  }

  Future<void> handleRetry() async {
    if (!widget.mqttService.isConnected) {
      setState(() {
        mqttError = 'MQTT Disconnected. Reconnecting...';
      });

      await widget.mqttService.connect();
      setState(() {
        mqttError = 'Trying to reconnect...';
      });
      await Future.delayed(const Duration(seconds: 3));
      if (widget.mqttService.isConnected) {
        setState(() {
          mqttError = '';
        });
        retryFailedPayloads();
      } else {
        setState(() {
          mqttError = 'MQTT Reconnection Failed!';
        });
      }
    } else {
      retryFailedPayloads();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final sentCount = payloadStatuses.where((s) => s['status'] == 'Sent').length;
    final totalCount = payloadStatuses.length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.sync_alt_rounded,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Processing Payloads",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Progress: $sentCount / $totalCount sent",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isSending && !isAllProcessed) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: totalCount > 0 ? sentCount / totalCount : null,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Payload list container
            Container(
              height: 320,
              width: MediaQuery.of(context).size.width > 400 ? 360 : 300,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: payloadStatuses.length,
                separatorBuilder: (context, index) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  var status = payloadStatuses[index];
                  String? key = status['key'];
                  String message = statusMessages[key] ?? "Unknown setting";
                  String currentStatus = status['status'];

                  Color statusColor = Colors.grey;
                  IconData statusIcon = Icons.hourglass_empty;

                  if (currentStatus == 'Sent') {
                    statusColor = Colors.green;
                    statusIcon = Icons.check_circle_rounded;
                  } else if (currentStatus == 'Failed') {
                    statusColor = Colors.red;
                    statusIcon = Icons.error_outline_rounded;
                  } else if (currentStatus == 'Sending' || currentStatus == 'Retrying') {
                    statusColor = primaryColor;
                    statusIcon = Icons.autorenew;
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: currentStatus == 'Failed'
                            ? Colors.red.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.15),
                      ),
                    ),
                    child: CheckboxListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      secondary: SizedBox(
                        height: 36,
                        width: 36,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (currentStatus == 'Sending' || currentStatus == 'Retrying')
                              SizedBox(
                                height: 32,
                                width: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                ),
                              )
                            else
                              Container(
                                height: 30,
                                width: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: statusColor.withOpacity(0.15),
                                ),
                                child: Center(
                                  child: Icon(
                                    statusIcon,
                                    size: 18,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      title: Text(
                        "${status['reference']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        message,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      value: payloadStatuses[index]['selected'],
                      onChanged: (bool? value) {
                        setState(() {
                          payloadStatuses[index]['selected'] = value!;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            if (mqttError.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        mqttError,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isAllProcessed && isAllSent) ...[
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text("Done"),
                  ),
                ] else ...[
                  OutlinedButton(
                    onPressed: () {
                      breakLoop = true;
                      Navigator.of(context).pop(false);
                    },
                    child: const Text("Cancel"),
                  ),
                ],
                if (isAllProcessed && !isAllSent) ...[
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: handleRetry,
                    style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade700),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text("Retry"),
                  ),
                ],
                if (!isSending && !isAllProcessed) ...[
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _processPayloads,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text("Send"),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
