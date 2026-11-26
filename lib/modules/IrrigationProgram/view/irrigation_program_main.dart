import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hex/modules/IrrigationProgram/view/preview_screen.dart';
import 'package:hex/modules/IrrigationProgram/view/schedule_screen.dart';
import 'package:hex/modules/IrrigationProgram/view/selection_screen.dart';
import 'package:hex/modules/IrrigationProgram/view/sequence_screen.dart';
import 'package:hex/modules/IrrigationProgram/view/water_and_fertilizer_screen.dart';
import 'package:hex/utils/Theme/oro_theme.dart';
import 'package:provider/provider.dart';
import '../../../models/customer/site_model.dart';
import '../../../utils/constants.dart';
import '../state_management/irrigation_program_provider.dart';
import '../../../StateManagement/mqtt_payload_provider.dart';
import '../widgets/custom_alert_dialog.dart';
import 'alarm_screen.dart';
import 'conditions_screen.dart';
import 'done_screen.dart';

class IrrigationProgram extends StatefulWidget {
  final int userId;
  final int customerId;
  final int groupId;
  final int categoryId;
  final int controllerId;
  final String deviceId;
  final int serialNumber;
  final String? programType;
  final bool fromDealer;
  final bool toDashboard;
  final int modelId;
  final String deviceName;
  final String categoryName;
  final List<NodeListModel> nodeList;

  const IrrigationProgram({
    Key? irrigationProgramKey,
    required this.userId,
    required this.controllerId,
    required this.serialNumber,
    this.programType,
    required this.deviceId,
    required this.fromDealer,
    required this.groupId,
    required this.categoryId,
    this.toDashboard = false,
    required this.customerId,
    required this.modelId,
    required this.deviceName,
    required this.categoryName,
    required this.nodeList,
  }) : super(key: irrigationProgramKey);

  @override
  State<IrrigationProgram> createState() => _IrrigationProgramState();
}

