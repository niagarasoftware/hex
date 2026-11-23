import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hex/Screens/Dealer/pumpTopicChange.dart';
import 'package:hex/utils/constants.dart';
import 'package:hex/utils/environment.dart';
import 'package:provider/provider.dart';
import '../../StateManagement/mqtt_payload_provider.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../services/mqtt_service.dart';
import '../../utils/shared_preferences_helper.dart';
import 'configureMqttTopic.dart';
import 'controllerlogfile.dart';
import 'frequencyLoRaPage.dart';
import 'package:hex/utils/helpers/log_print.dart';

class ResetVerssion extends StatefulWidget {
  const ResetVerssion(
      {Key? key,
        required this.userId,
        required this.createUser,
        required this.controllerId,
        required this.deviceID,
        required this.modeID,
      });
  final userId, controllerId, deviceID,modeID,createUser;

  @override
  _ResetVerssionState createState() => _ResetVerssionState();
}

class _ResetVerssionState extends State<ResetVerssion> {
  List<Map<String, dynamic>> mergedList = [];
  late MqttPayloadProvider mqttPayloadProvider;
  IconData iconData = Icons.start;
  Color iconcolor = Colors.transparent;
  String imeicheck = '';
  int checkrst = 0;
  int? selectindex;
  int checkupdatediable = 0;
  TextEditingController frequency1Controller = TextEditingController();
  TextEditingController frequency2Controller = TextEditingController();
  TextEditingController sf1Controller = TextEditingController();
  TextEditingController sf2Controller = TextEditingController();
  String? userRole;


  valAssing(List<dynamic> data) {
    mergedList = [];
    for (var device in data) {
      mergedList.add({
        'controllerId': device['controllerId'],
        'deviceId': device['deviceId'],
        'deviceName': device['deviceName'],
        'categoryId': device['categoryId'],
        'categoryName': device['categoryName'],
        'modelId': device['modelId'],
        'modelName': device['modelName'],
        'loraFrequency': device['loraFrequency'],
        'latestVersion': device['latestVersion'] ?? '',
        'currentVersion': device['currentVersion'] ?? '',
        'status': 'Status',
      });
    }
  }

  Future<void> fetchData() async {
    try{
      final Repository repository = Repository(HttpService());
      var response = await repository.getUserDeviceFirmwareDetails({"userId": widget.userId,"controllerId": widget.controllerId});
      if (response.statusCode == 200) {
        final jsondata = jsonDecode(response.body);
        if (!mounted) return;
        setState(() => valAssing(jsondata['data'] ?? []));
        MqttService().connect();
      } else {
        //_showSnackBar(response.body);
      }
    }
    catch (e, stackTrace) {
      AppLog.log(' Error overAll getData => ${e.toString()}');
      AppLog.log(' trace overAll getData  => ${stackTrace}');
    }


  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    mqttPayloadProvider =
        Provider.of<MqttPayloadProvider>(context, listen: false);
    mqttPayloadProvider.addListener(_onMqttPayload);
    fetchData();
    checkrole().then((role) {
      if (mounted) setState(() => userRole = role);
    });
  }

  bool _specialUpdateBusy = false;

  bool get _isSpecialModel => [
    ...AppConstants.ecoGemModelList,
    ...AppConstants.shine2V,
    ...AppConstants.shine4V,
    ...AppConstants.elite10V,
    ...AppConstants.pumpList,
    ...AppConstants.pumpPlusModelList,
    ...AppConstants.pumpModelList,
  ].map((e) => e.toString()).contains(widget.modeID.toString());

  void _onMqttPayload() {
    if (!mounted || selectindex == null ||
        selectindex! < 0 || selectindex! >= mergedList.length) return;
    setState(() => status());
  }

