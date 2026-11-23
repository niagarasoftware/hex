import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../models/customer/condition_library_model.dart';
import '../../../../repository/repository.dart';
import '../../../../services/http_service.dart';
import '../../../../utils/my_function.dart';
import '../../../../view_models/customer/condition_library_view_model.dart';
import '../widgets/component_selection.dart';

class ConditionLibraryWide extends StatefulWidget {
  const ConditionLibraryWide({
    super.key,
    required this.customerId,
    required this.controllerId,
    required this.userId,
    required this.deviceId,
  });

  final int customerId;
  final int controllerId;
  final int userId;
  final String deviceId;

  @override
  State<ConditionLibraryWide> createState() => _ConditionLibraryWideState();
}

class _ConditionLibraryWideState extends State<ConditionLibraryWide> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConditionLibraryViewModel(Repository(HttpService()))
        ..getConditionLibraryData(widget.customerId, widget.controllerId),
      child: Consumer<ConditionLibraryViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFFBFBFD),
            body: Column(
              children: [
                _buildHeader(context, vm),
                Expanded(
                  child: vm.isLoading
                      ? _buildSkeletonList()
                      : _buildConditionsList(context, vm),
                ),
                if (!vm.isLoading) _buildBottomBar(context, vm),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ConditionLibraryViewModel vm) {
    final conditionCount = vm.isLoading ? 0 : vm.clData.cnLibrary.condition.length;
    final limit = vm.isLoading ? 0 : vm.clData.defaultData.conditionLimit;
    final canCreate = conditionCount != limit && !vm.isLoading;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF3EEFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.layers_rounded,
              color: Color(0xFF5B22B6),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Condition Library',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Create and manage device conditions',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Search Field
          Container(
            width: 220,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim().toLowerCase();
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search condition...',
                      hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    child: const Icon(Icons.close, size: 16, color: Color(0xFF94A3B8)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Filter Button
          PopupMenuButton<String>(
            tooltip: 'Filter by type',
            onSelected: (val) {
              setState(() {
                _filterType = val;
              });
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'All', child: Text('All Types')),
              const PopupMenuItem(value: 'Sensor', child: Text('Sensor')),
              const PopupMenuItem(value: 'Program', child: Text('Program')),
              const PopupMenuItem(value: 'Combined', child: Text('Combined')),
            ],
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _filterType == 'All' ? Colors.white : const Color(0xFFF3EEFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _filterType == 'All' ? const Color(0xFFE2E8F0) : const Color(0xFF5B22B6),
                ),
              ),
              child: Icon(
                Icons.filter_alt_outlined,
                size: 18,
                color: _filterType == 'All' ? const Color(0xFF64748B) : const Color(0xFF5B22B6),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // + Create Condition Button
          ElevatedButton.icon(
            onPressed: canCreate ? () => vm.createNewCondition() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B22B6),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade500,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: const Text(
              'Create Condition',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonList() {
    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(width: 3.5, height: 48, color: const Color(0xFF5B22B6)),
              const SizedBox(width: 16),
              Container(width: 110, height: 20, color: Colors.grey.shade200),
              const SizedBox(width: 24),
              Container(width: 200, height: 24, color: Colors.grey.shade200),
              const SizedBox(width: 24),
              Container(width: 150, height: 24, color: Colors.grey.shade200),
              const Spacer(),
              const Icon(Icons.more_vert, size: 20, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConditionsList(BuildContext context, ConditionLibraryViewModel vm) {
    if (vm.clData.cnLibrary.condition.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rule_folder_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              'No condition available',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      );
    }

    final conditions = vm.clData.cnLibrary.condition;
    // Map with original indices
    final List<MapEntry<int, Condition>> filtered = [];
    for (int i = 0; i < conditions.length; i++) {
      final c = conditions[i];
      if (_filterType != 'All' && c.type != _filterType) continue;
      if (_searchQuery.isNotEmpty) {
        final matches = c.name.toLowerCase().contains(_searchQuery) ||
            c.component.toLowerCase().contains(_searchQuery) ||
            c.parameter.toLowerCase().contains(_searchQuery) ||
            c.rule.toLowerCase().contains(_searchQuery) ||
            c.reason.toLowerCase().contains(_searchQuery);
        if (!matches) continue;
      }
      filtered.add(MapEntry(i, c));
    }

    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'No matching conditions found',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final entry = filtered[idx];
        final index = entry.key;
        final condition = entry.value;

        return _buildConditionRow(context, vm, condition, index);
      },
    );
  }

  Widget _buildConditionRow(
    BuildContext context,
    ConditionLibraryViewModel vm,
    Condition condition,
    int index,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Purple Accent Line
            Container(
              width: 3.5,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF5B22B6),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            // Col 1: Condition Name & Status
            SizedBox(
              width: 110,
              child: _buildCol1NameAndStatus(context, vm, condition, index),
            ),
            const SizedBox(width: 8),
            // Col 2: Switch & Type Radios
            SizedBox(
              width: 275,
              child: _buildCol2SwitchAndType(context, vm, condition, index),
            ),
            const SizedBox(width: 10),
            // Col 3: COMPONENT
            SizedBox(
              width: 155,
              child: _buildCol3Component(context, vm, condition, index),
            ),
            const SizedBox(width: 10),
            // Col 4: PARAMETER
            SizedBox(
              width: 75,
              child: _buildCol4Parameter(context, vm, condition, index),
            ),
            const SizedBox(width: 10),
            // Col 5: VALUE / THRESHOLD
            SizedBox(
              width: 155,
              child: _buildCol5ValueThreshold(context, vm, condition, index),
            ),
            const SizedBox(width: 10),
            // Col 6: WHERE ? / REASON
            SizedBox(
              width: 125,
              child: _buildCol6WhereOrReason(context, vm, condition, index),
            ),
            const SizedBox(width: 10),
            // Col 7: DELAY TIME
            SizedBox(
              width: 70,
              child: _buildCol7DelayTime(context, vm, condition, index),
            ),
            const SizedBox(width: 6),
            // Col 8: Actions (Three Dot Menu)
            _buildThreeDotMenu(context, vm, condition, index),
          ],
        ),
      ),
    );
  }

  Widget _buildCol1NameAndStatus(
    BuildContext context,
    ConditionLibraryViewModel vm,
    Condition condition,
    int index,
  ) {
    String statusSubtitle = '';
    if (condition.type == 'Program') {
      if (condition.value.isNotEmpty && condition.value != '--') {
        statusSubtitle = 'Running ${condition.value}';
      } else {
        statusSubtitle = condition.rule.isNotEmpty && condition.rule != '--' ? condition.rule : '';
      }
    } else {
      if (condition.value.isNotEmpty && condition.value != '--') {
        statusSubtitle = '${condition.threshold != '--' ? condition.threshold : ''} ${condition.value}'.trim();
      } else if (condition.rule.isNotEmpty && condition.rule != '--') {
        statusSubtitle = condition.rule;
      }
    }

    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            condition.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (statusSubtitle.isNotEmpty) ...[
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    statusSubtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCol2SwitchAndType(
    BuildContext context,
    ConditionLibraryViewModel vm,
    Condition condition,
    int index,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 36,
          height: 20,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Switch(
              value: condition.status,
              activeColor: const Color(0xFF22C55E),
              activeTrackColor: const Color(0xFFBBF7D0),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFCBD5E1),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (val) => vm.switchStateOnChange(val, index),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _buildTypeRadioOption('Sensor', condition.type == 'Sensor', () => vm.conTypeOnChange('Sensor', index)),
        const SizedBox(width: 6),
        _buildTypeRadioOption('Program', condition.type == 'Program', () => vm.conTypeOnChange('Program', index)),
        const SizedBox(width: 6),
        _buildTypeRadioOption('Combined', condition.type == 'Combined', () => vm.conTypeOnChange('Combined', index)),
      ],
    );
  }

  Widget _buildTypeRadioOption(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF5B22B6) : const Color(0xFFCBD5E1),
                  width: isSelected ? 4 : 1.5,
                ),
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCol3Component(
    BuildContext context,
    ConditionLibraryViewModel vm,
    Condition condition,
    int index,
  ) {
    Widget valueWidget;
    if (condition.type == 'Combined') {
      valueWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<String>(
            tooltip: 'Select exactly 2 conditions',
            onSelected: (String cName) {
              final selectedCondition = vm.clData.cnLibrary.condition.firstWhere((c) => c.name == cName);
              vm.combinedTO(index, cName, selectedCondition.sNo);
            },
            itemBuilder: (BuildContext ctx) {
              return vm.getAvailableCondition(index).map((String source) {
                return CheckedPopupMenuItem<String>(
                  value: source,
                  height: 32,
                  checked: vm.connectedTo[index].contains(source),
                  child: Text(source, style: const TextStyle(fontSize: 12)),
                );
              }).toList();
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    condition.component.isNotEmpty ? condition.component : '--',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
          if (condition.component != '--')
            IconButton(
              iconSize: 16,
              padding: const EdgeInsets.all(2),
              constraints: const BoxConstraints(),
              tooltip: 'Clear combined',
              onPressed: () => vm.clearCombined(index),
              icon: const Icon(Icons.close, color: Colors.red),
            ),
        ],
      );
    } else {
      valueWidget = PopupMenuButton<ComponentSelection>(
        tooltip: condition.type == 'Sensor' ? 'Select sensor' : 'Select program',
        onSelected: (ComponentSelection selected) {
          vm.componentOnChange(selected.name, index, selected.sNo);
        },
        itemBuilder: (BuildContext ctx) {
          if (condition.type == 'Sensor') {
            return vm.clData.defaultData.sensors.map<PopupMenuEntry<ComponentSelection>>((sensor) {
              return PopupMenuItem<ComponentSelection>(
                value: ComponentSelection(name: sensor.name, sNo: sensor.sNo.toString()),
                height: 32,
                child: Text(sensor.name, style: const TextStyle(fontSize: 12)),
              );
            }).toList();
          } else {
            return vm.clData.defaultData.program.map<PopupMenuEntry<ComponentSelection>>((program) {
              return PopupMenuItem<ComponentSelection>(
                value: ComponentSelection(name: program.name, sNo: program.sNo.toString()),
                height: 32,
                child: Text(program.name, style: const TextStyle(fontSize: 12)),
              );
            }).toList();
          }
        },
        child: Row(
          children: [
            Expanded(
              child: Text(
                condition.component.isNotEmpty ? condition.component : '--',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF94A3B8)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'COMPONENT',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        valueWidget,
      ],
    );
  }

  Widget _buildCol4Parameter(
    BuildContext context,
    ConditionLibraryViewModel vm,
    Condition condition,
    int index,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'PARAMETER',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        PopupMenuButton<String>(
          tooltip: 'Select parameter',
          onSelected: (String selected) => vm.parameterOnChange(selected, index),
          itemBuilder: (BuildContext ctx) {
            if (condition.type == 'Sensor') {
              Sensor? selectedSensor;
              for (final sensor in vm.clData.defaultData.sensors) {
                if (sensor.name == condition.component) {
                  selectedSensor = sensor;
                  break;
                }
              }
              final filtered = vm.clData.defaultData.sensorParameter
                  .where((param) => param.objectId == selectedSensor?.objectId)
                  .toList();
              return filtered.map<PopupMenuEntry<String>>((param) {
                return PopupMenuItem<String>(
                  value: param.parameter,
                  height: 32,
                  child: Text(param.parameter, style: const TextStyle(fontSize: 12)),
                );
              }).toList();
            } else {
              return ['Status'].map((String val) {
                return PopupMenuItem<String>(
                  value: val,
                  height: 32,
                  child: Text(val, style: const TextStyle(fontSize: 12)),
                );
              }).toList();
            }
          },
          child: Row(
            children: [
              Expanded(
                child: Text(
                  condition.parameter.isNotEmpty ? condition.parameter : '--',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCol5ValueThreshold(
    BuildContext context,
    ConditionLibraryViewModel vm,
    Condition condition,
    int index,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'VALUE / THRESHOLD',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Threshold selector
            PopupMenuButton<String>(
              tooltip: 'Select threshold operator',
              onSelected: (String val) => vm.thresholdOnChange(val, index),
              itemBuilder: (BuildContext ctx) {
                final type = condition.type;
                final cSno = condition.componentSNo;
                final options = type == 'Sensor'
                    ? (cSno.toString().startsWith('23.') || cSno.toString().startsWith('40.'))
                        ? ['is']
                        : ['Below', 'Above', 'Equal to']
                    : type == 'Program'
                        ? ['is Running', 'is Starting', 'is Ending']
                        : ['Anyone is', 'Both are'];

                return options.map((String val) {
                  return PopupMenuItem<String>(
                    value: val,
                    height: 32,
                    child: Text(val, style: const TextStyle(fontSize: 12)),
                  );
                }).toList();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    condition.threshold.isNotEmpty ? condition.threshold : '--',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 14, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Value Badge Chip
            _buildValueBadge(context, vm, condition, index),
          ],
        ),
      ],
    );
  }

  Widget _buildValueBadge(
    BuildContext context,
    ConditionLibraryViewModel vm,
    Condition condition,
    int index,
  ) {
    final isSensor = condition.type == 'Sensor';
    final cSNo = condition.componentSNo;
    final isNumericSensor = isSensor &&
        !(cSNo.toString().startsWith('23.') || cSNo.toString().startsWith('40.'));

    final valLower = condition.value.toLowerCase().trim();
    Color bg;
    Color textColor;

    if (valLower == 'true' || valLower == 'high') {
      bg = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF166534);
    } else if (valLower == 'false' || valLower == 'low') {
      bg = const Color(0xFFFEE2E2);
      textColor = const Color(0xFF991B1B);
    } else {
      bg = const Color(0xFFEDE9FE);
      textColor = const Color(0xFF5B22B6);
    }

    if (isNumericSensor) {
      return InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _showSensorValueDialog(context, vm, index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            condition.value.isNotEmpty ? condition.value : '--',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
          ),
        ),
      );
    }

    final options = condition.type == 'Combined'
        ? ['True']
        : (cSNo.toString().startsWith('23.') || cSNo.toString().startsWith('40.'))
            ? ['High', 'Low']
            : ['True', 'False'];

    return PopupMenuButton<String>(
      tooltip: 'Select value',
      onSelected: (val) => vm.valueOnChange(val, index),
      itemBuilder: (ctx) => options.map((opt) {
        return PopupMenuItem<String>(
          value: opt,
          height: 32,
          child: Text(opt, style: const TextStyle(fontSize: 12)),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          condition.value.isNotEmpty ? condition.value : '--',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
        ),
      ),
    );
  }

  void _showSensorValueDialog(BuildContext context, ConditionLibraryViewModel vm, int index) {
    final controller = vm.vtTEVControllers[index];
    controller.text = vm.clData.cnLibrary.condition[index].value.replaceAll(RegExp(r'[^0-9.]'), '');

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Select Value', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Value',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ['7', '8', '9', '4', '5', '6', '1', '2', '3', '0', '.', 'C'].map((k) {
                    return SizedBox(
                      width: 60,
                      height: 38,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: k == 'C' ? Colors.red.shade100 : const Color(0xFFF1F5F9),
                          foregroundColor: k == 'C' ? Colors.red : const Color(0xFF0F172A),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          if (k == 'C') {
                            controller.clear();
                          } else {
                            controller.text += k;
                          }
                        },
                        child: Text(k, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B22B6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final newValue = controller.text.trim();
                if (newValue.isNotEmpty) {
                  Sensor? sensor;
                  for (final s in vm.clData.defaultData.sensors) {
                    if (s.name == vm.clData.cnLibrary.condition[index].component) {
                      sensor = s;
                      break;
                    }
                  }
                  if (sensor != null && sensor.objectName.isNotEmpty) {
                    if (sensor.objectName == 'Level Sensor') {
                      if (newValue.contains('%')) {
                        vm.valueOnChange(newValue, index);
                      } else {
                        vm.valueOnChange('$newValue%', index);
                      }
                    } else {
                      String unit = MyFunction().getUnitValue(context, sensor.objectName, newValue) ?? '';
                      vm.valueOnChange('$newValue $unit'.trim(), index);
                    }
                  } else {
                    vm.valueOnChange(newValue, index);
                  }
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCol6WhereOrReason(
    BuildContext context,
    ConditionLibraryViewModel vm,
    Condition condition,
    int index,
  ) {
    final isProgram = condition.type == 'Program' ||
        condition.component == "Any irrigation program" ||
        condition.component == "Any fertilizer program" ||
        condition.component == "Any Pre(Time/Qty) program";

    final headerText = isProgram ? 'WHERE ?' : 'REASON';

    Widget valueWidget;
    if (isProgram) {
      final irrigationLines = vm.clData.defaultData.irrigationLine;
      valueWidget = PopupMenuButton<String>(
        tooltip: 'Select irrigation line',
        onSelected: (String selected) {
          final line = irrigationLines.firstWhere((l) => l.name == selected);
          vm.updateLineName(selected, line.sNo.toString(), index);
        },
        itemBuilder: (BuildContext ctx) {
          if (irrigationLines.isEmpty) {
            return [
              const PopupMenuItem<String>(
                value: '',
                height: 32,
                child: Text('No lines available', style: TextStyle(fontSize: 12)),
              ),
            ];
          }
          return irrigationLines.map<PopupMenuEntry<String>>((line) {
            return PopupMenuItem<String>(
              value: line.name,
              height: 32,
              child: Text(line.name, style: const TextStyle(fontSize: 12)),
            );
          }).toList();
        },
        child: Row(
          children: [
            Expanded(
              child: Text(
                condition.reason.isNotEmpty ? condition.reason : '--',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF94A3B8)),
          ],
        ),
      );
    } else {
      const reasons = [
        '--',
        'Low flow',
        'High flow',
        'No flow',
        'High pressure',
        'Low pressure',
        'Over heating',
        'Low level',
        'High level',
        'Time limit',
        'Dry run',
      ];

      valueWidget = PopupMenuButton<String>(
        tooltip: 'Select reason',
        onSelected: (String val) => vm.reasonOnChange(val, index),
        itemBuilder: (BuildContext ctx) {
          return reasons.map((String r) {
            return PopupMenuItem<String>(
              value: r,
              height: 32,
              child: Text(r, style: const TextStyle(fontSize: 12)),
            );
          }).toList();
        },
        child: Row(
          children: [
            Expanded(
              child: Text(
                condition.reason.isNotEmpty ? condition.reason : '--',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF94A3B8)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          headerText,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        valueWidget,
      ],
    );
  }

  Widget _buildCol7DelayTime(
    BuildContext context,
    ConditionLibraryViewModel vm,
    Condition condition,
    int index,
  ) {
    const delayTimes = ['--', '3 Sec', '5 Sec', '10 Sec', '20 Sec', '30 Sec'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'DELAY TIME',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        PopupMenuButton<String>(
          tooltip: 'Select delay time',
          onSelected: (String val) => vm.delayTimeOnChange(val, index),
          itemBuilder: (BuildContext ctx) {
            return delayTimes.map((String dt) {
              return PopupMenuItem<String>(
                value: dt,
                height: 32,
                child: Text(dt, style: const TextStyle(fontSize: 12)),
              );
            }).toList();
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                condition.delayTime.isNotEmpty ? condition.delayTime : '--',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
              ),
              const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThreeDotMenu(
    BuildContext context,
    ConditionLibraryViewModel vm,
    Condition condition,
    int index,
  ) {
    return PopupMenuButton<String>(
      tooltip: 'Actions',
      icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF64748B)),
      splashRadius: 18,
      onSelected: (val) {
        if (val == 'edit') {
          _showEditNameDialog(context, vm, index);
        } else if (val == 'delete') {
          _confirmDelete(context, vm, index);
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 16, color: Color(0xFF0F172A)),
              SizedBox(width: 8),
              Text('Edit', style: TextStyle(fontSize: 13, color: Color(0xFF0F172A))),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 16, color: Colors.red),
              SizedBox(width: 8),
              Text('Remove', style: TextStyle(fontSize: 13, color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditNameDialog(BuildContext context, ConditionLibraryViewModel vm, int index) {
    final condition = vm.clData.cnLibrary.condition[index];
    final nameController = TextEditingController(text: condition.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: SizedBox(
          width: 320,
          child: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Condition Name',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B22B6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                vm.updateConditionName(index, newName);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ConditionLibraryViewModel vm, int index) {
    final condition = vm.clData.cnLibrary.condition[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Condition'),
        content: Text('Are you sure you want to remove ${condition.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              vm.removeCondition(index);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ConditionLibraryViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Total: ${vm.clData.cnLibrary.condition.length} of ${vm.clData.defaultData.conditionLimit}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B22B6),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.save_outlined, size: 18, color: Colors.white),
            label: const Text(
              'Save',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            onPressed: () => vm.saveConditionLibrary(
              context,
              widget.customerId,
              widget.controllerId,
              widget.userId,
              widget.deviceId,
            ),
          ),
        ],
      ),
    );
  }
}
