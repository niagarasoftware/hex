import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class DiseaseScreen extends StatefulWidget {
  const DiseaseScreen({super.key});

  @override
  State<DiseaseScreen> createState() => _DiseaseScreenState();
}

class _DiseaseScreenState extends State<DiseaseScreen>
    with SingleTickerProviderStateMixin {
  XFile? _image;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _image = photo;
        });
        _runScanningEffect();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error capturing image: $e");
      }
    }
  }

  Future<void> _runScanningEffect() async {
    setState(() {
      _isScanning = true;
    });
    _animationController.repeat(reverse: true);

    await Future.delayed(const Duration(seconds: 4));

    if (mounted) {
      setState(() {
        _isScanning = false;
      });
      _animationController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildScanningBanner(context),
                  const SizedBox(height: 20),
                  Text(
                    _image == null ? 'Crop Management' : 'Analysis Results',
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      const spacing = 12.0;
                      int columns = 1;
                      if (width >= 900) {
                        columns = 2;
                      }

                      final itemWidth =
                          (width - (spacing * (columns - 1))) / columns;

                      final cards = [
                        _buildInfoCard(
                          context,
                          icon: Icons.science_outlined,
                          title: 'Fertigation Health',
                          description: (_isScanning || _image == null)
                              ? 'Analyzing fertilizer levels...'
                              : 'A total of 50 kg of fertilizer was successfully applied. Nitrogen levels are optimal for crop growth.',
                        ),
                        _buildInfoCard(
                          context,
                          icon: Icons.water_drop_outlined,
                          title: 'Water Management',
                          description: (_isScanning || _image == null)
                              ? 'Calculating soil moisture...'
                              : 'Irrigation cycle efficient. Soil moisture is at 68%. Next watering scheduled for 6:00 PM.',
                        ),
                        _buildInfoCard(
                          context,
                          icon: Icons.bug_report_outlined,
                          title: 'Disease & Pathogen Risks',
                          description: (_isScanning || _image == null)
                              ? 'Detecting pathogens...'
                              : (_image == null
                              ? 'No data from satellite yet.'
                              : 'Possible Early Blight detected in lower leaves. Risk level: Low. Action: Monitor closely.'),
                        ),
                        _buildInfoCard(
                          context,
                          icon: Icons.health_and_safety_outlined,
                          title: 'Pest Management',
                          description: (_isScanning || _image == null)
                              ? 'Analyzing pest activity...'
                              : 'Prestige status: Safe. Natural predators observed. No chemical pesticides required currently.',
                        ),
                      ];

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: cards.map((card) {
                          return SizedBox(width: itemWidth, child: card);
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: FloatingActionButton.extended(
          onPressed: _isScanning ? null : _takePhoto,
          backgroundColor:
          _isScanning ? colorScheme.outline : colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          icon: const Icon(Icons.photo_camera_rounded),
          label: Text(
            _isScanning ? "Scanning..." : "Scan Crop Health",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildScanningBanner(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: kIsWeb ? 320 : 240,
      width: double.infinity,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: _image == null
                      ? const NetworkImage(
                    'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?q=80&w=2070&auto=format&fit=crop',
                  )
                      : (kIsWeb
                      ? NetworkImage(_image!.path)
                      : FileImage(File(_image!.path))) as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            if (_isScanning)
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Positioned(
                    top: _animationController.value *
                        (kIsWeb ? 320 : 240),
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.8),
                            blurRadius: 15,
                            spreadRadius: 15,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            if (_isScanning)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: colorScheme.primary),
                        const SizedBox(height: 12),
                        Text(
                          "Scanning for Health Issues...",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _image == null
                      ? 'Generated by Satellite Imagery Services'
                      : 'Field Analysis: Captured Image',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: InkWell(
                onTap: () {
                  _image == null ? _takePhoto() : _runScanningEffect();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.fullscreen,
                    size: 20,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String description,
      }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
