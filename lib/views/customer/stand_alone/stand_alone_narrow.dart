import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hex/views/customer/stand_alone/widgets/fert_main_source_card.dart';
import 'package:hex/views/customer/stand_alone/widgets/fertilizer_site_card.dart';
import 'package:hex/views/customer/stand_alone/widgets/filter_site_card.dart';
import 'package:hex/views/customer/stand_alone/widgets/irrigation_line_card.dart';
import 'package:hex/views/customer/stand_alone/widgets/irrigation_pump_card.dart';
import 'package:hex/views/customer/stand_alone/widgets/main_valve_card.dart';
import 'package:hex/views/customer/stand_alone/widgets/source_pump_card.dart';
import 'package:hex/views/customer/stand_alone/widgets/valve_card_table.dart';
import 'package:provider/provider.dart';

import 'package:hex/models/customer/program_model.dart';
import '../../../models/customer/site_model.dart';
import '../../../repository/repository.dart';
import '../../../services/http_service.dart';
import '../../../utils/constants.dart';
import '../../../view_models/customer/stand_alone_view_model.dart';

class StandAloneNarrow extends StatefulWidget {
  const StandAloneNarrow({
    super.key,
    required this.customerId,
    required this.siteId,
    required this.controllerId,
    required this.userId,
    required this.deviceId,
    required this.callbackFunction,
    required this.masterData,
  });

  final int customerId, siteId, controllerId, userId;
  final String deviceId;
  final void Function(String msg) callbackFunction;
  final MasterControllerModel masterData;

  @override
  State<StandAloneNarrow> createState() => _StandAloneNarrowState();
}

