import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hex/utils/Theme/oro_theme.dart';
import 'package:hex/utils/constants.dart';
import 'package:provider/provider.dart';
import '../../../Screens/planning/valve_group_screen.dart';
import '../state_management/irrigation_program_provider.dart';
import '../../SystemDefinitions/widgets/custom_snack_bar.dart';

class SequenceScreen extends StatefulWidget {
  final int userId;
  final int modelId;
  final int controllerId;
  final int serialNumber;
  final String deviceId;

  const SequenceScreen({
    super.key,
    required this.userId,
    required this.controllerId,
    required this.serialNumber,
    required this.deviceId,
    required this.modelId,
  });

  @override
  State<SequenceScreen> createState() => _SequenceScreenState();
}

class PlotData {
  final String id;
  final String title;
  final List<dynamic> items;
  final bool isGroup;
  final bool isMainValve;
  final int lineIndex;

  PlotData({
    required this.id,
    required this.title,
    required this.items,
    this.isGroup = false,
    this.isMainValve = false,
    this.lineIndex = 0,
  });
}

class _SequenceScreenState extends State<SequenceScreen> {
  final ScrollController _scrollController = ScrollController();
  final Set<String> _expandedPlotKeys = {};
  late IrrigationProgramMainProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<IrrigationProgramMainProvider>(context, listen: false);
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _provider.updateSequenceSerialNumber(
          widget.serialNumber == 0 ? _provider.serialNumberCreation : widget.serialNumber,
          modelId: widget.modelId,
        );
        if (_provider.irrigationLine != null &&
            (_provider.currentIndex < 0 ||
                _provider.currentIndex >= _provider.irrigationLine!.sequence.length)) {
          _provider.assigningCurrentIndex(0);
        }
        _provider.addNext = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String get _irrProgram => "Irrigation Program";
  String get _agiProgram => "Agitator Program";
  String get _othProgram => "Other Programs";
  String get _aeratorProgram => "Aerator Program";

  bool get _isIrrigationProgram =>
      _provider.programDetails!.programType == _irrProgram ||
      _provider.selectedProgramType == _irrProgram;

  bool get _isAgitatorProgram =>
      _provider.programDetails!.programType == _agiProgram ||
      _provider.selectedProgramType == _agiProgram;

  bool get _isOtherProgram =>
      _provider.programDetails!.programType == _othProgram ||
      _provider.selectedProgramType == _othProgram;

  bool get _isAeratorProgram =>
      _provider.programDetails!.programType == _aeratorProgram ||
      _provider.selectedProgramType == _aeratorProgram;

  int get _getIndexToShow => _provider.addNew
      ? _provider.irrigationLine!.sequence.length - 1
      : _provider.addNext
          ? _provider.currentIndex + 1
          : _provider.currentIndex;

