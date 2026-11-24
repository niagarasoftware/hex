import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hex/modules/Logs/view/pump_log_dashboard.dart';
import 'package:provider/provider.dart';

import 'package:hex/utils/constants.dart';

import '../../StateManagement/customer_provider.dart';
import '../../models/customer/site_model.dart';
import '../../modules/Logs/repository/log_repos.dart';

import '../../modules/irrigation_report/view/channel_log_page.dart';
import '../../modules/irrigation_report/view/list_of_log_config.dart';
import '../../modules/irrigation_report/view/fertigation_card_list_page.dart';
import '../../modules/irrigation_report/view/standalone_log.dart';
import '../../modules/irrigation_report/view/zone_log.dart';
import '../../modules/irrigation_report/view/zone_cyclic_log.dart';
import '../../modules/irrigation_report/view/motor_cyclic_log.dart';

import '../../services/http_service.dart';
import '../../view_models/customer/customer_screen_controller_view_model.dart';

class IrrigationAndPumpLog extends StatefulWidget {
  final Map<String, dynamic> userData;
  final MasterControllerModel masterData;

  const IrrigationAndPumpLog({
    super.key,
    required this.userData,
    required this.masterData,
  });

  @override
  State<IrrigationAndPumpLog> createState() => _IrrigationAndPumpLogState();
}