  Future<void> showAdminPasswordDialog(int index) async {
    if (_specialUpdateBusy || index < 0 || index >= mergedList.length) return;
    setState(() => _specialUpdateBusy = true);
    final passwordController = TextEditingController();
    bool loading = false;
    bool hidden = true;
    String? error;
    bool verified = false;
    try {
      verified = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, updateDialog) => AlertDialog(
            title: const Text('Admin Confirmation'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter admin password to update firmware.'),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: hidden,
                  enabled: !loading,
                  decoration: InputDecoration(
                    labelText: 'Admin Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    errorText: error,
                    suffixIcon: IconButton(
                      icon: Icon(hidden ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => updateDialog(() => hidden = !hidden),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: loading ? null : () async {
                  final userPsw = passwordController.text;
                  if (userPsw.trim().isEmpty) {
                    updateDialog(() => error = 'Please enter admin password');
                    return;
                  }
                  updateDialog(() { loading = true; error = null; });
                  try {
                    final repository = Repository(HttpService());
                    final response = await repository.checkpassword({'passkey': userPsw});
                    if (!dialogContext.mounted) return;
                    if (response.statusCode == 200) {
                      final jsonData = jsonDecode(response.body);
                      if (jsonData['code'] == 200) {
                        Navigator.pop(dialogContext, true);
                        return;
                      }
                      updateDialog(() => error =
                          jsonData['message']?.toString() ?? 'Incorrect password');
                    } else {
                      updateDialog(() => error = 'Password verification failed');
                    }
                  } catch (_) {
                    if (dialogContext.mounted) {
                      updateDialog(() => error = 'Unable to verify password');
                    }
                  } finally {
                    if (dialogContext.mounted) updateDialog(() => loading = false);
                  }
                },
                child: loading
                    ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Verify'),
              ),
            ],
          ),
        ),
      ) ?? false;
      if (verified && mounted) {
        await showFirmwareUpdateConfirmation(index);
      }
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      passwordController.dispose();
      if (mounted) setState(() => _specialUpdateBusy = false);
    }
  }

  Future<void> showFirmwareUpdateConfirmation(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Firmware Update Confirmation'),
        content: const Text('Admin verified successfully.\n\n'
            'Are you sure you want to update the controller firmware?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) sendSpecialFirmwareUpdate(index);
  }

  void sendSpecialFirmwareUpdate(int index) {
    if (index < 0 || index >= mergedList.length) return;
    final deviceId = mergedList[index]['deviceId']?.toString() ?? '';
    if (deviceId.isEmpty) {
      _showSnackBar('Device ID missing');
      return;
    }
    final topic = '${Environment.mqttPublishTopic}/$deviceId';
    MqttService().topicToPublishAndItsMessage('FW\$', topic);
    _showSnackBar('Firmware update command published');
  }

  ResetAll(int index) async {
    sendHttp("2","Controller Restart");
    mergedList[index]["status"] = 'Started';
    iconData = Icons.restart_alt;
    iconcolor = Colors.blue;
    Map<String, dynamic> payLoadFinal = {
      "5700":
      {"5701": "2"},

    };
    MqttService().topicToPublishAndItsMessage(jsonEncode(payLoadFinal), "${Environment.mqttPublishTopic}/${mergedList[index]["deviceId"]}");

  }
  statusCheck(int index) async {
    Map<String, dynamic> payLoadFinal = {
      "5700":
      {"5701": "31"},

    };
    MqttService().topicToPublishAndItsMessage(jsonEncode(payLoadFinal), "${Environment.mqttPublishTopic}/${mergedList[index]["deviceId"]}");

  }

  Update(int index) async {


    sendHttp("3","Controller Version Update");
    mergedList[index]["status"] = 'Started';
    iconData = Icons.start;
    iconcolor = Colors.blue;
    Map<String, dynamic> payLoadFinal = {
      "5700":
      {"5701": "3"},
    };

    MqttService().topicToPublishAndItsMessage(jsonEncode(payLoadFinal), "${Environment.mqttPublishTopic}/${mergedList[index]["deviceId"]}");
    // GlobalSnackBar.show(context, mqttPayloadProvider.messageFromHw, 200);
    // MQTTManager().publish(payLoadFinal, 'OroGemLog/${overAllPvd.imeiNo}');
  }

  bool compareVersions(String version1, String version2) {
    // Extract the version part before the colon
    String cleanVersion1 = version1.split(':')[0];
    String cleanVersion2 = version2.split(':')[0];

    // Split and convert to integer lists
    List<int> version1Parts = cleanVersion1.split('.').map(int.parse).toList();
    List<int> version2Parts = cleanVersion2.split('.').map(int.parse).toList();

    int length = max(version1Parts.length, version2Parts.length);
    for (int i = 0; i < length; i++) {
      int v1 = i < version1Parts.length ? version1Parts[i] : 0;
      int v2 = i < version2Parts.length ? version2Parts[i] : 0;

      if (v1 > v2) {
        return true; // version1 is greater
      } else if (v1 < v2) {
        return false; // version1 is less
      }
    }

    return false; // versions are equal, so not greater
  }

  Future<String?> checkrole() async {
    String? role = await PreferenceHelper.getUserRole();
    return role;
  }

  @override
  void dispose() {
    mqttPayloadProvider.removeListener(_onMqttPayload);
    frequency1Controller.dispose();
    frequency2Controller.dispose();
    sf1Controller.dispose();
    sf2Controller.dispose();
    super.dispose();
  }

  Widget _buildGridItem(String title, String value, {bool isCopyable = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SelectableText(
                value,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (isCopyable && value.isNotEmpty) ...[
              SizedBox(width: 2),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  _showSnackBar('Device ID copied to clipboard');
                },
                child: Icon(Icons.copy, size: 12, color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: true);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final progressValue = (double.tryParse(
      mqttPayloadProvider.proogressstatus.replaceAll('%', '').trim(),
    ) ?? 0).clamp(0, 100).toDouble() / 100;

    return SafeArea(
      child: Scaffold(
         appBar: AppBar(
           title: Text(
            'Controller Info',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: fetchData,
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 1 : (kIsWeb ? 2 : 1),
                  crossAxisSpacing: 20,
                  mainAxisSpacing: isMobile ? 16 : 24,
                  mainAxisExtent: isMobile ? 520 : 480,
                ),
                padding: EdgeInsets.all(5),
                itemCount: mergedList.length,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.7), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.shadow.withOpacity(0.06),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Top Center Icon Box & Title Section
                              Column(
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6), width: 1),
                                    ),
                                    child: Icon(
                                      Icons.memory,
                                      size: 36,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'CONTROLLER SPECIFICATION',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    mergedList[index]['categoryName'] ?? '',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),

                              // Action Pills Row
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6)),
                                      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        selectindex = index;
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ControllerLog(
                                              deviceID: '${mergedList[index]['deviceId']!}',
                                              communicationType: 'MQTT',
                                            ),
                                          ),
                                        );
                                      });
                                    },
                                    icon: Icon(Icons.arrow_circle_right_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
                                    label: Text(
                                      'Logs',
                                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  if (![
                                    ...AppConstants.ecoGemModelList,
                                    ...AppConstants.shine2V,
                                    ...AppConstants.shine4V,
                                    ...AppConstants.elite10V
                                  ].contains(widget.modeID))
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6)),
                                        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          AppLog.log('mergedList[index]:${mergedList[index]['modelId']}');
                                          selectindex = index;
                                          if (AppConstants.pumpList.contains(mergedList[index]['modelId'])) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => PumpTopicChangePage(
                                                  deviceID: '${mergedList[index]['deviceId']!}',
                                                  userId: widget.userId,
                                                  controllerId: widget.controllerId,
                                                  modelId: mergedList[index]['modelId'],
                                                  communicationType: "MQTT",
                                                ),
                                              ),
                                            );
                                          } else {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ConfigureMqtt(
                                                  deviceID: '${mergedList[index]['deviceId']!}',
                                                  userId: widget.userId,
                                                  controllerId: widget.controllerId,
                                                  communicationType: "MQTT",
                                                ),
                                              ),
                                            );
                                          }
                                        });
                                      },
                                      icon: Icon(Icons.settings_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
                                      label: Text(
                                        'Setting Update',
                                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6)),
                                      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        selectindex = index;
                                      });
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FrequencyPage(
                                            userId: widget.userId,
                                            controllerId: widget.controllerId,
                                            deviceId: mergedList[index]['deviceId'] ?? widget.deviceID,
                                            plusTrue: true,
                                            loraValue: mergedList[index]['loraFrequency'] ?? '',
                                            loara1Version: mqttPayloadProvider.Loara1verssion,
                                            loara2Version: mqttPayloadProvider.Loara2verssion,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: Icon(Icons.settings_applications, size: 16, color: Theme.of(context).colorScheme.primary),
                                    label: Text(
                                      'LoRa Key',
                                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  if (userRole == 'admin')
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6)),
                                        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          selectindex = index;
                                        });
                                      },
                                      icon: Icon(Icons.upgrade, size: 16, color: Theme.of(context).colorScheme.primary),
                                      label: Text(
                                        'LoRa Update',
                                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                ],
                              ),

                              // Card Body Data Grid
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
                                ),
                                child: isMobile
                                    ? Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: _buildGridItem('MAC ADDRESS', mergedList[index]['deviceId'] ?? '', isCopyable: true)),
                                        Expanded(child: _buildGridItem('MODEL', mergedList[index]['modelName'] ?? '')),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(child: _buildGridItem('FIRMWARE BUILD', mergedList[index]['currentVersion'] ?? '')),
                                        if (![
                                          ...AppConstants.ecoGemModelList,
                                          ...AppConstants.shine2V,
                                          ...AppConstants.shine4V,
                                          ...AppConstants.elite10V
                                        ].contains(widget.modeID))
                                          Expanded(child: _buildGridItem('SERVER TARGET', mergedList[index]['latestVersion'] ?? '')),
                                      ],
                                    ),
                                  ],
                                )
                                    : Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Expanded(child: _buildGridItem('MAC ADDRESS', mergedList[index]['deviceId'] ?? '', isCopyable: true)),
                                    Expanded(child: _buildGridItem('MODEL', mergedList[index]['modelName'] ?? '')),
                                    Expanded(child: _buildGridItem('FIRMWARE BUILD', mergedList[index]['currentVersion'] ?? '')),
                                    if (![
                                      ...AppConstants.ecoGemModelList,
                                      ...AppConstants.shine2V,
                                      ...AppConstants.shine4V,
                                      ...AppConstants.elite10V
                                    ].contains(widget.modeID))
                                      Expanded(child: _buildGridItem('SERVER TARGET', mergedList[index]['latestVersion'] ?? '')),
                                  ],
                                ),
                              ),

                              // Status / Progress indicator if active
                              if (mergedList[index]['status'] != 'Status')
                                Padding(
                                  padding: EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            statusCheck(index);
                                          });
                                        },
                                        icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.primary, size: 16),
                                      ),
                                      Expanded(
                                        child: LinearProgressIndicator(
                                          value: progressValue,
                                          minHeight: 6,
                                          backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.4),
                                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '${mqttPayloadProvider.proogressstatus}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Card Footer Action Buttons
                              SizedBox(
                                height: 48,
                                child: Row(
                                  children: [
                                    if (!_isSpecialModel) ...[
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6)),
                                            backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            padding: EdgeInsets.symmetric(vertical: 12),
                                          ),
                                          onPressed: () {
                                            if (checkupdatediable == 0) {
                                              resetItem(index);
                                            } else {
                                              _showSnackBar('Please wait ....');
                                            }
                                          },
                                          icon: Icon(Icons.refresh, size: 16, color: Theme.of(context).colorScheme.primary),
                                          label: Text(
                                            'Restart Controller',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurface,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: FilledButton.icon(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: checkupdatediable == 0
                                                ? Theme.of(context).colorScheme.primary
                                                : Theme.of(context).colorScheme.onSurfaceVariant,
                                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            padding: EdgeInsets.symmetric(vertical: 12),
                                          ),
                                          onPressed: () {
                                            if (checkupdatediable == 0) {
                                              updateItem(index);
                                            } else {
                                              _showSnackBar('Please wait ....');
                                            }
                                          },
                                          icon: Icon(Icons.upload, size: 16),
                                          label: checkupdatediable == 0 &&
                                              mergedList[index]['currentVersion'] !=
                                                  mergedList[index]['latestVersion']
                                              ? BlinkingText(
                                            text: 'Update Firmware',
                                            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                            blinkDuration: Duration(milliseconds: 500),
                                          )
                                              : Text(
                                            'Update Firmware',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      Expanded(
                                        child: FilledButton.icon(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Theme.of(context).colorScheme.primary,
                                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            padding: EdgeInsets.symmetric(vertical: 12),
                                          ),
                                          onPressed: _specialUpdateBusy
                                              ? null
                                              : () => showAdminPasswordDialog(index),
                                          icon: Icon(Icons.upload, size: 16),
                                          label: Text(
                                            'Update Firmware',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  sendHttp(String val, String msgstatus) async {
    Map<String, dynamic> payLoadFinal = {
      "5700":
      {"5701": "$val"},

    };
    Map<String, dynamic> body = {
      "userId": widget.userId,
      "controllerId": widget.controllerId,
      "hardware": payLoadFinal,
      "messageStatus": msgstatus,
      "createUser": widget.createUser
    };


    final Repository repository = Repository(HttpService());
    var response = await repository.sendManualOperationToServer(body);

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data["code"] == 200) {
        _showSnackBar(data["message"]);
      } else {
        _showSnackBar(data["message"]);
      }
    }
  }

  status() {
    if (selectindex != null) {
      Map<String, dynamic>? ctrldata = mqttPayloadProvider.messageFromHw;
      if ((ctrldata != null && ctrldata.isNotEmpty)) {
        var name = ctrldata['Name']?.toString() ?? '';
        // String message = ctrldata['Message'];
        var code = ctrldata['Code'];
        // imeicheck = ctrldata['DeviceId'];
        if (name.contains('Started')) {
          mergedList[selectindex!]['status'] = 'Started';
          iconData = Icons.start;
          iconcolor = Colors.blue;
        }
        else  if (name.contains('Code Update Progress')) {
          mergedList[selectindex!]['status'] = 'Progress';
          iconData = Icons.start;
          iconcolor = Colors.blue;
        }
        else if (name.contains('Restarting')) {
          mergedList[selectindex!]['status'] = 'Restarting...';
          iconData = Icons.incomplete_circle;
          iconcolor = Colors.teal;
        } else if (name.contains('Turned')) {
          iconData = Icons.check_circle;
          mergedList[selectindex!]['status'] = checkrst == 0
              ? 'Last update:${ctrldata['Time']}'
              : 'Last Restart:${ctrldata['Time']}';
          iconcolor = Colors.green;
          checkupdatediable = 0;
          selectindex = null;
          // startDelay();
        } else if (name.contains('wrong')) {
          mergedList[selectindex!]['status'] = '${ctrldata['Message']}';
          iconData = Icons.error;
          iconcolor = Colors.red;
          checkupdatediable = 0;
          selectindex = null;
        }else if (name.contains('GitFailed')) {
          mergedList[selectindex!]['status'] = '${ctrldata['Message']}';
          iconData = Icons.error;
          iconcolor = Colors.red;
          checkupdatediable = 0;
          selectindex = null;
        }
        else {
          mergedList[selectindex!]['status'] = 'Status';
          iconcolor = Colors.transparent;
          // checkupdatediable = 0;
          // selectindex = null;
        }
      }
    }
  }


  void resetItem(int index) {
    setState(() {
      checkupdatediable = 1;
      _showDialogcheck(context, "Restart", index);
    });
  }

  void updateItem(int index) {
    setState(() {
      checkupdatediable = 1;
      _showDialogcheck(context, "Update", index);
    });
  }
  String formatNumber(String input) {
    if (input.isEmpty) {
      return '0,0';
    }
    if (!input.contains('.')) {
      input += '.0';
    }
    double number = double.parse(input);
    number *= 10;
    String result = number.toStringAsFixed(0);
    while (result.length < 4) {
      result = '0' + result;
    }
    String firstPart = result.substring(0, 2);
    String secondPart = result.substring(2, 4);
    return '$firstPart,$secondPart';
  }

  viewLoaraSett(String val, ) async {

    Map<String, dynamic> payLoadFinal = {
      "5700":
      {"5701": val},
    };

    MqttService().topicToPublishAndItsMessage(jsonEncode(payLoadFinal), '${Environment.mqttPublishTopic}/${mergedList[selectindex ?? 0]["deviceId"]}');
    fetchData();
  }
  FrequnceAll() async {

    String firstfreequnce1 = formatNumber(frequency1Controller.text);
    String firstfreequnce2 = formatNumber(frequency2Controller.text);
    String sf1 = sf1Controller.text;
    String sf2 = sf2Controller.text;
    sf1 = sf1.isEmpty ? "0" : sf1;
    sf2 = sf2.isEmpty ? "0" : sf2;
    Map<String, dynamic> payLoadFinal = {
      "6500":
      {"6501": "$firstfreequnce1,$sf1,$firstfreequnce2,$sf2"},

    };
    Map<String, dynamic> body = {
      "userId": widget.userId,
      "controllerId": widget.controllerId,
      "loraFrequency":
      '${frequency1Controller.text},${sf1Controller.text},${frequency2Controller.text},${sf2Controller.text}',
      "modifyUser": widget.userId
    };

    final Repository repository = Repository(HttpService());
    var response = await repository.updateUserDeviceFirmwareDetails(body);

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data["code"] == 200) {
        _showSnackBar(data["message"]);
      } else {
        _showSnackBar(data["message"]);
      }
    }
    if(kDebugMode) {
      AppLog.log("selectindex----$selectindex");

      AppLog.log("payLoadFinal----$payLoadFinal");
      AppLog.log("payLoadFinal----${Environment
          .mqttPublishTopic}/${mergedList[selectindex!]["deviceId"]}");
    }
    MqttService().topicToPublishAndItsMessage(jsonEncode(payLoadFinal), '${Environment.mqttPublishTopic}/${mergedList[selectindex ?? 0]["deviceId"]}');
    fetchData();
  }
  bool _isValidFrequency(String freq) {
    final regex = RegExp(r'^\d{1,3}\.\d$');
    return regex.hasMatch(freq);
  }
  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: const Text('Please enter valid frequencies.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showDialogcheck(BuildContext context, String update, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Warning'),
          content: Text(
              "Are you sure you want to $update?\n First, stop. If you confirm that you want to stop, then update your controller by clicking the 'Sure' button."),
          actions: [
            TextButton(
              onPressed: () {
                update == "Update" ? Update(index) : ResetAll(index);
                Navigator.of(context).pop();
              },
              child: const Text('Sure'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (mounted) setState(() => checkupdatediable = 0);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
  void _showFrequencyDialog(BuildContext context,int index,bool plusTrue) {

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String loravalue =  mergedList[index]['loraFrequency'] ?? '';

        if( loravalue.isNotEmpty)
        {
          List<String> splitValues = loravalue.split(',');
          frequency1Controller.text = splitValues[0];
          sf1Controller.text = splitValues[1];
          frequency2Controller.text = splitValues[2];
          sf2Controller.text = splitValues[3];
        }
        else
        {
          frequency1Controller.text = '';
          sf1Controller.text = '';
          frequency2Controller.text = '';
          sf2Controller.text = '';
        }
        return AlertDialog(
          title: const Text('LoRa Frequency'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: frequency1Controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration:  const InputDecoration(
                          hintText: 'Enter LoRa Frequency 1 (000.0)',
                          labelText: "LoRa Frequency 1 ",
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(
                              r'^\d{1,3}(\.\d{0,1})?$|^99(\.0)?$|^99\.9$')),
                        ],
                      ),
                      TextField(
                        controller: sf1Controller,

                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration:  const InputDecoration(
                          hintText: 'Enter SF value (7-12)',
                          labelText: "SF value ",
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(
                            r'^(0|1|2|7|8|9|10|11|12)$', // Regex to allow values between 7 and 12 (no decimal)
                          )),
                        ],
                      ),
                      const SizedBox(),
                      Row(children: [ const Spacer(),
                        TextButton(
                          onPressed: () {
                            viewLoaraSett('29');
                            Navigator.of(context).pop();
                          },
                          child: const Text('View'),
                        ),
                        TextButton(
                          onPressed: () {

                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            String freq1 = frequency1Controller.text;
                            String sf1 = sf1Controller.text;
                            bool isValidFreq1 = _isValidFrequency(freq1) && sf1.isNotEmpty;
                            if(isValidFreq1)
                            {
                              FrequnceAll();
                              Navigator.of(context).pop();
                            }
                            else {
                              _showErrorDialog(context);
                            }
                          },
                          child: const Text('Send'),
                        ),],),
                      Text("View to Lora Details:"),
                      Text(mqttPayloadProvider.Loara1verssion)

                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              plusTrue ? Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: frequency2Controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration:  const InputDecoration(
                          hintText: 'Enter LoRa Frequency 2 (000.0)',
                          labelText: "LoRa Frequency 2",
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d{1,3}(\.\d{0,1})?$|^99(\.0)?$|^99\.9$')),
                        ],
                      ),
                      TextField(
                        controller: sf2Controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration:  const InputDecoration(
                          hintText: 'Enter SF value (7-12)',
                          labelText: 'SF value ',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(
                            r'^(0|1|2|7|8|9|10|11|12)$', // Regex to allow values between 7 and 12 (no decimal)
                          )),
                        ],
                      ),
                      Text("View to Lora Details:"),
                      Text(mqttPayloadProvider.Loara2verssion)
                    ],
                  ),
                ),
              ) :  const SizedBox(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                viewLoaraSett('30');
                Navigator.of(context).pop();
              },
              child: const Text('View'),
            ),
            TextButton(
              onPressed: () {

                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String freq1 = frequency1Controller.text;
                String freq2 = frequency2Controller.text;
                String sf1 = sf1Controller.text;
                String sf2 = sf2Controller.text;

                bool isValidFreq1 = _isValidFrequency(freq1) && sf1.isNotEmpty;
                bool isValidFreq2 = _isValidFrequency(freq2) && sf2.isNotEmpty;

                if (plusTrue)
                {
                  if(isValidFreq1 && isValidFreq2)
                  {
                    FrequnceAll();
                    Navigator.of(context).pop();
                  }
                  else {
                    _showErrorDialog(context);
                  }
                } else {

                  if(isValidFreq1)
                  {
                    FrequnceAll();
                    Navigator.of(context).pop();
                  }
                  else {
                    _showErrorDialog(context);
                  }
                }


              },
              child: const Text('Send'),
            ),

          ],
        );
      },
    );
  }

}

class BlinkingText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration blinkDuration;

  const BlinkingText({
    Key? key,
    required this.text,
    this.style = const TextStyle(fontSize: 20, color: Colors.red),
    this.blinkDuration = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  _BlinkingTextState createState() => _BlinkingTextState();
}

class _BlinkingTextState extends State<BlinkingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.blinkDuration,
      reverseDuration: widget.blinkDuration,
    )..repeat(reverse: true);

    _opacityAnimation =
        Tween<double>(begin: 1.0, end: 0.0).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Text(
        widget.text,
        style: widget.style,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}