  @override
  Widget build(BuildContext context) {
    _provider = Provider.of<IrrigationProgramMainProvider>(context);

    if (_provider.sampleIrrigationLine == null || _provider.irrigationLine == null) {
      return const Center(child: CircularProgressIndicator());
    }

    _provider.updateSequenceSerialNumber(
      widget.serialNumber == 0 ? _provider.serialNumberCreation : widget.serialNumber,
      modelId: widget.modelId,
    );

    final sequence = _provider.irrigationLine!.sequence;
    if (sequence.isEmpty) {
      return const Center(child: Text("No segments configured"));
    }

    final indexToShow = _getIndexToShow.clamp(0, sequence.length - 1);
    final isWide = MediaQuery.of(context).size.width >= 800;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? MediaQuery.of(context).size.width * 0.04 : 16,
        vertical: 16,
      ),
      child: Container(
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
        padding: const EdgeInsets.all(20),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 260,
                    child: _buildSegmentsSidebar(sequence, indexToShow),
                  ),
                  const SizedBox(width: 20),
                  const SizedBox(
                    height: 600,
                    child: VerticalDivider(width: 1, color: Color(0xFFF1F5F9)),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildSegmentDetailsPanel(sequence, indexToShow),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSegmentsHorizontalBar(sequence, indexToShow),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 16),
                  _buildSegmentDetailsPanel(sequence, indexToShow),
                ],
              ),
      ),
    );
  }

  Widget _buildSegmentsSidebar(List<dynamic> sequence, int indexToShow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "SEGMENTS",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 14),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sequence.length,
          itemBuilder: (context, index) {
            final isSelected = index == indexToShow;
            final item = sequence[index];
            final assignedValves = ((item['valve'] as List? ?? []).length +
                (item['mainValve'] as List? ?? []).length);
            final plots = _getPlotsList();
            final plotCount = plots.where((p) => _getAssignedValvesInPlot(p, index).isNotEmpty).length;
            final displayName = item['name'] ?? 'Segment ${index + 1}';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () {
                  _provider.addNext = false;
                  _provider.assigningCurrentIndex(index);
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFE2E8F0) : Colors.transparent,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        if (isSelected)
                          Container(
                            width: 4,
                            decoration: BoxDecoration(
                              color: primaryPurple,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                            ),
                          ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                          color: textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "$plotCount plots · $assignedValves valves",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? activeBgLavender
                                        : primaryBackground,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? primaryPurple
                                            : textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              _provider.addNextSequence(
                serialNumber: widget.serialNumber,
                zoneSno: sequence.length + 1,
                indexToInsert: sequence.length - 1,
                modelId: widget.modelId,
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: Icon(Icons.add, size: 18, color: primaryPurple),
            label: Text(
              "+ New segment",
              style: TextStyle(
                color: primaryPurple,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentsHorizontalBar(List<dynamic> sequence, int indexToShow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "SEGMENTS",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textMuted,
                letterSpacing: 0.8,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                _provider.addNextSequence(
                  serialNumber: widget.serialNumber,
                  zoneSno: sequence.length + 1,
                  indexToInsert: sequence.length - 1,
                  modelId: widget.modelId,
                );
              },
              icon: Icon(Icons.add, size: 16, color: primaryPurple),
              label: Text(
                "+ New segment",
                style: TextStyle(
                  color: primaryPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(sequence.length, (index) {
              final isSelected = index == indexToShow;
              final item = sequence[index];
              final displayName = item['name'] ?? 'Segment ${index + 1}';

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(displayName),
                  selected: isSelected,
                  onSelected: (_) {
                    _provider.addNext = false;
                    _provider.assigningCurrentIndex(index);
                  },
                  selectedColor: primaryPurple,
                  backgroundColor: primaryBackground,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : textDark,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? primaryPurple : const Color(0xFFE2E8F0),
                    ),
                  ),
                  showCheckmark: false,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentDetailsPanel(List<dynamic> sequence, int indexToShow) {
    final currentSeq = sequence[indexToShow];
    final segmentName = currentSeq['name'] ?? 'Segment ${indexToShow + 1}';
    final plots = _getPlotsList();

    final assignedValves = ((currentSeq['valve'] as List? ?? []).length +
        (currentSeq['mainValve'] as List? ?? []).length);
    final totalValvesCount = _provider.sampleIrrigationLine
            ?.expand((e) => e.valve ?? [])
            .length ??
        0;

    int plotsWithoutValves = 0;

    for (var plot in plots) {
      if (_getAssignedValvesInPlot(plot, indexToShow).isEmpty) {
        plotsWithoutValves++;
      }
    }

    if (_expandedPlotKeys.isEmpty && plots.isNotEmpty) {
      _expandedPlotKeys.add(plots.first.id);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Row of Detail Panel
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    segmentName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "${plots.length} plots · $assignedValves of $totalValvesCount valves assigned",
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      if (plotsWithoutValves > 0) ...[
                        const Text(
                          " · ",
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                        Text(
                          "$plotsWithoutValves plot${plotsWithoutValves > 1 ? 's' : ''} without valves",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => _showEditSequencesSheet(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  child: Text(
                    "Select",
                    style: TextStyle(color: textDark, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showAddPlotDialog(),
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                  label: const Text(
                    "Add plot",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                OutlinedButton(
                  onPressed: () => _showDeleteConfirmationDialog(indexToShow),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFEE2E8)),
                    backgroundColor: const Color(0xFFFEF2F2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  child: const Text(
                    "Delete segment",
                    style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Plot Cards List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: plots.length,
          itemBuilder: (context, index) {
            final plot = plots[index];
            return _buildPlotCard(plot, indexToShow);
          },
        ),
      ],
    );
  }

  Widget _buildPlotCard(PlotData plot, int sequenceIndex) {
    final isExpanded = _expandedPlotKeys.contains(plot.id);
    final assignedValves = _getAssignedValvesInPlot(plot, sequenceIndex);
    final badgeText = _getPlotBadge(assignedValves);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Accordion Header
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedPlotKeys.remove(plot.id);
                } else {
                  _expandedPlotKeys.add(plot.id);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                    color: textMuted,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    plot.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (assignedValves.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: activeBgLavender,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryPurple,
                        ),
                      ),
                    )
                  else
                    const Text(
                      "No valves assigned",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    "${assignedValves.length} valves",
                    style: TextStyle(fontSize: 13, color: textMuted),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => _deletePlotFromSequence(plot, sequenceIndex),
                    child: Text(
                      "Delete",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Accordion Body
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Valve map",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: plot.items.map((item) {
                      final isSelected = _isValveSelected(item, plot, sequenceIndex);
                      final itemName = item.name ?? 'Valve';

                      return InkWell(
                        onTap: () => _handleValveTap(
                          item,
                          plot.isGroup,
                          plot.isGroup ? plot.items : null,
                          plot.lineIndex,
                          plot.isMainValve,
                          sequenceIndex,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryPurple : primaryBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected ? null : Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: primaryPurple.withValues(alpha: 0.25),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            itemName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : textDark,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<PlotData> _getPlotsList() {
    final plots = <PlotData>[];
    final sampleIrrigationLine = _provider.sampleIrrigationLine;

    if (_isIrrigationProgram && sampleIrrigationLine != null) {
      // 1. Main Valves
      final mainValves = sampleIrrigationLine.expand((e) => e.mainValve ?? []).toList();
      if (mainValves.isNotEmpty) {
        final items = AppConstants.omsGemList.contains(widget.modelId)
            ? mainValves.take(1).toList()
            : mainValves;
        plots.add(PlotData(
          id: 'main_valves',
          title: 'Main valves',
          items: items,
          isMainValve: true,
        ));
      }

      // 2. Valve Groups
      final groups = _provider.irrigationLine?.defaultData.group ?? [];
      for (var group in groups) {
        plots.add(PlotData(
          id: group.id,
          title: group.name,
          items: group.valve,
          isGroup: true,
        ));
      }

      // 3. Irrigation Lines (Plots)
      for (int i = 0; i < sampleIrrigationLine.length; i++) {
        final line = sampleIrrigationLine[i];
        final lineValves = AppConstants.omsGemList.contains(widget.modelId)
            ? (line.valve ?? []).take(6).toList()
            : (line.valve ?? []);
        plots.add(PlotData(
          id: 'line_$i',
          title: line.irrigationLine.name ?? 'Unnamed Plot',
          items: lineValves,
          lineIndex: i,
        ));
      }
    }

    // Agitators
    if (_isAgitatorProgram && _provider.agitators != null && _provider.agitators!.isNotEmpty) {
      plots.add(PlotData(
        id: 'agitators',
        title: 'Agitators',
        items: _provider.agitators!,
      ));
    }

    // Aerators
    if (_isAeratorProgram && _provider.aerators != null && _provider.aerators!.isNotEmpty) {
      plots.add(PlotData(
        id: 'aerators',
        title: 'Aerators',
        items: _provider.aerators!,
      ));
    }

    // Other programs
    if (_isOtherProgram && sampleIrrigationLine != null) {
      final fans = sampleIrrigationLine.expand((e) => e.fan ?? []).toList();
      if (fans.isNotEmpty) {
        plots.add(PlotData(id: 'fans', title: 'Fans', items: fans));
      }
      final foggers = sampleIrrigationLine.expand((e) => e.fogger ?? []).toList();
      if (foggers.isNotEmpty) {
        plots.add(PlotData(id: 'foggers', title: 'Foggers', items: foggers));
      }
      final lights = sampleIrrigationLine.expand((e) => e.light ?? []).toList();
      if (lights.isNotEmpty) {
        plots.add(PlotData(id: 'lights', title: 'Lights', items: lights));
      }
    }

    return plots;
  }

  List<dynamic> _getAssignedValvesInPlot(PlotData plot, int sequenceIndex) {
    final sequence = _provider.irrigationLine!.sequence;
    if (sequence.isEmpty || sequenceIndex >= sequence.length) return [];
    final currentSeq = sequence[sequenceIndex];

    if (plot.isGroup) {
      final selectedGroups = currentSeq['selectedGroup'] as List? ?? [];
      if (selectedGroups.contains(plot.id)) {
        return plot.items;
      }
      return [];
    } else if (plot.isMainValve) {
      final mainValves = currentSeq['mainValve'] as List? ?? [];
      return plot.items.where((item) => mainValves.any((e) => e['sNo'] == item.sNo)).toList();
    } else {
      final valves = currentSeq['valve'] as List? ?? [];
      return plot.items.where((item) => valves.any((e) => e['sNo'] == item.sNo)).toList();
    }
  }

  bool _isValveSelected(dynamic item, PlotData plot, int sequenceIndex) {
    final sequence = _provider.irrigationLine!.sequence;
    if (sequence.isEmpty || sequenceIndex >= sequence.length) return false;
    final currentSeq = sequence[sequenceIndex];

    if (plot.isGroup) {
      return (currentSeq['selectedGroup'] as List?)?.contains(plot.id) ?? false;
    } else if (plot.isMainValve) {
      final mainValves = currentSeq['mainValve'] as List? ?? [];
      return mainValves.any((e) => e['sNo'] == item.sNo);
    } else {
      final valves = currentSeq['valve'] as List? ?? [];
      return valves.any((e) => e['sNo'] == item.sNo);
    }
  }

  String _getPlotBadge(List<dynamic> assignedValvesInPlot) {
    if (assignedValvesInPlot.isEmpty) {
      return "No valves assigned";
    }
    List<int> numbers = [];
    for (var v in assignedValvesInPlot) {
      var sno = v.sNo ?? v.id ?? v.objectId;
      if (sno != null) {
        var numStr = sno.toString().replaceAll(RegExp(r'[^\d]'), '');
        if (numStr.isNotEmpty) {
          var parsed = int.tryParse(numStr);
          if (parsed != null) numbers.add(parsed);
        }
      }
    }
    numbers.sort();
    if (numbers.isNotEmpty) {
      if (numbers.length == 1) {
        return "V${numbers.first}";
      } else if (numbers.last - numbers.first == numbers.length - 1) {
        return "V${numbers.first}-${numbers.last}";
      } else {
        return "V${numbers.join(', ')}";
      }
    }
    return "${assignedValvesInPlot.length} valves";
  }

  void _handleValveTap(
    dynamic item,
    bool isGroup,
    List<dynamic>? dataList,
    int lineIndex,
    bool isMainValve,
    int indexToShow,
  ) {
    final sequence = _provider.irrigationLine!.sequence;
    final groupId = isGroup ? item.id : '';

    void onConfirm() {
      sequence[indexToShow]['modified'] = true;
      _addValvesToSequence(isGroup, dataList, lineIndex, isMainValve, indexToShow, groupId, item);
    }

    if (sequence[indexToShow]['modified'] ?? false) {
      _showModifySequenceDialog(onConfirm);
    } else {
      if (!sequence[indexToShow].containsKey('selectedGroup')) {
        sequence[indexToShow]['selectedGroup'] = [];
      }
      _addValvesToSequence(isGroup, dataList, lineIndex, isMainValve, indexToShow, groupId, item);
    }
  }

  void _showModifySequenceDialog(VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Warning!"),
        content: const Text(
          "The fertilizer settings will be erased while adding or removing valve in the existing sequence! \n Are you sure modify the sequence?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
            },
            child: const Text("Yes", style: TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addValvesToSequence(
    bool isGroup,
    List<dynamic>? dataList,
    int lineIndex,
    bool isMainValve,
    int sequenceIndex,
    String groupId,
    dynamic item,
  ) {
    _provider.addValvesInSequence(
      valves: isGroup ? dataList!.map((e) => e.toJson()).toList() : [item.toJson()],
      lineIndex: lineIndex,
      isMainValve: isMainValve,
      sequenceIndex: sequenceIndex,
      isGroup: isGroup,
      serialNumber: widget.serialNumber == 0 ? _provider.serialNumberCreation : widget.serialNumber,
      sNo: _provider.irrigationLine!.sequence.length + 1,
      groupId: groupId,
      context: context,
      modelId: widget.modelId,
    );
  }

  void _deletePlotFromSequence(PlotData plot, int sequenceIndex) {
    final sequence = _provider.irrigationLine!.sequence[sequenceIndex];
    for (var item in plot.items) {
      if (plot.isMainValve) {
        (sequence['mainValve'] as List).removeWhere((e) => e['sNo'] == item.sNo);
      } else if (plot.isGroup) {
        (sequence['selectedGroup'] as List).remove(plot.id);
        for (var v in plot.items) {
          (sequence['valve'] as List).removeWhere((e) => e['sNo'] == v.sNo);
        }
      } else {
        (sequence['valve'] as List).removeWhere((e) => e['sNo'] == item.sNo);
      }
    }
    _provider.notifyUI();
  }

  void _showAddPlotDialog() {
    showAdaptiveDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Plot / Group"),
        content: const Text("Select or create a valve group/plot to add to this segment."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupListScreen(
                    userId: widget.userId,
                    customerId: widget.userId,
                    controllerId: widget.controllerId,
                    deviceId: widget.deviceId,
                  ),
                ),
              );
            },
            child: const Text("Create Group"),
          ),
        ],
      ),
    );
  }

  void _showEditSequencesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 8),
                child: Text(
                  'Edit Sequences',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _provider.irrigationLine!.sequence.length,
                  itemBuilder: (context, index) =>
                      _buildSequenceListTile(index, setModalState),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSequenceListTile(int index, StateSetter setModalState) {
    final sequence = _provider.irrigationLine!.sequence[index];
    final valves = (sequence['valve'] as List? ?? []);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Text('${index + 1}'),
      title: Text(sequence['name']),
      subtitle: Text(
        valves.map((e) => e['name']).join(', '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit, size: 20),
        color: Theme.of(context).primaryColor,
        onPressed: () => _showEditNameDialog(context, index, setModalState),
      ),
      onTap: () => _showEditNameDialog(context, index, setModalState),
    );
  }

  void _showEditNameDialog(BuildContext context, int index, StateSetter setModalState) {
    final sequence = _provider.irrigationLine!.sequence;
    final controller = TextEditingController(text: sequence[index]['name'])
      ..selection = TextSelection(baseOffset: 0, extentOffset: sequence[index]['name'].length);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Sequence Name'),
        content: Form(
          key: formKey,
          child: TextFormField(
            autofocus: true,
            controller: controller,
            inputFormatters: [
              LengthLimitingTextInputFormatter(20),
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s.]')),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Name cannot be empty';
              if (sequence.any((e) => e['name'] == value && e != sequence[index])) {
                return 'Name already exists';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                setModalState(() => sequence[index]['name'] = controller.text);
                _provider.notifyUI();
                Navigator.pop(ctx);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(int indexToShow) {
    showAdaptiveDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('Are you sure to erase the sequence?'),
        actions: [
          TextButton(
            child: const Text("CANCEL", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text("OK"),
            onPressed: () {
              _provider.deleteFunction(
                indexToShow: indexToShow,
                serialNumber: widget.serialNumber,
                modelId: widget.modelId,
              );
              Navigator.of(context).pop();
              if (mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(CustomSnackBar(message: 'The sequence is erased!'));
              }
            },
          ),
        ],
      ),
    );
  }
}
