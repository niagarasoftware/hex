import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfo extends StatefulWidget {
  const AppInfo({super.key});

  static const String appName = 'VIOM Irrigation';

  @override
  State<AppInfo> createState() => _AppInfoState();
}

class _AppInfoState extends State<AppInfo> {
  late final Future<PackageInfo> _packageInfo;

  @override
  void initState() {
    super.initState();
    _packageInfo = PackageInfo.fromPlatform();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,

      appBar: AppBar(
        title: const Text('App Info'),
        elevation: 0,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        surfaceTintColor: cs.primary,
      ),

      body: FutureBuilder<PackageInfo>(
        future: _packageInfo,
        builder: (context, snapshot) {
          final version = snapshot.data?.version ?? '—';
          final buildNumber =
              snapshot.data?.buildNumber ?? '—';

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),

              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  maxWidth: 420,
                ),

                clipBehavior: Clip.antiAlias,

                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: cs.outlineVariant,
                  ),
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // Orange top accent
                    Container(
                      width: double.infinity,
                      height: 5,
                      color: cs.secondary,
                    ),

                    Padding(
                      padding: const EdgeInsets.all(28),

                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          // Application Icon
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              color: cs.secondary,
                              borderRadius:
                              BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.water_drop_outlined,
                              size: 40,
                              color: cs.onSecondary,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Application Name
                          Text(
                            AppInfo.appName,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Subtitle
                          Text(
                            'Smart Irrigation Management',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Orange Accent Line
                          Container(
                            width: 44,
                            height: 3,
                            decoration: BoxDecoration(
                              color: cs.secondary,
                              borderRadius:
                              BorderRadius.circular(10),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Version & Build Information
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius:
                              BorderRadius.circular(12),
                            ),

                            child: Column(
                              children: [
                                _infoRow(
                                  context,
                                  Icons.info_outline_rounded,
                                  'Version',
                                  version,
                                ),

                                const SizedBox(height: 12),

                                Divider(
                                  height: 1,
                                  color: cs.onPrimaryContainer
                                      .withOpacity(0.15),
                                ),

                                const SizedBox(height: 12),

                                _infoRow(
                                  context,
                                  Icons.build_outlined,
                                  'Build Number',
                                  buildNumber,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Application Description
                          Text(
                            'Monitor and manage irrigation '
                                'controllers, pumps, valves and sensors.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 24),

                          Divider(
                            height: 1,
                            color: cs.outlineVariant,
                          ),

                          const SizedBox(height: 20),

                          // Copyright
                          Text(
                            '© ${DateTime.now().year} '
                                '${AppInfo.appName}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(
      BuildContext context,
      IconData icon,
      String label,
      String value,
      ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: cs.onPrimaryContainer,
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onPrimaryContainer,
            ),
          ),
        ),

        const SizedBox(width: 12),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}