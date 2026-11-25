import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../StateManagement/mqtt_payload_provider.dart';
import '../../flavors.dart';
import '../../repository/repository.dart';
import '../../services/communication_service.dart';
import '../../services/http_service.dart';
import '../../services/mqtt_service.dart';
import '../../utils/constants.dart';
import 'package:hex/utils/helpers/log_print.dart';


class ConfigureMqtt extends StatefulWidget {
  final deviceID, userId, controllerId,communicationType;

  const ConfigureMqtt(
      {super.key,
        required this.deviceID,
        required this.userId,
        required this.communicationType,
        required this.controllerId});

  @override
  _ConfigureMqttState createState() => _ConfigureMqttState();
}

class _ConfigureMqttState extends State<ConfigureMqtt> {
  late MqttPayloadProvider mqttPayloadProvider;
  List<Map<String, dynamic>> configs = [];
  int? selectedIndex;
  bool isLoading = true;
  String errorMessage = '';
  String? formattedConfig;

  // New fields
  String macAddress = '';
  String? selectedPlatform;
  String? selectedVersion;
  String? selectedDealer;

  final List<String> platforms = ['AWS', 'Azure'];
  final List<String> dealers = ['ORO', 'LK'];
  final List<String> versions = ['Version 1.0', 'Version 1.1'];
  final TextEditingController _macController = TextEditingController();
  final Repository repository = Repository(HttpService());
  String _lastPayload = '';

  @override
  void initState() {
    super.initState();
    mqttPayloadProvider =
        Provider.of<MqttPayloadProvider>(context, listen: false);

    mqttPayloadProvider.addListener(_onPayloadChanged);
    fetchData();
    _macController.text = widget.deviceID;
    macAddress = widget.deviceID;
  }
  @override
  void dispose() {
    mqttPayloadProvider.removeListener(_onPayloadChanged);
    super.dispose();
  }

  void _onPayloadChanged() {
    final provider =
    Provider.of<MqttPayloadProvider>(context, listen: false);

    final payload = provider.receivedPayload;


    if (payload.isNotEmpty && payload != _lastPayload) {
      _lastPayload = payload;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!payload.contains("6801") ? payload : ""),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> fetchData() async {
    AppLog.log('fetchData ');
    final url = Uri.parse('http://13.235.254.21:9000/getConfigs');

    try {
      final response =
      await http.get(url, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> rawConfigs = data['data'];
        configs = rawConfigs.cast<Map<String, dynamic>>();

        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load configs: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching data: $e,';
        isLoading = false;
      });
    }
  }

