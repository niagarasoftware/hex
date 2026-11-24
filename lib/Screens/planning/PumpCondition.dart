import 'dart:ui' show PointerDeviceKind;

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

  // Header / panel state
  int selectedPumpIndex = 0; // which pump tab is selected in the header
  String headerSearch = ''; // "Find a pump" search (filters header tabs)
  String listFilter = ''; // "Filter pumps in this list" search
  bool showSelectedOnly = false; // "Show selected only" toggle

  // Horizontal scroll of the header tabs (needed for the visible scrollbar).
  final ScrollController _tabScrollController = ScrollController();

  // Colors
  // Green / teal comes from the app theme (same green as the other screens).
  Color get _accent => Theme.of(context).primaryColor; // selected / highlight
  Color get _accentSoft => _accent.withValues(alpha: 0.12); // soft green fill
  static const Color _headerBg = Color(0xFFE8F0F3); // header bar background
  static const Color _headerBorder = Color(0xFFD3DEE3); // header bar border
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

  @override
  void dispose() {
    _tabScrollController.dispose();
    super.dispose();
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

  // ---------------------------------------------------------------------------
  // Small UI helpers
  // ---------------------------------------------------------------------------

  Widget _searchField(String hint, ValueChanged<String> onChanged) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _cardBorder),
    );

    return TextField(
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13, color: _titleText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: _cellText),
        isDense: true,
        filled: true,
        fillColor: _cellFill,
        prefixIcon: const Icon(Icons.search, size: 18, color: _cellText),
        prefixIconConstraints:
        const BoxConstraints(minWidth: 36, minHeight: 36),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _accent),
        ),
      ),
    );
  }

  Widget _actionButton(String label, VoidCallback onTap,
      {bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? _accentSoft : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? _accent : _cardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? _accent : _titleText,
          ),
        ),
      ),
    );
  }

  // Ignore spaces and case, so "pump2", "Pump 2" and "PUMP 2" all match.
  String _norm(String s) => s.replaceAll(RegExp(r'\s+'), '').toLowerCase();

  /// When the user types in the header search, open the matching pump below.
  /// An exact match wins (e.g. "pump2" -> Pump 2), otherwise the first pump
  /// whose name contains the text is opened.
  void _selectPumpFromSearch(String query, List<PumpCondition> allPumps) {
    final q = _norm(query);
    if (q.isEmpty) return;

    int found = allPumps.indexWhere((p) => _norm(p.name ?? '') == q);
    if (found == -1) {
      found = allPumps.indexWhere((p) => _norm(p.name ?? '').contains(q));
    }
    if (found != -1) selectedPumpIndex = found;
  }

  /// Top header: search box + horizontally scrollable pump tabs with counts.
  /// Tabs are flat (no separate boxes); only the selected one is filled green.
  Widget _buildHeader(List<PumpCondition> allPumps, int activeIndex) {
    final hq = _norm(headerSearch);
    final List<Widget> tabs = [];

    for (int i = 0; i < allPumps.length; i++) {
      final p = allPumps[i];
      if (hq.isNotEmpty && !_norm(p.name ?? '').contains(hq)) {
        continue;
      }

      final bool active = i == activeIndex;

      tabs.add(
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () => setState(() => selectedPumpIndex = i),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? _accent : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    p.name ?? 'Pump',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : _titleText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Horizontal scroll with a visible scrollbar. Mouse drag / trackpad / touch
    // all work, so all pumps (e.g. 18) can be reached on web and desktop too.
    final tabsScroll = ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),
      child: Scrollbar(
        controller: _tabScrollController,
        thumbVisibility: true,
        trackVisibility: true,
        child: SingleChildScrollView(
          controller: _tabScrollController,
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(children: tabs),
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _headerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _headerBorder, width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool narrow = constraints.maxWidth < 600;

          final search = _searchField(
            'Find a pump',
                (val) => setState(() {
              headerSearch = val;
              _selectPumpFromSearch(val, allPumps);
            }),
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                search,
                const SizedBox(height: 8),
                tabsScroll,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 240, child: search),
              const SizedBox(width: 12),
              Expanded(child: tabsScroll),
            ],
          );
        },
      ),
    );
  }

  /// Panel for the pump selected in the header.
  Widget _buildPumpPanel(
      PumpCondition current,
      List<PumpCondition> others,
      ) {
    final selectedList = current.selectedPumps ?? [];
    // Ignore spaces and case, so "pump2" also finds "Pump 2".
    final q = _norm(listFilter);

    final visible = others.where((p) {
      final bool matches = q.isEmpty || _norm(p.name ?? '').contains(q);
      final bool picked = selectedList.any((sp) => sp.sNo == p.sNo);
      return matches && (!showSelectedOnly || picked);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Select all / Clear
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current.name ?? 'No Name',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _titleText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${selectedList.length} of ${others.length} pumps selected',
                      style: const TextStyle(fontSize: 12, color: _cellText),
                    ),
                  ],
                ),
              ),
              _actionButton('Select all', () {
                setState(() {
                  final list = current.selectedPumps ?? [];
                  for (final p in visible) {
                    if (!list.any((sp) => sp.sNo == p.sNo)) {
                      list.add(SelectedPump(sNo: p.sNo, objectId: p.objectId));
                    }
                  }
                  current.selectedPumps = list;
                });
              }),
              const SizedBox(width: 8),
              _actionButton('Clear', () {
                setState(() {
                  current.selectedPumps = [];
                });
              }),
            ],
          ),
          const SizedBox(height: 12),

          // Filter + Show selected only
          Row(
            children: [
              Expanded(
                child: _searchField(
                  'Filter pumps in this list',
                      (val) => setState(() => listFilter = val),
                ),
              ),
              const SizedBox(width: 8),
              _actionButton(
                'Show selected only',
                    () => setState(() => showSelectedOnly = !showSelectedOnly),
                active: showSelectedOnly,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cells grid (up to 9 per row)
          LayoutBuilder(
            builder: (context, constraints) {
              const double cellGap = 8.0;
              const double minCellWidth = 88.0;
              const int maxColumns = 9;

              int columns =
              ((constraints.maxWidth + cellGap) / (minCellWidth + cellGap))
                  .floor();
              if (columns > maxColumns) columns = maxColumns;
              if (columns < 2) columns = 2;

              final double cellWidth =
              ((constraints.maxWidth - (columns - 1) * cellGap) / columns)
                  .floorToDouble();

              if (visible.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No pumps found',
                    style: TextStyle(fontSize: 13, color: _cellText),
                  ),
                );
              }

              return Wrap(
                spacing: cellGap,
                runSpacing: cellGap,
                children: visible.map((pump) {
                  final bool isSelected =
                  selectedList.any((sp) => sp.sNo == pump.sNo);

                  return GestureDetector(
                    onTap: () => togglePumpSelection(current, pump),
                    child: Container(
                      width: cellWidth,
                      height: 36,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
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
                          fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
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
    );
  }

  Widget _buildPumpSelector(List<PumpCondition> allPumps) {
    if (allPumps.isEmpty) return const SizedBox.shrink();

    final int activeIndex =
    selectedPumpIndex < allPumps.length ? selectedPumpIndex : 0;
    final current = allPumps[activeIndex];
    final others = allPumps.where((p) => p.sNo != current.sNo).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Page title + description
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Pump condition',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _titleText,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Choose a pump, then tap the other pumps it should be linked with. '
                'Selected pumps turn teal.',
            style: TextStyle(fontSize: 14, color: _cellText),
          ),
        ),
        const SizedBox(height: 16),

        _buildHeader(allPumps, activeIndex),
        const SizedBox(height: 16),
        _buildPumpPanel(current, others),
      ],
    );
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
        )  : _buildPumpSelector(allPumps),
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