class _IrrigationProgramState extends State<IrrigationProgram> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<String> labels;
  late List<IconData> icons;
  late MqttPayloadProvider mqttPayloadProvider;
  bool _isDialogShowing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final irrigationProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: false);
    
    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: false);

    final result = irrigationProvider.getLabelAndIcon(
      sno: widget.serialNumber,
      programType: widget.programType,
      conditionLibrary: irrigationProvider.conditionsLibraryIsNotEmpty,
    );
    labels = result.labels;
    icons = result.icons;

    _tabController = TabController(length: labels.length, vsync: this);
    _tabController.addListener(() {
      irrigationProvider.updateTabIndex(_tabController.index);
    });

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchData();
      });
    }
  }

  void _showLoadingDialog() {
    if (_isDialogShowing) return;
    _isDialogShowing = true;
    showAdaptiveDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Loading program data...", style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(height: 8),
              Text("Please wait while we sync your settings", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  void _hideLoadingDialog() {
    if (_isDialogShowing) {
      Navigator.of(context, rootNavigator: true).pop();
      _isDialogShowing = false;
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _errorMessage = null;
    });

    _showLoadingDialog();

    try {
      final irrigationProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: false);
      irrigationProvider.updateTabIndex(0);

      // Fetch sequence data first as other data might depend on it
      await irrigationProvider.getUserProgramSequence(
        userId: widget.customerId,
        controllerId: widget.controllerId,
        serialNumber: widget.serialNumber,
        groupId: widget.groupId,
        categoryId: widget.categoryId,
        modelId: widget.modelId,
      );

      // Fetch other data in parallel
      await Future.wait([
        irrigationProvider.doneData(widget.customerId, widget.controllerId, widget.serialNumber),
        irrigationProvider.scheduleData(widget.customerId, widget.controllerId, widget.serialNumber),
        irrigationProvider.getUserProgramCondition(widget.customerId, widget.controllerId, widget.serialNumber),
        irrigationProvider.getWaterAndFertData(
          userId: widget.customerId,
          controllerId: widget.controllerId,
          serialNumber: widget.serialNumber,
        ),
        irrigationProvider.getUserProgramSelection(widget.customerId, widget.controllerId, widget.serialNumber),
        irrigationProvider.getUserProgramAlarm(widget.customerId, widget.controllerId, widget.serialNumber),
      ]);

      if (mounted) {
        final result = irrigationProvider.getLabelAndIcon(
          sno: widget.serialNumber,
          programType: widget.programType,
          conditionLibrary: irrigationProvider.conditionsLibraryIsNotEmpty,
        );
        setState(() {
          labels = result.labels;
          icons = result.icons;
          if (_tabController.length != labels.length) {
            final oldIndex = _tabController.index;
            _tabController.dispose();
            _tabController = TabController(
              length: labels.length,
              vsync: this,
              initialIndex: oldIndex < labels.length ? oldIndex : 0,
            );
            _tabController.addListener(() {
              irrigationProvider.updateTabIndex(_tabController.index);
            });
          }
        });
        _hideLoadingDialog();
      }
    } catch (e, stackTrace) {
      debugPrint("Error fetching irrigation program data: $e");
      debugPrint(stackTrace.toString());
      if (mounted) {
        _hideLoadingDialog();
        setState(() {
          _errorMessage = "Failed to load irrigation program data: $e";
        });
        _showErrorDialog();
      }
    }
  }

  void _showErrorDialog() {
    showAdaptiveDialog(
      context: context,
      builder: (context) => CustomAlertDialog(
        title: "Error",
        content: "Some data failed to load. Would you like to try again or go back?",
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _fetchData();
            },
            child: const Text("Try Again"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text("Go Back", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToTab(int tabIndex) {
    if (_tabController.index != tabIndex) {
      _tabController.animateTo(tabIndex);
    }
  }

  void _navigateToNextTab() {
    _tabController.animateTo((_tabController.index + 1) % _tabController.length);
  }

  void _navigateToPreviousTab() {
    _tabController.animateTo((_tabController.index - 1 + _tabController.length) % _tabController.length);
  }

  bool _validateBeforeGoingTo(int targetIndex, IrrigationProgramMainProvider mainProvider) {
    if (widget.programType != "Irrigation Program") {
      return true;
    }

    final threshold = labels.length == 7 ? 2 : 3;
    if (targetIndex <= threshold) {
      return true;
    }

    if (!mainProvider.selectedObjects!.any((element) => element.objectId == 2)) {
      _showValidationAlert(content: "Please select at least one head unit!");
      return false;
    }

    if (!mainProvider.isPumpStationMode && mainProvider.pump!.isNotEmpty && !mainProvider.selectedObjects!.any((element) => element.objectId == 5) && !AppConstants.ecoGemFlowControlValveModel.contains(widget.modelId)) {
      if (!mainProvider.ignoreValidation) {
        _showValidationAlert(
          content: "Are you sure to proceed without pump selection?",
          showConfirm: true,
          onConfirm: () {
            mainProvider.ignoreValidation = true;
            _navigateToTab(targetIndex);
          },
          targetIndex: targetIndex,
        );
        return false;
      }
      return true;
    }

    if (mainProvider.isPumpStationMode) {
      final result = mainProvider.calculateTotalFlowRate();
      if (result['sequenceData'].isNotEmpty) {
        _showFlowRateWarning(result);
        return false;
      }
    }

    return true;
  }

  void _showValidationAlert({
    required String content,
    bool showConfirm = false,
    VoidCallback? onConfirm,
    int? targetIndex,
  }) {
    showAdaptiveDialog(
      context: context,
      builder: (context) => CustomAlertDialog(
        title: "Warning",
        content: content,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (showConfirm && onConfirm != null && targetIndex != null) {
                onConfirm();
              }
            },
            child: Text(showConfirm ? "Yes" : "OK"),
          ),
          if (showConfirm)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("No", style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  void _showFlowRateWarning(Map<String, dynamic> validationData) {
    final mainProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            Text("Warning!", style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Pump station range is not sufficient for zone's valve flow rate!",
              style: TextStyle(fontWeight: FontWeight.w300, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pump station range', style: TextStyle(color: Colors.black)),
                const SizedBox(width: 20),
                Text(
                  '${validationData['pumpFlowRate']} L/hr',
                  style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for(var seq in validationData['sequenceData'])
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${seq['name']}', style: const TextStyle(color: Colors.black)),
                  const SizedBox(width: 20),
                  Text(
                    '${seq['flowrate']} L/hr',
                    style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _handleTabNavigation(int targetIndex) {
    final mainProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: false);
    if (_tabController.index == 0 && mainProvider.irrigationLine!.sequence.any((element) => element['valve'].isEmpty)) {
      _showSequenceWarning(mainProvider);
    } else if (_validateBeforeGoingTo(targetIndex, mainProvider)) {
      _navigateToTab(targetIndex);
    }
  }

  void _showSequenceWarning(IrrigationProgramMainProvider mainProvider) {
    final indexWhereEmpty = mainProvider.irrigationLine!.sequence.indexWhere((element) => element['valve'].isEmpty);
    showAdaptiveDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Warning!'),
        content: RichText(
          text: TextSpan(
            children: [
              const TextSpan(text: 'There is no valve configured at ', style: TextStyle(color: Colors.black)),
              TextSpan(
                text: '${mainProvider.irrigationLine!.sequence[indexWhereEmpty]['name']}',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    final mainProvider = Provider.of<IrrigationProgramMainProvider>(context);
    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: true);

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Error"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _fetchData,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Try Again"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (mainProvider.irrigationLine != null && mainProvider.programDetails != null) {
      final isIrrigationProgram = (mainProvider.programDetails!.programType == "Irrigation Program") ||
          (mainProvider.selectedProgramType == "Irrigation Program");

      final programName = widget.serialNumber == 0
          ? "New Program"
          : mainProvider.programDetails!.programName.isNotEmpty
          ? (mainProvider.programName == '' ? "Program ${mainProvider.programCount + 1}" : mainProvider.programName)
          : mainProvider.programDetails!.defaultProgramName;

      final sequenceLength = mainProvider.irrigationLine?.sequence.length ?? 0;
      final priority = mainProvider.programDetails?.priority ?? "Low";

      return DefaultTabController(
        length: labels.length,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: Colors.white,
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        mainProvider.programLibraryData(widget.customerId, widget.controllerId);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, size: 18, color: Color(0xFF1E293B)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: primaryPurple,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.water_drop, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            programName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            '$sequenceLength Segments · Priority: $priority',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Program settings saved")),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      icon: const Icon(Icons.save_outlined, size: 16, color: Colors.white),
                      label: const Text(
                        "Save Program",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Horizontal Stepper Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(labels.length, (i) {
                      final isSelected = _tabController.index == i;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InkWell(
                          onTap: () => _handleTabNavigation(i),
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryPurple : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  labels[i],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? Colors.white : const Color(0xFF475569),
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
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Step SubHeader
              _buildStepSubHeader(mainProvider.selectedTabIndex, labels[mainProvider.selectedTabIndex], labels.length),

              // Tab View Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (int i = 0; i < labels.length; i++)
                      _buildTabContent(
                        index: i,
                        isIrrigationProgram: isIrrigationProgram,
                        conditionsLibraryIsNotEmpty: (mainProvider.conditionsLibraryIsNotEmpty),
                      ),
                  ],
                ),
              ),

              // Bottom Navigation Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (mainProvider.selectedTabIndex > 0)
                      TextButton.icon(
                        onPressed: _navigateToPreviousTab,
                        icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF475569)),
                        label: const Text(
                          "Previous Step",
                          style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      )
                    else
                      const SizedBox(width: 110),

                    // Pagination Dots
                    Row(
                      children: List.generate(labels.length, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == mainProvider.selectedTabIndex ? 20 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: i == mainProvider.selectedTabIndex ? primaryPurple : const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),

                    if (mainProvider.selectedTabIndex < labels.length - 1)
                      FilledButton.icon(
                        onPressed: () {
                          final nextIndex = _tabController.index + 1;
                          final mainProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: false);
                          if (_tabController.index == 0 &&
                              mainProvider.irrigationLine!.sequence.any((element) => element['valve'].isEmpty)) {
                            _showSequenceWarning(mainProvider);
                          } else if (_validateBeforeGoingTo(nextIndex, mainProvider)) {
                            _navigateToNextTab();
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryPurple,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        ),
                        label: const Text(
                          "Next Step",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        icon: const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                      )
                    else
                      const SizedBox(width: 110),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final title = widget.serialNumber == 0 ? "New Program" : "Program ${widget.serialNumber}";
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        body: Container(
          color: Colors.grey[50],
        ),
      );
    }
  }

  Widget _buildStepSubHeader(int currentIndex, String label, int totalCount) {
    final progress = (((currentIndex + 1) / totalCount) * 100).toInt();
    String getStepDescription(String stepName) {
      switch (stepName) {
        case 'Sequence':
          return 'Configure Segments, plots, and valve distribution';
        case 'Schedule':
          return 'Select execution strategy: No Planning Method, By Days, By Run List, or By Program';
        case 'Conditions':
          return 'Set sensor triggers that allow or stop a run';
        case 'Selection':
          return 'Configure hardware and line selection settings';
        case 'Water & Fert':
          return 'Configure irrigation and fertigation parameters';
        case 'Alarm':
          return 'Set notification triggers and system alerts';
        default:
          return 'Configure program settings and parameters';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      color: primaryBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STEP ${currentIndex + 1} OF $totalCount · ${label.toUpperCase()}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: primaryPurple,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                'Progress: $progress%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            getStepDescription(label),
            style: TextStyle(
              fontSize: 12,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  /*Widget _buildTabContent({required int index, required bool isIrrigationProgram, required bool conditionsLibraryIsNotEmpty}) {
    switch (index) {
      case 0:
        return SequenceScreen(userId: overAllPvd.takeSharedUserId ? overAllPvd.sharedUserId : overAllPvd.userId, controllerId: widget.controllerId, serialNumber: widget.serialNumber);
      case 1:
        return ScheduleScreen(serialNumber: widget.serialNumber,);
      case 2:
        return isIrrigationProgram
            ? conditionsLibraryIsNotEmpty
            ? ConditionsScreen(userId: overAllPvd.takeSharedUserId ? overAllPvd.sharedUserId : overAllPvd.userId, controllerId: widget.controllerId, serialNumber: widget.serialNumber, deviceId: widget.deviceId,)
            : const SelectionScreen()
            : WaterAndFertilizerScreen(userId: overAllPvd.takeSharedUserId ? overAllPvd.sharedUserId : overAllPvd.userId, controllerId: widget.controllerId, serialNumber: widget.serialNumber, isIrrigationProgram: isIrrigationProgram,);
      case 3:
        return isIrrigationProgram
            ? conditionsLibraryIsNotEmpty
            ? const SelectionScreen()
            : WaterAndFertilizerScreen(userId: overAllPvd.takeSharedUserId ? overAllPvd.sharedUserId : overAllPvd.userId, controllerId: widget.controllerId, serialNumber: widget.serialNumber, isIrrigationProgram: isIrrigationProgram,)
            : const NewAlarmScreen2();
      case 4:
        return isIrrigationProgram
            ? conditionsLibraryIsNotEmpty
            ? WaterAndFertilizerScreen(userId: overAllPvd.takeSharedUserId ? overAllPvd.sharedUserId : overAllPvd.userId, controllerId: widget.controllerId, serialNumber: widget.serialNumber, isIrrigationProgram: isIrrigationProgram,)
            : const NewAlarmScreen2()
            : AdditionalDataScreen(userId: overAllPvd.takeSharedUserId ? overAllPvd.sharedUserId : overAllPvd.userId, controllerId: widget.controllerId, deviceId: widget.deviceId, serialNumber: widget.serialNumber, toDashboard: widget.toDashboard, fromDealer: widget.fromDealer, programType: widget.programType, conditionsLibraryIsNotEmpty: widget.conditionsLibraryIsNotEmpty, isIrrigationProgram: isIrrigationProgram,);
      case 5:
        return isIrrigationProgram
            ? conditionsLibraryIsNotEmpty
            ? const NewAlarmScreen2()
            : AdditionalDataScreen(userId: overAllPvd.takeSharedUserId ? overAllPvd.sharedUserId : overAllPvd.userId, controllerId: widget.controllerId, deviceId: widget.deviceId, serialNumber: widget.serialNumber, toDashboard: widget.toDashboard, fromDealer: widget.fromDealer, programType: widget.programType, conditionsLibraryIsNotEmpty: widget.conditionsLibraryIsNotEmpty, isIrrigationProgram: isIrrigationProgram,)
            : PreviewScreen(userId: overAllPvd.takeSharedUserId ? overAllPvd.sharedUserId : overAllPvd.userId, controllerId: widget.controllerId, deviceId: widget.deviceId, serialNumber: widget.serialNumber, toDashboard: widget.toDashboard, fromDealer: widget.fromDealer, programType: widget.programType, conditionsLibraryIsNotEmpty: widget.conditionsLibraryIsNotEmpty,);
      case 6:
        return conditionsLibraryIsNotEmpty
            ? AdditionalDataScreen(userId: overAllPvd.userId, controllerId: widget.controllerId, deviceId: widget.deviceId, serialNumber: widget.serialNumber, toDashboard: widget.toDashboard, fromDealer: widget.fromDealer, programType: widget.programType, conditionsLibraryIsNotEmpty: widget.conditionsLibraryIsNotEmpty, isIrrigationProgram: isIrrigationProgram,)
            : PreviewScreen(userId: overAllPvd.takeSharedUserId ? overAllPvd.sharedUserId : overAllPvd.userId, controllerId: widget.controllerId, deviceId: widget.deviceId, serialNumber: widget.serialNumber, toDashboard: widget.toDashboard, fromDealer: widget.fromDealer, programType: widget.programType, conditionsLibraryIsNotEmpty: widget.conditionsLibraryIsNotEmpty,);
      case 7:
        return conditionsLibraryIsNotEmpty
            ? PreviewScreen(userId: overAllPvd.takeSharedUserId ? overAllPvd.sharedUserId : overAllPvd.userId, controllerId: widget.controllerId, deviceId: widget.deviceId, serialNumber: widget.serialNumber, toDashboard: widget.toDashboard, fromDealer: widget.fromDealer, programType: widget.programType, conditionsLibraryIsNotEmpty: widget.conditionsLibraryIsNotEmpty,)
            : Container();
      default:
        return Container();
    }
  }
}*/

  Widget _buildTabContent({
    required int index,
    required bool isIrrigationProgram,
    required bool conditionsLibraryIsNotEmpty,
  }) {
    if (index < 0 || index >= labels.length) {
      return const SizedBox();
    }

    final label = labels[index];

    switch (label) {
      case 'Sequence':
        return SequenceScreen(
          userId: widget.customerId,
          controllerId: widget.controllerId,
          serialNumber: widget.serialNumber,
          deviceId: widget.deviceId,
          modelId: widget.modelId,
        );
      case 'Schedule':
        return ScheduleScreen(
          serialNumber: widget.serialNumber,
          modelId: widget.modelId,
        );
      case 'Conditions':
        return ConditionsScreen(
          userId: widget.userId,
          controllerId: widget.controllerId,
          serialNumber: widget.serialNumber,
          deviceId: widget.deviceId,
          customerId: widget.customerId,
        );
      case 'Selection':
        return SelectionScreen(
          modelId: widget.modelId,
          nodeList: widget.nodeList,
        );
      case 'Water & Fert':
      case 'Settings':
        return WaterAndFertilizerScreen(
          userId: widget.customerId,
          controllerId: widget.controllerId,
          serialNumber: widget.serialNumber,
          isIrrigationProgram: isIrrigationProgram,
          modelId: widget.modelId,
        );
      case 'Alarm':
        return AlarmScreen(
          modelId: widget.modelId,
        );
      case 'Additional':
        return AdditionalDataScreen(
          userId: widget.userId,
          controllerId: widget.controllerId,
          deviceId: widget.deviceId,
          serialNumber: widget.serialNumber,
          toDashboard: widget.toDashboard,
          fromDealer: widget.fromDealer,
          programType: widget.programType,
          isIrrigationProgram: isIrrigationProgram,
          customerId: widget.customerId,
          groupId: widget.groupId,
          categoryId: widget.categoryId,
          modelId: widget.modelId,
          deviceName: widget.deviceName,
          categoryName: widget.categoryName,
        );
      case 'Preview':
        return PreviewScreen(
          userId: widget.userId,
          controllerId: widget.controllerId,
          deviceId: widget.deviceId,
          serialNumber: widget.serialNumber,
          toDashboard: widget.toDashboard,
          fromDealer: widget.fromDealer,
          programType: widget.programType,
          customerId: widget.customerId,
          groupId: widget.groupId,
          categoryId: widget.categoryId,
          modelId: widget.modelId,
          deviceName: widget.deviceName,
          categoryName: widget.categoryName,
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildActionButton({
    required String key,
    required IconData icon,
    required VoidCallback onPressed,
    required BuildContext context,
  }) {
    return MaterialButton(
      key: Key(key),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      color: Theme.of(context).primaryColor,
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}