  String formatConfig(Map<String, dynamic> config) {
    if (selectedVersion == 'Version 1.0') {
      return '${config['MQTT_IP'] ?? '-'},'
          '${config['MQTT_USER_NAME'] ?? '-'},'
          '${config['MQTT_PASSWORD'] ?? '-'},'
          '${config['MQTT_PORT'] ?? '-'},'
          '${config['HTTP_URL'] ?? '-'},'
          '${config['STATIC_IP'] ?? '-'},'
          '${config['SUBNET_MASK'] ?? '-'},'
          '${config['DEFAULT_GATEWAY'] ?? '-'},'
          '${config['DNS_SERVER'] ?? '-'},'
          '${config['FTP_IP'] ?? '-'},'
          '${config['FTP_USER_NAME'] ?? '-'},'
          '${config['FTP_PASSWORD'] ?? '-'},'
          '${config['FTP_PORT'] ?? '-'},'
          '${config['MQTT_FRONTEND_TOPIC'] ?? '-'},'
          '${config['MQTT_HARDWARE_TOPIC'] ?? '-'},'
          '${config['MQTT_SERVER_TOPIC'] ?? '-'}';
    } else {
      return '${config['MQTT_IP'] ?? '-'},'
          '${config['MQTT_USER_NAME'] ?? '-'},'
          '${config['MQTT_PASSWORD'] ?? '-'},'
          '${config['MQTT_PORT'] ?? '-'},'
          '${config['HTTP_URL'] ?? '-'},'
          '${config['STATIC_IP'] ?? '-'},'
          '${config['SUBNET_MASK'] ?? '-'},'
          '${config['DEFAULT_GATEWAY'] ?? '-'},'
          '${config['DNS_SERVER'] ?? '-'},'
          '${config['FTP_IP'] ?? '-'},'
          '${config['FTP_USER_NAME'] ?? '-'},'
          '${config['FTP_PASSWORD'] ?? '-'},'
          '${config['FTP_PORT'] ?? '-'},'
          '${config['MQTT_FRONTEND_TOPIC'] ?? '-'},'
          '${config['MQTT_HARDWARE_TOPIC'] ?? '-'},'
          '${config['MQTT_SERVER_TOPIC'] ?? '-'},'
          '${config['SFTP_IP'] ?? '-'},'
          '${config['SFTP_USER_NAME'] ?? '-'},'
          '${config['SFTP_PASSWORD'] ?? '-'},'
          '${config['SFTP_PORT'] ?? '-'},'
          '${config['MQTTS_PORT'] ?? '-'},'
          '${config['MQTTS_STATUS'] ?? '-'},'
          '${config['REVERSE_SSH_BROKER_NAME'] ?? '-'},'
          '${config['REVERSE_SSH_PORT'] ?? '-'}';
    }
  }

