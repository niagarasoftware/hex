import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../StateManagement/mqtt_payload_provider.dart';
import '../../models/PumpConditionModel.dart';
import '../../modules/IrrigationProgram/view/program_library.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../services/mqtt_service.dart';
import '../../utils/constants.dart';
import 'package:hex/utils/helpers/log_print.dart';
import '../../utils/snack_bar.dart';

class PumpConditionScreen extends StatefulWidget {
  final dynamic userId;
  final dynamic customerId;
  final dynamic controllerId;
  final dynamic modelid;
  final String imeiNo;
  final bool? isProgram;

  const PumpConditionScreen({
    Key? key,
    required this.userId,
    required this.controllerId,
    required this.modelid,
    required this.imeiNo,
    this.isProgram, this.customerId,
  }) : super(key: key);

  @override
  State<PumpConditionScreen> createState() => _PumpConditionScreenState();
}

class _PumpConditionScreenState extends State<PumpConditionScreen> {
  late PumpConditionModel pumpConditionModel = PumpConditionModel();
  late MqttPayloadProvider mqttPayloadProvider;
  String selectedMode = "";
  bool isNova = false;

  // Colors (matched to the reference design).
  static const Color _accent = Color(0xFF4F2CB8); // selected / highlight
  static const Color _accentSoft = Color(0xFFEDE9FE); // selected cell fill
  static const Color _cardBorder = Color(0xFFE5E7EB); // card & cell border
  static const Color _cellFill = Color(0xFFF7F8FA); // normal cell fill
  static const Color _titleText = Color(0xFF111827); // card title
  static const Color _cellText = Color(0xFF4B5563); // normal cell text

