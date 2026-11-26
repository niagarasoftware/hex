import 'package:flutter/material.dart';
import '../../models/customer/site_model.dart';

class InputOutputConnectionDetails extends StatefulWidget {
  const InputOutputConnectionDetails({
    super.key,
    required this.masterInx,
    required this.nodes,
  });

  final int masterInx;
  final List<NodeListModel> nodes;

  @override
  State<InputOutputConnectionDetails> createState() =>
      _InputOutputConnectionDetailsState();
}

class _InputOutputConnectionDetailsState
    extends State<InputOutputConnectionDetails> {
  String selectedCategory = 'ALL';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, int> _getCategoryCounts() {
    final counts = <String, int>{'ALL': widget.nodes.length};
    for (final node in widget.nodes) {
      final cat = node.categoryName.isNotEmpty ? node.categoryName : 'OTHER';
      counts[cat] = (counts[cat] ?? 0) + 1;
    }
    return counts;
  }

  List<NodeListModel> _getFilteredNodes() {
    return widget.nodes.where((node) {
      // 1. Category Filter
      if (selectedCategory != 'ALL' &&
          node.categoryName.toUpperCase() != selectedCategory.toUpperCase()) {
        return false;
      }

      // 2. Search Query Filter
      if (searchQuery.trim().isEmpty) return true;

      final query = searchQuery.trim().toLowerCase();
      final nameMatch = node.deviceName.toLowerCase().contains(query) ||
          node.categoryName.toLowerCase().contains(query);
      final serialMatch = node.deviceId.toLowerCase().contains(query) ||
          node.serialNumber.toString().contains(query);

      final outputMatch = node.rlyStatus.any((rly) {
        final rlyName = rly.name?.toLowerCase() ?? '';
        final swName = rly.swName?.toLowerCase() ?? '';
        final rlyNoStr = 'do-${rly.rlyNo}';
        return rlyName.contains(query) ||
            swName.contains(query) ||
            rlyNoStr.contains(query) ||
            rly.rlyNo.toString() == query;
      });

      return nameMatch || serialMatch || outputMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryCounts = _getCategoryCounts();
    final filteredNodes = _getFilteredNodes();

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Output Mapping '),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // -------------------------------------------------------------------
          // 1. Device Type Horizontal Filter Navigation Tabs
          // -------------------------------------------------------------------
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: colorScheme.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categoryCounts.entries.map((entry) {
                  final catName = entry.key;
                  final count = entry.value;
                  final isSelected = selectedCategory.toUpperCase() ==
                      catName.toUpperCase();

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectedCategory = catName;
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                catName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colorScheme.onPrimary.withOpacity(0.2)
                                      : colorScheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? colorScheme.onPrimary
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Divider(height: 1, color: colorScheme.outlineVariant),

          // -------------------------------------------------------------------
          // 2. Search Field Section
          // -------------------------------------------------------------------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: colorScheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                      onChanged: (val) {
                        setState(() {
                          searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText:
                            'Search by device name, serial number, output ID, or output name...',
                        hintStyle: TextStyle(
                          fontSize: 12.5,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  size: 18,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: colorScheme.outlineVariant),

          // -------------------------------------------------------------------
          // 3. Filtered Devices List / Output Mapping Grid
          // -------------------------------------------------------------------
          Expanded(
            child: filteredNodes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No devices or outputs match your filter',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredNodes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final node = filteredNodes[index];
                      return _NodeDeviceCard(
                        node: node,
                        masterIndex: widget.masterInx,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NodeDeviceCard extends StatelessWidget {
  final NodeListModel node;
  final int masterIndex;

  const _NodeDeviceCard({
    required this.node,
    required this.masterIndex,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxOutputs =
        int.tryParse(node.relayOutput) ?? node.rlyStatus.length;
    final totalOutputs =
        maxOutputs > node.rlyStatus.length ? maxOutputs : node.rlyStatus.length;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Device Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    node.categoryName.isNotEmpty
                        ? node.categoryName
                        : node.deviceName,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimaryContainer.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    node.deviceId,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Output Mapping Grid
          Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 10.0;
                final width = constraints.maxWidth;

                int columns = 1;
                if (width >= 1200) {
                  columns = 5;
                } else if (width >= 900) {
                  columns = 4;
                } else if (width >= 600) {
                  columns = 3;
                } else if (width >= 400) {
                  columns = 2;
                }

                final tileWidth =
                    (width - (spacing * (columns - 1))) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: List.generate(totalOutputs, (outputIdx) {
                    final outputNo = outputIdx + 1;
                    RelayStatus? rly;
                    try {
                      rly = node.rlyStatus.firstWhere(
                        (r) => r.rlyNo == outputNo,
                      );
                    } catch (_) {
                      rly = RelayStatus(
                        sNo: -1,
                        name: 'N/A',
                        swName: 'N/A',
                        rlyNo: outputNo,
                        objType: '',
                      );
                    }

                    return SizedBox(
                      width: tileWidth,
                      child: _OutputTile(
                        outputNo: outputNo,
                        relay: rly,
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OutputTile extends StatelessWidget {
  final int outputNo;
  final RelayStatus? relay;

  const _OutputTile({
    required this.outputNo,
    required this.relay,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final name = (relay?.name == 'N/A' || relay?.name == '--')
        ? ''
        : (relay?.name ?? '');
    final swName = (relay?.swName == 'N/A' || relay?.swName == '--')
        ? ''
        : (relay?.swName ?? '');

    final isFree = name.isEmpty && swName.isEmpty;

    String displayText = 'Free output';
    if (!isFree) {
      if (name.isNotEmpty && swName.isNotEmpty && name != swName) {
        displayText = '$name • $swName';
      } else if (name.isNotEmpty) {
        displayText = name;
      } else {
        displayText = swName;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isFree
            ? colorScheme.surfaceContainerLowest
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isFree
              ? colorScheme.outlineVariant.withOpacity(0.5)
              : colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // DO-N Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isFree
                  ? colorScheme.outlineVariant.withOpacity(0.3)
                  : colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'DO-$outputNo',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color:
                    isFree ? colorScheme.onSurfaceVariant : colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Output Name
          Expanded(
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isFree ? FontWeight.normal : FontWeight.w600,
                color:
                    isFree ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                fontStyle: isFree ? FontStyle.italic : FontStyle.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 6),

          // Plus Action Button
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () {
                // Action callback for output mapping configuration
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 17,
                  color: colorScheme.onSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
