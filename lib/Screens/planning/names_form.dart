import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/names_model.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../utils/snack_bar.dart';
import 'package:hex/utils/helpers/log_print.dart';

// AppConstants import path உங்கள் project-க்கு ஏற்ப சரிபார்க்கவும்.
import 'package:hex/utils/constants.dart';

class Names extends StatefulWidget {
  final int userID;
  final int customerID;
  final int controllerId;
  final int menuId;
  final int modelId;
  final String imeiNo;

  const Names({
    super.key,
    required this.userID,
    required this.customerID,
    required this.controllerId,
    required this.menuId,
    required this.imeiNo,
    required this.modelId,
  });

  @override
  State<Names> createState() => _NamesState();
}

class _NamesState extends State<Names> {
  NamesConfigModel configModel = NamesConfigModel();

  List<String> uniqueObjectNames = [];
  List<TextEditingController> _controllers = [];

  dynamic liveData;
  int selectedCategory = 0;

  // Layout values - change these to adjust spacing quickly.
  static const double _sNoWidth = 64; // S.NO column width (fits "1.001")
  static const double _outerGap = 16; // left/right gap from screen edge
  static const double _innerGap = 8; // padding inside header & row cards

  // Pump models -> Location hidden.
  // Other models -> Location visible.
  bool get showLocation => !AppConstants.pumpList.contains(widget.modelId);

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> getData() async {
    try {
      final Repository repository = Repository(HttpService());

      final response = await repository.getUserConfigMaker({
        "userId": widget.customerID,
        "controllerId": widget.controllerId,
      });

      final jsonData = jsonDecode(response.body);

      if (jsonData['code'] == 200) {
        final newModel = NamesConfigModel.fromJson(jsonData['data']);

        final newCategories = (newModel.configObject ?? [])
            .map((obj) => obj.objectName ?? '')
            .toSet()
            .toList();

        final newControllers = (newModel.configObject ?? [])
            .map((obj) => TextEditingController(text: obj.name ?? ''))
            .toList();

        if (!mounted) {
          for (final controller in newControllers) {
            controller.dispose();
          }
          return;
        }

        setState(() {
          for (final controller in _controllers) {
            controller.dispose();
          }

          configModel = newModel;
          uniqueObjectNames = newCategories;
          _controllers = newControllers;

          if (selectedCategory >= uniqueObjectNames.length) {
            selectedCategory = 0;
          }
        });
      }
    } catch (e, stackTrace) {
      AppLog.log('Error overAll getData => $e');
      AppLog.log('trace overAll getData => $stackTrace');
    }
  }

