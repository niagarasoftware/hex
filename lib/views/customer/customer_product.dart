import 'package:data_table_2/data_table_2.dart';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../view_models/customer/customer_product_view_model.dart';

class CustomerProduct extends StatefulWidget {
  const CustomerProduct({
    super.key,
    required this.customerId,
  });

  final int customerId;

  @override
  State<CustomerProduct> createState() => _CustomerProductState();
}

class _CustomerProductState extends State<CustomerProduct> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _categoryScrollController = ScrollController();

  String _searchText = '';
  String _selectedCategory = 'All';
  String _selectedSite = 'All sites';

  int _currentPage = 0;
  final int _pageSize = 10;

  static const Color primaryColor = Color(0xFF087681);
  static const Color textColor = Color(0xFF243746);
  static const Color secondaryText = Color(0xFF718692);
  static const Color borderColor = Color(0xFFE5ECEF);
  static const Color backgroundColor = Color(0xFFF4F2F8);

  @override
  void dispose() {
    _searchController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CustomerProductViewModel(Repository(HttpService()))
        ..getCustomerProducts(widget.customerId),
      child: Consumer<CustomerProductViewModel>(
        builder: (context, viewModel, _) {
          final products = viewModel.productInventoryListCus;

          final categories = products
              .map((e) => e.categoryName)
              .toSet()
              .toList()
            ..sort();

          final sites = products
              .where((e) => e.productStatus != 3)
              .map((e) => e.siteName)
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

          final activeCount =
              products.where((e) => e.productStatus != 3).length;

          final filteredProducts = products.where((device) {
            final search = _searchText.toLowerCase();

            final matchesSearch = search.isEmpty ||
                device.deviceId.toLowerCase().contains(search) ||
                device.model.toLowerCase().contains(search) ||
                device.categoryName.toLowerCase().contains(search) ||
                device.siteName.toLowerCase().contains(search);

            final matchesCategory = _selectedCategory == 'All' ||
                device.categoryName == _selectedCategory;

            final matchesSite = _selectedSite == 'All sites' ||
                device.siteName == _selectedSite;

            return matchesSearch && matchesCategory && matchesSite;
          }).toList();

          final totalPages = (filteredProducts.length / _pageSize).ceil();

          if (totalPages == 0) {
            _currentPage = 0;
          } else if (_currentPage >= totalPages) {
            _currentPage = totalPages - 1;
          }

          final startIndex = _currentPage * _pageSize;

          final endIndex =
          (startIndex + _pageSize).clamp(0, filteredProducts.length);

          final pageProducts =
          filteredProducts.sublist(startIndex, endIndex);

          if (kIsWeb) {
            return _buildWebContent(
              context,
              viewModel,
              products,
              categories,
              sites,
              filteredProducts,
              pageProducts,
              activeCount,
              startIndex,
              endIndex,
              totalPages,
            );
          }

          return Scaffold(
            backgroundColor: backgroundColor,
            appBar: AppBar(
              title: const Text('All My Devices'),
              backgroundColor: Colors.white,
              foregroundColor: textColor,
              elevation: 0,
            ),
            body: _buildMobileContent(
              products,
              categories,
              sites,
              filteredProducts,
              pageProducts,
              activeCount,
            ),
          );
        },
      ),
    );
  }

  // --------------------------------------------------
  // WEB DESIGN
  // --------------------------------------------------

  Widget _buildWebContent(
      BuildContext context,
      CustomerProductViewModel viewModel,
      List products,
      List<String> categories,
      List<String> sites,
      List filteredProducts,
      List pageProducts,
      int activeCount,
      int startIndex,
      int endIndex,
      int totalPages,
      ) {
    final siteCount = products
        .where((e) => e.productStatus != 3)
        .map((e) => e.siteName)
        .where((e) => e.isNotEmpty)
        .toSet()
        .length;

    final categoryCount = categories.length;

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummarySection(
                    total: products.length,
                    active: activeCount,
                    sites: siteCount,
                    categories: categoryCount,
                  ),

                  const SizedBox(height: 18),

                  _buildSearchSection(sites),

                  const SizedBox(height: 12),

                  _buildCategoryFilters(categories, products),

                  const SizedBox(height: 12),

                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: DataTable2(
                          minWidth: 1050,
                          columnSpacing: 18,
                          horizontalMargin: 15,
                          headingRowHeight: 48,
                          dataRowHeight: 58,
                          dividerThickness: 0.7,
                          border: TableBorder(
                            horizontalInside: BorderSide(
                              color: borderColor,
                              width: 0.7,
                            ),
                          ),
                          headingRowColor:
                          WidgetStateProperty.all(
                            const Color(0xFFF0F4F5),
                          ),
                          columns: const [
                            DataColumn2(
                              label: _HeaderText('S.NO'),
                              fixedWidth: 55,
                            ),
                            DataColumn2(
                              label: _HeaderText('CATEGORY'),
                              fixedWidth: 170,
                            ),
                            DataColumn2(
                              label: _HeaderText('MODEL NAME'),
                              size: ColumnSize.M,
                            ),
                            DataColumn2(
                              label: _HeaderText('DEVICE ID'),
                              size: ColumnSize.M,
                            ),
                            DataColumn2(
                              label: _HeaderText('SITE NAME'),
                              size: ColumnSize.M,
                            ),
                            DataColumn2(
                              label: _HeaderText('STATUS'),
                              fixedWidth: 115,
                            ),
                            DataColumn2(
                              label: _HeaderText('MODIFY DATE ↓'),
                              fixedWidth: 145,
                            ),
                          ],
                          rows: List.generate(
                            pageProducts.length,
                                (index) {
                              final device = pageProducts[index];

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      '${startIndex + index + 1}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: secondaryText,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    _buildCategoryBadge(
                                      device.categoryName,
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      device.model,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SelectableText(
                                            device.deviceId,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: textColor,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Copy Device ID',
                                          icon: const Icon(
                                            Icons.copy,
                                            size: 15,
                                            color: secondaryText,
                                          ),
                                          onPressed: () {
                                            Clipboard.setData(
                                              ClipboardData(
                                                text: device.deviceId,
                                              ),
                                            );

                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Device ID copied',
                                                ),
                                                duration:
                                                Duration(seconds: 1),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      device.productStatus == 3
                                          ? '-'
                                          : device.siteName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    _buildStatusBadge(
                                      device.productStatus,
                                    ),
                                  ),
                                  DataCell(
                                    _buildDateCell(
                                      device.modifyDate,
                                      viewModel,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // SUMMARY SECTION
  // --------------------------------------------------

  Widget _buildSummarySection({
    required int total,
    required int active,
    required int sites,
    required int categories,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 42) / 4;

        return Wrap(
          spacing: 14,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _summaryItem(
                value: '$total',
                label: 'Total devices',
                background: const Color(0xFFE0F0F2),
                icon: Icons.devices_outlined,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _summaryItem(
                value: '$active',
                label: 'Active',
                background: const Color(0xFFE4F3EA),
                icon: Icons.check_circle_outline,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _summaryItem(
                value: '$sites',
                label: 'Sites',
                background: const Color(0xFFE9EEF9),
                icon: Icons.location_on_outlined,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _summaryItem(
                value: '$categories',
                label: 'Categories',
                background: const Color(0xFFF1EAF9),
                icon: Icons.sell_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryItem({
    required String value,
    required String label,
    required Color background,
    required IconData icon,
  }) {
    return Container(
      height: 58, // Changed from 76 to 58
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFEDF1F3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 19,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // SEARCH SECTION
  // --------------------------------------------------

  Widget _buildSearchSection(List<String> sites) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                    _currentPage = 0;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search device ID, model or site',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: secondaryText,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 19,
                    color: secondaryText,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF0F4F5),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: const BorderSide(
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 155,
            height: 40,
            child: DropdownButtonFormField<String>(
              value: _selectedSite,
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF0F4F5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                const DropdownMenuItem(
                  value: 'All sites',
                  child: Text('All sites'),
                ),
                ...sites.map(
                      (site) => DropdownMenuItem(
                    value: site,
                    child: Text(
                      site,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSite = value ?? 'All sites';
                  _currentPage = 0;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // CATEGORY FILTER
  // --------------------------------------------------

  void _scrollCategories(double delta) {
    if (!_categoryScrollController.hasClients) return;

    final pos = _categoryScrollController.position;
    final target =
    (pos.pixels + delta).clamp(0.0, pos.maxScrollExtent);

    _categoryScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Widget _scrollArrow(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor),
        ),
        child: Icon(icon, size: 20, color: secondaryText),
      ),
    );
  }

  Widget _buildCategoryFilters(
      List<String> categories,
      List products,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      child: Row(
        children: [
          _scrollArrow(
            Icons.chevron_left,
                () => _scrollCategories(-250),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                },
                scrollbars: false,
              ),
              child: ScrollbarTheme(
                data: ScrollbarThemeData(
                  thickness: WidgetStateProperty.all(4),
                  radius: const Radius.circular(4),
                  thumbColor:
                  WidgetStateProperty.all(const Color(0xFFCBD5DB)),
                  trackColor:
                  WidgetStateProperty.all(const Color(0xFFF0F4F5)),
                  trackBorderColor:
                  WidgetStateProperty.all(Colors.transparent),
                ),
                child: Scrollbar(
                  controller: _categoryScrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: SingleChildScrollView(
                    controller: _categoryScrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        ...categories.map((category) {
                          final count = products
                              .where((e) => e.categoryName == category)
                              .length;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _categoryChip(
                              category,
                              count,
                              _categoryColor(category),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _scrollArrow(
            Icons.chevron_right,
                () => _scrollCategories(250),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(
      String category,
      int count,
      Color color,
      ) {
    final selected = _selectedCategory == category;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() {
          _selectedCategory = category;
          _currentPage = 0;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : Colors.white,
          border: Border.all(
            color: selected ? color.withOpacity(0.5) : borderColor,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              category == 'All' ? 'All devices' : category,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? color : secondaryText,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '· $count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? color : secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(String category) {
    final name = category.toLowerCase();

    if (name.contains('smart')) {
      return const Color(0xFF0795A4);
    }
    if (name.contains('sense')) {
      return const Color(0xFF299E60);
    }
    if (name.contains('rtu')) {
      return const Color(0xFF3975E8);
    }
    if (name.contains('pump')) {
      return const Color(0xFFEA850C);
    }
    if (name.contains('level')) {
      return const Color(0xFF9461CE);
    }

    return const Color(0xFF64748B);
  }

  Widget _buildCategoryBadge(String category) {
    final color = _categoryColor(category);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 7,
            width: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              category,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // STATUS
  // --------------------------------------------------

  Widget _buildStatusBadge(int status) {
    final isFree = status == 3;

    final color = isFree
        ? const Color(0xFFD97706)
        : const Color(0xFF269B5D);

    final background = isFree
        ? const Color(0xFFFFF0DC)
        : const Color(0xFFE4F3EA);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 7,
            width: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isFree ? 'Free' : 'Active',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // DATE
  // --------------------------------------------------

  Widget _buildDateCell(
      String date,
      CustomerProductViewModel viewModel,
      ) {
    final parsedDate = DateTime.tryParse(date);

    String relativeDate = '';

    if (parsedDate != null) {
      final now = DateTime.now();

      final difference = DateTime(
        now.year,
        now.month,
        now.day,
      ).difference(
        DateTime(
          parsedDate.year,
          parsedDate.month,
          parsedDate.day,
        ),
      ).inDays;

      if (difference == 0) {
        relativeDate = 'Today';
      } else if (difference == 1) {
        relativeDate = 'Yesterday';
      } else if (difference > 1 && difference < 30) {
        relativeDate = '$difference days ago';
      } else if (difference >= 30) {
        relativeDate = '${(difference / 30).floor()} month ago';
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          viewModel.getDateTime(date),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        if (relativeDate.isNotEmpty)
          Text(
            relativeDate,
            style: const TextStyle(
              fontSize: 11,
              color: secondaryText,
            ),
          ),
      ],
    );
  }

  // --------------------------------------------------
  // MOBILE VIEW
  // --------------------------------------------------

  Widget _buildMobileContent(
      List products,
      List<String> categories,
      List<String> sites,
      List filteredProducts,
      List pageProducts,
      int activeCount,
      ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: _buildSummarySection(
            total: products.length,
            active: activeCount,
            sites: sites.length,
            categories: categories.length,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _buildSearchSection(sites),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: _buildCategoryFilters(categories, products),
        ),
        Expanded(
          child: filteredProducts.isEmpty
              ? const Center(
            child: Text('No devices found'),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: pageProducts.length,
            itemBuilder: (context, index) {
              final device = pageProducts[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildCategoryBadge(
                            device.categoryName,
                          ),
                        ),
                        _buildStatusBadge(
                          device.productStatus,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _mobileDetail('Model Name', device.model),
                    _mobileDetail('Device ID', device.deviceId),
                    _mobileDetail(
                      'Site Name',
                      device.productStatus == 3
                          ? '-'
                          : device.siteName,
                    ),
                    _mobileDetail(
                      'Modify Date',
                      device.modifyDate,
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

  Widget _mobileDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: secondaryText,
              ),
            ),
          ),
          const Text(':  '),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// TABLE HEADING
// --------------------------------------------------

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: Color(0xFF718692),
      ),
    );
  }
}