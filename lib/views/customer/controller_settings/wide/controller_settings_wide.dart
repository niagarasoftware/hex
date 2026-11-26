import 'package:flutter/material.dart';
import 'package:hex/view_models/customer/controller_settings_view_model.dart';
import 'package:provider/provider.dart';
import '../../../../StateManagement/customer_provider.dart';
import '../../../../models/customer/controller_context.dart';
import '../../../../models/customer/site_model.dart';
import '../../../../repository/repository.dart';
import '../../../../services/http_service.dart';
import '../../../common/widgets/build_loading_indicator.dart';
import '../widgets/settings_screen_factory.dart';

class ControllerSettingWide extends StatelessWidget {
  const ControllerSettingWide({
    super.key,
    required this.customerId,
    required this.userId,
    required this.masterController,
  });

  final int customerId, userId;
  final MasterControllerModel masterController;

  ControllerContext get ctx => ControllerContext(
    userId: userId,
    customerId: customerId,
    controllerId: masterController.controllerId,
    categoryId: masterController.categoryId,
    modelId: masterController.modelId,
    imeiNo: masterController.deviceId,
    deviceName: masterController.deviceName,
    master: masterController,
    categoryName: masterController.categoryName,
    isSubUser: masterController.isSubUser,
  );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey(Provider.of<CustomerProvider>(context).controllerId),
      create: (_) => ControllerSettingsViewModel(Repository(HttpService()))
        ..getSettingsMenu(customerId, masterController.controllerId, masterController.modelId),
      child: Consumer<ControllerSettingsViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return buildLoadingIndicator(context);
          }
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          return Scaffold(
            backgroundColor: colorScheme.surfaceContainerLowest,
            body: DefaultTabController(
              length: viewModel.filteredSettingList.length,
              child: Builder(
                builder: (context) {
                  final tabController = DefaultTabController.of(context);
                  return Column(
                    children: [
                      _CustomWorkspaceTabBar(
                        tabs: viewModel.filteredSettingList,
                        tabController: tabController,
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: tabController,
                          children: viewModel.filteredSettingList.map((tab) {
                            return _buildTabContent(tab['title']);
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent(String title) {
    return SettingsScreenFactory.getScreenWidget(title, ctx, false) ?? const SizedBox();
  }
}

class _CustomWorkspaceTabBar extends StatefulWidget {
  final List<Map<String, dynamic>> tabs;
  final TabController tabController;

  const _CustomWorkspaceTabBar({
    required this.tabs,
    required this.tabController,
  });

  @override
  State<_CustomWorkspaceTabBar> createState() => _CustomWorkspaceTabBarState();
}

class _CustomWorkspaceTabBarState extends State<_CustomWorkspaceTabBar> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_handleTabChange);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!mounted) return;
    setState(() {});
    _scrollToSelectedTab();
  }

  void _scrollToSelectedTab() {
    if (!_scrollController.hasClients) return;
    final index = widget.tabController.index;
    const itemWidth = 110.0;
    final targetOffset = (index * itemWidth) - 80.0;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: colorScheme.surfaceContainerLowest,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(widget.tabs.length, (index) {
            final tab = widget.tabs[index];
            final isSelected = widget.tabController.index == index;

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    widget.tabController.animateTo(index);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    constraints: const BoxConstraints(minWidth: 100),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerLow,
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          tab['icon'] as IconData?,
                          size: 20,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tab['title'] as String? ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}