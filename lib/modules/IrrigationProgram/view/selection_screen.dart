import 'package:flutter/material.dart';
import 'package:hex/modules/config_maker/model/device_object_model.dart';
import 'package:hex/utils/Theme/oro_theme.dart';
import 'package:hex/utils/constants.dart';
import 'package:provider/provider.dart';
import '../../../models/customer/site_model.dart';
import '../state_management/irrigation_program_provider.dart';

class SelectionScreen extends StatefulWidget {
  final List<NodeListModel> nodeList;
  final int modelId;

  const SelectionScreen({
    super.key,
    required this.modelId,
    required this.nodeList,
  });

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  late IrrigationProgramMainProvider irrigationProgramProvider;

  @override
  void initState() {
    super.initState();
    irrigationProgramProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: false);

    if (irrigationProgramProvider.selectedObjects != null) {
      if (irrigationProgramProvider.sampleIrrigationLine?.map((e) => e.irrigationLine).toList().length == 1 &&
          !(irrigationProgramProvider.selectedObjects!.any((element) => element.objectId == 2))) {
        irrigationProgramProvider.selectedObjects!.add(
          irrigationProgramProvider.sampleIrrigationLine!.map((e) => e.irrigationLine).toList()[0],
        );
      }
      if (!irrigationProgramProvider.isPumpStationMode) {
        if (irrigationProgramProvider.selectedObjects!.where((element) => element.objectId == 2).length > 1) {
          for (var i = 0; i < irrigationProgramProvider.sampleIrrigationLine!.map((e) => e.irrigationLine).toList().length; i++) {
            if (i != 0) {
              irrigationProgramProvider.selectedObjects!.removeWhere((element) => element.objectId == 2);
            } else {
              irrigationProgramProvider.selectedObjects!.add(
                irrigationProgramProvider.sampleIrrigationLine!.where((headUnit) {
                  return irrigationProgramProvider.irrigationLine!.sequence.any((sequenceItem) {
                    return sequenceItem['valve'].any((valve) {
                      return headUnit.valve!.any((valveItem) {
                        return valveItem.sNo == valve['sNo'];
                      });
                    });
                  });
                }).map((e) => e.irrigationLine).toList()[0],
              );
            }
          }
        }
      }
    }
  }

  void toggleSelection(int objectId, int siteMode, int index, List<DeviceObjectModel> dataList) {
    bool isAlreadySelected = irrigationProgramProvider.selectedObjects!.any((element) => element.sNo == dataList[index].sNo);

    if (isAlreadySelected) {
      irrigationProgramProvider.selectedObjects!.removeWhere((element) => element.sNo == dataList[index].sNo);
    } else {
      if (objectId == 4 && siteMode == 1) {
        irrigationProgramProvider.selectedObjects!.removeWhere((element) =>
            element.objectId == objectId &&
            irrigationProgramProvider.filterSite!.any((site) => site.siteMode == 1 && site.filterSite!.sNo == element.sNo));
      }
      if (objectId == 5 && siteMode == 1) {
        irrigationProgramProvider.selectedObjects!.removeWhere((element) =>
            element.objectId == objectId &&
            irrigationProgramProvider.fertilizerSite!.any((site) => site.siteMode == 1 && site.fertilizerSite!.sNo == element.sNo));
      }
      if (objectId == 4 && siteMode == 2) {
        irrigationProgramProvider.selectedObjects!.removeWhere((element) =>
            element.objectId == objectId &&
            irrigationProgramProvider.filterSite!.any((site) => site.siteMode == 2 && site.filterSite!.sNo == element.sNo));
      }
      if (objectId == 5 && siteMode == 2) {
        irrigationProgramProvider.selectedObjects!.removeWhere((element) =>
            element.objectId == objectId &&
            irrigationProgramProvider.fertilizerSite!.any((site) => site.siteMode == 2 && site.fertilizerSite!.sNo == element.sNo));
      }
      irrigationProgramProvider.selectedObjects!.add(dataList[index]);
    }
    irrigationProgramProvider.notifyUI();
  }

  @override
  Widget build(BuildContext context) {
    irrigationProgramProvider = Provider.of<IrrigationProgramMainProvider>(context);
    final isEcoGem = AppConstants.ecoGemAndPlusModelList.contains(widget.modelId);

    if (irrigationProgramProvider.sampleIrrigationLine == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final irrigationLine = irrigationProgramProvider.sampleIrrigationLine!;

    final centralFertilizerSite = irrigationProgramProvider.fertilizerSite!.where((site) {
      for (var i = 0; i < irrigationProgramProvider.selectedObjects!.length; i++) {
        if (site.siteMode == 1 &&
            irrigationProgramProvider.selectedObjects![i].objectId == 3 &&
            irrigationProgramProvider.selectedObjects![i].sNo == site.fertilizerSite?.sNo) {
          return true;
        }
      }
      return false;
    }).toList();

    final localFertilizerSite = irrigationProgramProvider.fertilizerSite!.where((site) {
      for (var i = 0; i < irrigationProgramProvider.selectedObjects!.length; i++) {
        if (site.siteMode == 2 &&
            irrigationProgramProvider.selectedObjects![i].objectId == 3 &&
            irrigationProgramProvider.selectedObjects![i].sNo == site.fertilizerSite?.sNo) {
          return true;
        }
      }
      return false;
    }).toList();

    final centralFilterSite = irrigationProgramProvider.filterSite!.where((site) {
      for (var i = 0; i < irrigationProgramProvider.selectedObjects!.length; i++) {
        if (site.siteMode == 1 &&
            irrigationProgramProvider.selectedObjects![i].objectId == 4 &&
            irrigationProgramProvider.selectedObjects![i].sNo == site.filterSite?.sNo) {
          return true;
        }
      }
      return false;
    }).toList();

    final localFilterSite = irrigationProgramProvider.filterSite!.where((site) {
      for (var i = 0; i < irrigationProgramProvider.selectedObjects!.length; i++) {
        if (site.siteMode == 2 &&
            irrigationProgramProvider.selectedObjects![i].objectId == 4 &&
            irrigationProgramProvider.selectedObjects![i].sNo == site.filterSite?.sNo) {
          return true;
        }
      }
      return false;
    }).toList();

    final selectedValves = irrigationProgramProvider.irrigationLine?.sequence
            .expand((e) => e['mainValve'].map((valve) => valve['sNo']))
            .toList() ??
        [];
    final availableValves = irrigationProgramProvider.mainValves?.map((e) => e.sNo).toList() ?? [];
    bool allSelectedValvesExist =
        selectedValves.isNotEmpty && selectedValves.every((sNo) => availableValves.contains(sNo));

    final isWide = MediaQuery.of(context).size.width >= 800;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? MediaQuery.of(context).size.width * 0.04 : 16,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CATEGORY 1: GENERAL
          _buildCategoryBadge("GENERAL"),
          const SizedBox(height: 12),

          // Main Valves
          if (!allSelectedValvesExist && (irrigationProgramProvider.mainValves?.isNotEmpty ?? false))
            _buildHardwareCard(
              title: "Main Valves",
              subtitle: "Master control valves",
              icon: Icons.alt_route_rounded,
              iconBgColor: const Color(0xFFFEF3C7),
              iconColor: const Color(0xFFD97706),
              items: irrigationLine.map((e) => e.mainValve ?? []).expand((list) => list).toList(),
              activeChipBg: const Color(0xFFFEF3C7),
              activeChipDot: const Color(0xFFF59E0B),
              activeChipText: const Color(0xFFB45309),
            ),

          // Pump Station Mode Switch Card
          if (irrigationLine.map((e) => e.irrigationPump ?? []).expand((list) => list).toList().length > 1)
            _buildHardwareCard(
              title: "Enable pump station mode",
              subtitle: "Automated pump selection based on real-time valve flow rate",
              icon: Icons.cell_tower_rounded,
              iconBgColor: activeBgLavender,
              iconColor: primaryPurple,
              trailingControl: Switch(
                value: irrigationProgramProvider.isPumpStationMode,
                activeThumbColor: Colors.white,
                activeTrackColor: primaryPurple,
                onChanged: (newValue) {
                  irrigationProgramProvider.updatePumpStationMode(newValue, 0);
                },
              ),
            ),

          if (!isEcoGem &&
              irrigationLine.map((e) => e.irrigationPump ?? []).expand((list) => list).toList().length > 1 &&
              irrigationProgramProvider.isPumpStationMode)
            _buildHardwareCard(
              title: "Change over",
              subtitle: "Automated pump changeover during trip conditions",
              icon: Icons.published_with_changes_rounded,
              iconBgColor: activeBgLavender,
              iconColor: primaryPurple,
              trailingControl: Switch(
                value: irrigationProgramProvider.isChangeOverMode,
                activeThumbColor: Colors.white,
                activeTrackColor: primaryPurple,
                onChanged: (newValue) {
                  irrigationProgramProvider.updatePumpStationMode(newValue, 1);
                },
              ),
            ),

          // Irrigation Pumps
          if (!irrigationProgramProvider.isPumpStationMode)
            _buildHardwareCard(
              title: "Irrigation Pumps",
              subtitle: "Select active primary booster pumps",
              icon: Icons.speed_rounded,
              iconBgColor: const Color(0xFFFEF2F2),
              iconColor: const Color(0xFFEF4444),
              items: irrigationLine.map((e) => e.irrigationPump ?? []).expand((list) => list).toList(),
              activeChipBg: const Color(0xFFFEE2E2),
              activeChipDot: const Color(0xFFEF4444),
              activeChipText: const Color(0xFFDC2626),
            ),

          // Head Units
          _buildHardwareCard(
            title: "Head Units",
            subtitle: "Main field distribution manifold lines",
            icon: Icons.water_drop_outlined,
            iconBgColor: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF10B981),
            items: !irrigationProgramProvider.isPumpStationMode
                ? irrigationProgramProvider.selectedObjects!.any((element) => element.objectId == 5)
                    ? irrigationLine
                        .where((line) => irrigationProgramProvider.selectedObjects!.any((element) =>
                            line.irrigationPump != null && line.irrigationPump!.any((pump) => element.sNo == pump.sNo)))
                        .map((line) => line.irrigationLine)
                        .toList()
                    : irrigationLine.where((headUnit) {
                        return irrigationProgramProvider.irrigationLine!.sequence.any((sequenceItem) {
                          return sequenceItem['valve'].any((valve) {
                            return headUnit.valve!.any((valveItem) {
                              return valveItem.sNo == valve['sNo'];
                            });
                          });
                        });
                      }).map((e) => e.irrigationLine).toList()
                : irrigationLine.map((e) => e.irrigationLine).toList(),
            activeChipBg: const Color(0xFFDCFCE7),
            activeChipDot: const Color(0xFF22C55E),
            activeChipText: const Color(0xFF166534),
          ),

          // Select OMS (if model has OMS)
          if (AppConstants.omsGemList.contains(widget.modelId))
            _buildControllerSection(
              title: "Select OMS",
              subtitle: "Assigned output management stations",
              icon: Icons.account_tree_outlined,
              iconBgColor: const Color(0xFFECFDF5),
              iconColor: const Color(0xFF10B981),
              controllerList: widget.nodeList
                  .map((e) => {
                        "controllerId": e.controllerId,
                        "deviceId": e.deviceId,
                        'serialNo': e.serialNumber,
                      })
                  .toList(),
            ),

          const SizedBox(height: 20),

          // CATEGORY 2: FERTILIZER
          if (irrigationLine
                  .map((e) => e.centralFertilization != null ? [e.centralFertilization!] : [])
                  .expand((list) => list)
                  .whereType<DeviceObjectModel>()
                  .toList()
                  .isNotEmpty ||
              irrigationLine
                  .map((e) => e.localFertilization != null ? [e.localFertilization!] : [])
                  .expand((list) => list)
                  .whereType<DeviceObjectModel>()
                  .toList()
                  .isNotEmpty) ...[
            _buildCategoryBadge("FERTILIZER"),
            const SizedBox(height: 12),

            // Central fertilizer site
            _buildHardwareCard(
              title: "Central fertilizer site",
              subtitle: "Master chemical dosing injection facility",
              icon: Icons.science_outlined,
              iconBgColor: const Color(0xFFF5F3FF),
              iconColor: const Color(0xFF7C3AED),
              siteMode: 1,
              connectedObject: 3,
              items: irrigationLine
                  .map((e) => e.centralFertilization != null ? [e.centralFertilization!] : [])
                  .expand((list) => list)
                  .whereType<DeviceObjectModel>()
                  .toList(),
              activeChipBg: const Color(0xFFEDE9FE),
              activeChipDot: const Color(0xFF7C3AED),
              activeChipText: const Color(0xFF6D28D9),
            ),

            // Central fert Selector
            if (centralFertilizerSite
                .map((e) => e.selector != null ? List<DeviceObjectModel>.from(e.selector!) : [])
                .expand((list) => list)
                .isNotEmpty)
              _buildHardwareCard(
                title: "Central fert Selector",
                subtitle: "Nutrient selector valves",
                icon: Icons.hub_outlined,
                iconBgColor: const Color(0xFFF5F3FF),
                iconColor: const Color(0xFF7C3AED),
                siteMode: 1,
                connectedObject: 3,
                items: centralFertilizerSite
                    .map((e) => e.selector != null ? List<DeviceObjectModel>.from(e.selector!) : [])
                    .expand((list) => list)
                    .whereType<DeviceObjectModel>()
                    .toList(),
              ),

            // EC sensors in central site
            if (centralFertilizerSite
                .map((e) => e.ec != null ? List<DeviceObjectModel>.from(e.ec!) : [])
                .expand((list) => list)
                .isNotEmpty)
              _buildHardwareCard(
                title: "EC sensors in central site",
                subtitle: "Electrical conductivity probes",
                icon: Icons.bolt_outlined,
                iconBgColor: const Color(0xFFECFDF5),
                iconColor: const Color(0xFF10B981),
                siteMode: 1,
                connectedObject: 3,
                items: centralFertilizerSite
                    .map((e) => e.ec != null ? List<DeviceObjectModel>.from(e.ec!) : [])
                    .expand((list) => list)
                    .whereType<DeviceObjectModel>()
                    .toList(),
                activeChipBg: const Color(0xFFDCFCE7),
                activeChipDot: const Color(0xFF22C55E),
                activeChipText: const Color(0xFF166534),
              ),

            // pH sensors in central site
            if (centralFertilizerSite
                .map((e) => e.ph != null ? List<DeviceObjectModel>.from(e.ph!) : [])
                .expand((list) => list)
                .isNotEmpty)
              _buildHardwareCard(
                title: "pH sensors in central site",
                subtitle: "Acidity / alkalinity sensors",
                icon: Icons.opacity_outlined,
                iconBgColor: const Color(0xFFFEF2F2),
                iconColor: const Color(0xFFEF4444),
                siteMode: 1,
                connectedObject: 3,
                items: centralFertilizerSite
                    .map((e) => e.ph != null ? List<DeviceObjectModel>.from(e.ph!) : [])
                    .expand((list) => list)
                    .whereType<DeviceObjectModel>()
                    .toList(),
                activeChipBg: const Color(0xFFFEE2E2),
                activeChipDot: const Color(0xFFEF4444),
                activeChipText: const Color(0xFFDC2626),
              ),

            // Local fertilizer site
            _buildHardwareCard(
              title: "Local fertilizer site",
              subtitle: "Field-level secondary nutrient station",
              icon: Icons.science_outlined,
              iconBgColor: const Color(0xFFF5F3FF),
              iconColor: const Color(0xFF7C3AED),
              siteMode: 2,
              connectedObject: 3,
              items: irrigationLine
                  .map((e) => e.localFertilization != null ? [e.localFertilization!] : [])
                  .expand((list) => list)
                  .whereType<DeviceObjectModel>()
                  .toList(),
              activeChipBg: const Color(0xFFEDE9FE),
              activeChipDot: const Color(0xFF7C3AED),
              activeChipText: const Color(0xFF6D28D9),
            ),

            // Local fert Selector
            if (localFertilizerSite
                .map((e) => e.selector != null ? List<DeviceObjectModel>.from(e.selector!) : [])
                .expand((list) => list)
                .isNotEmpty)
              _buildHardwareCard(
                title: "Local fert Selector",
                subtitle: "Field nutrient selector valves",
                icon: Icons.hub_outlined,
                iconBgColor: const Color(0xFFF5F3FF),
                iconColor: const Color(0xFF7C3AED),
                siteMode: 2,
                connectedObject: 3,
                items: localFertilizerSite
                    .map((e) => e.selector != null ? List<DeviceObjectModel>.from(e.selector!) : [])
                    .expand((list) => list)
                    .whereType<DeviceObjectModel>()
                    .toList(),
              ),

            // EC sensors in local site
            if (localFertilizerSite
                .map((e) => e.ec != null ? List<DeviceObjectModel>.from(e.ec!) : [])
                .expand((list) => list)
                .isNotEmpty)
              _buildHardwareCard(
                title: "EC sensors in local site",
                subtitle: "Electrical conductivity probes",
                icon: Icons.bolt_outlined,
                iconBgColor: const Color(0xFFECFDF5),
                iconColor: const Color(0xFF10B981),
                siteMode: 2,
                connectedObject: 3,
                items: localFertilizerSite
                    .map((e) => e.ec != null ? List<DeviceObjectModel>.from(e.ec!) : [])
                    .expand((list) => list)
                    .whereType<DeviceObjectModel>()
                    .toList(),
                activeChipBg: const Color(0xFFDCFCE7),
                activeChipDot: const Color(0xFF22C55E),
                activeChipText: const Color(0xFF166534),
              ),

            // pH sensors in local site
            if (localFertilizerSite
                .map((e) => e.ph != null ? List<DeviceObjectModel>.from(e.ph!) : [])
                .expand((list) => list)
                .isNotEmpty)
              _buildHardwareCard(
                title: "pH sensors in local site",
                subtitle: "Acidity / alkalinity sensors",
                icon: Icons.opacity_outlined,
                iconBgColor: const Color(0xFFFEF2F2),
                iconColor: const Color(0xFFEF4444),
                siteMode: 2,
                connectedObject: 3,
                items: localFertilizerSite
                    .map((e) => e.ph != null ? List<DeviceObjectModel>.from(e.ph!) : [])
                    .expand((list) => list)
                    .whereType<DeviceObjectModel>()
                    .toList(),
                activeChipBg: const Color(0xFFFEE2E2),
                activeChipDot: const Color(0xFFEF4444),
                activeChipText: const Color(0xFFDC2626),
              ),

            const SizedBox(height: 20),
          ],

          // CATEGORY 3: FILTERS
          if (irrigationLine
                  .map((e) => e.centralFiltration != null ? [e.centralFiltration!] : [])
                  .expand((list) => list)
                  .whereType<DeviceObjectModel>()
                  .isNotEmpty ||
              irrigationLine
                  .map((e) => e.localFiltration != null ? [e.localFiltration!] : [])
                  .expand((list) => list)
                  .whereType<DeviceObjectModel>()
                  .isNotEmpty) ...[
            _buildCategoryBadge("FILTERS"),
            const SizedBox(height: 12),

            // Central filter site
            _buildHardwareCard(
              title: "Central filter site",
              subtitle: "Primary media / gravel / mesh filtration station",
              icon: Icons.filter_alt_outlined,
              iconBgColor: const Color(0xFFFEF3C7),
              iconColor: const Color(0xFFD97706),
              siteMode: 1,
              connectedObject: 4,
              items: irrigationLine
                  .map((e) => e.centralFiltration != null ? [e.centralFiltration!] : [])
                  .expand((list) => list)
                  .whereType<DeviceObjectModel>()
                  .toList(),
              activeChipBg: const Color(0xFFFEF3C7),
              activeChipDot: const Color(0xFFF59E0B),
              activeChipText: const Color(0xFFB45309),
            ),

            // Central filters
            if (centralFilterSite.isNotEmpty)
              _buildHardwareCard(
                title: "Central filters",
                subtitle: "Assigned hardware units",
                icon: Icons.filter_list_outlined,
                iconBgColor: const Color(0xFFF5F3FF),
                iconColor: const Color(0xFF7C3AED),
                siteMode: 1,
                connectedObject: 4,
                items: centralFilterSite
                    .map((e) => e.filters != null ? List<DeviceObjectModel>.from(e.filters!) : [])
                    .expand((list) => list)
                    .whereType<DeviceObjectModel>()
                    .toList(),
                activeChipBg: const Color(0xFFEDE9FE),
                activeChipDot: const Color(0xFF7C3AED),
                activeChipText: const Color(0xFF6D28D9),
              ),

            // Central Filter Mode & Beginning Only Cards
            if (centralFilterSite.isNotEmpty) ...[
              if (isWide)
                Row(
                  children: [
                    Expanded(
                      child: _buildHardwareCard(
                        title: "CENTRAL FILTER OPERATION MODE",
                        subtitle: "Select central filter operation mode",
                        icon: Icons.access_time_rounded,
                        iconBgColor: const Color(0xFFF5F3FF),
                        iconColor: const Color(0xFF5B21B6),
                        trailingControl: PopupMenuButton<String>(
                          onSelected: (newValue) =>
                              irrigationProgramProvider.updateFiltrationMode(newValue, true),
                          itemBuilder: (ctx) => irrigationProgramProvider.filtrationModes
                              .map((m) => PopupMenuItem(value: m, child: Text(m)))
                              .toList(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F3FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  irrigationProgramProvider.selectedCentralFiltrationMode,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF5B21B6),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down, color: Color(0xFF5B21B6), size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!isEcoGem) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildHardwareCard(
                          title: "CENTRAL FILTRATION BEGINNING ONLY",
                          subtitle: "Filtration preference",
                          icon: Icons.filter_alt_outlined,
                          iconBgColor: const Color(0xFFF5F3FF),
                          iconColor: const Color(0xFF5B21B6),
                          trailingControl: Switch(
                            value: irrigationProgramProvider.centralFiltBegin,
                            activeThumbColor: Colors.white,
                            activeTrackColor: const Color(0xFF5B21B6),
                            onChanged: (newValue) =>
                                irrigationProgramProvider.updateFiltBegin(newValue, true),
                          ),
                        ),
                      ),
                    ],
                  ],
                )
              else ...[
                _buildHardwareCard(
                  title: "CENTRAL FILTER OPERATION MODE",
                  subtitle: "Select central filter operation mode",
                  icon: Icons.access_time_rounded,
                  iconBgColor: const Color(0xFFF5F3FF),
                  iconColor: const Color(0xFF5B21B6),
                  trailingControl: PopupMenuButton<String>(
                    onSelected: (newValue) =>
                        irrigationProgramProvider.updateFiltrationMode(newValue, true),
                    itemBuilder: (ctx) => irrigationProgramProvider.filtrationModes
                        .map((m) => PopupMenuItem(value: m, child: Text(m)))
                        .toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            irrigationProgramProvider.selectedCentralFiltrationMode,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5B21B6),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, color: Color(0xFF5B21B6), size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!isEcoGem)
                  _buildHardwareCard(
                    title: "CENTRAL FILTRATION BEGINNING ONLY",
                    subtitle: "Filtration preference",
                    icon: Icons.filter_alt_outlined,
                    iconBgColor: const Color(0xFFF5F3FF),
                    iconColor: const Color(0xFF5B21B6),
                    trailingControl: Switch(
                      value: irrigationProgramProvider.centralFiltBegin,
                      activeThumbColor: Colors.white,
                      activeTrackColor: const Color(0xFF5B21B6),
                      onChanged: (newValue) =>
                          irrigationProgramProvider.updateFiltBegin(newValue, true),
                    ),
                  ),
              ],
            ],

            // Local filter site
            _buildHardwareCard(
              title: "Local filter site",
              subtitle: "Field secondary filter station",
              icon: Icons.filter_alt_outlined,
              iconBgColor: const Color(0xFFFEF2F2),
              iconColor: const Color(0xFFEF4444),
              siteMode: 2,
              connectedObject: 4,
              items: irrigationLine
                  .map((e) => e.localFiltration != null ? [e.localFiltration!] : [])
                  .expand((list) => list)
                  .whereType<DeviceObjectModel>()
                  .toList(),
              activeChipBg: const Color(0xFFFEE2E2),
              activeChipDot: const Color(0xFFEF4444),
              activeChipText: const Color(0xFFDC2626),
            ),

            // Local filters
            if (localFilterSite.isNotEmpty)
              _buildHardwareCard(
                title: "Local filters",
                subtitle: "Secondary field filter units",
                icon: Icons.filter_list_outlined,
                iconBgColor: const Color(0xFFF5F3FF),
                iconColor: const Color(0xFF7C3AED),
                siteMode: 2,
                connectedObject: 4,
                items: localFilterSite
                    .map((e) => e.filters != null ? List<DeviceObjectModel>.from(e.filters!) : [])
                    .expand((list) => list)
                    .whereType<DeviceObjectModel>()
                    .toList(),
                activeChipBg: const Color(0xFFEDE9FE),
                activeChipDot: const Color(0xFF7C3AED),
                activeChipText: const Color(0xFF6D28D9),
              ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: primaryPurple,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildHardwareCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    Widget? trailingControl,
    List<DeviceObjectModel>? items,
    int? siteMode,
    int? connectedObject,
    Color activeChipBg = const Color(0xFFEDE9FE),
    Color activeChipDot = const Color(0xFF7C3AED),
    Color activeChipText = const Color(0xFF6D28D9),
  }) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    // Deduplicate items
    List<DeviceObjectModel> deduplicatedItems = [];
    if (items != null) {
      for (var ele in items) {
        if (!deduplicatedItems.any((e) => e.sNo == ele.sNo)) {
          deduplicatedItems.add(ele);
        }
      }
    }

    final hasChips = deduplicatedItems.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isWide && hasChips
          ? Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: iconColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: deduplicatedItems.map((item) {
                        item.siteMode = siteMode;
                        item.connectedObject = connectedObject;
                        final isSelected = irrigationProgramProvider.selectedObjects!
                            .any((element) => element.sNo == item.sNo);

                        return _buildChip(
                          label: item.name ?? "No name",
                          isSelected: isSelected,
                          activeBg: activeChipBg,
                          activeDot: activeChipDot,
                          activeText: activeChipText,
                          onTap: () {
                            if ((item.objectId == 4 && siteMode == 1) ||
                                (item.objectId == 4 && siteMode == 2) ||
                                (item.objectId == 5 && siteMode == 1) ||
                                (item.objectId == 5 && siteMode == 2)) {
                              toggleSelection(item.objectId, siteMode!, deduplicatedItems.indexOf(item), deduplicatedItems);
                            } else {
                              if (irrigationProgramProvider.selectedObjects!.any((element) => element.sNo == item.sNo)) {
                                irrigationProgramProvider.selectedObjects!.removeWhere((element) => (element.sNo == item.sNo));
                              } else {
                                irrigationProgramProvider.selectedObjects!.add(item);
                              }
                              irrigationProgramProvider.selectedObjects!.removeWhere((element) => (element.objectId == 2 && element.sNo != item.sNo));
                            }
                            irrigationProgramProvider.notifyUI();
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: iconBgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: iconColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (trailingControl != null) trailingControl,
                  ],
                ),
                if (hasChips) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: deduplicatedItems.map((item) {
                      item.siteMode = siteMode;
                      item.connectedObject = connectedObject;
                      final isSelected = irrigationProgramProvider.selectedObjects!
                          .any((element) => element.sNo == item.sNo);

                      return _buildChip(
                        label: item.name ?? "No name",
                        isSelected: isSelected,
                        activeBg: activeChipBg,
                        activeDot: activeChipDot,
                        activeText: activeChipText,
                        onTap: () {
                          if ((item.objectId == 4 && siteMode == 1) ||
                              (item.objectId == 4 && siteMode == 2) ||
                              (item.objectId == 5 && siteMode == 1) ||
                              (item.objectId == 5 && siteMode == 2)) {
                            toggleSelection(item.objectId, siteMode!, deduplicatedItems.indexOf(item), deduplicatedItems);
                          } else {
                            if (irrigationProgramProvider.selectedObjects!.any((element) => element.sNo == item.sNo)) {
                              irrigationProgramProvider.selectedObjects!.removeWhere((element) => (element.sNo == item.sNo));
                            } else {
                              irrigationProgramProvider.selectedObjects!.add(item);
                            }
                            irrigationProgramProvider.selectedObjects!.removeWhere((element) => (element.objectId == 2 && element.sNo != item.sNo));
                          }
                          irrigationProgramProvider.notifyUI();
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildControllerSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required List<Map<String, dynamic>> controllerList,
  }) {
    List<Map<String, dynamic>> deduplicated = [];
    for (var ele in controllerList) {
      if (!deduplicated.any((e) => e['controllerId'] == ele['controllerId'])) {
        deduplicated.add(ele);
      }
    }

    final isWide = MediaQuery.of(context).size.width >= 800;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isWide
          ? Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: iconColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: deduplicated.map((item) {
                        final controllerId = item['controllerId'];
                        final isSelected = irrigationProgramProvider.additionalData!.nodeSelection
                            .any((element) => element['controllerId'] == controllerId);

                        return _buildChip(
                          label: item['deviceId'] ?? "-",
                          isSelected: isSelected,
                          activeBg: const Color(0xFFDCFCE7),
                          activeDot: const Color(0xFF22C55E),
                          activeText: const Color(0xFF166534),
                          onTap: () {
                            if (irrigationProgramProvider.additionalData!.nodeSelection
                                .any((element) => element['controllerId'] == controllerId)) {
                              irrigationProgramProvider.additionalData!.nodeSelection
                                  .removeWhere((element) => element['controllerId'] == controllerId);
                            } else {
                              irrigationProgramProvider.additionalData!.nodeSelection.add(item);
                            }
                            irrigationProgramProvider.notifyUI();
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: deduplicated.map((item) {
                    final controllerId = item['controllerId'];
                    final isSelected = irrigationProgramProvider.additionalData!.nodeSelection
                        .any((element) => element['controllerId'] == controllerId);

                    return _buildChip(
                      label: item['deviceId'] ?? "-",
                      isSelected: isSelected,
                      activeBg: const Color(0xFFDCFCE7),
                      activeDot: const Color(0xFF22C55E),
                      activeText: const Color(0xFF166534),
                      onTap: () {
                        if (irrigationProgramProvider.additionalData!.nodeSelection
                            .any((element) => element['controllerId'] == controllerId)) {
                          irrigationProgramProvider.additionalData!.nodeSelection
                              .removeWhere((element) => element['controllerId'] == controllerId);
                        } else {
                          irrigationProgramProvider.additionalData!.nodeSelection.add(item);
                        }
                        irrigationProgramProvider.notifyUI();
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color activeBg = const Color(0xFFEDE9FE),
    Color activeDot = const Color(0xFF7C3AED),
    Color activeText = const Color(0xFF6D28D9),
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeDot.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isSelected ? activeDot : const Color(0xFF94A3B8),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeText : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
