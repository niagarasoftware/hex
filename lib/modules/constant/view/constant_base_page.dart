import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hex/modules/constant/repository/constant_repository.dart';
import 'package:hex/modules/constant/state_management/constant_provider.dart';
import 'package:hex/modules/constant/view/ec_ph_in_constant.dart';
import 'package:hex/modules/constant/view/fertilizer_site_in_constant.dart';
import 'package:hex/modules/constant/view/global_alarm_in_constant.dart';
import 'package:hex/modules/constant/view/main_valve_in_constant.dart';
import 'package:hex/modules/constant/view/common_alarm_in_constant.dart';
import 'package:hex/modules/constant/view/normal_critical_alarm_in_constant.dart';
import 'package:hex/modules/constant/view/pump_in_constant.dart';
import 'package:hex/modules/constant/view/valve_in_constant.dart';
import 'package:hex/modules/constant/view/water_meter_in_constant.dart';
import 'package:hex/modules/constant/widget/arrow_tab.dart';
import 'package:hex/utils/constants.dart';
import 'package:provider/provider.dart';

import '../../../StateManagement/overall_use.dart';
import '../../SystemDefinitions/widgets/custom_snack_bar.dart';
import 'package:hex/modules/IrrigationProgram/view/program_library.dart';
import 'package:hex/utils/environment.dart';
import 'package:hex/utils/helpers/log_print.dart';
import 'channel_in_constant.dart';
import 'filter_in_constant.dart';
import 'filter_site_in_constant.dart';
import 'general_in_constant.dart';
import 'level_in_constant.dart';
import 'moisture_in_constant.dart';

class ConstantBasePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ConstantBasePage({super.key, required this.userData});

  @override
  State<ConstantBasePage> createState() => _ConstantBasePageState();
}

