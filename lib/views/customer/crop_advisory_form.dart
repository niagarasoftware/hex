import 'dart:convert';

import 'package:flutter/material.dart';

import '../../repository/repository.dart';
import '../../services/http_service.dart';

class CropAdvisoryForm extends StatefulWidget {
  const CropAdvisoryForm({
    super.key,
    required this.customerId,
    required this.controllerId,
    required this.isNarrow,
  });

  final int customerId, controllerId;
  final bool isNarrow;

  @override
  State<CropAdvisoryForm> createState() => _CropAdvisoryFormPageState();
}

class _CropAdvisoryFormPageState extends State<CropAdvisoryForm> {
  final _formKey = GlobalKey<FormState>();

  String? cropName, variety, stage, soilType, irrigationType, location;
  String? rainfall, waterSource, fertilizerUsed, fertilizerFreq;
  DateTime? sowingDate;
  late TextEditingController _dateController,
      _cvController,
      _sphController,
      _faController,
      _lfuController,
      _ldController;

  bool isEnabled = true;

  final Map<String, List<String>> crops = {
    "Crops": [
      "Cotton",
      "Sugarcane",
      "Maize",
      "Groundnut",
      "Wheat",
      "Tomato",
      "Chilli",
      "Brinjal",
      "Okra",
      "Cabbage",
      "Cauliflower",
      "Cucumber",
      "Capsicum",
      "Pumpkin",
      "Bitter Gourd",
      "Banana",
      "Pomegranate",
      "Papaya",
      "Grapes",
      "Mango",
      "Guava",
      "Sweet Lime",
      "Orange",
      "Watermelon",
      "Muskmelon",
      "Turmeric",
      "Ginger",
      "Aloe Vera",
      "Ashwagandha",
      "Tulsi",
      "Coconut",
      "Arecanut",
      "Coffee",
      "Tea",
      "Rubber"
    ],
  };

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController();
    _cvController = TextEditingController();
    _sphController = TextEditingController();
    _faController = TextEditingController();
    _lfuController = TextEditingController();
    _ldController = TextEditingController();
    getSiteData();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _cvController.dispose();
    _sphController.dispose();
    _faController.dispose();
    _lfuController.dispose();
    _ldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: widget.isNarrow
          ? AppBar(
        title: Text(
          "Crop Advisory Setup",
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          Row(
            children: [
              Text(
                isEnabled ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isEnabled
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: isEnabled,
                  activeThumbColor: colorScheme.onPrimary,
                  activeTrackColor: colorScheme.primary,
                  inactiveTrackColor: colorScheme.surfaceContainerHighest,
                  onChanged: (value) {
                    setState(() {
                      isEnabled = value;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? "Crop Advisory activated"
                              : "Crop Advisory deactivated",
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ],
      )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _buildMinimalHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildCropProfileHeroCard(context),
                          const SizedBox(height: 20),
                          _buildGrowthStageSection(context),
                          const SizedBox(height: 20),
                          _buildSoilLandSection(context),
                          const SizedBox(height: 20),
                          _buildIrrigationSection(context),
                          const SizedBox(height: 20),
                          _buildWaterSourceSection(context),
                          const SizedBox(height: 20),
                          _buildFertilizerSection(context),
                          const SizedBox(height: 20),
                          _buildLocationSection(context),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildBottomActionBar(context),
          ],
        ),
      ),
    );
  }

  // 1. Page Header
  Widget _buildMinimalHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crop Advisory Setup',
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Field Configuration Studio',
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (!widget.isNarrow)
                Row(
                  children: [
                    Text(
                      isEnabled ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: isEnabled
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Transform.scale(
                      scale: 0.75,
                      child: Switch(
                        value: isEnabled,
                        activeThumbColor: colorScheme.onPrimary,
                        activeTrackColor: colorScheme.primary,
                        inactiveTrackColor: colorScheme.surfaceContainerHighest,
                        onChanged: (value) {
                          setState(() {
                            isEnabled = value;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value
                                    ? "Crop Advisory activated"
                                    : "Crop Advisory deactivated",
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Crop Profile Hero Card
  Widget _buildCropProfileHeroCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cropName ?? 'Select Crop Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Stage: ${stage ?? 'Not Set'}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.eco_rounded,
                    color: colorScheme.primary,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              if (width >= 700) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildExternalLabel(context, "Crop Name"),
                          _buildDropdownInput(context, crops['Crops']!,
                                  (val) => setState(() => cropName = val),
                              selected: cropName),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildExternalLabel(context, "Crop Variety / Hybrid"),
                          _buildTextInput(context, _cvController,
                              hint: "e.g. Hybrid Tomato 501"),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildExternalLabel(context, "Sowing Date"),
                          _buildDateFieldInput(context, (val) {
                            debugPrint("Selected Date: $val");
                          }),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildExternalLabel(context, "Crop Name"),
                  _buildDropdownInput(context, crops['Crops']!,
                          (val) => setState(() => cropName = val),
                      selected: cropName),
                  const SizedBox(height: 12),
                  _buildExternalLabel(context, "Crop Variety / Hybrid"),
                  _buildTextInput(context, _cvController,
                      hint: "e.g. Hybrid Tomato 501"),
                  const SizedBox(height: 12),
                  _buildExternalLabel(context, "Sowing Date"),
                  _buildDateFieldInput(context, (val) {
                    debugPrint("Selected Date: $val");
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // 3. Growth Stage — Visual Selection Cards
  Widget _buildGrowthStageSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stages = [
      {"name": "Germination", "icon": Icons.eco_outlined, "desc": "Seedling & Sprouting"},
      {"name": "Flowering", "icon": Icons.local_florist_outlined, "desc": "Bloom & Pollination"},
      {"name": "Harvest", "icon": Icons.content_cut_outlined, "desc": "Ripening & Picking"},
    ];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
              context, Icons.energy_savings_leaf_outlined, "Growth Stage"),
          const SizedBox(height: 14),
          Row(
            children: stages.map((st) {
              final stName = st['name'] as String;
              final isSelected = stage == stName;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        stage = stName;
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                            : colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            st['icon'] as IconData,
                            size: 26,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            stName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            st['desc'] as String,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 4. Soil & Land — Image-Based Selection Cards
  Widget _buildSoilLandSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final soils = [
      {"name": "Loamy", "asset": "assets/Images/CropAdvisory/loam_soil.png"},
      {"name": "Clay", "asset": "assets/Images/CropAdvisory/clay_soil.png"},
      {"name": "Red", "asset": "assets/Images/CropAdvisory/Volcanic_soil.png"},
    ];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(context, Icons.landscape_outlined, "Soil & Land"),
          const SizedBox(height: 14),
          Row(
            children: soils.map((st) {
              final stName = st['name'] as String;
              final isSelected = soilType == stName;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        soilType = stName;
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                            : colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(13),
                            ),
                            child: Image.asset(
                              st['asset'] as String,
                              height: 65,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 65,
                                color: colorScheme.surfaceContainerHigh,
                                child: Icon(Icons.terrain,
                                    color: colorScheme.onSurfaceVariant),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              '$stName Soil',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExternalLabel(context, "Soil pH Level"),
                    _buildTextInput(context, _sphController, hint: "e.g. 6.5"),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExternalLabel(context, "Field Area (acres)"),
                    _buildTextInput(context, _faController, hint: "e.g. 10.5"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 5. Irrigation — Illustrated Selection Cards
  Widget _buildIrrigationSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final types = [
      {"name": "Drip", "icon": Icons.water_drop_outlined, "desc": "Precision Drop Dosing"},
      {"name": "Sprinkler", "icon": Icons.opacity_outlined, "desc": "Overhead Rain Spray"},
    ];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
              context, Icons.water_drop_outlined, "Irrigation System Type"),
          const SizedBox(height: 14),
          Row(
            children: types.map((st) {
              final stName = st['name'] as String;
              final isSelected = irrigationType == stName;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        irrigationType = stName;
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                            : colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            st['icon'] as IconData,
                            size: 24,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$stName Irrigation',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  st['desc'] as String,
                                  style: TextStyle(
                                    fontSize: 10.5,
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
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 6. Water Source — Icon Selection Tiles
  Widget _buildWaterSourceSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sources = [
      {"name": "Bore-well", "icon": Icons.tire_repair_outlined},
      {"name": "Tank", "icon": Icons.storage_outlined},
      {"name": "Canal", "icon": Icons.alt_route_outlined},
      {"name": "River", "icon": Icons.waves_outlined},
    ];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
              context, Icons.waves_outlined, "Primary Water Source"),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sources.map((st) {
              final stName = st['name'] as String;
              final isSelected = waterSource == stName;

              return SizedBox(
                width: 125,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      waterSource = stName;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                          : colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          st['icon'] as IconData,
                          size: 18,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            stName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 7. Fertilizer Info
  Widget _buildFertilizerSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final freqs = ["Daily", "Weekly", "Biweekly", "Monthly"];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
              context, Icons.science_outlined, "Fertilizer Information"),
          const SizedBox(height: 14),
          _buildExternalLabel(context, "Last Fertilizer Used"),
          _buildTextInput(context, _lfuController, hint: "e.g. NPK 19:19:19"),
          const SizedBox(height: 16),
          _buildExternalLabel(context, "Fertilizer Application Frequency"),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: freqs.map((f) {
              final isSelected = fertilizerFreq == f;

              return ChoiceChip(
                label: Text(f),
                selected: isSelected,
                selectedColor: colorScheme.primary,
                backgroundColor: colorScheme.surfaceContainerLow,
                labelStyle: TextStyle(
                  color:
                  isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                  ),
                ),
                onSelected: (selected) {
                  setState(() {
                    fertilizerFreq = selected ? f : null;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 8. Field Location
  Widget _buildLocationSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
              context, Icons.location_on_outlined, "Field Location"),
          const SizedBox(height: 14),
          _buildExternalLabel(context, "Location / District"),
          _buildTextInput(context, _ldController,
              hint: "e.g. Coimbatore, Tamil Nadu"),
        ],
      ),
    );
  }

  // 9. Persistent Bottom Action Bar
  Widget _buildBottomActionBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${cropName ?? 'No Crop Selected'} (${stage ?? 'Stage N/A'})',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${irrigationType ?? 'Irrigation N/A'} • ${soilType ?? 'Soil N/A'}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
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
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final data = {
                      "cropName": cropName,
                      "cropVariety": _cvController.text,
                      "sowingDate": sowingDate?.toIso8601String(),
                      "stage": stage,
                      "soilType": soilType,
                      "soilPh": _sphController.text,
                      "fieldArea": _faController.text,
                      "irrigationType": irrigationType,
                      "waterSource": waterSource,
                      "lastFertilizerUsed": _lfuController.text,
                      "fertilizerFrequency": fertilizerFreq,
                      "location": _ldController.text,
                    };
                    updateSiteData(context, data);
                  }
                },
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text(
                  "Save Details",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper UI Components
  Widget _buildSectionHeading(BuildContext context, IconData icon, String title) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildExternalLabel(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildTextInput(
      BuildContext context, TextEditingController controller,
      {required String hint}) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      style: TextStyle(fontSize: 13.5, color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        fillColor: colorScheme.surfaceContainerLow,
        filled: true,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildDropdownInput(
      BuildContext context, List<String> items, Function(String?) onChanged,
      {String? selected}) {
    final colorScheme = Theme.of(context).colorScheme;

    return DropdownButtonFormField<String>(
      initialValue: selected,
      dropdownColor: colorScheme.surface,
      style: TextStyle(fontSize: 13.5, color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: 'Select Crop',
        isDense: true,
        fillColor: colorScheme.surfaceContainerLow,
        filled: true,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Required' : null,
    );
  }

  Widget _buildDateFieldInput(
      BuildContext context, Function(DateTime) onDatePicked) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            sowingDate = picked;
            _dateController.text = "${picked.toLocal()}".split(' ')[0];
          });
          onDatePicked(picked);
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: _dateController,
          style: TextStyle(fontSize: 13.5, color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Select Date',
            isDense: true,
            fillColor: colorScheme.surfaceContainerLow,
            filled: true,
            suffixIcon:
            Icon(Icons.calendar_month, color: colorScheme.primary),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          validator: (_) => sowingDate == null ? 'Select a date' : null,
        ),
      ),
    );
  }

  Future<void> getSiteData() async {
    try {
      Map<String, Object> body = {
        "userId": widget.customerId,
        "controllerId": widget.controllerId,
      };
      final response =
      await Repository(HttpService()).fetchSiteAiAdvisoryData(body);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData["code"] == 200) {
          final data = jsonData['data'];
          if (data != null && data.isNotEmpty) {
            cropName = data['cropName'];
            _cvController.text = data['cropVariety'] ?? '';

            if (data['sowingDate'] != null &&
                data['sowingDate'].toString().isNotEmpty) {
              sowingDate =
                  DateTime.tryParse(data['sowingDate'].split('T')[0]);
              if (sowingDate != null) {
                _dateController.text =
                "${sowingDate!.year}-${sowingDate!.month.toString().padLeft(2, '0')}-${sowingDate!.day.toString().padLeft(2, '0')}";
              }
            }

            stage = data['stage'];
            soilType = data['soilType'];
            _sphController.text = data['soilPh'] ?? '';
            _faController.text = data['fieldArea'] ?? '';
            irrigationType = data['irrigationType'];
            waterSource = data['waterSource'];
            _lfuController.text = data['lastFertilizerUsed'] ?? '';
            fertilizerFreq = data['fertilizerFrequency'];
            location = data['location'];
            _ldController.text = location ?? '';

            setState(() {});
          }
        }
      }
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  Future<void> updateSiteData(
      BuildContext context, Map<String, String?> data) async {
    try {
      Map<String, Object> body = {
        "userId": widget.customerId,
        "controllerId": widget.controllerId,
        "aiAdvisory": data,
        "modifyUser": widget.customerId,
      };
      final response =
      await Repository(HttpService()).updateSiteAiAdvisoryData(body);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData["code"] == 200) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(jsonData["message"])),
          );
        }
      }
    } catch (error) {
      debugPrint(error.toString());
    }
  }
}
