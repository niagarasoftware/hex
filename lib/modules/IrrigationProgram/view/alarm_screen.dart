import 'package:flutter/material.dart';
import 'package:hex/modules/IrrigationProgram/model/sequence_model.dart';
import 'package:hex/utils/constants.dart';
import 'package:provider/provider.dart';
import '../state_management/irrigation_program_provider.dart';

class AlarmScreen extends StatefulWidget {
  final int modelId;

  const AlarmScreen({
    super.key,
    required this.modelId,
  });

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class AlarmCategory {
  final String title;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final List<AlarmData> items;

  AlarmCategory({
    required this.title,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.items,
  });

  int get activeCount => items.where((e) => e.value).length;
}

class _AlarmScreenState extends State<AlarmScreen> {
  late IrrigationProgramMainProvider irrigationProgramMainProvider;
  late List<AlarmData> alarmList;
  bool isGlobalOverride = false;

  @override
  void initState() {
    super.initState();
    irrigationProgramMainProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: false);
    _initAlarmList();
  }

  void _initAlarmList() {
    if (irrigationProgramMainProvider.newAlarmList == null) return;
    if (AppConstants.gemModelList.contains(widget.modelId)) {
      alarmList = irrigationProgramMainProvider.newAlarmList!.alarmList
          .where((e) => e.gemDisplay)
          .toList();
    } else {
      alarmList = irrigationProgramMainProvider.newAlarmList!.alarmList
          .where((e) => e.ecoGemDisplay)
          .toList();
    }
  }

  List<AlarmCategory> _groupAlarms(List<AlarmData> alarms) {
    final flowItems = <AlarmData>[];
    final pressureItems = <AlarmData>[];
    final fertItems = <AlarmData>[];
    final commItems = <AlarmData>[];
    final tankItems = <AlarmData>[];
    final otherItems = <AlarmData>[];

    for (var a in alarms) {
      if (AppConstants.omsGemList.contains(widget.modelId) && ![1, 3].contains(a.sNo)) {
        // filter if oms condition applies
      }
      final nameLower = a.name.toLowerCase();
      if (nameLower.contains('flow')) {
        flowItems.add(a);
      } else if (nameLower.contains('pressure')) {
        pressureItems.add(a);
      } else if (nameLower.contains('ec') || nameLower.contains('ph') || nameLower.contains('dosing')) {
        fertItems.add(a);
      } else if (nameLower.contains('power') ||
          nameLower.contains('battery') ||
          nameLower.contains('communication') ||
          nameLower.contains('feedback') ||
          nameLower.contains('comm')) {
        commItems.add(a);
      } else if (nameLower.contains('tank') || nameLower.contains('pump') || nameLower.contains('sump')) {
        tankItems.add(a);
      } else {
        otherItems.add(a);
      }
    }

    final categories = <AlarmCategory>[];

    if (flowItems.isNotEmpty) {
      categories.add(AlarmCategory(
        title: "Flow Metrics",
        icon: Icons.show_chart_rounded,
        iconBgColor: const Color(0xFFF5F3FF),
        iconColor: const Color(0xFF7C3AED),
        items: flowItems,
      ));
    }

    if (pressureItems.isNotEmpty) {
      categories.add(AlarmCategory(
        title: "Pressure Monitoring",
        icon: Icons.speed_rounded,
        iconBgColor: const Color(0xFFF5F3FF),
        iconColor: const Color(0xFF7C3AED),
        items: pressureItems,
      ));
    }

    if (fertItems.isNotEmpty) {
      categories.add(AlarmCategory(
        title: "Fertigation & Chemical Dosing",
        icon: Icons.science_outlined,
        iconBgColor: const Color(0xFFF5F3FF),
        iconColor: const Color(0xFF7C3AED),
        items: fertItems,
      ));
    }

    if (commItems.isNotEmpty) {
      categories.add(AlarmCategory(
        title: "Power & Telemetry Comm",
        icon: Icons.bolt_outlined,
        iconBgColor: const Color(0xFFFFF7ED),
        iconColor: const Color(0xFFF59E0B),
        items: commItems,
      ));
    }

    if (tankItems.isNotEmpty) {
      categories.add(AlarmCategory(
        title: "Tanks & Pump Stations",
        icon: Icons.tune_outlined,
        iconBgColor: const Color(0xFFFEF2F2),
        iconColor: const Color(0xFFEF4444),
        items: tankItems,
      ));
    }

    if (otherItems.isNotEmpty) {
      categories.add(AlarmCategory(
        title: "General Notifications",
        icon: Icons.notifications_none_rounded,
        iconBgColor: const Color(0xFFF1F5F9),
        iconColor: const Color(0xFF5B21B6),
        items: otherItems,
      ));
    }

    return categories;
  }

  void _selectAll(bool value) {
    setState(() {
      for (var a in alarmList) {
        a.value = value;
        final mainIdx = irrigationProgramMainProvider.newAlarmList!.alarmList.indexWhere((e) => e.sNo == a.sNo);
        if (mainIdx != -1) {
          irrigationProgramMainProvider.newAlarmList!.alarmList[mainIdx].value = value;
        }
      }
    });
  }