class _IrrigationAndPumpLogState extends State<IrrigationAndPumpLog>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  List pumpList = [];

  String message = '';

  final LogRepository repository = LogRepository(HttpService());

  // Channel Log data
  List<ChannelLogRecord> channelLogData = [];

  bool get isEcoGem =>
      AppConstants.ecoGemAndPlusModelList.contains(widget.masterData.modelId);

  bool get isOmsGem =>
      AppConstants.omsGemList.contains(widget.masterData.modelId);

  bool get showPumpLog => isEcoGem || pumpList.isNotEmpty;

  int _calculateTabLength() {
    if (isOmsGem) {
      return 1;
    }

    if (isEcoGem) {
      return 3; // Motor + Zone Cyclic + Pump
    }

    // Irrigation + Zone + Fertilizer + Standalone
    // + optional Pump
    return 4 + (showPumpLog ? 1 : 0);
  }

  @override
  void initState() {
    super.initState();

    tabController = TabController(
      length: _calculateTabLength(),
      vsync: this,
    );

    getUserNodePumpList();
  }

  @override
  void didUpdateWidget(covariant IrrigationAndPumpLog oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCtrlId =
        oldWidget.userData['controllerId'] ?? oldWidget.masterData.controllerId;
    final newCtrlId =
        widget.userData['controllerId'] ?? widget.masterData.controllerId;
    if (oldCtrlId != newCtrlId ||
        oldWidget.userData['customerId'] != widget.userData['customerId']) {
      getUserNodePumpList();
    }
  }

  void _updateTabController() {
    final newLength = _calculateTabLength();

    if (tabController.length == newLength) {
      return;
    }

    final oldController = tabController;
    final oldIndex = oldController.index;

    tabController = TabController(
      length: newLength,
      vsync: this,
      initialIndex: oldIndex < newLength ? oldIndex : newLength - 1,
    );

    oldController.dispose();
  }

  Future<void> getUserNodePumpList() async {
    try {
      final userData = {
        'userId': widget.userData['customerId'],
        'controllerId': widget.userData['controllerId'],
      };

      final result = await repository.getUserNodePumpList(userData);

      if (!mounted) return;

      final response = jsonDecode(result.body);

      List fetchedList = [];
      if (result.statusCode == 200 &&
          response['data'] is List &&
          (response['data'] as List).isNotEmpty) {
        fetchedList = response['data'];
      } else if (widget.masterData.nodeList.isNotEmpty) {
        final pumpNodes = widget.masterData.nodeList.where((n) {
          return AppConstants.pumpList.contains(n.modelId) ||
              n.categoryId == 1 ||
              n.categoryName.toLowerCase().contains('pump');
        }).toList();

        final nodesToUse =
            pumpNodes.isNotEmpty ? pumpNodes : widget.masterData.nodeList;
        fetchedList = nodesToUse
            .map((n) => {
                  'controllerId': n.controllerId,
                  'deviceId': n.deviceId,
                  'deviceName': n.deviceName.isNotEmpty
                      ? n.deviceName
                      : 'Node ${n.serialNumber}',
                })
            .toList();
      }

      setState(() {
        pumpList = fetchedList;
        message =
            fetchedList.isEmpty ? (response['message']?.toString() ?? '') : '';
        _updateTabController();
      });
    } catch (e) {
      if (!mounted) return;

      List fallbackList = [];
      if (widget.masterData.nodeList.isNotEmpty) {
        final pumpNodes = widget.masterData.nodeList.where((n) {
          return AppConstants.pumpList.contains(n.modelId) ||
              n.categoryId == 1 ||
              n.categoryName.toLowerCase().contains('pump');
        }).toList();

        final nodesToUse =
            pumpNodes.isNotEmpty ? pumpNodes : widget.masterData.nodeList;
        fallbackList = nodesToUse
            .map((n) => {
                  'controllerId': n.controllerId,
                  'deviceId': n.deviceId,
                  'deviceName': n.deviceName.isNotEmpty
                      ? n.deviceName
                      : 'Node ${n.serialNumber}',
                })
            .toList();
      }

      setState(() {
        pumpList = fallbackList;
        message = fallbackList.isEmpty ? e.toString() : '';
        _updateTabController();
      });

      debugPrint('Pump list error: $e');
    }
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  void _openLogDetail(BuildContext context, _LogCardItem card) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) {
          if (card.page is FertigationCardListPage) {
            return card.page;
          }
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              backgroundColor: const Color(0xFFF8FAFC),
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              automaticallyImplyLeading: false,
              titleSpacing: 16,
              title: Row(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(Icons.arrow_back, size: 20, color: Color(0xFF1E293B)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          card.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1B4B),
                          ),
                        ),
                        Text(
                          card.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            body: card.page,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    CustomerScreenControllerViewModel? customerVM;
    try {
      customerVM =
          Provider.of<CustomerScreenControllerViewModel>(context, listen: true);
    } catch (_) {}

    final bool isOffline = customerVM?.isNotCommunicate ?? false;

    final List<_LogCardItem> cards = _buildCardItems();

    return Scaffold(
      key: ValueKey(
        Provider.of<CustomerProvider>(context).controllerId,
      ),
      backgroundColor: const Color(0xFFF7FAFD),
      body: SafeArea(
        child: _buildOverviewDashboard(context, cards, isOffline, customerVM),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card builders
  // ---------------------------------------------------------------------------

  _LogCardItem _irrigationCard() {
    return _LogCardItem(
      title: 'Irrigation Log',
      subtitle:
          'Every irrigation cycle, with water used and duration for each zone.',
      iconWidget: const Icon(
        Icons.water_drop_outlined,
        color: Color(0xFF0284C7),
        size: 24,
      ),
      accentColor: const Color(0xFF0284C7),
      iconBgColor: const Color(0xFFE0F2FE),
      buttonColor: const Color(0xFF278EA5),
      features: const [
        'Start & stop times',
        'Water usage',
        'Zone-wise',
      ],
      page: ListOfLogConfig(
        userData: widget.userData,
        masterData: widget.masterData,
      ),
    );
  }

  _LogCardItem _zoneLogCard() {
    return _LogCardItem(
      title: 'Cumulative Log',
      subtitle:
          'Running totals of irrigation, valve activity and runtime.',
      iconWidget: const Icon(
        Icons.grid_view_rounded,
        color: Color(0xFF7C3AED),
        size: 24,
      ),
      accentColor: const Color(0xFF7C3AED),
      iconBgColor: const Color(0xFFEDE9FE),
      buttonColor: const Color(0xFF7C3AED),
      features: const [
        'Valve activity',
        'Runtime per zone',
        'Usage summary',
      ],
      page: ZoneLog(
        userData: widget.userData,
        masterData: widget.masterData,
      ),
    );
  }

  _LogCardItem _fertilizerLogCard() {
    return _LogCardItem(
      title: 'Fertilizer Log',
      subtitle:
          'Fertigation recipes, channel runtime and EC / pH readings.',
      iconWidget: const Icon(
        Icons.science_outlined,
        color: Color(0xFF0D9488),
        size: 24,
      ),
      accentColor: const Color(0xFF0D9488),
      iconBgColor: const Color(0xFFCCFBF1),
      buttonColor: const Color(0xFF006573),
      features: const [
        'Recipes',
        'Channel quantity',
        'EC & pH',
      ],
      page: FertigationCardListPage(
        serverData: const {'logName': 'Fertilizer'},
        userData: widget.userData,
        nameData: const [],
      ),
    );
  }

  _LogCardItem _standaloneLogCard() {
    return _LogCardItem(
      title: 'Standalone Log',
      subtitle:
          'Manual runs: when each was started and stopped, and how long it ran.',
      iconWidget: const Icon(
        Icons.touch_app_outlined,
        color: Color(0xFFDB2777),
        size: 24,
      ),
      accentColor: const Color(0xFFDB2777),
      iconBgColor: const Color(0xFFFCE7F3),
      buttonColor: const Color(0xFFDB2777),
      features: const [
        'Manual events',
        'Run duration',
        'Water usage',
      ],
      page: StandaloneLog(
        userData: widget.userData,
      ),
    );
  }

  _LogCardItem _pumpLogCard() {
    return _LogCardItem(
      title: 'Pump Log',
      subtitle:
          'Pump start / stop events, total runtime and any faults or alarms.',
      iconWidget: SvgPicture.asset(
        'assets/svg_images/pump.svg',
        width: 22,
        height: 22,
        colorFilter: const ColorFilter.mode(Color(0xFFEA580C), BlendMode.srcIn),
      ),
      accentColor: const Color(0xFFEA580C),
      iconBgColor: const Color(0xFFFFEDD5),
      buttonColor: const Color(0xFFF38220),
      features: const [
        'Start / Stop',
        'Runtime hours',
        'Faults',
      ],
      page: PumpLogDashboardScreen(
        pumpList: pumpList,
        userId: widget.userData['customerId'],
        controllerId: widget.masterData.controllerId,
        masterData: widget.masterData,
        userData: widget.userData,
        showMobileCalendar: true,
      ),
    );
  }

  List<_LogCardItem> _buildCardItems() {
    final List<_LogCardItem> cards = [];

    if (isOmsGem) {
      cards.add(_irrigationCard());
    } else if (isEcoGem) {
      cards.addAll([
        _LogCardItem(
          title: 'Motor Cyclic Log',
          subtitle:
              'Motor operations, runtime intervals and status logs.',
          iconWidget: const Icon(
            Icons.sync_rounded,
            color: Color(0xFF0284C7),
            size: 24,
          ),
          accentColor: const Color(0xFF0284C7),
          iconBgColor: const Color(0xFFE0F2FE),
          buttonColor: const Color(0xFF278EA5),
          features: const [
            'Runtime & duration',
            'Start & stop intervals',
            'Cycle frequency',
          ],
          page: MotorCyclicLog(userData: widget.userData),
        ),
        _LogCardItem(
          title: 'Zone Cyclic Log',
          subtitle:
              'Zone cyclic status, flow and runtime information.',
          iconWidget: const Icon(
            Icons.pin_drop_outlined,
            color: Color(0xFF16A34A),
            size: 24,
          ),
          accentColor: const Color(0xFF16A34A),
          iconBgColor: const Color(0xFFDCFCE7),
          buttonColor: const Color(0xFF2E8B57),
          features: const [
            'Zone activity',
            'Valve sequence',
            'Flow & duration',
          ],
          page: ZoneCyclicLog(userData: widget.userData),
        ),
        _pumpLogCard(),
      ]);
    } else {
      cards.addAll([
        _irrigationCard(),
        _zoneLogCard(),
        _fertilizerLogCard(),
        _standaloneLogCard(),
        // Matches _calculateTabLength(): pump log only when it applies
        if (showPumpLog) _pumpLogCard(),
      ]);
    }

    return cards;
  }

  // ---------------------------------------------------------------------------
  // Layout
  // ---------------------------------------------------------------------------

  Widget _buildOverviewDashboard(
    BuildContext context,
    List<_LogCardItem> cards,
    bool isOffline,
    CustomerScreenControllerViewModel? customerVM,
  ) {
    return LayoutBuilder(
      builder: (context, screenConstraints) {
        final bool isCompact = screenConstraints.maxWidth < 620;

        return Stack(
          children: [
            // Main content
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 16 : 24,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // Responsive Cards Layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double width = constraints.maxWidth;

                      if (width >= 1150) {
                        // All cards in a single row
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (int i = 0; i < cards.length; i++) ...[
                                if (i > 0) const SizedBox(width: 18),
                                Expanded(
                                  child: _buildLogCard(context, cards[i],
                                      isStretched: true),
                                ),
                              ],
                            ],
                          ),
                        );
                      } else if (width >= 620) {
                        // 2 cards per row
                        final rows = <Widget>[];
                        for (int i = 0; i < cards.length; i += 2) {
                          final hasNext = i + 1 < cards.length;
                          rows.add(
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                      child: _buildLogCard(context, cards[i],
                                          isStretched: true)),
                                  const SizedBox(width: 16),
                                  if (hasNext)
                                    Expanded(
                                        child: _buildLogCard(
                                            context, cards[i + 1],
                                            isStretched: true))
                                  else
                                    const Spacer(),
                                ],
                              ),
                            ),
                          );
                          if (i + 2 < cards.length) {
                            rows.add(const SizedBox(height: 16));
                          }
                        }
                        return Column(children: rows);
                      } else {
                        // 1 column (mobile)
                        return Column(
                          children: [
                            for (int i = 0; i < cards.length; i++) ...[
                              if (i > 0) const SizedBox(height: 16),
                              _buildLogCard(context, cards[i],
                                  isStretched: false),
                            ],
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.eco_outlined,
            size: 30,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Logs',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'View and manage your system logs',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogCard(
    BuildContext context,
    _LogCardItem card, {
    bool isStretched = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openLogDetail(context, card),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: isStretched ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: isStretched
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top row: Icon and Arrow
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon Avatar
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: card.iconBgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(child: card.iconWidget),
                        ),
                        
                        // Right Arrow
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      card.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      card.subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Feature Chips
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: card.features.map((featureText) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: card.iconBgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            featureText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: card.accentColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogCardItem {
  final String title;
  final String subtitle;
  final Widget iconWidget;
  final Color accentColor;
  final Color iconBgColor;
  final Color buttonColor;
  final List<String> features;
  final Widget page;

  const _LogCardItem({
    required this.title,
    required this.subtitle,
    required this.iconWidget,
    required this.accentColor,
    required this.iconBgColor,
    required this.buttonColor,
    required this.features,
    required this.page,
  });
}