class _ConstantBasePageState extends State<ConstantBasePage>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  late Future<int> constantResponse;
  late ConstantProvider constPvd;
  late OverAllUse overAllPvd;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    debugPrint("userData : ${widget.userData}");
    constPvd = Provider.of<ConstantProvider>(context, listen: false);
    overAllPvd = Provider.of<OverAllUse>(context, listen: false);
    constantResponse = getData(widget.userData);
  }

  Future<int> getData(userData) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      var body = {
        "userId": userData['customerId'],
        "controllerId": userData['controllerId'],
      };
      var constantResponse = await ConstantRepository().getUserConstant(body);
      Map<String, dynamic> constantJsonData =
      jsonDecode(constantResponse.body);
      var configMakerResponse =
      await ConstantRepository().getUserDefaultConfigMaker(body);
      Map<String, dynamic> configMakerJsonData =
      jsonDecode(configMakerResponse.body);
      constPvd.updateConstant(
          constantData: constantJsonData,
          configMakerData: configMakerJsonData,
          userDataAndMasterData: userData);
      setState(() {
        tabController = TabController(
            length: constPvd.listOfConstantMenuModel.length, vsync: this);
        tabController.addListener(() {
          if (!tabController.indexIsChanging) {
            setState(() {});
          }
        });
      });
      return constantJsonData['code'];
    } catch (e, stacktrace) {
      debugPrint('Error on getting constant data :: $e');
      debugPrint('Stacktrace on getting constant data :: $stacktrace');
      rethrow;
    }
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    constPvd = Provider.of<ConstantProvider>(context, listen: true);
    overAllPvd = Provider.of<OverAllUse>(context, listen: true);
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<int>(
        future: constantResponse,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: colorScheme.surfaceContainerLowest,
              body: const Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: colorScheme.surfaceContainerLowest,
              body: Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            );
          } else if (snapshot.hasData) {
            return Scaffold(
              backgroundColor: colorScheme.surfaceContainerLowest,
              appBar: MediaQuery.of(context).size.width < 500
                  ? AppBar(
                title: const Text(
                  'Constant Settings',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                backgroundColor: colorScheme.surface,
                foregroundColor: colorScheme.onSurface,
                elevation: 0,
              )
                  : null,
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    children: [
                      _buildStepNavigationBar(context),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _buildMainContentPanel(context),
                      ),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: _buildBottomNavigationBar(context),
            );
          } else {
            return Scaffold(
              backgroundColor: colorScheme.surfaceContainerLowest,
              body: const Center(child: Text('No data')),
            );
          }
        });
  }

  void updateTabs(int index) {
    constPvd.listOfConstantMenuModel[index].arrowTabState.value =
        ArrowTabState.onProgress;
    for (var i = 0; i < index; i++) {
      constPvd.listOfConstantMenuModel[i].arrowTabState.value =
          ArrowTabState.complete;
    }
    for (var i = constPvd.listOfConstantMenuModel.length - 1;
    i > index;
    i--) {
      constPvd.listOfConstantMenuModel[i].arrowTabState.value =
          ArrowTabState.inComplete;
    }
    setState(() {
      tabController.animateTo(index);
    });
  }

  Widget _buildStepNavigationBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final menuList = constPvd.listOfConstantMenuModel;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(menuList.length, (index) {
            final isSelected = tabController.index == index;
            final stepNumber = "${index + 1}";
            final title = menuList[index].parameter;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                onTap: () {
                  updateTabs(index);
                },
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                    isSelected ? colorScheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected
                            ? colorScheme.secondary
                            : Colors.transparent,
                        width: 4.0,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.primaryContainer,
                        ),
                        child: Center(
                          child: Text(
                            stepNumber,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  String? _getCategoryDescription(String title) {
    final t = title.toLowerCase();
    if (t.contains('general')) {
      return 'Configure global controller properties, unit modes, and default system timeouts.';
    }
    if (t.contains('pump')) {
      return 'Configure pump connections, location assignments, flow rates, and operating limits.';
    }
    if (t.contains('filter site') || t.contains('filter')) {
      return 'Set up backwash durations, flushing intervals, and pressure differential thresholds.';
    }
    if (t.contains('main valve') || t.contains('valve')) {
      return 'Configure valve output assignments, response times, and maximum open limits.';
    }
    if (t.contains('fertilizer') ||
        t.contains('channel') ||
        t.contains('ec') ||
        t.contains('ph')) {
      return 'Set up dosing channels, injection ratios, EC/pH target ranges, and safety cutoffs.';
    }
    if (t.contains('moisture') ||
        t.contains('level') ||
        t.contains('water meter')) {
      return 'Configure sensor telemetry, pulse multipliers, and cutoff thresholds.';
    }
    if (t.contains('alarm')) {
      return 'Set up normal and critical alarm triggers, scan times, and reset behaviors.';
    }
    return 'Configure operational parameters and system constants.';
  }

  Widget _buildMainContentPanel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentMenuIndex =
    tabController.index.clamp(0, constPvd.listOfConstantMenuModel.length - 1);
    final currentTitle =
        constPvd.listOfConstantMenuModel[currentMenuIndex].parameter;
    final currentDesc = _getCategoryDescription(currentTitle);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          if (currentDesc != null) ...[
            const SizedBox(height: 4),
            Text(
              currentDesc,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Divider(
            height: 1,
            thickness: 0.5,
            color: colorScheme.outlineVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: getTabBarView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFirstTab = tabController.index == 0;
    final isLastTab =
        tabController.index == constPvd.listOfConstantMenuModel.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.4),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (!isFirstTab)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      updateTabs(tabController.index - 1);
                    });
                  },
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text("Back"),
                )
              else
                const SizedBox.shrink(),
            ],
          ),
          Row(
            children: [
              if (!isLastTab) ...[
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      updateTabs(tabController.index + 1);
                    });
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text("Next"),
                ),
                const SizedBox(width: 12),
              ],
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isSaving ? null : () => _handleSaveConstant(context),
                icon: _isSaving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(
                  _isSaving ? "Saving..." : "Save Constant",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleSaveConstant(BuildContext context) async {
    if (_isSaving) {
      AppLog.log("Save Constant click ignored: Save operation already in progress.");
      return;
    }

    final controllerId = widget.userData['controllerId'];
    final customerId = widget.userData['customerId'];
    final deviceId = (widget.userData['deviceId'] ?? widget.userData['imeiNo'] ?? '').toString();

    AppLog.log("Save Constant button clicked for customer: $customerId, controller: $controllerId, device: $deviceId");

    setState(() {
      _isSaving = true;
    });

    try {
      final hardwarePayload = constPvd.getConstantHardwarePayload();
      AppLog.log("Generated Constant Hardware Payload (Code 300): $hardwarePayload");

      var body = {
        "userId": customerId,
        "controllerId": controllerId,
        "general": constPvd.general.map((setting) => setting.toJson()).toList(),
        "waterSource": [],
        "levelSensor": constPvd.level.map((setting) => setting.toJson()).toList(),
        "pump": constPvd.pump.map((setting) => setting.toJson()).toList(),
        "filterSite": constPvd.filterSite.map((setting) => setting.toJson()).toList(),
        "filter": constPvd.filter.map((setting) => setting.toJson()).toList(),
        "fertilizerSite": constPvd.fertilizerSite.map((setting) => setting.toJson()).toList(),
        "fertilizerChannel": constPvd.channel.map((setting) => setting.toJson()).toList(),
        "ecPhSensor": constPvd.ecPhSensor.map((setting) => setting.toJson()).toList(),
        "waterMeter": constPvd.waterMeter.map((setting) => setting.toJson()).toList(),
        "pressureSensor": [],
        "mainValve": constPvd.mainValve.map((setting) => setting.toJson()).toList(),
        "valve": constPvd.valve.map((setting) => setting.toJson()).toList(),
        "moistureSensor": constPvd.moisture.map((setting) => setting.toJson()).toList(),
        "analogSensor": [],
        "normalCriticalAlarm": constPvd.normalCriticalAlarm.map((setting) => setting.toJson()).toList(),
        "commonAlarm": constPvd.commonAlarm.map((setting) => setting.toJson()).toList(),
        "globalAlarm": constPvd.globalAlarm.map((setting) => setting.toJson()).toList(),
        "hardware": hardwarePayload,
        "controllerReadStatus": "0",
        "createUser": widget.userData['userId'] ?? customerId,
      };

      AppLog.log("Sending Constant Settings API request to ConstantRepository...");
      var response = await ConstantRepository().createUserConstant(body);
      AppLog.log("Constant Settings API response code: ${response.statusCode}, body: ${response.body}");

      if (response.statusCode != 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            CustomSnackBar(
              message: "Failed to save constant settings to server. Please try again.",
              color: Colors.red.shade700,
            ),
          );
        }
        return;
      }

      AppLog.log("MQTT Publish Topic: ${Environment.mqttPublishTopic}/$deviceId");

      await validatePayloadSent(
        dialogContext: context,
        context: context,
        payload: hardwarePayload,
        payloadCode: "300",
        deviceId: deviceId,
        acknowledgedFunction: () {
          AppLog.log("Constant Settings Hardware Acknowledgement received successfully!");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              CustomSnackBar(
                message: "Constant settings saved and sent to hardware successfully!",
                color: Colors.green.shade700,
              ),
            );
          }
        },
        failedFunction: () {
          AppLog.log("Constant Settings Hardware Acknowledgement failed or timed out.");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              CustomSnackBar(
                message: "Hardware confirmation failed or timed out. Please retry.",
                color: Colors.red.shade700,
              ),
            );
          }
        },
      );
    } catch (error, stackTrace) {
      AppLog.log("Exception in Constant Settings save: $error\n$stackTrace");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar(
            message: "Failed to save settings due to: $error",
            color: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  List<Widget> getTabBarView() {
    return List.generate(tabController.length, (index) {
      final menuId = constPvd.listOfConstantMenuModel[index].dealerDefinitionId;

      if (menuId == AppConstants.generalInConstant) {
        return GeneralInConstant(constPvd: constPvd, overAllPvd: overAllPvd);
      } else if (menuId == AppConstants.pumpInConstant) {
        return PumpInConstant(constPvd: constPvd, overAllPvd: overAllPvd);
      } else if (menuId == AppConstants.filterSiteInConstant) {
        return FilterSiteInConstant(constPvd: constPvd, overAllPvd: overAllPvd);
      } else if (menuId == AppConstants.filterInConstant) {
        return FilterInConstant(constPvd: constPvd, overAllPvd: overAllPvd);
      } else if (menuId == AppConstants.mainValveInConstant) {
        return MainValveInConstant(constPvd: constPvd, overAllPvd: overAllPvd);
      } else if (menuId == AppConstants.valveInConstant) {
        return ValveInConstant(constPvd: constPvd, overAllPvd: overAllPvd);
      } else if (menuId == AppConstants.waterMeterInConstant) {
        return WaterMeterInConstant(
            constPvd: constPvd, overAllPvd: overAllPvd);
      } else if (menuId == AppConstants.fertilizerSiteInConstant) {
        return FertilizerSiteInConstant(
            constPvd: constPvd, overAllPvd: overAllPvd);
      } else if (menuId == AppConstants.fertilizerChannelInConstant) {
        return ChannelInConstant(constPvd: constPvd, overAllPvd: overAllPvd);
      } else if (menuId == AppConstants.ecPhInConstant) {
        return EcPhInConstant(constPvd: constPvd, overAllPvd: overAllPvd);
      } else if (menuId == AppConstants.moistureSensorInConstant) {
        return MoistureInConstant(constPvd: constPvd, overAllPvd: overAllPvd);
      } else if (menuId == AppConstants.levelSensorInConstant) {
        return LevelInConstant(constPvd: constPvd, overAllPvd: overAllPvd);
      } else if (menuId == AppConstants.normalCriticalInConstant) {
        return NormalCriticalInConstant(
            constPvd: constPvd, overAllPvd: overAllPvd);
      } else if (menuId == AppConstants.commonAlarmInConstant) {
        return CommonAlarmInConstant(
            constPvd: constPvd, overAllPvd: overAllPvd);
      } else if (menuId == AppConstants.globalAlarmInConstant) {
        return GlobalAlarmInConstant(
          constPvd: constPvd,
          overAllPvd: overAllPvd,
          userData: widget.userData,
        );
      } else {
        return Center(
          child: Text(constPvd.listOfConstantMenuModel[index].parameter),
        );
      }
    });
  }

  Widget getTabs() {
    return _buildStepNavigationBar(context);
  }
}