  @override
  void initState() {
    isNova = [...AppConstants.ecoGemModelList].contains(widget.modelid);

    super.initState();
    mqttPayloadProvider =
        Provider.of<MqttPayloadProvider>(context, listen: false);
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final repository = Repository(HttpService());
      var getUserDetails = await repository.getUserPlanningPumpCondition({
        "userId": widget.customerId,
        "controllerId": widget.controllerId,
      });

      if (getUserDetails.statusCode == 200) {
        setState(() {
          var jsonData = jsonDecode(getUserDetails.body);
          pumpConditionModel = PumpConditionModel.fromJson(jsonData);
          selectedMode = pumpConditionModel.data?.novaselectmode ?? "Alternative";
        });
      }
    } catch (e, stackTrace) {
      AppLog.log('Error in fetchData: $e');
      AppLog.log('Stack trace: $stackTrace');
    }
  }

  void togglePumpSelection(PumpCondition currentPump, PumpCondition targetPump) {
    var selectedList = currentPump.selectedPumps ?? [];

    final alreadySelected =
    selectedList.any((p) => p.sNo == targetPump.sNo);

    setState(() {
      if (alreadySelected) {
        selectedList.removeWhere((p) => p.sNo == targetPump.sNo);
      } else {
        selectedList.add(SelectedPump(
          sNo: targetPump.sNo,
          objectId: targetPump.objectId,
        ));
      }

      currentPump.selectedPumps = selectedList;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allPumps = pumpConditionModel.data?.pumpCondition ?? [];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MediaQuery.of(context).size.width <= 500 ? AppBar(
        title: const Text('Pump Conditions'),
      ) : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: isNova ?  Card(
          elevation: 4.0,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text('Nova Pump Condition',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8.0),
                Container(height: 0.5, color: Colors.grey),
                const SizedBox(height: 8.0),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Select Pump Mode",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    /// --- TWO CHIPS WITH NEW NAMES ---
                    Wrap(
                      spacing: 10,
                      children: [
                        ChoiceChip(
                          label: const Text("Alternative Pump"),
                          selected: selectedMode == "Alternative",
                          selectedColor: Colors.greenAccent.shade100,
                          onSelected: (_) {
                            setState(() {
                              selectedMode = "Alternative";
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text("Combined Pumps"),
                          selected: selectedMode == "combined",
                          selectedColor: Colors.greenAccent.shade100,
                          onSelected: (_) {
                            setState(() {
                              selectedMode = "combined";
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// Result Text
                    Text(
                      "Selected Mode: ${selectedMode.isEmpty ? 'None' : selectedMode}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                )

              ],
            ),
          ),
        )  : LayoutBuilder(
          builder: (context, constraints) {
            // 2 columns: Pump 1 | Pump 2, Pump 3 | Pump 4, ...
            const double gap = 16.0;
            final double cardWidth = (constraints.maxWidth - gap) / 2;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: allPumps.map((pumpCondition) {
                var selectedPumps = pumpCondition.selectedPumps ?? [];

                return SizedBox(
                  width: cardWidth,
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _cardBorder, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card title (left aligned)
                        Text(
                          pumpCondition.name ?? 'No Name',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _titleText,
                          ),
                        ),
                        const SizedBox(height: 12.0),

                        // 5 cells per row inside each card.
                        LayoutBuilder(
                          builder: (context, innerConstraints) {
                            const int columns = 5;
                            const double cellGap = 8.0;
                            final double cellWidth =
                            ((innerConstraints.maxWidth -
                                (columns - 1) * cellGap) /
                                columns)
                                .floorToDouble();

                            return Wrap(
                              spacing: cellGap,
                              runSpacing: cellGap,
                              children: allPumps
                                  .where((pump) => pump.sNo != pumpCondition.sNo)
                                  .map((pump) {
                                bool isSelected = selectedPumps.any(
                                        (sp) => sp.sNo == pump.sNo);

                                return GestureDetector(
                                  onTap: () =>
                                      togglePumpSelection(pumpCondition, pump),
                                  child: Container(
                                    width: cellWidth,
                                    height: 36,
                                    alignment: Alignment.center,
                                    padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: isSelected ? _accentSoft : _cellFill,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected ? _accent : _cardBorder,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      pump.name ?? 'Unknown Pump',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isSelected ? _accent : _cellText,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        onPressed: _sendData,
        child: const Icon(Icons.send),
        tooltip: 'Send Data',
      ),
    );
  }

  String convertPumpDataToString(PumpConditionModel model) {
    final buffer = StringBuffer();
    final pumps = model.data?.pumpCondition ?? [];

    for (var pump in pumps) {
      buffer.write(pump.sNo?.toString() ?? '');
      final selected = pump.selectedPumps ?? [];

      if (selected.isNotEmpty) {
        buffer.write(',');
        buffer.writeAll(
          selected.map((sp) => sp.sNo?.toString() ?? ','),
          '_',
        );
      }
      else
      {
        buffer.write(',');
      }

      buffer.write(';');
    }

    return buffer.toString();
  }


  Future<void> _sendData() async {
    final repository = Repository(HttpService());

    String mqttSendData = convertPumpDataToString(pumpConditionModel);
    AppLog.log('mqttSendData$mqttSendData');

    // Prepare JSON for server
    Map<String, dynamic> pumpConditionJson = pumpConditionModel.toJson();
    Map<String, dynamic> pumpConditionServerData = {
      "pumpCondition": pumpConditionJson["data"]?["pumpCondition"] ?? [],
      "controllerReadStatus": "0",
      "novaMode": selectedMode,
    };
    var novadata = selectedMode == "Alternative" ? "1" : "0";
    // MQTT Payload format
    Map<String, dynamic> payLoadFinal = {
      "7100":
      {"7101": isNova ? novadata : mqttSendData},
    };

    AppLog.log("payLoadFinal,$payLoadFinal");
    // Main request body
    Map<String, dynamic> body = {
      "userId": widget.customerId,
      "controllerId": widget.controllerId,
      "pumpCondition": pumpConditionServerData,
      "hardware": payLoadFinal,
      "createUser": widget.userId,
    };


    try {
      final getUserDetails = await repository.updateUserPlanningPumpCondition(body);
      final jsonDataResponse = jsonDecode(getUserDetails.body);

      AppLog.log('Response ---> $jsonDataResponse');

      if (MqttService().isConnected == true) {
        await validatePayloadSent(
          dialogContext: context,
          context: context,
          mqttPayloadProvider: mqttPayloadProvider,
          acknowledgedFunction: () async {
            setState(() {
              body["pumpCondition"]["controllerReadStatus"] = "1";
            });
          },
          payload: payLoadFinal,
          payloadCode: '7100',
          deviceId: widget.imeiNo,
        );
      } else {
        GlobalSnackBar.show(context, 'MQTT is Disconnected', 201);
      }

      GlobalSnackBar.show(
        context,
        jsonDataResponse['message'],
        jsonDataResponse['code'],
      );
    } catch (e ,stacktrace) {
      AppLog.log("Error in _sendData: $e");
      AppLog.log("stacktrace in _sendData: $stacktrace");
      GlobalSnackBar.show(context, 'Error sending data: $e', 500);
    }
  }

}