  IconData _iconForCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('water source')) return Icons.water_drop_outlined;
    if (n.contains('irrigation')) return Icons.linear_scale_rounded;
    if (n.contains('pump')) return Icons.settings_input_component_outlined;
    if (n.contains('valve')) return Icons.compare_arrows_rounded;
    if (n.contains('moisture')) return Icons.opacity_outlined;
    if (n.contains('level')) return Icons.straighten_outlined;
    if (n.contains('float')) return Icons.pin_drop_outlined;
    if (n.contains('filter')) return Icons.filter_alt_outlined;
    if (n.contains('fertilizer')) return Icons.science_outlined;
    return Icons.category_outlined;
  }

  Widget getTabBarViewWidget() {
    final List<String> listOfCategory = uniqueObjectNames;
    final primary = Theme.of(context).primaryColor;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(_outerGap, 12, _outerGap, 4),
      child: Row(
        children: [
          for (int i = 0; i < listOfCategory.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    selectedCategory = i;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selectedCategory == i ? primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedCategory == i
                          ? primary
                          : Colors.grey.shade300,
                      width: 0.8,
                    ),
                    boxShadow: selectedCategory == i
                        ? [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _iconForCategory(listOfCategory[i]),
                        size: 16,
                        color: selectedCategory == i
                            ? Colors.white
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        listOfCategory[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selectedCategory == i
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildTab(int selectedTabIndex) {
    if (selectedTabIndex < 0 || selectedTabIndex >= uniqueObjectNames.length) {
      return const Center(child: Text('No category selected'));
    }

    final filteredData = (configModel.configObject ?? [])
        .where((obj) => obj.objectName == uniqueObjectNames[selectedTabIndex])
        .toList();

    final primary = Theme.of(context).primaryColor;

    return Column(
      children: [
        // Header (white background)
        Container(
          margin: const EdgeInsets.fromLTRB(_outerGap, 12, _outerGap, 8),
          padding: const EdgeInsets.symmetric(
              horizontal: _innerGap, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 0.8),
          ),
          child: Row(
            children: [
              SizedBox(width: _sNoWidth, child: _buildHeaderCell('S.NO')),
              if (showLocation)
                Expanded(flex: 3, child: _buildHeaderCell('LOCATION')),
              Expanded(flex: 4, child: _buildHeaderCell('NAME')),
            ],
          ),
        ),

        // Rows
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(_outerGap, 0, _outerGap, 80),
            itemCount: filteredData.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final data = filteredData[index];
              final int originalIndex =
              (configModel.configObject ?? []).indexOf(data);

              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: _innerGap, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300, width: 0.8),
                ),
                child: Row(
                  children: [
                    // S.No pill
                    SizedBox(
                      width: _sNoWidth,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            data.sNo.toString(),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Location: hide for pump models.
                    if (showLocation)
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            configModel.getNameBySNo(data.location ?? 0.0),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                    // Name box
                    Expanded(
                      flex: 4,
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextFormField(
                          controller: _controllers[originalIndex],
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(15),
                            FilteringTextInputFormatter.allow(
                              RegExp(
                                r'[a-zA-Z0-9\s.!@#$%^&*()_+\-=\[\]{}|;:"<>,.?/`~]',
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() {
                              final bool nameExists =
                              (configModel.configObject ?? []).any(
                                    (element) =>
                                element != data &&
                                    element.name?.trim().toLowerCase() ==
                                        val.trim().toLowerCase() &&
                                    element.objectName == "Valve" &&
                                    element.location == data.location,
                              );

                              if (nameExists) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Name Already Exists'),
                                  ),
                                );
                              } else if (val.length > 15) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                    Text('Name length Maximum reached'),
                                  ),
                                );
                              } else if (val.isNotEmpty) {
                                AppLog.log("val->$val");
                                data.name = val;
                              }
                            });
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isCollapsed: true,
                            contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                            suffixIcon: Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: Colors.grey.shade500,
                            ),
                            suffixIconConstraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (configModel.configObject == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: kIsWeb
          ? null
          : AppBar(
        title: const Text('Names'),
      ),
      body: Column(
        children: [
          getTabBarViewWidget(),
          Expanded(
            child: buildTab(selectedCategory),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColorDark,
        foregroundColor: Colors.white,
        onPressed: () {
          updateAllNames();
          updateUserNames();
        },
        tooltip: 'Send',
        child: const Icon(Icons.send),
      ),
    );
  }

  Future<void> updateUserNames() async {
    final Map<String, dynamic> namesModelData = configModel.toJson();

    final Repository repository = Repository(HttpService());

    AppLog.log(namesModelData['configObject']);

    final Map<String, dynamic> body = {
      "userId": widget.customerID,
      "controllerId": widget.controllerId,
      "configObject": namesModelData['configObject'],
      "waterSource": namesModelData['waterSource'],
      "pump": namesModelData['pump'],
      "filterSite": namesModelData['filterSite'],
      "fertilizerSite": namesModelData['fertilizerSite'],
      "irrigationLine": namesModelData['irrigationLine'],
      "moistureSensor": namesModelData['moistureSensor'],
      "createUser": widget.userID,
    };

    AppLog.log('body:-$body');

    final response = await repository.updateUserNames(body);

    final jsonDataResponsePut = jsonDecode(response.body);

    if (!mounted) return;

    GlobalSnackBar.show(
      context,
      jsonDataResponsePut['message'],
      jsonDataResponsePut['code'],
    );
  }

  void updateAllNames() {
    final Map<double, String> configNames = {};

    for (final obj in configModel.configObject ?? []) {
      if (obj.sNo != null && obj.name != null) {
        configNames[obj.sNo!] = obj.name!;
      }
    }

    for (final src in configModel.waterSource ?? []) {
      if (configNames.containsKey(src.commonDetails?.sNo)) {
        src.commonDetails?.name = configNames[src.commonDetails!.sNo];
      }
    }

    for (final pump in configModel.pump ?? []) {
      if (configNames.containsKey(pump.commonDetails?.sNo)) {
        pump.commonDetails?.name = configNames[pump.commonDetails!.sNo];
      }
    }

    for (final filterSite in configModel.filterSite ?? []) {
      if (configNames.containsKey(filterSite.commonDetails?.sNo)) {
        filterSite.commonDetails?.name =
        configNames[filterSite.commonDetails!.sNo];
      }
    }

    for (final fertSite in configModel.fertilizerSite ?? []) {
      if (configNames.containsKey(fertSite.commonDetails?.sNo)) {
        fertSite.commonDetails?.name =
        configNames[fertSite.commonDetails!.sNo];
      }
    }

    for (final moisture in configModel.moistureSensor ?? []) {
      if (configNames.containsKey(moisture.commonDetails?.sNo)) {
        moisture.commonDetails?.name =
        configNames[moisture.commonDetails!.sNo];
      }
    }

    for (final line in configModel.irrigationLine ?? []) {
      if (configNames.containsKey(line.commonDetails?.sNo)) {
        line.commonDetails?.name = configNames[line.commonDetails!.sNo];
      }
    }

    setState(() {});
  }
}