class _StandAloneNarrowState extends State<StandAloneNarrow>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isNova =
    [...AppConstants.ecoGemModelList].contains(widget.masterData.modelId);

    return ChangeNotifierProvider(
      create: (_) => StandAloneViewModel(
          Repository(HttpService()),
          widget.masterData,
          widget.userId,
          widget.customerId,
          widget.controllerId,
          widget.deviceId)
        ..getProgramList(),
      child: Consumer<StandAloneViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: colorScheme.surfaceContainerLowest,
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              title: const Text(
                'Manual Control',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: colorScheme.surface,
              foregroundColor: colorScheme.onSurface,
              elevation: 0,
            ),
            body: SafeArea(
              child: Column(
                children: [
                  _buildControlHeader(context, viewModel, isNova),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: displayLineOrSequence(
                        widget.masterData,
                        viewModel,
                        viewModel.ddCurrentPosition,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => viewModel.stopAllManualOperation(context),
                    icon: const Icon(Icons.stop_circle_outlined, size: 18),
                    label: const Text(
                      'Stop Manually',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => viewModel.startManualOperation(context),
                    icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                    label: const Text(
                      'Start Manually',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlHeader(
      BuildContext context, StandAloneViewModel viewModel, bool isNova) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Program Selection Row
          if (viewModel.programList.length > 1) ...[
            Row(
              children: [
                Text(
                  'Select by: ',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<ProgramModel>(
                        isExpanded: true,
                        dropdownColor: colorScheme.surface,
                        value: viewModel.programList.isNotEmpty
                            ? viewModel.programList[viewModel.ddCurrentPosition]
                            : null,
                        items: viewModel.programList.map((item) {
                          return DropdownMenuItem<ProgramModel>(
                            value: item,
                            child: Text(
                              item.programName,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          viewModel.fetchStandAloneSelection(
                            value.serialNumber,
                            viewModel.programList.indexOf(value),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // Mode Selection (Timeless / Duration / Liters)
          if (!isNova)
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<SegmentWithFlow>(
                      segments: viewModel.ddCurrentPosition == 0
                          ? const <ButtonSegment<SegmentWithFlow>>[
                        ButtonSegment<SegmentWithFlow>(
                            value: SegmentWithFlow.manual,
                            label: Text('Timeless'),
                            icon: Icon(Icons.pan_tool_alt_outlined, size: 16)),
                        ButtonSegment<SegmentWithFlow>(
                            value: SegmentWithFlow.duration,
                            label: Text('Duration'),
                            icon: Icon(Icons.timer_outlined, size: 16)),
                      ]
                          : const <ButtonSegment<SegmentWithFlow>>[
                        ButtonSegment<SegmentWithFlow>(
                            value: SegmentWithFlow.manual,
                            label: Text('Timeless'),
                            icon: Icon(Icons.pan_tool_alt_outlined, size: 16)),
                        ButtonSegment<SegmentWithFlow>(
                            value: SegmentWithFlow.duration,
                            label: Text('Duration'),
                            icon: Icon(Icons.timer_outlined, size: 16)),
                        ButtonSegment<SegmentWithFlow>(
                            value: SegmentWithFlow.flow,
                            label: Text('Liters'),
                            icon: Icon(Icons.water_drop_outlined, size: 16)),
                      ],
                      selected: <SegmentWithFlow>{viewModel.segmentWithFlow},
                      onSelectionChanged:
                          (Set<SegmentWithFlow> newSelection) {
                        viewModel.segmentWithFlow = newSelection.first;
                        viewModel.segmentSelectionCallbackFunction(
                          viewModel.segmentWithFlow.index,
                          viewModel.durationValue,
                          viewModel.selectedIrLine,
                        );
                      },
                    ),
                  ),
                ),
                if (viewModel.segmentWithFlow.index == 1) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 38,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        side: BorderSide(color: colorScheme.outlineVariant),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () =>
                          viewModel.showDurationInputDialog(context),
                      child: Text(
                        viewModel.durationValue,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
                if (viewModel.segmentWithFlow.index == 2) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    height: 38,
                    child: TextField(
                      maxLength: 7,
                      controller: viewModel.flowLiter,
                      onChanged: (value) =>
                          viewModel.segmentSelectionCallbackFunction(
                            viewModel.segmentWithFlow.index,
                            value,
                            viewModel.selectedIrLine,
                          ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                      ],
                      decoration: InputDecoration(
                        hintText: 'Liters',
                        counterText: '',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        fillColor: colorScheme.surfaceContainerLow,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                          BorderSide(color: colorScheme.outlineVariant),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget displayLineOrSequence(
      MasterControllerModel masterData, StandAloneViewModel vm, int ddPosition) {
    bool isNova = [...AppConstants.ecoGemModelList].contains(masterData.modelId);
    bool isAerator =
    [...AppConstants.aquacultureModelList].contains(masterData.modelId);

    if (isAerator) {
      final aerator = masterData.irrigationLine
          .expand((line) => line.aeratorSources)
          .expand((ws) => ws.aeratorPump)
          .toList();

      final allAerator = aerator.fold<Map<double, PumpModel>>({}, (map, pump) {
        map[pump.sNo] = pump;
        return map;
      }).values.toList();

      return AeratorCard(
        pumps: allAerator,
        onChanged: (pump, val) => setState(() => pump.selected = val),
      );
    }

    final sourcePumps = masterData.irrigationLine
        .expand((line) => line.inletSources)
        .expand((ws) => ws.outletPump)
        .toList();

    final allSourcePumps =
    sourcePumps.fold<Map<double, PumpModel>>({}, (map, pump) {
      map[pump.sNo] = pump;
      return map;
    }).values.toList();

    final irrigationPumps = masterData.irrigationLine
        .expand((line) => line.outletSources)
        .expand((ws) => ws.outletPump)
        .toList();

    final allIrrigationPumps =
    irrigationPumps.fold<Map<double, PumpModel>>({}, (map, pump) {
      map[pump.sNo] = pump;
      return map;
    }).values.toList();

    final cFilterSites = masterData.irrigationLine
        .map((line) => line.centralFilterSite)
        .whereType<FilterSiteModel>()
        .toList();

    final cFertilizerSite = masterData.irrigationLine
        .map((line) => line.centralFertilizerSite)
        .whereType<FertilizerSiteModel>()
        .toList();

    final lFilterSites = masterData.irrigationLine
        .map((line) => line.localFilterSite)
        .whereType<FilterSiteModel>()
        .toList();

    final lFertilizerSite = masterData.irrigationLine
        .map((line) => line.localFertilizerSite)
        .whereType<FertilizerSiteModel>()
        .toList();

    final mainValve = masterData.irrigationLine
        .expand((line) => line.mainValveObjects)
        .toList();

    final allMainValve =
    mainValve.fold<Map<double, MainValveModel>>({}, (map, mValve) {
      map[mValve.sNo] = mValve;
      return map;
    }).values.toList();

    final fertMainSources = <double, FertMainSource>{};
    final fertTanks = <double, FertTank>{};
    for (final site in [...cFertilizerSite, ...lFertilizerSite]) {
      if (!site.hasTankSystem) continue;
      for (final m in site.tankSystem!.mainSources) {
        fertMainSources.putIfAbsent(m.source.sNo, () => m);
      }
      for (final t in site.tankSystem!.tanks) {
        fertTanks.putIfAbsent(t.sNo, () => t);
      }
    }

    return Column(
      children: [
        if (!isNova && vm.ddCurrentPosition == 0)
          SourcePumpCard(
            pumps: allSourcePumps,
            onChanged: (pump, val) => setState(() => pump.selected = val),
          ),
        IrrigationPumpCard(
          pumps: allIrrigationPumps,
          onChanged: (pump, val) => setState(() => pump.selected = val),
        ),
        FilterSiteCard(
          sites: cFilterSites,
          onChanged: (filter, val) => setState(() => filter.selected = val),
        ),
        FilterSiteCard(
          sites: lFilterSites,
          onChanged: (filter, val) => setState(() => filter.selected = val),
        ),
        FertilizerSiteCard(
          sites: cFertilizerSite,
          onChanged: (item, val) => setState(() => item.selected = val),
        ),
        FertilizerSiteCard(
          sites: lFertilizerSite,
          onChanged: (item, val) => setState(() => item.selected = val),
        ),
        MainValveCard(
          mainValve: allMainValve,
          onChanged: (item, val) => setState(() => item.selected = val),
        ),
        (!isNova && ddPosition == 0)
            ? Column(
          children: masterData.irrigationLine.map((line) {
            return IrrigationLineCard(
              line: line,
              showSwitch: vm.ddCurrentPosition != 0,
              onToggleValve: (valve, value) {
                setState(() => valve.isOn = value);
              },
              onToggleFogger: (FoggerModel fogger, bool value) {
                setState(() => fogger.isOn = value);
              },
            );
          }).toList(),
        )
            : vm.standAloneData != null
            ? Column(
          children: vm.standAloneData!.sequence.map((sequence) {
            final valveItems = sequence.valve.map((v) {
              return ValveTileItem(
                iconPath: 'assets/png/m_valve_grey.png',
                name: v.name,
                isOn: sequence.selected,
                onToggle: (val) {
                  setState(() {
                    for (var seq in vm.standAloneData!.sequence) {
                      seq.selected = false;
                    }
                    sequence.selected = val;
                  });
                },
              );
            }).toList();

            return ValveCardTable(
              title: sequence.name,
              showSwitch: !isNova ? vm.ddCurrentPosition != 0 : true,
              switchValue: sequence.selected,
              onSwitchChanged: (value) {
                setState(() {
                  for (var seq in vm.standAloneData!.sequence) {
                    seq.selected = false;
                  }
                  sequence.selected = value;
                });
              },
              valveItems: valveItems,
            );
          }).toList(),
        )
            : const SizedBox(),
        FertMainSourceCard(
          sources: fertMainSources.values.toList(),
          onChanged: (pump, val) => setState(() => pump.selected = val),
        ),
        FertTankValveCard(
          tanks: fertTanks.values.toList(),
          onChanged: (valve, val) => setState(() => valve.selected = val),
        ),
      ],
    );
  }
}
