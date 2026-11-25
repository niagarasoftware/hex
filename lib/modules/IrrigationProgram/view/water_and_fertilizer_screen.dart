import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hex/Constants/properties.dart';
import 'package:hex/utils/constants.dart';
import 'package:provider/provider.dart';
import '../../../Constants/constants.dart';
import '../../../StateManagement/overall_use.dart';
import '../../../Widgets/HoursMinutesSeconds.dart';
import '../state_management/irrigation_program_provider.dart';

String formatTime(int seconds) {
  int hrs = seconds ~/ 3600;
  int mins = (seconds % 3600) ~/ 60;
  int secs = seconds % 60;
  return '${hrs.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
}

class WaterAndFertilizerScreen extends StatefulWidget {
  final int userId;
  final int controllerId;
  final int serialNumber;
  final int modelId;
  final bool isIrrigationProgram;

  const WaterAndFertilizerScreen({
    super.key,
    required this.userId,
    required this.controllerId,
    required this.serialNumber,
    required this.isIrrigationProgram,
    required this.modelId,
  });

  @override
  State<WaterAndFertilizerScreen> createState() => _WaterAndFertilizerScreenState();
}

class _WaterAndFertilizerScreenState extends State<WaterAndFertilizerScreen> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode myFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        var programPvd = Provider.of<IrrigationProgramMainProvider>(context, listen: false);
        programPvd.waterAndFert(widget.modelId);
        programPvd.editSegmentedControlGroupValue(0);
        if (programPvd.sequenceData.isNotEmpty) {
          programPvd.editGroupSiteInjector(
            programPvd.segmentedControlCentralLocal == 0 ? 'selectedCentralSite' : 'selectedLocalSite',
            programPvd.segmentedControlCentralLocal == 0 ? programPvd.selectedCentralSite : programPvd.selectedLocalSite,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    myFocus.dispose();
    super.dispose();
  }

  void closeKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final programPvd = Provider.of<IrrigationProgramMainProvider>(context);
    final overAllPvd = Provider.of<OverAllUse>(context, listen: true);

    if (programPvd.sequenceData.isEmpty) {
      return const Center(child: Text('Please Create At least One Sequence'));
    }

    final isWide = MediaQuery.of(context).size.width >= 1000;
    final selectedGroup = programPvd.selectedGroup.clamp(0, programPvd.sequenceData.length - 1);
    final currentSeq = programPvd.sequenceData[selectedGroup];

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? MediaQuery.of(context).size.width * 0.04 : 16,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. SEGMENT SELECTOR PILLS BAR
          _buildSegmentSelectorBar(programPvd),
          const SizedBox(height: 16),

          // 2. ACTIVE VALVE SCOPE & FLOW / DOSING BAR CHART CARD
          _buildActiveValveScopeCard(context, programPvd, overAllPvd, currentSeq, isWide),
          const SizedBox(height: 20),

          // 3. FERTIGATION INJECTION SITE CARD
          _buildFertigationInjectionSiteCard(context, programPvd, overAllPvd, currentSeq, isWide),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // 1. Segment Selector Pills Bar
  Widget _buildSegmentSelectorBar(IrrigationProgramMainProvider programPvd) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      child: Row(
        children: List.generate(programPvd.sequenceData.length, (seq) {
          final isSelected = seq == programPvd.selectedGroup;
          final seqName = programPvd.sequenceData[seq]['seqName'] ?? 'Segment ${seq + 1}';

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () {
                programPvd.editGroupSiteInjector('selectedGroup', seq);
                if (programPvd.sequenceData[seq]['centralDosing'].isNotEmpty) {
                  programPvd.editSegmentedCentralLocal(0);
                } else if (programPvd.sequenceData[seq]['localDosing'].isNotEmpty) {
                  programPvd.editSegmentedCentralLocal(1);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  seqName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // 2. Active Valve Scope & Dosing Chart Card
  Widget _buildActiveValveScopeCard(
    BuildContext context,
    IrrigationProgramMainProvider programPvd,
    OverAllUse overAllPvd,
    dynamic currentSeq,
    bool isWide,
  ) {
    final valves = (currentSeq['valve'] as List? ?? []);
    final waterQty = programPvd.waterValueInQuantity;
    final waterTime = programPvd.waterValueInTime;
    final preValue = currentSeq['preValue'] ?? '00:00:30';
    final postValue = currentSeq['postValue'] ?? '00:00:30';

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ACTIVE VALVE SCOPE",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(valves.length, (idx) {
                        final v = valves[idx];
                        final vName = v['name'] ?? 'Valve ${idx + 1}';
                        final isSelected = idx == 0;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF5B21B6) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF5B21B6) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            vName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "TOTAL FLOW VOLUME",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${waterQty != '' && waterQty != '0' ? waterQty : '32'} Litres",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "(${Constants.showHourAndMinuteOnly(waterTime, widget.modelId)})",
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Visual Dosing Timeline Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(flex: 1, child: Container(color: const Color(0xFF3B82F6))),
                  Expanded(flex: 5, child: Container(color: const Color(0xFFF59E0B))),
                  Expanded(flex: 4, child: Container(color: const Color(0xFF7C3AED))),
                  Expanded(flex: 1, child: Container(color: const Color(0xFF10B981))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Timeline Legend
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _buildLegendItem(const Color(0xFF3B82F6), "Pre-Flush (${Constants.showHourAndMinuteOnly(preValue, widget.modelId)})"),
              _buildLegendItem(const Color(0xFFF59E0B), "Nutrient Dosing (00:05:00)"),
              _buildLegendItem(const Color(0xFF7C3AED), "Balance (00:04:00)"),
              _buildLegendItem(const Color(0xFF10B981), "Post-Flush (${Constants.showHourAndMinuteOnly(postValue, widget.modelId)})"),
            ],
          ),
          const SizedBox(height: 24),

          // Watering Controls Row (4 Fields)
          if (isWide)
            Row(
              children: [
                Expanded(child: _buildWateringMethodField(currentSeq, programPvd)),
                const SizedBox(width: 12),
                Expanded(child: _buildDurationValueField(currentSeq, programPvd, overAllPvd)),
                const SizedBox(width: 12),
                Expanded(child: _buildPreFlushField(currentSeq, programPvd, overAllPvd)),
                const SizedBox(width: 12),
                Expanded(child: _buildPostFlushField(currentSeq, programPvd, overAllPvd)),
              ],
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildWateringMethodField(currentSeq, programPvd)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDurationValueField(currentSeq, programPvd, overAllPvd)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildPreFlushField(currentSeq, programPvd, overAllPvd)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildPostFlushField(currentSeq, programPvd, overAllPvd)),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 16),

          // Soil Moisture Sensor Cut-off Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Soil Moisture Sensor Cut-off",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Automatically terminate watering cycle if volumetric moisture saturation limit is reached.",
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Switch(
                  value: currentSeq['applyMoisture'] ?? false,
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF5B21B6),
                  onChanged: (val) {
                    programPvd.editGroupSiteInjector('applyMoisture', val);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildWateringMethodField(dynamic currentSeq, IrrigationProgramMainProvider programPvd) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Watering Method",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),
          DropdownButton<String>(
            isExpanded: true,
            underline: Container(),
            value: currentSeq['method'] ?? 'Time',
            icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
            items: ['Time', 'Quantity'].map((m) {
              return DropdownMenuItem(
                value: m,
                child: Text(
                  m == 'Time' ? 'Duration (Time)' : 'Quantity (Volume)',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) programPvd.editWaterSetting('method', val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDurationValueField(dynamic currentSeq, IrrigationProgramMainProvider programPvd, OverAllUse overAllPvd) {
    final isQuantity = currentSeq['method'] == 'Quantity';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isQuantity ? "Quantity (Litres)" : "Duration (HH:MM:SS)",
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),
          isQuantity
              ? TextFormField(
                  controller: programPvd.waterQuantity,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  onFieldSubmitted: (val) => programPvd.editWaterSetting('quantityValue', val),
                )
              : InkWell(
                  onTap: () {
                    _showTimePicker(
                      programPvd,
                      overAllPvd,
                      programPvd.selectedGroup,
                      'waterTimeValue',
                      currentSeq['timeValue'] ?? '00:10:00',
                      'water',
                    );
                  },
                  child: Text(
                    Constants.showHourAndMinuteOnly(currentSeq['timeValue'] ?? '00:10:00', widget.modelId),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildPreFlushField(dynamic currentSeq, IrrigationProgramMainProvider programPvd, OverAllUse overAllPvd) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Pre-Flush Window",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () {
              _showTimePicker(
                programPvd,
                overAllPvd,
                programPvd.selectedGroup,
                'pre',
                currentSeq['preValue'] ?? '00:00:30',
                'pre',
              );
            },
            child: Text(
              Constants.showHourAndMinuteOnly(currentSeq['preValue'] ?? '00:00:30', widget.modelId),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostFlushField(dynamic currentSeq, IrrigationProgramMainProvider programPvd, OverAllUse overAllPvd) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Post-Flush Window",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () {
              _showTimePicker(
                programPvd,
                overAllPvd,
                programPvd.selectedGroup,
                'post',
                currentSeq['postValue'] ?? '00:00:30',
                'post',
              );
            },
            child: Text(
              Constants.showHourAndMinuteOnly(currentSeq['postValue'] ?? '00:00:30', widget.modelId),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Fertigation Injection Site Card
  Widget _buildFertigationInjectionSiteCard(
    BuildContext context,
    IrrigationProgramMainProvider programPvd,
    OverAllUse overAllPvd,
    dynamic currentSeq,
    bool isWide,
  ) {
    final isCentral = programPvd.segmentedControlCentralLocal == 0;
    final dosingKey = isCentral ? 'centralDosing' : 'localDosing';
    final applyFertKey = isCentral ? 'applyFertilizerForCentral' : 'applyFertilizerForLocal';

    final dosingList = currentSeq[dosingKey] as List? ?? [];
    final hasDosing = dosingList.isNotEmpty;
    final currentDosing = hasDosing ? dosingList[0] : null;

    final isFertEnabled = currentSeq[applyFertKey] ?? false;

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
                    child: const Icon(Icons.science_outlined, color: Color(0xFF7C3AED), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "FERTIGATION INJECTION SITE",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),

              // Central / Local Segmented Toggle
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => programPvd.editSegmentedCentralLocal(0),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCentral ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: isCentral
                              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)]
                              : null,
                        ),
                        child: Text(
                          "Central Injection",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isCentral ? FontWeight.bold : FontWeight.w500,
                            color: isCentral ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => programPvd.editSegmentedCentralLocal(1),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: !isCentral ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: !isCentral
                              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)]
                              : null,
                        ),
                        child: Text(
                          "Local Plot Injection",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: !isCentral ? FontWeight.bold : FontWeight.w500,
                            color: !isCentral ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Sub-Header Controls (Enable Fertigation Checkbox & Recipe Selector)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: isFertEnabled,
                    activeColor: const Color(0xFF5B21B6),
                    onChanged: (val) {
                      programPvd.editGroupSiteInjector('applyFertilizer', val);
                    },
                  ),
                  const Text(
                    "Enable Fertigation Channel Injections",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              if (isFertEnabled && hasDosing)
                Row(
                  children: [
                    Checkbox(
                      value: currentDosing?['applyRecipe'] ?? false,
                      activeColor: const Color(0xFF5B21B6),
                      onChanged: (val) {
                        programPvd.editGroupSiteInjector('applyRecipe', val);
                      },
                    ),
                    const Text(
                      "Preset Recipe",
                      style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            programPvd.recipe.isNotEmpty ? programPvd.recipe[0]['recipeName'] ?? "Recipe Alpha" : "Standard Recipe",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Channels Table Container
          if (hasDosing && isFertEnabled) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  // Table Header
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          "CHANNEL",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.8),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "METHOD",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.8),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "VALVE / VALUE",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.8),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "SUPPLY VALVE",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),

                  // Table Rows
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: (currentDosing['fertilizer'] as List? ?? []).length,
                    itemBuilder: (context, idx) {
                      final fertItem = currentDosing['fertilizer'][idx];
                      return _buildChannelRow(idx, fertItem, dosingKey, programPvd, overAllPvd);
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChannelRow(
    int idx,
    dynamic fertItem,
    String dosingKey,
    IrrigationProgramMainProvider programPvd,
    OverAllUse overAllPvd,
  ) {
    final isOn = fertItem['onOff'] ?? true;
    var currentMethod = fertItem['method'] ?? 'Time';
    if (currentMethod == 'Pro.qty per 1000L') {
      currentMethod = 'Pro.quant per 1000L';
    }

    final channelSNo = fertItem['sNo'];
    double? currentTankSNo;
    if (fertItem['outletTankValve'] != null) {
      currentTankSNo = (fertItem['outletTankValve'] as num).toDouble();
    }

    final tankList = programPvd.getOutletValveForChannel(channelSNo);
    final isValidTank = currentTankSNo != null && tankList.any((t) => (t['sNo'] as double) == currentTankSNo);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          // CHANNEL
          Expanded(
            child: Row(
              children: [
                Checkbox(
                  value: isOn,
                  activeColor: const Color(0xFF5B21B6),
                  onChanged: (val) {
                    programPvd.editOnOffInInjector(dosingKey, idx, val ?? true);
                  },
                ),
                Text(
                  "CH #${idx + 1}",
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),

          // METHOD
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButton<String>(
                isExpanded: true,
                underline: Container(),
                value: currentMethod,
                icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
                items: [
                  'Time',
                  if (AppConstants.gemModelList.contains(widget.modelId)) 'Pro.time',
                  if (AppConstants.gemModelList.contains(widget.modelId)) 'Pro.quantity',
                  'Quantity',
                  if (AppConstants.gemModelList.contains(widget.modelId)) 'Pro.quant per 1000L'
                ].map((m) {
                  return DropdownMenuItem(
                    value: m,
                    child: Text(m, style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A))),
                  );
                }).toList(),
                onChanged: (val) {
                  programPvd.editParticularChannelDetails('method', dosingKey, val, idx);
                },
              ),
            ),
          ),
          const SizedBox(width: 12),

          // VALUE / TIME
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ['Pro.quantity', 'Quantity', 'Pro.quant per 1000L'].contains(currentMethod)
                  ? TextFormField(
                      controller: programPvd.getInjectorController(idx),
                      keyboardType: TextInputType.number,
                      inputFormatters: AppProperties.regexForDecimal,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                      ),
                      onChanged: (val) {
                        programPvd.editParticularChannelDetails('quantityValue', dosingKey, val, idx);
                      },
                    )
                  : InkWell(
                      onTap: () {
                        _showTimePicker(
                          programPvd,
                          overAllPvd,
                          programPvd.selectedGroup,
                          'timeValue',
                          fertItem['timeValue'] ?? '00:05:00',
                          'fertilizer',
                          idx,
                        );
                      },
                      child: Center(
                        child: Text(
                          Constants.showHourAndMinuteOnly('${fertItem['timeValue'] ?? "00:05:00"}', widget.modelId),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // SUPPLY VALVE / TANK
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: tankList.isEmpty
                  ? const Center(
                      child: Text(
                        "N/A",
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    )
                  : DropdownButton<double>(
                      isExpanded: true,
                      underline: Container(),
                      value: isValidTank ? currentTankSNo : null,
                      hint: const Text("Select Valve", style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
                      items: tankList.map((t) {
                        return DropdownMenuItem<double>(
                          value: (t['sNo'] as num).toDouble(),
                          child: Text(
                            t['name'] ?? '',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        programPvd.editParticularChannelDetails('outletTankValve', dosingKey, val, idx);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTimePicker(
    IrrigationProgramMainProvider programPvd,
    OverAllUse overAllPvd,
    int index,
    String purpose,
    dynamic value,
    String validation, [
    int? fertIndex,
  ]) async {
    var fertilizerList = [
      if (programPvd.sequenceData[programPvd.selectedGroup]['centralDosing'].isNotEmpty)
        ...[
          for (var i in programPvd.sequenceData[programPvd.selectedGroup]['centralDosing'][0]['fertilizer'])
            formatTime(programPvd.fertilizerValueInSec(fertilizerData: i))
        ],
      if (programPvd.sequenceData[programPvd.selectedGroup]['localDosing'].isNotEmpty)
        ...[
          for (var i in programPvd.sequenceData[programPvd.selectedGroup]['localDosing'][0]['fertilizer'])
            formatTime(programPvd.fertilizerValueInSec(fertilizerData: i))
        ]
    ];

    Widget check() {
      String water = formatTime(programPvd.waterValueInSec());
      String pre = formatTime(programPvd.preValueInSec());
      String post = formatTime(programPvd.postValueInSec());

      if (validation == 'water') {
        return HoursMinutesSeconds(
          initialTime: '$value',
          waterTime: water,
          postTime: post,
          preTime: pre,
          validation: 'water',
          fertilizerTime: {'list': fertilizerList},
          modelId: widget.modelId,
        );
      } else if (validation == 'pre') {
        return HoursMinutesSeconds(
          initialTime: '$value',
          waterTime: water,
          postTime: post,
          preTime: pre,
          validation: 'pre',
          fertilizerTime: {'list': fertilizerList},
          modelId: widget.modelId,
        );
      } else if (validation == 'post') {
        return HoursMinutesSeconds(
          initialTime: '$value',
          waterTime: water,
          postTime: post,
          preTime: pre,
          validation: 'post',
          fertilizerTime: {'list': fertilizerList},
          modelId: widget.modelId,
        );
      } else if (validation == 'fertilizer') {
        return HoursMinutesSeconds(
          index: fertIndex,
          initialTime: '$value',
          waterTime: water,
          postTime: post,
          preTime: pre,
          validation: 'fertilizer-$fertIndex',
          fertilizerTime: {'list': fertilizerList},
          modelId: widget.modelId,
        );
      } else {
        return const Text('nothing');
      }
    }

    overAllPvd.editTimeAll();
    overAllPvd.editTime('hrs', int.parse(value.toString().split(':')[0]));
    overAllPvd.editTime('min', int.parse(value.toString().split(':')[1]));
    overAllPvd.editTime('sec', int.parse(value.toString().split(':')[2]));

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          surfaceTintColor: Colors.white,
          backgroundColor: Colors.white,
          title: check(),
        );
      },
    );
  }
}
