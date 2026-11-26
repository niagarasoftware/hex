import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hex/utils/Theme/oro_theme.dart';
import 'package:provider/provider.dart';
import '../../../Constants/constants.dart';
import '../../../Constants/properties.dart';
import '../state_management/irrigation_program_provider.dart';
import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../StateManagement/overall_use.dart';
import '../widgets/custom_native_time_picker.dart';

class AdditionalDataScreen extends StatefulWidget {
  final int serialNumber;
  final bool isIrrigationProgram;
  final int userId;
  final int customerId;
  final int controllerId;
  final String deviceId;
  final bool toDashboard;
  final String? programType;
  final bool fromDealer;
  final int groupId, categoryId;
  final int modelId;
  final String deviceName;
  final String categoryName;

  const AdditionalDataScreen({
    super.key,
    required this.serialNumber,
    required this.isIrrigationProgram,
    required this.userId,
    required this.controllerId,
    required this.deviceId,
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
  State<AdditionalDataScreen> createState() => _AdditionalDataScreenState();
}

class _AdditionalDataScreenState extends State<AdditionalDataScreen> {
  final TextEditingController _textEditingController = TextEditingController();
  String tempProgramName = '';
  late OverAllUse overAllPvd;
  late MqttPayloadProvider mqttPayloadProvider;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doneProvider = Provider.of<IrrigationProgramMainProvider>(context);
    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context);
    overAllPvd = Provider.of<OverAllUse>(context, listen: false);

    String programName = doneProvider.programName == ''
        ? "Program ${doneProvider.programCount}"
        : doneProvider.programName;

    final isEcoGem = [3].contains(widget.modelId);
    final isWide = MediaQuery.of(context).size.width >= 1000;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? MediaQuery.of(context).size.width * 0.04 : 16,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TOP SUPERVISORY HEADER CARD
          _buildSupervisoryCard(context),
          const SizedBox(height: 20),

          // 2. 2x2 GRID OF ADVANCED CONTROL CARDS
          _buildAdvancedCardsGrid(context, doneProvider, programName, isEcoGem, isWide),

          // 3. ADVANCED PRESSURE & FLOW CONTROL CARD (if non-EcoGem and isIrrigationProgram)
          if (widget.isIrrigationProgram && !isEcoGem) ...[
            const SizedBox(height: 20),
            _buildPressureFlowCard(context, doneProvider, isWide),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Top Supervisory Header Card
  Widget _buildSupervisoryCard(BuildContext context) {
    return Container(
      width: double.infinity,
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
          Text(
            "SYSTEM TUNING & DELAYS",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: primaryPurple,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Advanced Program Attributes",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Configure hydraulic changeover buffers, water scaling factors, and program dispatch arbitration priorities.",
            style: TextStyle(
              fontSize: 13,
              color: textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // 2x2 Grid of Advanced Cards
  Widget _buildAdvancedCardsGrid(
    BuildContext context,
    IrrigationProgramMainProvider doneProvider,
    String programName,
    bool isEcoGem,
    bool isWide,
  ) {
    final card1 = _buildCard1Identification(context, doneProvider, programName);
    final card2 = _buildCard2WaterScaling(context, doneProvider);
    final card3 = _buildCard3ValveDelay(context, doneProvider);
    final card4 = _buildCard4RestInterval(context, doneProvider);

    if (isWide) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: card1),
              const SizedBox(width: 16),
              Expanded(child: card2),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: card3),
              const SizedBox(width: 16),
              Expanded(child: card4),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          card1,
          const SizedBox(height: 16),
          card2,
          const SizedBox(height: 16),
          card3,
          const SizedBox(height: 16),
          card4,
        ],
      );
    }
  }

  // Card 1: Identification & Priority
  Widget _buildCard1Identification(
    BuildContext context,
    IrrigationProgramMainProvider doneProvider,
    String programName,
  ) {
    final currentPriority = doneProvider.priority;

    return Container(
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: activeBgLavender,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.tune_rounded, color: primaryPurple, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                "Identification & Priority",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Field 1: Program Display Name
          Text(
            "PROGRAM DISPLAY NAME",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _showEditProgramNameDialog(context, doneProvider, programName),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: primaryBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tempProgramName != ''
                        ? tempProgramName
                        : widget.serialNumber == 0
                            ? "Program ${doneProvider.programCount}"
                            : doneProvider.programDetails!.programName.isNotEmpty
                                ? programName
                                : doneProvider.programDetails!.defaultProgramName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  Icon(Icons.edit_outlined, size: 16, color: primaryPurple),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Field 2: Arbitration Priority
          Text(
            "ARBITRATION PRIORITY",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Higher priority programs interrupt or defer lower priority programs when water pump capacity is constrained.",
            style: TextStyle(fontSize: 11, color: textMuted, height: 1.3),
          ),
          const SizedBox(height: 12),

          // Priority Selector Pills (Low / Medium / High)
          Row(
            children: ['Low', 'Medium', 'High'].map((p) {
              final isSelected = currentPriority.toLowerCase() == p.toLowerCase();
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    onTap: () {
                      doneProvider.updateProgramName(p, 'priority');
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryPurple : primaryBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? primaryPurple : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          p,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : textDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showEditProgramNameDialog(
    BuildContext context,
    IrrigationProgramMainProvider doneProvider,
    String programName,
  ) {
    _textEditingController.text = widget.serialNumber == 0
        ? "Program ${doneProvider.programCount}"
        : doneProvider.programDetails!.programName.isNotEmpty
            ? programName
            : doneProvider.programDetails!.defaultProgramName;
    _textEditingController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _textEditingController.text.length,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit program name"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Form(
          key: _formKey,
          child: TextFormField(
            autofocus: true,
            controller: _textEditingController,
            inputFormatters: [
              LengthLimitingTextInputFormatter(20),
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s.]')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Name cannot be empty";
              } else if (doneProvider.programLibrary!.program.any((element) => element.programName == value)) {
                return "Name already exists";
              } else {
                setState(() {
                  tempProgramName = value;
                });
              }
              return null;
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("CANCEL", style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                doneProvider.updateProgramName(tempProgramName, 'programName');
                Navigator.of(ctx).pop();
              }
            },
            child: const Text("OKAY", style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  // Card 2: Water Volume Scaling Factor
  Widget _buildCard2WaterScaling(
    BuildContext context,
    IrrigationProgramMainProvider doneProvider,
  ) {
    final scaleVal = doneProvider.adjustPercentage != "" ? doneProvider.adjustPercentage : "100";

    return Container(
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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: activeBgLavender,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.percent_rounded, color: primaryPurple, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Water Volume Scaling Factor",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                ],
              ),
              Text(
                "$scaleVal%",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: primaryPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Dynamically scale all valve irrigation durations up or down across this program for seasonal ET adjustments without re-entering individual valves.",
            style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
          ),
          const SizedBox(height: 16),

          // Input Box & Presets Legend
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: primaryBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: scaleVal,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp('[^0-9]')),
                      LengthLimitingTextInputFormatter(5),
                    ],
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: "100",
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                    onChanged: (newValue) {
                      doneProvider.updateProgramName(newValue, 'adjustPercentage');
                    },
                  ),
                ),
                Text(
                  "%",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("10% {Extreme Dry}", style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: textMuted)),
              Text("100% {Baseline}", style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: textMuted)),
              Text("200% {High Heat}", style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  // Card 3: Inter-Valve Changeover Delay
  Widget _buildCard3ValveDelay(
    BuildContext context,
    IrrigationProgramMainProvider doneProvider,
  ) {
    final delayVal = doneProvider.delayBetweenZones != ""
        ? (doneProvider.delayBetweenZones.length > 5
            ? doneProvider.delayBetweenZones
            : '${doneProvider.delayBetweenZones}:00')
        : "00:00:00";

    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: activeBgLavender,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.alarm_outlined, color: primaryPurple, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                "Inter-Valve Changeover Delay",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Safety pause duration between closing one valve and opening the next to prevent water hammer and pressure spikes in the main line.",
            style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
          ),
          const SizedBox(height: 16),

          // Time Input Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: primaryBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomNativeTimePicker(
                  initialValue: Constants.showHourAndMinuteOnly(delayVal, widget.modelId),
                  is24HourMode: false,
                  modelId: widget.modelId,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                  onChanged: (newTime) {
                    doneProvider.updateProgramName(newTime, 'delayBetweenZones');
                  },
                ),
                Text(
                  "HH:MM:SS",
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card 4: Inter-Cycle Rest Interval
  Widget _buildCard4RestInterval(
    BuildContext context,
    IrrigationProgramMainProvider doneProvider,
  ) {
    final restVal = doneProvider.cyclicOffTime != "" ? doneProvider.cyclicOffTime : "00:00:00";

    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: activeBgLavender,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.access_time_rounded, color: primaryPurple, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                "Inter-Cycle Rest Interval",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Soaking interval pause between multi-cycle runs before beginning the Segment again.",
            style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
          ),
          const SizedBox(height: 16),

          // Time Input Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: primaryBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomNativeTimePicker(
                  initialValue: Constants.showHourAndMinuteOnly(restVal, widget.modelId),
                  is24HourMode: false,
                  modelId: widget.modelId,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                  onChanged: (newTime) {
                    doneProvider.updateProgramName(newTime, 'cyclicOffTime');
                  },
                ),
                Text(
                  "HH:MM:SS",
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Pressure & Flow Control Card
  Widget _buildPressureFlowCard(
    BuildContext context,
    IrrigationProgramMainProvider doneProvider,
    bool isWide,
  ) {
    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.speed_rounded, color: avatarGreen, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                "Pressure & Flow Management",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Enable Pressure Sensing",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark),
              ),
              Switch(
                value: doneProvider.enablePressure,
                activeThumbColor: Colors.white,
                activeTrackColor: primaryPurple,
                onChanged: (val) {
                  doneProvider.updateProgramName(val, 'enablePressure');
                },
              ),
            ],
          ),
          if (doneProvider.enablePressure) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "SET PRESSURE (BAR)",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textMuted),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: primaryBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextFormField(
                          initialValue: doneProvider.setPressure,
                          keyboardType: TextInputType.number,
                          inputFormatters: AppProperties.regexForDecimal,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                          ),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark),
                          onChanged: (val) => doneProvider.updateProgramName(val, 'setPressure'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "CONTROL MODE",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textMuted),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          underline: Container(),
                          value: doneProvider.controlMode,
                          items: <String>['pressure', 'flow'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            doneProvider.updateProgramName(newValue, 'controlMode');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