  Future<void> sendSelectedProject() async {
    if (selectedIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a project")),
      );
      return;
    }
    final selectedConfig = configs[selectedIndex!];
    final formatted = formatConfig(selectedConfig);
    if(widget.communicationType == "MQTT") {
      List checkTopic =
      getMqttTopic(selectedPlatform!, selectedVersion!, selectedDealer!);
      AppLog.log('checkTopic---->$checkTopic,$macAddress');
      String topic = checkTopic[0];
      String oldnewcheck = checkTopic[1];
      if (oldnewcheck == '1') {
        final payload = {
          "6100": [
            {"6101": formatted},
          ]
        };
        MqttService().topicToPublishAndItsMessage(
          jsonEncode(payload),
          "$topic${_macController.text}",
        );
        AppLog.log('payload $payload  \n $topic${_macController.text}');
      } else {
        final payload = {
          "6100": {"6101": formatted}
        };
        MqttService().topicToPublishAndItsMessage(
          jsonEncode(payload),
          "$topic${_macController.text}",
        );
        AppLog.log('payload $payload  \n $topic${_macController.text}');
      }
    }
    else
    {
      //bluetooth
      try {
        String payLoadFinal = jsonEncode({
          "6100": {"6101": formatted}
        });
        final result = await context.read<CommunicationService>().sendCommand(payload: payLoadFinal,
            serverMsg: '');
        debugPrint("Payload sent to Server$payLoadFinal");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Settings sent Ble")),
        );
        if (result['http'] == true) {
          debugPrint("Payload sent to Server ");
        }
        if (result['mqtt'] == true) {
          debugPrint("Payload sent to MQTT Box ");
        }
        if (result['bluetooth'] == true) {
          debugPrint("Payload sent via Bluetooth ");
        }

      } finally {
        setState(() => isLoading = false);
      }
    }
    var data = {
      "userId": widget.userId,
      "controllerId": widget.controllerId,
      "data": {
        "6100": [
          {"6101": formatted},
        ]
      },
      "messageStatus": "Settings update",
      "createUser": widget.userId,
      "hardware": {
        "6100": [
          {"6101": formatted},
        ]
      },
    };
    await repository.sendManualOperationToServer(data);
  }

  List<String> getMqttTopic(
      String selectedPlatform, String selectedVersion, String selecteddealer) {
    if (selecteddealer == 'ORO') {
      if (selectedPlatform == 'AWS') {
        AppLog.log('return ORO AWS');
        if(F.appFlavor == Flavor.agritel)
        {
          AppLog.log("agritel");
          return ['AgritelAppToFirmware/', '0'];
        }

        if (selectedVersion == 'Version 1.0') {
          return ['AppToFirmware/', '1'];
        } else {
          return ['OroAppToFirmware/', '0'];
        }
      }
    } else {
      if (selectedPlatform == 'AWS') {
        AppLog.log('return LK AWS');
        if (selectedVersion == 'Version 1.0') return ['AppsToFirmware/', '1'];
      } else {
        AppLog.log('return LK azure');
        if (selectedVersion == 'Version 1.0') {
          return ['AppsToFirmware/', '1'];
        } else {
          return ['AppToFirmware/', '0'];
        }
      }
    }
    AppLog.log('return else');
    return ['AppToFirmware/', '0'];
  }

  Future<void> viewsettings() async {
    if(widget.communicationType == "MQTT")
    {
      List checkTopic =
      getMqttTopic(selectedPlatform!, selectedVersion!, selectedDealer!);
      String topic = checkTopic[0];
      String oldnewcheck = checkTopic[1];
      if (oldnewcheck == '1') {
        final payload = {
          "5700": [
            {"5701": "22"},
          ]
        };
        MqttService().topicToPublishAndItsMessage(
          jsonEncode(payload),
          "$topic${_macController.text}",
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("view settings sent")),
        );
      } else {
        final payload = {
          "5700": {"5701": "22"}
        };
        MqttService().topicToPublishAndItsMessage(
          jsonEncode(payload),
          "$topic${_macController.text}",
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("view settings sent")),
        );
      }
    }
    else   {
      //bluetooth
      try {
        String payLoadFinal = jsonEncode({
          "5700": {"5701": "22"}
        });
        final result = await context.read<CommunicationService>().sendCommand(payload: payLoadFinal,
            serverMsg: '');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("view settings sent Ble")),
        );
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
    var data = {
      "userId": widget.userId,
      "controllerId": widget.controllerId,
      "data": {
        "5700": [
          {"5701": "22"},
        ]
      },
      "messageStatus": "View Settings",
      "createUser": widget.userId,
      "hardware": {
        "5700": [
          {"5701": "22"},
        ]
      },
    };
    await repository.sendManualOperationToServer(data);
  }

  Future<void> updateCode() async {
    if(widget.communicationType == "MQTT") {
      List checkTopic =
      getMqttTopic(selectedPlatform!, selectedVersion!, selectedDealer!);
      String topic = checkTopic[0];
      String oldnewcheck = checkTopic[1];
      final payload = oldnewcheck == '1'
          ? {"5700": [{"5701": "27"}]}
          : {"5700": {"5701": "28"}};

      MqttService().topicToPublishAndItsMessage(
        jsonEncode(payload),
        "$topic${_macController.text}",
      );

      var data = {
        "userId": widget.userId,
        "controllerId": widget.controllerId,
        "data": payload,
        "messageStatus": "updateCode",
        "createUser": widget.userId,
        "hardware": payload,
      };
      await repository.sendManualOperationToServer(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("update settings sent")),
      );
    } else {
      //bluetooth
      try {
        String payLoadFinal = jsonEncode({
          "5700": {"5701": "28"}
        });
        final result = await context.read<CommunicationService>().sendCommand(
            payload: payLoadFinal, serverMsg: 'updateCode');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("update settings sent Ble")),
        );
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> updateCodeonly() async {
    if(widget.communicationType == "MQTT") {
      List checkTopic =
      getMqttTopic(selectedPlatform!, selectedVersion!, selectedDealer!);
      String topic = checkTopic[0];
      String oldnewcheck = checkTopic[1];
      final payload = oldnewcheck == '1'
          ? {"5700": [{"5701": "3"}]}
          : {"5700": {"5701": "3"}};

      MqttService().topicToPublishAndItsMessage(
        jsonEncode(payload),
        "$topic${_macController.text}",
      );

      var data = {
        "userId": widget.userId,
        "controllerId": widget.controllerId,
        "data": payload,
        "messageStatus": "updateCode",
        "createUser": widget.userId,
        "hardware": payload,
      };
      await repository.sendManualOperationToServer(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("update settings sent")),
      );
    } else {
      //bluetooth
      try {
        String payLoadFinal = jsonEncode({
          "5700": {"5701": "3"}
        });
        final result = await context.read<CommunicationService>().sendCommand(
            payload: payLoadFinal, serverMsg: 'updateCode');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("update settings sent Ble")),
        );
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> Restart() async {
    if(widget.communicationType == "MQTT") {
      List checkTopic =
      getMqttTopic(selectedPlatform!, selectedVersion!, selectedDealer!);
      String topic = checkTopic[0];
      String oldnewcheck = checkTopic[1];
      final payload = oldnewcheck == '1'
          ? {"5700": [{"5701": "2"}]}
          : {"5700": {"5701": "2"}};

      MqttService().topicToPublishAndItsMessage(
        jsonEncode(payload),
        "$topic${_macController.text}",
      );

      var data = {
        "userId": widget.userId,
        "controllerId": widget.controllerId,
        "data": payload,
        "messageStatus": "Restart",
        "createUser": widget.userId,
        "hardware": payload,
      };
      await repository.sendManualOperationToServer(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Restart settings sent")),
      );
    } else {
      //bluetooth
      try {
        String payLoadFinal = jsonEncode({
          "5700": {"5701": "2"}
        });
        final result = await context.read<CommunicationService>().sendCommand(
            payload: payLoadFinal, serverMsg: 'Restart');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Restart settings sent Ble")),
        );
      } finally {
        setState(() => isLoading = false);
      }
    }
  }


  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final primaryColor = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    final primaryColor = Theme.of(context).primaryColor;
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Future<void> _confirmAction({
    required String title,
    required String message,
    required Future<void> Function() action,
    String confirmLabel = 'Yes',
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await action();
    }
  }

  Widget _actionButton(String label, IconData icon, Color color,
      VoidCallback onPressed) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(165, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: true);
    final primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: primaryColor.withOpacity(0.01),
      appBar: AppBar(
        title: const Text('Configure Hardware',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
          : errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(errorMessage,
                        style: const TextStyle(color: Colors.red)),
                  ),
                )
              : LayoutBuilder(builder: (context, constraints) {
                  final outerPadding = constraints.maxWidth < 600 ? 16.0 : 24.0;
                  final availableWidth =
                      (constraints.maxWidth - outerPadding * 2).clamp(0.0, 1200.0);
                  const gap = 16.0;
                  final columns = availableWidth >= 900 ? 3 :
                  availableWidth >= 560 ? 2 : 1;
                  final cardWidth = (availableWidth - gap * (columns - 1)) / columns;
                  return SingleChildScrollView(
                    padding: EdgeInsets.all(outerPadding),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hardware Provisioning & Configuration',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Manage device connection and firmware settings',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    widget.communicationType.toString(),
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: [
                                SizedBox(
                                  width: cardWidth,
                                  child: _sectionCard(
                                    title: 'MAC Address',
                                    icon: Icons.fingerprint,
                                    child: TextField(
                                      controller: _macController,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'monospace',
                                        color: Color(0xFF1E293B),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      onChanged: (value) => macAddress = value,
                                      decoration: _fieldDecoration('Enter MAC Address'),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _sectionCard(
                                    title: 'Current Dealer',
                                    icon: Icons.business,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: selectedDealer,
                                      isExpanded: true,
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      decoration: _fieldDecoration('Select Dealer'),
                                      items: dealers.map((dealer) => DropdownMenuItem<String>(
                                        value: dealer,
                                        child: Text(dealer),
                                      )).toList(),
                                      onChanged: (value) => setState(() => selectedDealer = value),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _sectionCard(
                                    title: 'Current Platform',
                                    icon: Icons.cloud_outlined,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: selectedPlatform,
                                      isExpanded: true,
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      decoration: _fieldDecoration('Select Platform'),
                                      items: platforms.map((platform) => DropdownMenuItem<String>(
                                        value: platform,
                                        child: Text(platform),
                                      )).toList(),
                                      onChanged: (value) => setState(() {
                                        AppLog.log('flaVOR ${F.appFlavor}');
                                        AppLog.log(AppConstants.mqttUrl);
                                        selectedPlatform = value;
                                      }),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _sectionCard(
                                    title: 'Current Version',
                                    icon: Icons.system_update_alt,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: selectedVersion,
                                      isExpanded: true,
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      decoration: _fieldDecoration('Select Version'),
                                      items: versions.map((version) => DropdownMenuItem<String>(
                                        value: version,
                                        child: Text(version),
                                      )).toList(),
                                      onChanged: (value) => setState(() => selectedVersion = value),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _sectionCard(
                                    title: 'Update Project',
                                    icon: Icons.folder_outlined,
                                    child: DropdownButtonFormField<int>(
                                      initialValue: selectedIndex,
                                      isExpanded: true,
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      decoration: _fieldDecoration('Select Update Project'),
                                      items: List.generate(configs.length, (index) {
                                        final config = configs[index];
                                        return DropdownMenuItem<int>(
                                          value: index,
                                          child: Text(
                                            '${config['PROJECT_NAME']} - ${config['SERVER_NAME']}',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }),
                                      onChanged: (index) => setState(() {
                                        selectedIndex = index;
                                        formattedConfig = index != null
                                            ? formatConfig(configs[index])
                                            : null;
                                      }),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _sectionCard(
                              title: 'Hardware Actions',
                              icon: Icons.tune,
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  _actionButton(
                                    'Settings Update',
                                    Icons.sync_rounded,
                                    primaryColor,
                                    () => _confirmAction(
                                      title: 'Confirm Settings Update',
                                      message: 'Are you sure you want to update settings?',
                                      action: sendSelectedProject,
                                    ),
                                  ),
                                  _actionButton(
                                    'Update HW Code',
                                    Icons.code_rounded,
                                    const Color(0xFF22C55E),
                                    () => _confirmAction(
                                      title: 'Confirm Update',
                                      message: 'Are you sure you want to update HW Code?',
                                      confirmLabel: 'Yes, Update',
                                      action: updateCode,
                                    ),
                                  ),
                                  _actionButton(
                                    'View Settings',
                                    Icons.visibility_rounded,
                                    const Color(0xFF475569),
                                    () {
                                      viewsettings();
                                    },
                                  ),
                                  if (widget.communicationType != 'MQTT') ...[
                                    _actionButton(
                                      'Update',
                                      Icons.upload_rounded,
                                      const Color(0xFF0D9488),
                                      () => _confirmAction(
                                        title: 'Confirm Settings Update',
                                        message: 'Are you sure you want to update settings?',
                                        action: updateCodeonly,
                                      ),
                                    ),
                                    _actionButton(
                                      'Restart',
                                      Icons.restart_alt_rounded,
                                      const Color(0xFFE11D48),
                                      () => _confirmAction(
                                        title: 'Confirm Restart',
                                        message: 'Are you sure you want to Restart?',
                                        confirmLabel: 'Yes, Restart',
                                        action: Restart,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (widget.communicationType != 'MQTT' &&
                                mqttPayloadProvider.receivedPayload.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              _sectionCard(
                                title: 'Device Response',
                                icon: Icons.terminal,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: SelectableText(
                                    mqttPayloadProvider.receivedPayload,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: Color(0xFF38BDF8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
    );
  }
}