  void _resetToDefaults() {
    setState(() {
      final defaultList = irrigationProgramMainProvider.newAlarmList?.defaultAlarm ?? [];
      for (var i = 0; i < alarmList.length; i++) {
        if (i < defaultList.length) {
          alarmList[i].value = defaultList[i].value;
          final mainIdx = irrigationProgramMainProvider.newAlarmList!.alarmList.indexWhere((e) => e.sNo == alarmList[i].sNo);
          if (mainIdx != -1) {
            irrigationProgramMainProvider.newAlarmList!.alarmList[mainIdx].value = defaultList[i].value;
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    irrigationProgramMainProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: true);

    if (irrigationProgramMainProvider.newAlarmList == null) {
      return const Center(child: CircularProgressIndicator());
    }

    _initAlarmList();
    final categories = _groupAlarms(alarmList);
    final isWide = MediaQuery.of(context).size.width >= 1000;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? MediaQuery.of(context).size.width * 0.04 : 16,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TOP SUPERVISORY CARD
          _buildSupervisoryCard(context),
          const SizedBox(height: 20),

          // 2. CATEGORIZED ALARM GROUPS GRID
          _buildCategoriesGrid(context, categories),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Top Supervisory System Header Card
  Widget _buildSupervisoryCard(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "REAL-TIME SUPERVISORY SYSTEM",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5B21B6),
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Alarm & Incident Notifications",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Specify which telemetry anomalies immediately flag alerts, pause Segments, or dispatch SMS/Push notifications to on-duty irrigation managers.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          if (isWide)
            Row(
              children: [
                // Global Override Control
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "GLOBAL ALARM OVERRIDE",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            "Master emergency interlock",
                            style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: isGlobalOverride,
                        activeThumbColor: Colors.white,
                        activeTrackColor: const Color(0xFF5B21B6),
                        onChanged: (val) {
                          setState(() {
                            isGlobalOverride = val;
                            _selectAll(val);
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Action Buttons
                OutlinedButton(
                  onPressed: () => _selectAll(true),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  child: const Text(
                    "Select All",
                    style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _selectAll(false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  child: const Text(
                    "Clear All",
                    style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _resetToDefaults,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F3FF),
                    side: const BorderSide(color: Color(0xFFDDD6FE)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  icon: const Icon(Icons.sync_rounded, size: 16, color: Color(0xFF5B21B6)),
                  label: const Text(
                    "Defaults",
                    style: TextStyle(color: Color(0xFF5B21B6), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: () => _selectAll(true),
                      child: const Text("Select All", style: TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: () => _selectAll(false),
                      child: const Text("Clear All", style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  onPressed: _resetToDefaults,
                  icon: const Icon(Icons.sync_rounded, size: 14, color: Color(0xFF5B21B6)),
                  label: const Text("Defaults", style: TextStyle(color: Color(0xFF5B21B6), fontSize: 11)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // Categorized Alarm Cards Grid
  Widget _buildCategoriesGrid(BuildContext context, List<AlarmCategory> categories) {
    final width = MediaQuery.of(context).size.width;
    int crossAxisCount = 3;
    if (width < 800) {
      crossAxisCount = 1;
    } else if (width < 1200) {
      crossAxisCount = 2;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: categories.map((cat) {
            double cardWidth = (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;
            return SizedBox(
              width: cardWidth,
              child: _buildCategoryCard(cat),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCategoryCard(AlarmCategory cat) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cat.iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(cat.icon, color: cat.iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${cat.activeCount} of ${cat.items.length} active",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Items List
          Column(
            children: cat.items.map((alarmItem) {
              final isChecked = alarmItem.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      alarmItem.value = !alarmItem.value;
                      final mainIdx = irrigationProgramMainProvider.newAlarmList!.alarmList
                          .indexWhere((e) => e.sNo == alarmItem.sNo);
                      if (mainIdx != -1) {
                        irrigationProgramMainProvider.newAlarmList!.alarmList[mainIdx].value = alarmItem.value;
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isChecked ? const Color(0xFFF5F3FF) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isChecked ? const Color(0xFFDDD6FE) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            alarmItem.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isChecked ? FontWeight.bold : FontWeight.w500,
                              color: isChecked ? const Color(0xFF0F172A) : const Color(0xFF334155),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: isChecked,
                            activeColor: const Color(0xFF5B21B6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              setState(() {
                                alarmItem.value = val ?? false;
                                final mainIdx = irrigationProgramMainProvider.newAlarmList!.alarmList
                                    .indexWhere((e) => e.sNo == alarmItem.sNo);
                                if (mainIdx != -1) {
                                  irrigationProgramMainProvider.newAlarmList!.alarmList[mainIdx].value =
                                      val ?? false;
                                }
                              });
                            },
                          ),
                        ),
                      ],
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
}
