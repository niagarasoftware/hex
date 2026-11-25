import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hex/utils/helpers/log_print.dart';
import 'package:loading_indicator/loading_indicator.dart';
import '../../models/admin_dealer/dealer_definition_model.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../utils/snack_bar.dart';

class DealerDefinitionInConfig extends StatefulWidget {
  const DealerDefinitionInConfig(
      {super.key,
        required this.userId,
        required this.customerId,
        required this.controllerId,
        required this.imeiNo});
  final int userId, customerId, controllerId;
  final String imeiNo;

  @override
  State<DealerDefinitionInConfig> createState() =>
      DealerDefinitionInConfigState();
}

class DealerDefinitionInConfigState extends State<DealerDefinitionInConfig> {
  DataModelDDConfig data =
  DataModelDDConfig(categories: [], dealerDefinition: {});
  bool visibleLoading = false;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final Repository repository = Repository(HttpService());
      var getUserDetails = await repository.getdealerDefinition({
        "userId": widget.customerId,
        "controllerId": widget.controllerId
      });
      if (getUserDetails.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          var jsonData = jsonDecode(getUserDetails.body);
          AppLog.log("jsonData:$jsonData");
          data = DataModelDDConfig.fromJson(jsonData);
          indicatorViewHide();
        });
      }
    } catch (e, stackTrace) {
      AppLog.log(' Error overAll getData => ${e.toString()}');
      AppLog.log(' trace overAll getData  => $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'Dealer Definition',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: visibleLoading
          ? Center(
        child: SizedBox(
          width: 80,
          height: 80,
          child: LoadingIndicator(
            indicatorType: Indicator.ballPulse,
            colors: [colorScheme.primary],
          ),
        ),
      )
          : DealerDefinitionDashboard(
        data: data,
        userId: widget.userId,
        customerId: widget.customerId,
        controllerId: widget.controllerId,
        onStateChanged: () => setState(() {}),
      ),
    );
  }

  Widget wideLayout(DataModelDDConfig data, BuildContext context) {
    return build(context);
  }

  void indicatorViewShow() {
    setState(() {
      visibleLoading = true;
    });
  }

  void indicatorViewHide() {
    setState(() {
      visibleLoading = false;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Delegated builders for backward compatibility
  Widget buildCategoryContainer(Category category, DataModelDDConfig data,
      {bool isSingleCategoryView = false, BoxConstraints? constraints}) {
    return _DealerDefinitionDashboardState.buildCategoryContainerStatic(
      context: context,
      category: category,
      data: data,
      isSingleCategoryView: isSingleCategoryView,
      onStateChanged: () => setState(() {}),
    );
  }

  Widget buildDealerDefinitionItem(
      DealerDefinition? definition, Category category) {
    return _DealerDefinitionDashboardState.buildDealerDefinitionItemStatic(
      context: context,
      definition: definition,
      category: category,
      data: data,
      onStateChanged: () => setState(() {}),
    );
  }

  Widget buildDropdownItem(DealerDefinition? definition,
      List<String> dropdownlist, int iconcode, String iconfontfamily) {
    return _DealerDefinitionDashboardState.buildDropdownItemStatic(
      context: context,
      definition: definition,
      dropdownlist: dropdownlist,
      onStateChanged: () => setState(() {}),
    );
  }

  Widget buildTextFieldItem(
      DealerDefinition? definition, int iconcode, String iconfontfamily) {
    Category dummyCat = Category(
        categoryId: 0, categoryName: '', categoryDescription: '', active: '1');
    return _DealerDefinitionDashboardState.buildTextFieldItemStatic(
      context: context,
      definition: definition,
      category: dummyCat,
      onStateChanged: () => setState(() {}),
    );
  }

  Widget buildSwitchItem(
      DealerDefinition? definition, int iconcode, String iconfontfamily) {
    Category dummyCat = Category(
        categoryId: 0, categoryName: '', categoryDescription: '', active: '1');
    return _DealerDefinitionDashboardState.buildSwitchItemStatic(
      context: context,
      definition: definition,
      category: dummyCat,
      data: data,
      onStateChanged: () => setState(() {}),
    );
  }
}

class MyContainerWithTabs extends StatefulWidget {
  const MyContainerWithTabs(
      {super.key,
        required this.data,
        required this.userID,
        required this.customerID,
        required this.controllerId});
  final DataModelDDConfig data;
  final int userID, customerID, controllerId;

  @override
  State<MyContainerWithTabs> createState() => _MyContainerWithTabsState();
}

class _MyContainerWithTabsState extends State<MyContainerWithTabs> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceContainerLowest,
      child: DealerDefinitionDashboard(
        data: widget.data,
        userId: widget.userID,
        customerId: widget.customerID,
        controllerId: widget.controllerId,
        onStateChanged: () => setState(() {}),
      ),
    );
  }
}

