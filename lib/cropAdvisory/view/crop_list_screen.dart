import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hex/cropAdvisory/view/crop_advisory_main_screen.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import 'package:hex/utils/helpers/log_print.dart';
import '../../utils/snack_bar.dart';
import '../model/cropadvisory_model.dart';
import 'getUserInformationScreen.dart';

class CropListScreen extends StatefulWidget {
  const CropListScreen({
    super.key,
    required this.userId,
    required this.controllerId,
    this.isInsideTabs = false,
  });

  final int userId, controllerId;
  final bool isInsideTabs;

  @override
  State<CropListScreen> createState() => _CropListScreenState();
}

class _CropListScreenState extends State<CropListScreen> {
  bool _isLoading = true;
  List<CropAdvisoryModel> cropList = [];
  int cropId = 1;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final repository = Repository(HttpService());

      final response = await repository.getCropList({
        "userId": widget.userId,
        "controllerId": widget.controllerId,
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> cropData = body['data'];

        setState(() {
          cropList =
              cropData.map((e) => CropAdvisoryModel.fromJson(e)).toList();
          cropId = cropData.length + 1;
        });
      }
    } catch (e) {
      AppLog.log(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> deleteCropList(int cropId) async {
    try {
      final repository = Repository(HttpService());

      final response = await repository.deleteCropList({
        "userId": widget.userId,
        "controllerId": widget.controllerId,
        "cropId": cropId
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (mounted) {
          GlobalSnackBar.show(context, body['message'], response.statusCode);
        }
        setState(() {
          fetchData();
        });
      }
    } catch (e) {
      AppLog.log(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: !widget.isInsideTabs,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (widget.isInsideTabs) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: Text(
            "Crop Advisory",
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          leading: widget.isInsideTabs
              ? IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(),
          )
              : null,
        ),
        body: _isLoading
            ? Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        )
            : SafeArea(
          child: SingleChildScrollView(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDashboardSummaryHeader(context),
                    const SizedBox(height: 20),
                    if (cropList.isEmpty)
                      _buildEmptyState(context)
                    else
                      _buildCropGrid(context),
                  ],
                ),
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            CropAdvisoryModel.instance.reset();
            CropAdvisoryModel.instance.userId = widget.userId;
            CropAdvisoryModel.instance.controllerId = widget.controllerId;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Cropinformationscreen(
                  userId: widget.userId,
                  controllerId: widget.controllerId,
                  cropId: cropId,
                  edit: false,
                ),
              ),
            );
            fetchData();
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            "Create Crop",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildDashboardSummaryHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.energy_savings_leaf_outlined,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crop Management Center',
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Track crop cycles, weather forecasts, disease risks, and irrigation recommendations.',
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 12.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _buildStatChip(
                context: context,
                icon: Icons.grass_rounded,
                label: 'Total Crops',
                value: '${cropList.length}',
              ),
              _buildStatChip(
                context: context,
                icon: Icons.shield_outlined,
                label: 'Status',
                value: 'Active Monitoring',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              Icons.energy_savings_leaf_outlined,
              size: 32,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Crops Created Yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create your first crop profile to unlock AI-powered irrigation, weather, and disease advisories.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const spacing = 16.0;
        int columns = 1;
        if (width >= 900) {
          columns = 3;
        } else if (width >= 600) {
          columns = 2;
        }

        final itemWidth = (width - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cropList.map((crop) {
            return SizedBox(
              width: itemWidth,
              child: _buildCropCard(context, crop),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCropCard(BuildContext context, CropAdvisoryModel crop) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Band
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.eco_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crop.cropName ?? 'Unnamed Crop',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        crop.farmName ?? 'Farm',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  context: context,
                  icon: Icons.spa_outlined,
                  label: 'Variety',
                  value: crop.cropVariety ?? 'N/A',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  context: context,
                  icon: Icons.category_outlined,
                  label: 'Crop Type',
                  value: crop.cropType ?? 'N/A',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  context: context,
                  icon: Icons.landscape_outlined,
                  label: 'Soil Type',
                  value: crop.soilTypeName.isNotEmpty
                      ? crop.soilTypeName
                      : 'N/A',
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            thickness: 0.5,
            color: colorScheme.outlineVariant.withOpacity(0.3),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      if (widget.isInsideTabs) {
                        Navigator.of(context, rootNavigator: true)
                            .pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => CropAdvisoryMainScreen(
                              userId: widget.userId,
                              controllerId: widget.controllerId,
                              cropModel: crop,
                            ),
                          ),
                          (route) => route.isFirst,
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CropAdvisoryMainScreen(
                              userId: widget.userId,
                              controllerId: widget.controllerId,
                              cropModel: crop,
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.analytics_outlined, size: 16),
                    label: const Text(
                      'Open Advisory',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Edit Crop',
                  icon: Icon(Icons.edit_outlined, color: colorScheme.primary),
                  onPressed: () async {
                    CropAdvisoryModel.instance.fromJson(crop.toJson());
                    CropAdvisoryModel.instance.cropId = crop.cropId;
                    CropAdvisoryModel.instance.userId = widget.userId;
                    CropAdvisoryModel.instance.controllerId =
                        widget.controllerId;

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Cropinformationscreen(
                          userId: widget.userId,
                          controllerId: widget.controllerId,
                          cropId: crop.cropId!,
                          edit: true,
                        ),
                      ),
                    );
                    fetchData();
                  },
                ),
                IconButton(
                  tooltip: 'Delete Crop',
                  icon: Icon(Icons.delete_outline_rounded,
                      color: colorScheme.error),
                  onPressed: () async {
                    bool? confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: colorScheme.surface,
                        title: const Text("Delete Crop"),
                        content: const Text(
                            "Are you sure you want to delete this crop profile?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.error,
                              foregroundColor: colorScheme.onError,
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Delete"),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      deleteCropList(crop.cropId!);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12.5,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