class DealerDefinitionDashboard extends StatefulWidget {
  final DataModelDDConfig data;
  final int userId;
  final int customerId;
  final int controllerId;
  final VoidCallback onStateChanged;

  const DealerDefinitionDashboard({
    super.key,
    required this.data,
    required this.userId,
    required this.customerId,
    required this.controllerId,
    required this.onStateChanged,
  });

  @override
  State<DealerDefinitionDashboard> createState() =>
      _DealerDefinitionDashboardState();
}

class _DealerDefinitionDashboardState
    extends State<DealerDefinitionDashboard> {
  int selectedCategoryFilter = -1; // -1 means "All"

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.data.categories.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    return Column(
      children: [
        _buildCategoryFilterChips(context),
        Expanded(
          child: _buildMainDashboardBody(context),
        ),
        _buildBottomActionBar(context),
      ],
    );
  }

  Widget _buildCategoryFilterChips(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (widget.data.categories.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildFilterChip(
                context: context,
                title: 'All',
                isSelected: selectedCategoryFilter == -1,
                onTap: () {
                  setState(() {
                    selectedCategoryFilter = -1;
                  });
                },
              ),
              for (var category in widget.data.categories)
                _buildFilterChip(
                  context: context,
                  title: category.categoryName,
                  isSelected: selectedCategoryFilter == category.categoryId,
                  onTap: () {
                    setState(() {
                      selectedCategoryFilter = category.categoryId;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ChoiceChip(
      label: Text(title),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      side: BorderSide(
        color: isSelected
            ? colorScheme.primary
            : colorScheme.outlineVariant,
      ),
      labelStyle: textTheme.bodyMedium?.copyWith(
        color: isSelected
            ? colorScheme.onPrimary
            : colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 13,
      ),
    );
  }

  Widget _buildMainDashboardBody(BuildContext context) {
    if (widget.data.categories.isEmpty) {
      final colorScheme = Theme.of(context).colorScheme;
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    final isSingleCategory = selectedCategoryFilter != -1;
    final filteredCategories = isSingleCategory
        ? widget.data.categories
        .where((c) => c.categoryId == selectedCategoryFilter)
        .toList()
        : widget.data.categories;

    return LayoutBuilder(
      builder: (context, constraints) {
        const marginHorizontal = 16.0 * 2;
        const contentMaxWidth = 980.0;
        final parentWidth = constraints.maxWidth;
        final effectiveWidth =
        parentWidth > contentMaxWidth ? contentMaxWidth : parentWidth;
        final availableWidth = effectiveWidth - marginHorizontal;
        const spacing = 16.0;
        final isMobile = availableWidth < 640;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: contentMaxWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 16, bottom: 80),
              child: (isSingleCategory || isMobile)
                  ? Column(
                children: [
                  for (final category in filteredCategories) ...[
                    buildCategoryContainerStatic(
                      context: context,
                      category: category,
                      data: widget.data,
                      isSingleCategoryView: isSingleCategory,
                      onStateChanged: () {
                        setState(() {});
                        widget.onStateChanged();
                      },
                    ),
                    const SizedBox(height: spacing),
                  ],
                ],
              )
                  : _buildMasonryGrid(
                  filteredCategories, availableWidth, spacing),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMasonryGrid(
      List<Category> categories, double availableWidth, double spacing) {
    final leftColumn = <Widget>[];
    final rightColumn = <Widget>[];

    for (int i = 0; i < categories.length; i++) {
      final cardWidget = buildCategoryContainerStatic(
        context: context,
        category: categories[i],
        data: widget.data,
        onStateChanged: () {
          setState(() {});
          widget.onStateChanged();
        },
      );
      if (leftColumn.length <= rightColumn.length) {
        leftColumn.add(cardWidget);
      } else {
        rightColumn.add(cardWidget);
      }
    }

    final colWidth =
        ((availableWidth - spacing) / 2).floorToDouble() - 0.5;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: colWidth,
          child: Column(
            children: [
              for (int i = 0; i < leftColumn.length; i++) ...[
                leftColumn[i],
                if (i < leftColumn.length - 1) SizedBox(height: spacing),
              ],
            ],
          ),
        ),
        SizedBox(width: spacing),
        SizedBox(
          width: colWidth,
          child: Column(
            children: [
              for (int i = 0; i < rightColumn.length; i++) ...[
                rightColumn[i],
                if (i < rightColumn.length - 1) SizedBox(height: spacing),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static Widget buildCategoryContainerStatic({
    required BuildContext context,
    required Category category,
    required DataModelDDConfig data,
    bool isSingleCategoryView = false,
    required VoidCallback onStateChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFixedRowStatic(context, category.categoryName),
          _buildDealerDefinitionListStatic(
            context: context,
            category: category,
            data: data,
            isSingleCategoryView: isSingleCategoryView,
            onStateChanged: onStateChanged,
          ),
        ],
      ),
    );
  }

  static Widget _buildFixedRowStatic(
      BuildContext context, String categoryName) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              categoryName,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildDealerDefinitionListStatic({
    required BuildContext context,
    required Category category,
    required DataModelDDConfig data,
    bool isSingleCategoryView = false,
    required VoidCallback onStateChanged,
  }) {
    final definitions =
        data.dealerDefinition['${category.categoryId}'] ?? [];
    final colorScheme = Theme.of(context).colorScheme;

    if (definitions.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, cardConstraints) {
        final useTwoColumns =
            isSingleCategoryView && cardConstraints.maxWidth >= 580;

        if (useTwoColumns) {
          const spacing = 12.0;
          final colWidth =
              ((cardConstraints.maxWidth - spacing) / 2).floorToDouble() - 0.5;

          final leftItems = <Widget>[];
          final rightItems = <Widget>[];

          for (int i = 0; i < definitions.length; i++) {
            final itemWidget = buildDealerDefinitionItemStatic(
              context: context,
              definition: definitions[i],
              category: category,
              data: data,
              onStateChanged: onStateChanged,
            );
            if (i % 2 == 0) {
              leftItems.add(itemWidget);
            } else {
              rightItems.add(itemWidget);
            }
          }

          return ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: colWidth,
                  child: Column(
                    children: [
                      for (int i = 0; i < leftItems.length; i++) ...[
                        leftItems[i],
                        if (i < leftItems.length - 1)
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color: colorScheme.outlineVariant,
                          ),
                      ],
                    ],
                  ),
                ),
                Container(
                  width: spacing,
                  alignment: Alignment.center,
                  child: Container(
                    width: 0.5,
                    color: colorScheme.outlineVariant,
                  ),
                ),
                SizedBox(
                  width: colWidth,
                  child: Column(
                    children: [
                      for (int i = 0; i < rightItems.length; i++) ...[
                        rightItems[i],
                        if (i < rightItems.length - 1)
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color: colorScheme.outlineVariant,
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < definitions.length; i++) ...[
                buildDealerDefinitionItemStatic(
                  context: context,
                  definition: definitions[i],
                  category: category,
                  data: data,
                  onStateChanged: onStateChanged,
                ),
                if (i < definitions.length - 1)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: colorScheme.outlineVariant,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  static Widget buildDealerDefinitionItemStatic({
    required BuildContext context,
    required DealerDefinition? definition,
    required Category category,
    required DataModelDDConfig data,
    required VoidCallback onStateChanged,
  }) {
    final dropdownlist =
    StringToList().stringtolist('${definition?.dropdownValues}', ',');

    if (definition?.widgetTypeId == 3) {
      return buildDropdownItemStatic(
        context: context,
        definition: definition,
        dropdownlist: dropdownlist,
        onStateChanged: onStateChanged,
      );
    } else if (definition?.widgetTypeId == 1) {
      return buildTextFieldItemStatic(
        context: context,
        definition: definition,
        category: category,
        onStateChanged: onStateChanged,
      );
    } else {
      return buildSwitchItemStatic(
        context: context,
        definition: definition,
        category: category,
        data: data,
        onStateChanged: onStateChanged,
      );
    }
  }

  static Widget buildDropdownItemStatic({
    required BuildContext context,
    required DealerDefinition? definition,
    required List<String> dropdownlist,
    required VoidCallback onStateChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final selectedValue = (definition?.value == '' || definition?.value == null)
        ? (dropdownlist.isNotEmpty ? dropdownlist[0].toString() : null)
        : definition?.value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: LayoutBuilder(
        builder: (context, rowConstraints) {
          final isNarrow = rowConstraints.maxWidth < 250;

          final labelColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${definition?.parameter}',
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              if (definition?.description != null &&
                  definition!.description.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  definition.description,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          );

          final dropdownControl = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outlineVariant,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                isDense: true,
                items: dropdownlist.map((String items) {
                  return DropdownMenuItem<String>(
                    value: items,
                    child: Text(
                      items,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  definition?.value = value;
                  onStateChanged();
                },
                value: selectedValue,
                dropdownColor: colorScheme.surface,
                iconEnabledColor: colorScheme.onSurfaceVariant,
              ),
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                labelColumn,
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: dropdownControl,
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: labelColumn),
              const SizedBox(width: 10),
              SizedBox(
                width: 140,
                child: dropdownControl,
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget buildTextFieldItemStatic({
    required BuildContext context,
    required DealerDefinition? definition,
    required Category category,
    required VoidCallback onStateChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: LayoutBuilder(
        builder: (context, rowConstraints) {
          final isNarrow = rowConstraints.maxWidth < 230;

          final labelColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${definition?.parameter}',
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              if (definition?.description != null &&
                  definition!.description.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  definition.description,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          );

          final inputControl = SizedBox(
            width: 70,
            height: 36,
            child: CustomTextField(
              key: ValueKey(
                  'txt_${category.categoryId}_${definition?.dealerDefinitionId}'),
              onChanged: (text) {
                definition?.value = text;
                onStateChanged();
              },
              initialValue: definition?.value ?? '0',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Value is required';
                } else {
                  definition?.value = value;
                }
                return null;
              },
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                labelColumn,
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: inputControl,
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: labelColumn),
              const SizedBox(width: 10),
              inputControl,
            ],
          );
        },
      ),
    );
  }

  static Widget buildSwitchItemStatic({
    required BuildContext context,
    required DealerDefinition? definition,
    required Category category,
    required DataModelDDConfig data,
    required VoidCallback onStateChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: LayoutBuilder(
        builder: (context, rowConstraints) {
          final isNarrow = rowConstraints.maxWidth < 200;

          final labelColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${definition?.parameter}',
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              if (definition?.description != null &&
                  definition!.description.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  definition.description,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          );

          final switchControl = MySwitch(
            value: definition?.value == '1',
            onChanged: (value) {
              _handleMutualExclusionStatic(definition, category, data, value);
              onStateChanged();
            },
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                labelColumn,
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: switchControl,
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: labelColumn),
              const SizedBox(width: 8),
              switchControl,
            ],
          );
        },
      ),
    );
  }

  static void _handleMutualExclusionStatic(DealerDefinition? definition,
      Category category, DataModelDDConfig data, bool value) {
    final categoryIdStr = '${category.categoryId}';
    definition?.value = !value ? '0' : '1';

    if (categoryIdStr == "1" && value && data.dealerDefinition["1"] != null) {
      final list = data.dealerDefinition["1"]!;
      final id = definition?.dealerDefinitionId;

      int rtcindex = list.indexWhere((e) => e.dealerDefinitionId == 33);
      int rtcmaxindex = list.indexWhere((e) => e.dealerDefinitionId == 34);
      int stopmethod = list.indexWhere((e) => e.dealerDefinitionId == 35);

      if (id == 33) {
        if (rtcmaxindex >= 0) list[rtcmaxindex].value = '0';
        if (stopmethod >= 0) list[stopmethod].value = '0';
      } else if (id == 34) {
        if (rtcindex >= 0) list[rtcindex].value = '0';
        if (stopmethod >= 0) list[stopmethod].value = '0';
      } else if (id == 35) {
        if (rtcindex >= 0) list[rtcindex].value = '0';
        if (rtcmaxindex >= 0) list[rtcmaxindex].value = '0';
      }
    }
  }

  Widget _buildBottomActionBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final Repository repository = Repository(HttpService());
              Map<String, Object> body = {
                "userId": widget.customerId,
                "controllerId": widget.controllerId,
                "dealerDefinition": widget.data.dealerDefinition,
                "createUser": widget.userId
              };
              var getUserDetails =
              await repository.createdealerDefinition(body);
              final jsonDataResponseput =
              json.decode(getUserDetails.body);
              if (!mounted) return;
              GlobalSnackBar.show(
                context,
                jsonDataResponseput['message'],
                jsonDataResponseput['code'],
              );
            },
            icon: const Icon(Icons.save_as_outlined, size: 18),
            label: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class StringToList {
  List<String> stringtolist(
      String name,
      String split,
      ) {
    var f = name.split(split);
    return f;
  }
}

class MySwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const MySwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Switch(
      value: value,
      activeThumbColor: colorScheme.onPrimary,
      activeTrackColor: colorScheme.primary,
      inactiveTrackColor: colorScheme.surfaceContainerHighest,
      onChanged: onChanged,
    );
  }
}

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? initialValue;

  final IconData? prefixIcon;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    this.controller,
    this.labelText,
    this.initialValue,
    this.prefixIcon,
    this.obscureText = false,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      initialValue: initialValue,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
          BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
          BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        fillColor: colorScheme.surfaceContainerLow,
        filled: true,
      ),
      validator: validator,
    );
  }
}
